// Find code in which there is the following pattern:
//
// 1. Load from memory via variable X
// 2. Write to memory through a character type
// 3. Load from memory via variable X
//
// And in between 1 and 3 X is not modified

// Known False Positives:
// 1. False positives due to memory references being on the stack
// 2. False positives due to not checking if any subexpressions of the expression that form
//    the offset or the base (e.g. intel_pm.c#2190 in the kernel) have changed. 
// 3. False positives due to isMemCharWriteExpr stripping pointer types and identifying
//    writes to char* as well as just char types. 
// 4. False positives due to not checking if the access is an assignment or a read
// 5. False positives due to function calls occurring between a1 and a2. Some calls, e.g.
//    inline ones, would be OK, but others, e.g. calls to an extern function, would not. 
//    The latter cause the compiler to generate a reload from memory. I'm unsure how exactly
//    the compiler reasons about called functions that are neither inline nor externs, but it
//    seems that if the function has no writes to memory then it may not cause the compiler
//    to reload memory contents. If it does have a write to memory then it seems like it 
//    will cause a reload.
//
// Known False Negatives:
// 1. False negatives due to the 'base not modified' check limiting base to 
//    only be a Variable. i.e. this excludes something like 'buf[i]' as a base in 'buf[i][j]'.
import cpp

import aliashelpers

from
  Expr w, ArrayExpr a1, ArrayExpr a2, Variable base, Variable offset
where
  (
    isMemCharWriteExpr(w) 

    // Sequence of execution is a1 -> w -> a2
    and a1 = w.getAPredecessor+() 
    and w = a2.getAPredecessor+() 

    // a1 and a2 access the same array[offset]
    and base.getAnAccess() = a1.getArrayBase() and base.getAnAccess() = a2.getArrayBase() 
    and offset.getAnAccess() = a1.getArrayOffset() and offset.getAnAccess() = a2.getArrayOffset()

    // Base is not modified between a1 and a2
    and not exists(AssignExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.getLValue().(VariableAccess).getTarget() = base)
    and not exists (DeclStmt ds, int i | 
        ds = a1.getASuccessor+() 
        and ds = a2.getAPredecessor+()
        and ds.getDeclarationEntry(i).(VariableDeclarationEntry).getVariable() = base
    ) 

    // Offset is not modified between a1 and a2
    and offset = a1.getArrayOffset().(VariableAccess).getTarget() and 
    not exists(AssignExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(AssignExpr).getLValue().(VariableAccess).getTarget() = offset
    )
    and not exists(AssignAddExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(AssignAddExpr).getLValue().(VariableAccess).getTarget() = offset
    )
    and not exists(AssignSubExpr redef | 
      redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(AssignSubExpr).getLValue().(VariableAccess).getTarget() = offset
    )
    and not exists(Expr redef |  
      (
        redef instanceof PostfixIncrExpr
        or redef instanceof PrefixIncrExpr
        or redef instanceof PostfixDecrExpr
        or redef instanceof PrefixDecrExpr
      ) 
      and redef = a1.getASuccessor+() 
      and redef = a2.getAPredecessor+() 
      and redef.(UnaryOperation).getOperand().(VariableAccess).getTarget() = offset
    )
    and not exists (DeclStmt ds, int i | 
        ds = a1.getASuccessor+() 
        and ds = a2.getAPredecessor+()
        and (
          ds.getDeclarationEntry(i).(VariableDeclarationEntry).getVariable() = offset
          or ds.getDeclarationEntry(i).(VariableDeclarationEntry).getVariable() = base
        )
    )
  )
select a1.getLocation().getFile().getBaseName(), a1.getLocation().getStartLine(), a1, w, a2
