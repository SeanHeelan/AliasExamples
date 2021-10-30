// Finds loops in which there is a write to memory of a character type and that
// same loop loads a pointer from memory.
//
// We determine if an expression will load a pointer from memory by looking for:
// * Multi-dimensional array accesses
// * Use of STL containers
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
predicate isMultiDimensionalArrayAccess(ArrayExpr a) { exists(ArrayExpr b | a.getArrayBase() = b) }

// True if the loop within which the write takes place is the same loop as the access loop,
// or is nested within it.
predicate writeLoopWithinAccessLoop(Expr access, Expr write) {
  exists(Loop accessLoop, Loop writeLoop |
    access.getEnclosingStmt().getParentStmt*() = accessLoop.getStmt() and
    write.getEnclosingStmt().getParentStmt*() = writeLoop.getStmt() and
    accessLoop.getStmt() = writeLoop.getEnclosingStmt().getParentStmt*()
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
