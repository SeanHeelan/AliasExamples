// Contains predicates shared between two or more queries

import cpp

// Returns true if the expression will involve a write to memory through a 
// character type.
predicate isMemCharWriteExpr(Expr e) {
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
  or
  exists(PostfixIncrExpr p |
    p = e.(PostfixIncrExpr) and
    p.getType().stripType() instanceof CharType and
    (
      p.getOperand() instanceof PointerDereferenceExpr or
      p.getOperand() instanceof ArrayExpr or
      p.getOperand() instanceof ReferenceDereferenceExpr or
      p.getOperand() instanceof OverloadedArrayExpr
    )
  )
  or
  exists(PostfixDecrExpr p |
    p = e.(PostfixDecrExpr) and
    p.getType().stripType() instanceof CharType and
    (
      p.getOperand() instanceof PointerDereferenceExpr or
      p.getOperand() instanceof ArrayExpr or
      p.getOperand() instanceof ReferenceDereferenceExpr or
      p.getOperand() instanceof OverloadedArrayExpr
    )
  )
  or
  exists(PrefixIncrExpr p |
    p = e.(PrefixIncrExpr) and
    p.getType().stripType() instanceof CharType and
    (
      p.getOperand() instanceof PointerDereferenceExpr or
      p.getOperand() instanceof ArrayExpr or
      p.getOperand() instanceof ReferenceDereferenceExpr or
      p.getOperand() instanceof OverloadedArrayExpr
    )
  )
  or
  exists(PrefixDecrExpr p |
    p = e.(PrefixDecrExpr) and
    p.getType().stripType() instanceof CharType and
    (
      p.getOperand() instanceof PointerDereferenceExpr or
      p.getOperand() instanceof ArrayExpr or
      p.getOperand() instanceof ReferenceDereferenceExpr or
      p.getOperand() instanceof OverloadedArrayExpr
    )
  )
}

// Returns true if the loop condition contains a function call that we think will 
// result in a memory access.
predicate loopConditionAccessesMemory(Loop l) {
  exists(FunctionCall funcCall, Function func | 
    funcCall = l.getCondition().getAChild()
    and func = funcCall.getTarget() 
    and func.isInline()
    and allCalleesAreInline(func)
    and hasMemoryAccess(func)
  )
}

// Recursive predicate. Returns true if this function, or any function it calls, 
// contains an expression that we think will result in a memory access.
predicate hasMemoryAccess(Function func) {
  // The function contains either a PointerFieldAccess (e.g. this->x) or an 
  // implicit access via the this pointer
  exists (PointerFieldAccess pfa | pfa.getEnclosingFunction() = func)
  or exists (ImplicitThisFieldAccess itfa | itfa.getEnclosingFunction() = func)
  // Or, it calls a function that meets the above properties
  or exists (Function called | 
    called.getACallToThisFunction().getEnclosingFunction() = func
    and hasMemoryAccess(called))
}

// Recursive predicate. Returns true if all functions called from this function 
// are inline, as are their callees, and so on.
predicate allCalleesAreInline(Function func) { 
  not exists (Function called | 
    (not called.isInline() or not allCalleesAreInline(called)) 
    and called.getACallToThisFunction().getEnclosingFunction() = func
  )
}

// This statement is linear (no control flow branches)
predicate isLinearStmt(Stmt s) {
  not exists(ConditionalStmt c | s.getAChild*() = c) 
}

// All functions called by this function are linear
predicate allCalleesAreLinear(Function func) {
  not exists (Function called | 
    (not isLinearStmt(called.getBlock()) or not allCalleesAreLinear(called))
    and called.getACallToThisFunction().getEnclosingFunction() = func
  )
}

// Any functions called in this loop body are inline and linear 
predicate functionsCalledAreInlineAndLinear(Stmt body) {
  not exists (FunctionCall fc, Function f | 
    body.getAChild*() = fc 
    and f = fc.getTarget() 
    and (
      // All functions called are inline
      not f.isInline() or not allCalleesAreInline(f) 
      // All functions called are linear
      or not isLinearStmt(f.getBlock()) or not allCalleesAreLinear(f)))
}