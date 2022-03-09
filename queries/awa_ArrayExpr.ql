// Find code in which there is the following pattern:
//
// 1. Load from memory via variable X
// 2. Write to memory through a character type
// 3. Load from memory via variable X
//
// And in betwween 1 and 3 X is not modified
// Problems:
// 1. False positives due to memory references being on the stack
// 2. False negatives due to the 'base not modified' check limiting base to 
//    only be a Variable. i.e. this excludes something like 'buf[i]' as a base in 'buf[i][j]'.

// SEEMS TO BE A PROBLEM AT THE MOMENT WHEREBY I ONLY EVER GET RESULTS WHERE THE TWO ACCESSES ARE THE IDERNTICAL SAME ONES
// Perhaps this isn't a problem? Maybe there are no examples in the targets I'm looking at where they are not? I'll 
// get an answer once the recently pushed database with add_vals is analysed. 
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
  Expr w, ArrayExpr a1, ArrayExpr a2, Variable base, Variable offset
where
  (
    isWriteThroughMemDeref(w) and

    // Sequence of execution is a1 -> w -> a2
    a1 = w.getAPredecessor+() and
    w = a2.getAPredecessor+() and


    // a1 and a2 are accesses that use the same base and offset expressions
    a1.getArrayBase() = a2.getArrayBase() and 
    a1.getArrayOffset() = a2.getArrayOffset()  and 
    // a1.getLocation() != a2.getLocation() and

    // Base is not modified between a1 and a2
    base = a1.getArrayBase().(VariableAccess).getTarget() and 
    not exists(AssignExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.getLValue().(VariableAccess).getTarget() = base)
    and not exists (DeclStmt ds, int i | 
        ds = a1.getASuccessor+() 
        and ds = a2.getAPredecessor+()
        and ds.getDeclarationEntry(i).(VariableDeclarationEntry).getVariable() = base
    ) 

    // Offset is not modified between a1 and a2
    and offset = a1.getArrayOffset().(VariableAccess).getTarget() and 
    not exists(AssignExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(AssignExpr).getLValue().(VariableAccess).getTarget() = offset
    )
    and not exists(AssignAddExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(AssignAddExpr).getLValue().(VariableAccess).getTarget() = offset
    )
    and not exists(AssignSubExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(AssignSubExpr).getLValue().(VariableAccess).getTarget() = offset
    )
    and not exists(Expr redef |  
      (
        redef instanceof PostfixIncrExpr
        or redef instanceof PrefixIncrExpr
        or redef instanceof PostfixDecrExpr
        or redef instanceof PostfixIncrExpr
      ) 
      and redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(UnaryOperation).getOperand().(VariableAccess).getTarget() = offset
    )
    and not exists (DeclStmt ds, int i | 
        ds = a1.getASuccessor+() 
        and ds = a2.getAPredecessor+()
        and ds.getDeclarationEntry(i).(VariableDeclarationEntry).getVariable() = offset
    )
  )
select a1.getLocation().getFile().getBaseName(), a1.getLocation().getStartLine(), a1, w, a2, "Found ..."
