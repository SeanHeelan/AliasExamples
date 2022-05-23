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

import aliashelpers

// Find a loop with a call to vector.size() (or some equivalent) in the condition
predicate loopConditionAccessesMemory2(Loop loopCond) {
  exists(Expr funcCall, Function func, string fname |
    funcCall = loopCond.getCondition().getAChild() 
    and funcCall instanceof FunctionCall
    and func = funcCall.(FunctionCall).getTarget()
    and func.isInline()
    and fname = func.getName() 
    and (
      fname = "size" or fname = "len" or fname = "count" or fname = "length"
      or fname = "begin" or fname = "end" or fname = "rbegin" or fname = "rend"
    )
  )
}

from Loop l, Expr w
where
  (loopConditionAccessesMemory2(l) or l instanceof RangeBasedForStmt) and
  isMemCharWriteExpr(w) and
  w.getEnclosingStmt().getParentStmt*() = l.getStmt()
select l.getLocation().getFile().getBaseName(), l, w, "Found ..."
