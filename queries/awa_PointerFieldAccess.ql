
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
    
    (a1 instanceof PointerFieldAccess and a2 instanceof PointerFieldAccess) and
    accessVar = a1.(PointerFieldAccess).getQualifier().(VariableAccess).getTarget() and
    // Assert that a1 and a2 use the same base pointer
    accessVar = a2.(PointerFieldAccess).getQualifier().(VariableAccess).getTarget() and 
    // Assert a1 and a2 access the same field in the struct
    a1.(PointerFieldAccess).getTarget() = a2.(PointerFieldAccess).getTarget() and

    // Eliminate cases where the variable holding the base pointer is modified
    not exists(AssignExpr redef | 
        redef = a1.getASuccessor+() 
        and redef = a2.getAPredecessor+() 
        and redef.(AssignExpr).getLValue().(VariableAccess).getTarget() = accessVar
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
        and redef.(UnaryOperation).getOperand().(VariableAccess).getTarget() = accessVar
    )
    // Eliminate cases where the access variable is redeclared prior to its second use
    // e.g. in the case of a loop where the access variable is redeclared within the loop
    and not exists (DeclStmt ds, int i | 
        ds = a1.getASuccessor+() 
        and ds = a2.getAPredecessor+()
        and ds.getDeclarationEntry(i).(VariableDeclarationEntry).getVariable() = accessVar
    ) 
  )
select a1.getLocation().getFile().getBaseName(), a1, w, a2, accessVar, "Found ..."