// Find code in which there is the following pattern:
//
// 1. Load from memory via variable X
// 2. Write to memory through a character type
// 3. Load from memory via variable X
//
// And in betwween 1 and 3 X is not modified
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

// False positives due to accesses being writes
from
  Expr w, Expr a1, Expr a2, Variable accessVar
where
  (
    isWriteThroughMemDeref(w) and 
    a1 = w.getAPredecessor+() and
    w = a2.getAPredecessor+() and
    a1 instanceof PointerDereferenceExpr and a2 instanceof PointerDereferenceExpr and 
    // We to get the variable holding the base pointer for the accesses. There are a few ways a
    // PointerDerefrenceExpr may be formed.
    (
      // Case 0: *(ptr->x)
      (accessVar = a1.(PointerDereferenceExpr).getOperand().(PointerFieldAccess).getQualifier().(VariableAccess).getTarget() and 
      // Assert that a1 and a2 use the same base pointer
      accessVar = a2.(PointerDereferenceExpr).getOperand().(PointerFieldAccess).getQualifier().(VariableAccess).getTarget())
      
      or
      // Case1: *ptr
      // We must assert that the operand is not a PointerFieldAccess, as a PointerFieldAccess
      // is a subclass of VariableAccess and if we don't eliminate this this case can end up
      // asserting `accessVar = x` in a ptr->x.

      (not a1.(PointerDereferenceExpr).getOperand() instanceof PointerFieldAccess and
      accessVar = a1.(PointerDereferenceExpr).getOperand().(VariableAccess).getTarget() and
      // Assert that a1 and a2 use the same base pointer
      accessVar = a2.(PointerDereferenceExpr).getOperand().(VariableAccess).getTarget())
    ) and
    
    // Eliminate cases where the variable holding the base pointer is modified
    not exists(AssignExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getLValue().(VariableAccess).getTarget() = accessVar) and
    not exists(PostfixIncrExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getOperand().(VariableAccess).getTarget() = accessVar) and
    not exists(PrefixIncrExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getOperand().(VariableAccess).getTarget() = accessVar) and
    not exists(PostfixDecrExpr redef| redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getOperand().(VariableAccess).getTarget() = accessVar) and
    not exists(PostfixIncrExpr redef | redef = a1.getASuccessor+() and redef = a2.getAPredecessor+() and redef.getOperand().(VariableAccess).getTarget() = accessVar) 
  )
select a1.getLocation().getFile().getBaseName(), a1, w, a2, accessVar, "Found ..."
