// Find code in which there is the following pattern:
//
// 1. A loop L that accesses some memory internals of a datastructure in its condition
// 2. A write to memory through an AT in the body of L
// 
// Examples of code that would satisfy point 1 are:
// * A loop with a vector.size() call in the condition
// * Range-based for loops
// * A loop that uses the .begin() or .end() functions in determining loop termination
//
// Results to check:
//  * godotengine : basis_universal_unpacker in register_types.cpp appears to have a vectorisable
//      memset() to 0x0
// 
// False positives:
// * We don't eliminate cases where we have a loop condition with a call like `s.size()` and s is 
//    a local variable. This is pretty common with strings. 
import cpp

import aliashelpers

from Loop l, Expr w
where
  (
  // The loop condition accesses memory in some way
    (loopConditionAccessesMemory(l) or l instanceof RangeBasedForStmt) 
    and isLinearStmt(l.getStmt())
    and functionsCalledAreInlineAndLinear(l.getStmt())
  )
  // And the loop contains a character-write expression
  and isMemCharWriteExpr(w) 
  and w.getEnclosingStmt().getParentStmt*() = l.getStmt()
select l.getLocation().getFile().getBaseName(), l.getLocation().getStartLine(), l, w
