// Finds loops in which there is a write to memory of a character type and that
// same loop loads a pointer from memory.
//
// We determine if an expression will load a pointer from memory by looking for:
// * Multi-dimensional array accesses
// * Use of STL container functions that are typically inlined and that
//    access memory (e.g. vector.size())
// * A load of anything inside a loop from memory (that is then used)
import cpp

// True if the expression writes to a character type
predicate isCharWriteExpr(Expr e) {
  exists(AssignExpr a |
    a = e.(AssignExpr) and
    a.getLValue().getType().stripType() instanceof CharType
  )
  or
  exists(PostfixIncrExpr p |
    p = e.(PostfixIncrExpr) and
    p.getType().stripType() instanceof CharType
  )
}

// True if the expresion is within the body of a loop
predicate isInLoopBody(Expr e) {
  exists(Loop l | e.getEnclosingStmt().getParentStmt*() = l.getStmt())
}

// True if the expression is the update statement in a for loop
predicate isForLoopUpdate(Expr e) { exists(ForStmt f | f.getUpdate() = e) }

// True if e is a multi-dimensional array access expression
predicate isMultiDimensionalArrayAccess(ArrayExpr a) {
  // a is an multi-dim access if its base expression is an array expression
  exists(ArrayExpr b | a.getArrayBase() = b)
}

// True if the loop within which the write takes place is the same loop as the access loop,
// or is nested within it.
predicate writeLoopWithinAccessLoop(Expr access, Expr write) {
  exists(Loop accessLoop, Loop writeLoop |
    // The access is in a loop
    access.getEnclosingStmt().getParentStmt*() = accessLoop.getStmt() and
    // The write is in a loop
    write.getEnclosingStmt().getParentStmt*() = writeLoop.getStmt() and
    // The loop containing the access subsumes the loop containing the write
    (
      accessLoop.getStmt() = writeLoop.getStmt() or
      accessLoop.getStmt() = writeLoop.getEnclosingStmt().getParentStmt*()
    )
  )
}

from Expr e, Expr d
where
  (
    isCharWriteExpr(e) and
    (isInLoopBody(e) or isForLoopUpdate(e)) and
    (isMultiDimensionalArrayAccess(d) and writeLoopWithinAccessLoop(d, e))
  )
select e, d, "Write through AT in loop"
