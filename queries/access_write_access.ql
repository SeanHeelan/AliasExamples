// Find code in which there is the following pattern:
//
// 1. Load from memory via variable X
// 2. Write to memory through a character type
// 3. Load from memory via variable X
//
// And in betwween 1 and 3 X is not modified
import cpp

from
  PointerDereferenceExpr w, PointerDereferenceExpr a1, PointerDereferenceExpr a2, Variable accessVar
where
  (
    w != a1 and
    w != a2 and
    a1 = w.getAPredecessor+() and
    w = a2.getAPredecessor+() and
    // We to get the variable holding the base pointer for the accesses. There are a few ways a
    // PointerDerefrenceExpr may be formed.
    (
      // Case 0: ptr->x
      accessVar = a1.getOperand().(PointerFieldAccess).getQualifier().(VariableAccess).getTarget()
      or
      // Case1: *ptr
      // We must assert that the operand is not a PointerFieldAccess, as a PointerFieldAccess
      // is a subclass of VariableAccess and if we don't eliminate this this case can end up
      // asserting `accessVar = x` in a ptr->x.
      not a1.getOperand() instanceof PointerFieldAccess and
      accessVar = a1.getOperand().(VariableAccess).getTarget()
    ) and
    // Eliminate cases where the variable holding the base pointer is modified
    not exists(AssignExpr redef | redef.getLValue().(VariableAccess).getTarget() = accessVar) and
    not exists(PostfixIncrExpr redef | redef.getOperand().(VariableAccess).getTarget() = accessVar) and
    not exists(PrefixIncrExpr redef | redef.getOperand().(VariableAccess).getTarget() = accessVar) and
    not exists(PostfixDecrExpr redef | redef.getOperand().(VariableAccess).getTarget() = accessVar) and
    not exists(PrefixDecrExpr redef | redef.getOperand().(VariableAccess).getTarget() = accessVar)
  )
select a1, w, a2, accessVar, "Found ..."
