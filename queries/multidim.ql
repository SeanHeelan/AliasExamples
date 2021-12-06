// Finds loops in which there is a write to memory of a character type and that
// same loop loads a pointer from memory.
//
// We determine if an expression will load a pointer from memory by looking for:
// * Multi-dimensional array accesses
// * Use of STL container functions that are typically inlined and that
//    access memory (e.g. vector.size())
// * A load of anything inside a loop from memory (that is then used)
//
// False positives:
//  * There seems to be an issue with false positives in scenarios where the
//      access loop is within the write loop. On this topic, the current approach
//      isn't really correct. What we care about is finding scenarios where the
//      compiler is forced to generate a reload of a pointer from memory in a
//      scenario where it otherwise wouldn't. This happens when an access takes
//      place to a value, followed by a write through a character type, and then
//      another access to the first value without a change in the pointer used.
//      That could happen when the access loop is nested in the write loop OR
//      vice versa.
//  * I still don't handle the vector examples
//  * Writes to statically sized arrays in structs are being identified as aliasing writes
import cpp

// True if the expression writes to a character type through a pointer
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
      accessLoop = writeLoop or
      accessLoop.getStmt() = writeLoop.getEnclosingStmt().getParentStmt*()
    )
  )
}

predicate isInSimpleLoop(Expr e) {
  exists(Loop loop |
    e.getEnclosingStmt().getParentStmt*() = loop.getStmt() and
    not exists(FunctionCall fc | fc.getEnclosingStmt().getParentStmt*() = loop.getStmt())
  )
}

predicate isWriteThroughMemDeref(Expr e) {
  exists(AssignExpr a, Expr lval |
    a = e.(AssignExpr) and
    lval = a.getLValue() and
    not lval.getType().stripType() instanceof CharType and
    (
      lval instanceof PointerDereferenceExpr or
      lval instanceof ArrayExpr or
      lval instanceof OverloadedArrayExpr
    )
  )
  or
  exists(PostfixIncrExpr p |
    p = e.(PostfixIncrExpr) and
    not p.getType().stripType() instanceof CharType and
    (
      p.getOperand() instanceof PointerDereferenceExpr or
      p.getOperand() instanceof ArrayExpr or
      p.getOperand() instanceof ReferenceDereferenceExpr or
      p.getOperand() instanceof OverloadedArrayExpr
    )
  )
}

// w represents the expression that writes through an aliasing type
// a represents the expression that accesses some data in memory
from Expr w, Expr a
where
  (
    // Write conditions
    isCharWriteExpr(w) and
    (isInLoopBody(w) or isForLoopUpdate(w)) and
    // Access conditions
    (
      isMultiDimensionalArrayAccess(a)
      or
      isWriteThroughMemDeref(a)
    ) and
    // Write and access are in the same loop, or write loop is nested within
    // the access loop
    writeLoopWithinAccessLoop(a, w) and
    // The loop does not contain things that would otherwise prevent
    // vectorisation
    isInSimpleLoop(a)
  )
select w, a, "Write through AT in loop"
