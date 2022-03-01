// Find code in which there is the following pattern:
//
// 1. Load from memory via variable X
// 2. Write to memory through a character type
// 3. Load from memory via variable X
//
// And in betwween 1 and 3 X is not modified
// Problems:
// 1. False positives due to memory references being on the stack
// 2. False positives due to base variables changing before second access (e.g. write2d vs write2d_noalias)
import cpp

predicate isWriteThroughMemDeref(Expr e) {
    exists(AssignExpr a, Expr lval |
      a = e.(AssignExpr) and
      lval = a.getLValue() and
      lval.getType().stripType() instanceof CharType and
      (
        lval instanceof PointerDereferenceExpr or
        lval instanceof ArrayExpr or
        lval instanceof OverloadedArrayExpr
      )
    )
  }

from
  Expr w, Expr a1, Expr a2, Variable base, Variable offset
where
  (
    a1 instanceof ArrayExpr and
    a2 instanceof ArrayExpr and
    isWriteThroughMemDeref(w) and

    // Sequence of execution is a1 -> w -> a2
    a1 = w.getAPredecessor+() and
    w = a2.getAPredecessor+() and

    // a1 and a2 are accesses that use the same base and offset expressions
    a1.(ArrayExpr).getArrayBase() = a2.(ArrayExpr).getArrayBase() and 
    a1.(ArrayExpr).getArrayOffset() = a2.(ArrayExpr).getArrayOffset()  and 

    // Base is not modified between a1 and a2
    base = a1.(ArrayExpr).getArrayBase().(VariableAccess).getTarget() and 
    not exists(AssignExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getLValue().(VariableAccess).getTarget() = base) and

    // Offset is not modified between a1 and a2
    offset = a1.(ArrayExpr).getArrayOffset().(VariableAccess).getTarget() and 
    not exists(AssignExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getLValue().(VariableAccess).getTarget() = offset) and
    not exists(PostfixIncrExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getOperand().(VariableAccess).getTarget() = offset) and
    not exists(PrefixIncrExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getOperand().(VariableAccess).getTarget() = offset) 
  )
select a1.getLocation().getFile().getBaseName(), a1, w, a2, "Found ..."
