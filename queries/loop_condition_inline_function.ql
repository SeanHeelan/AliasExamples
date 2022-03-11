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

import cpp

import aliashelpers

// Returns true if the loop condition contains a function call that we think will 
// result in a memory access.
predicate loopConditionAccessesMemory(Loop l) {
  exists(FunctionCall funcCall, Function func | 
    funcCall = l.getAChild()
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

from Loop l, Expr w
where
  // The loop condition accesses memory in some way
  (
    loopConditionAccessesMemory(l)
    or l instanceof RangeBasedForStmt
  )
  // And the loop contains a character-write expression
  and isMemCharWriteExpr(w) 
  and w.getEnclosingStmt().getParentStmt*() = l.getStmt()
select l.getLocation().getFile().getBaseName(), l.getLocation().getStartLine(), l, w
