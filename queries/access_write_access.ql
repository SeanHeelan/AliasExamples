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
    accessVar = a1.getOperand().(PointerFieldAccess).getTarget() and
    not exists(AssignExpr redef | redef.getLValue().(VariableAccess).getTarget() = accessVar)
  )
select a1, w, a2, "Found ..."
