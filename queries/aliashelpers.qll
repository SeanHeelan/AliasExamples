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