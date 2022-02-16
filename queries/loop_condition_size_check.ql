// Find code in which there is the following pattern:
//
// 1. A loop L that accesses some memory internals of a datastructure on each iteration, to determine termination
// 2. A write to memory through an AT in the body of L
// 
// Examples of code that would satisfy point 1 are:
// * A loop with a vector.size() call in the condition
// * Range-based for loops
// * A loop that uses the .begin() or .end() functions in determining loop termination


import cpp

// Find a loop with a call to vector.size() in the condition
predicate loopConditionAccessesMemory(Expr loopCond) {
  exists(Expr funcCall, Function func, string fname |
    funcCall = loopCond.getAChild() and
    funcCall instanceof FunctionCall and
    func = funcCall.(FunctionCall).getTarget() and
    fname = func.getName() and
    (fname = "size" or fname = "len" or fname = "count" or fname = "length" or 
    fname = "begin" or fname = "end" or fname = "rbegin" or fname = "rend")
  )
}

predicate isCharWriteExpr(Expr e) {
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

from Loop l, Expr w
where
  (loopConditionAccessesMemory(l.getCondition()) or l instanceof RangeBasedForStmt) and
  isCharWriteExpr(w) and
  w.getEnclosingStmt().getParentStmt*() = l.getStmt()
select l, w, "Found ..."
