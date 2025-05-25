/*
 *----------------------------------------------------------------------------
 * Wanted - ~/Wanted.xs
 * Version v0.1.0
 * Copyright(c) 2025 DEGUEST Pte. Ltd.
 * Original author: Robin Houston
 * Modified by: Jacques Deguest <jack@deguest.jp>
 * Created 2025/05/16
 * Modified 2025/05/24
 * All rights reserved
 * 
 * This program is free software; you can redistribute  it  and/or  modify  it
 * under the same terms as Perl itself.
 *
 * Description:
 *     XS implementation for the Wanted Perl module, providing low-level
 *     functions to inspect and manipulate Perl's context stack and op tree.
 *----------------------------------------------------------------------------
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Between 5.9.1 and 5.9.2 the retstack was removed, and the return op is now stored on the cxstack. */
#define HAS_RETSTACK (\
  PERL_REVISION < 5 || \
  (PERL_REVISION == 5 && PERL_VERSION < 9) || \
  (PERL_REVISION == 5 && PERL_VERSION == 9 && PERL_SUBVERSION < 2) \
)

/* Define PERL_VERSION_GE, PERL_VERSION_LT, PERL_VERSION_LE if not already defined (Perl < 5.24.0) */
#ifndef PERL_VERSION_GE
#define PERL_VERSION_GE(major, minor, patch) \
    (PERL_REVISION > (major) || \
     (PERL_REVISION == (major) && (PERL_VERSION > (minor) || \
     (PERL_VERSION == (minor) && PERL_SUBVERSION >= (patch)))))
#endif

#ifndef PERL_VERSION_LT
#define PERL_VERSION_LT(major, minor, patch) \
    (PERL_REVISION < (major) || \
     (PERL_REVISION == (major) && (PERL_VERSION < (minor) || \
     (PERL_VERSION == (minor) && PERL_SUBVERSION < (patch)))))
#endif

#ifndef PERL_VERSION_LE
#define PERL_VERSION_LE(major, minor, patch) \
    (PERL_REVISION < (major) || \
     (PERL_REVISION == (major) && (PERL_VERSION < (minor) || \
     (PERL_VERSION == (minor) && PERL_SUBVERSION <= (patch)))))
#endif

#define PERL_HAS_FREE_OS_BUG (PERL_VERSION_GE(5, 22, 0) && PERL_VERSION_LE(5, 24, 0))

#define ENABLE_DOUBLE_RETURN_HACKS 1

/* After 5.10, the CxLVAL macro was added. */
#ifndef CxLVAL
#  define CxLVAL(cx) cx->blk_sub.lval
#endif

#ifndef OpSIBLING
#  define OpSIBLING(o) o->op_sibling
#endif

/* Stolen from B.xs */
#ifdef PERL_OBJECT
#undef PL_op_name
#undef PL_opargs 
#undef PL_op_desc
#define PL_op_name (get_op_names())
#define PL_opargs (get_opargs())
#define PL_op_desc (get_op_descs())
#endif

/* Define oplist and numop types */
#define OPLIST_MAX 50
typedef struct {
    U16 numop_num;
    OP* numop_op;
} numop;

typedef struct {
    U16    length;
    numop  ops[OPLIST_MAX];
} oplist;

#define new_oplist                      (oplist*) malloc(sizeof(oplist))
#define init_oplist(l)                  l->length = 0

/* Function declarations */
numop* lastnumop(oplist* l);
OP* lastop(oplist* l);
oplist* pushop(oplist* l, OP* o, U16 i);
oplist* find_ancestors_from(OP* start, OP* next, oplist* l);
I32 count_list (OP* parent, OP* returnop);
I32 count_slice (OP* o);

/* Stolen from pp_ctl.c (with modifications) */
/*
 * dopoptosub_at - Scans the given context stack for the nearest subroutine or format block.
 *
 * Arguments:
 *     PERL_CONTEXT *cxstk - The context stack to search.
 *     I32 startingblock   - The starting index from which to scan downward.
 *
 * Return:
 *     I32 - The index of the found subroutine or format block, or -1 if none is found.
 *
 * Description:
 *     This is a helper function to locate the closest CXt_SUB or CXt_FORMAT in a given stack.
 *     It is used in walking the context stack and is central to call depth resolution.
 *
 * Internal:
 *     Used by dopoptosub() to implement context stack traversal.
 */
I32
dopoptosub_at(pTHX_ PERL_CONTEXT *cxstk, I32 startingblock)
{
    dTHR;
    I32 i;
    PERL_CONTEXT *cx;
    if (!cxstk) return -1;
    for (i = startingblock; i >= 0; i--)
    {
        cx = &cxstk[i];
        switch (CxTYPE(cx))
        {
            default:
                continue;
            case CXt_SUB:
            case CXt_FORMAT:
                DEBUG_l( Perl_deb(aTHX_ "(Found sub #%ld)\n", (long)i));
                return i;
        }
    }
    return i;
}

/*
 * dopoptosub - Convenience wrapper around dopoptosub_at using the current cxstack.
 *
 * Arguments:
 *     I32 startingblock - Start index into cxstack to scan for a subroutine context.
 *
 * Return:
 *     I32 - The index of the found subroutine or format block, or -1 if not found.
 *
 * Description:
 *     This function uses the current 'cxstack' and is typically used to locate
 *     the active subroutine context for the current execution stack.
 *
 * Internal:
 *     Used by upcontext() and upcontext_plus() to traverse the context stack.
 */
I32
dopoptosub(pTHX_ I32 startingblock)
{
    dTHR;
    if (!cxstack) return -1;
    return dopoptosub_at(aTHX_ cxstack, startingblock);
}

/*
 * upcontext - Retrieves the subroutine context 'count' levels up the stack.
 *
 * Arguments:
 *     I32 count - The number of subroutine contexts to go up.
 *
 * Return:
 *     PERL_CONTEXT* - Pointer to the located context or NULL if not found.
 *
 * Description:
 *     This searches up through the Perl call stack, accounting for DB::sub wrappers,
 *     and returns the context frame corresponding to the requested call depth.
 *
 * Internal:
 *     Used by want_gimme(), want_lvalue(), find_return_op(), and other context-inspection functions.
 */
PERL_CONTEXT*
upcontext(pTHX_ I32 count)
{
    PERL_SI *top_si = PL_curstackinfo;
    I32 cxix = dopoptosub(aTHX_ cxstack_ix);
    PERL_CONTEXT *cx;
    PERL_CONTEXT *ccstack = cxstack;
    I32 dbcxix;

    if (!top_si || !ccstack || cxix < 0)
    {
        return (PERL_CONTEXT *)0;
    }

    for (;;)
    {
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN)
        {
            top_si = top_si->si_prev;
            if (!top_si)
            {
                return (PERL_CONTEXT *)0;
            }
            ccstack = top_si->si_cxstack;
            cxix = dopoptosub_at(aTHX_ ccstack, top_si->si_cxix);
        }
        if (cxix < 0)
        {
            return (PERL_CONTEXT *)0;
        }
        if (PL_DBsub && cxix >= 0 &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;
        cxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
    }
    cx = &ccstack[cxix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT)
    {
        dbcxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
        if (PL_DBsub && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
        {
            cx = &ccstack[dbcxix];
        }
    }
    return cx;
}

/*
 * upcontext_plus - Retrieves the block or loop context enclosing the subroutine at the given depth.
 *
 * Arguments:
 *     I32 count         - Number of subroutine levels up to inspect.
 *     bool end_of_block - Whether to return the context at the end of the enclosing block.
 *
 * Return:
 *     PERL_CONTEXT* - The identified context or NULL.
 *
 * Description:
 *     This is a more sophisticated version of 'upcontext', considering debugger issues,
 *     tie/tied ops, and whether the block context is required instead of the sub context.
 *
 * Internal:
 *     Used by find_start_cop() to locate the starting context op for a subroutine or block.
 */
PERL_CONTEXT*
upcontext_plus(pTHX_ I32 count, bool end_of_block)
{
    PERL_SI *top_si = PL_curstackinfo;
    I32 cxix = dopoptosub(aTHX_ cxstack_ix);
    PERL_CONTEXT *cx, *tcx;
    PERL_CONTEXT *ccstack = cxstack;
    I32 dbcxix, i;
    bool debugger_trouble;

    if (!top_si || !ccstack || cxix < 0)
    {
        return (PERL_CONTEXT *)0;
    }

    if (PL_op && (PL_op->op_type == OP_TIE || PL_op->op_type == OP_TIED))
    {
        I32 i;
        for (i = cxix; i >= 0; i--)
        {
            cx = &ccstack[i];
            if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_BLOCK)
            {
                OP *op = cx->blk_oldcop ? (OP*)cx->blk_oldcop : PL_op;
                if (op && (op->op_type == OP_LIST || op->op_type == OP_AASSIGN))
                {
                    cx->blk_gimme = G_ARRAY;
                }
                return cx;
            }
        }
        return (PERL_CONTEXT *)0;
    }

    for (;;)
    {
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN)
        {
            top_si = top_si->si_prev;
            if (!top_si)
            {
                return (PERL_CONTEXT *)0;
            }
            ccstack = top_si->si_cxstack;
            cxix = dopoptosub_at(aTHX_ ccstack, top_si->si_cxix);
        }
        if (cxix < 0)
        {
            return (PERL_CONTEXT *)0;
        }
        if (PL_DBsub && cxix >= 0 &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;
        cxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
    }
    cx = &ccstack[cxix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT)
    {
        dbcxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
        if (PL_DBsub && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
        {
            cxix = dbcxix;
            cx = &ccstack[dbcxix];
        }
    }

    debugger_trouble = (cx->blk_oldcop->op_type == OP_DBSTATE);

    for (i = cxix-1; i>=0 ; i--)
    {
        tcx = &ccstack[i];
        switch (CxTYPE(tcx))
        {
            case CXt_BLOCK:
                if (debugger_trouble && i > 0) return tcx;
            default:
                continue;
#ifdef CXt_LOOP_PLAIN
            case CXt_LOOP_PLAIN:
#endif
#ifdef CXt_LOOP_FOR
            case CXt_LOOP_FOR:
#endif
#ifdef CXt_LOOP_LIST
            case CXt_LOOP_LIST:
#endif
#ifdef CXt_LOOP_ARY
            case CXt_LOOP_ARY:
#endif
#ifdef CXt_LOOP
            case CXt_LOOP:
#endif
                return tcx;
            case CXt_SUB:
            case CXt_FORMAT:
                return cx;
        }
    }
    return ((end_of_block && cxix > 1) ? &ccstack[cxix-1] : cx);
}

/*
 * want_gimme - Returns the context type (void, scalar, or array) at the given call stack level.
 *
 * Arguments:
 *     I32 uplevel - The number of call frames up to check.
 *
 * Return:
 *     U8 - One of G_VOID, G_SCALAR, or G_ARRAY.
 *
 * Description:
 *     This uses the PERL_CONTEXT retrieved by 'upcontext' to determine the evaluation context
 *     of the caller. It is a low-level helper for functions like wantarray_up().
 *
 * Internal:
 *     Used by wantarray_up(), want_count(), and Perl-side context inspection.
 */
U8
want_gimme (I32 uplevel)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    if (!cx) return G_VOID;
    return cx->blk_gimme;
}

/*
 * lastnumop - Retrieves the last meaningful 'numop' from an 'oplist'.
 *
 * Arguments:
 *     oplist* l - Pointer to an 'oplist' structure containing a sequence of 'numop' entries.
 *
 * Return:
 *     numop* - A pointer to the last 'numop' whose op is not of type 'OP_NULL' or 'OP_SCOPE',
 *              or NULL if no such entry exists.
 *
 * Description:
 *     This function scans backward through the list of 'numop' entries and returns the last
 *     one that corresponds to a significant operation. It is used to find the operative
 *     instruction before a return or assignment analysis.
 *
 * Internal:
 *     Used by 'want_assign()' to determine the final operational node before returning values.
 */
numop*
lastnumop(oplist* l)
{
    U16 i;
    numop* ret;

    if (!l) return (numop*)0;
    i = l->length;
    while (i-- > 0)
    {
        ret = &(l->ops)[i];
        if (ret->numop_op->op_type != OP_NULL && ret->numop_op->op_type != OP_SCOPE)
        {
            return ret;
        }
    }
    return (numop*)0;
}

/*
 * lastop - Returns the last significant OP from a given oplist.
 *
 * Arguments:
 *     oplist* l - The list of operations to search.
 *
 * Return:
 *     OP* - The last non-NULL, non-SCOPE, non-LEAVE op, or Nullop if none found.
 *
 * Description:
 *     This function scans backwards through an oplist to find the last significant operation,
 *     ignoring NULL, SCOPE, and LEAVE ops. It is used to determine the most relevant op at
 *     the end of an op chain, typically for context or assignment analysis.
 *
 * Internal:
 *     Used by parent_op() to identify the final operation in an op chain.
*/
OP*
lastop(oplist* l)
{
    U16 i;
    OP* ret;

    if (!l) return Nullop;
    i = l->length;
    while (i-- > 0)
    {
        ret = (l->ops)[i].numop_op;
        if (ret->op_type != OP_NULL
            && ret->op_type != OP_SCOPE
            && ret->op_type != OP_LEAVE)
        {
            return ret;
        }
    }
    free(l);
    return Nullop;
}

/*
 * pushop - Adds an operation to an oplist with an associated index.
 *
 * Arguments:
 *     oplist* l - The oplist to modify.
 *     OP* o     - The op to push.
 *     U16 i     - The op’s index or position.
 *
 * Return:
 *     oplist* - The modified list.
 *
 * Description:
 *     This utility is used during op tree traversal to maintain a list of encountered operations.
 *
 * Internal:
 *     Used by find_ancestors_from() to build the list of parent ops.
 */
oplist*
pushop(oplist* l, OP* o, U16 i)
{
    I16 len = l->length;
    if (o && len < OPLIST_MAX)
    {
        ++ l->length;
        l->ops[len].numop_op  = o;
        l->ops[len].numop_num = -1;
    }
    if (len > 0)
        l->ops[len-1].numop_num = i;

    return l;
}

/*
 * find_ancestors_from - Recursively traverses an op tree to find a path to a target op.
 *
 * Arguments:
 *     OP* start - Starting op for the tree walk.
 *     OP* next  - Target op to find.
 *     oplist* l - The oplist to accumulate ops into (can be NULL).
 *
 * Return:
 *     oplist* - A list of parent ops leading to the target op, or NULL if not found.
 *
 * Description:
 *     This function recursively traverses the op tree starting from 'start' to find a path
 *     to the 'next' op, accumulating parent ops in an oplist. It is used to trace a path
 *     through the abstract syntax tree (AST) from a COP to a return op.
 *
 * Notes:
 *     The caller is responsible for freeing the oplist if the function returns NULL.
 *
 * Internal:
 *     Used by ancestor_ops() to build the list of ancestor ops for context analysis.
 */
oplist*
find_ancestors_from(OP* start, OP* next, oplist* l)
{
    OP     *o, *p;
    U16    cn = 0;
    U16    ll;
    bool outer_call = FALSE;

    if (!start || !next)
    {
        /* Do not free l here; let the caller handle it */
        return (oplist*)0;
    }

    if (!l)
    {
        outer_call = TRUE;
        l = new_oplist;
        init_oplist(l);
        ll = 0;
    }
    else ll = l->length;

    for (o = start; o; p = o, o = OpSIBLING(o), ++cn)
    {
        if (o->op_type == OP_ENTERSUB && o->op_next == next)
            return pushop(l, Nullop, cn);

        if (o->op_flags & OPf_KIDS)
        {
            U16 ll = l->length;
        
            pushop(l, o, cn);
            if (find_ancestors_from(cUNOPo->op_first, next, l))
                return l;
            else
                l->length = ll;
        }
    }
    /* Do not free l here; let the caller handle it */
    return (oplist*)0;
}

/*
 * find_return_op - Resolves the return OP for the subroutine at a given depth.
 *
 * Arguments:
 *     I32 uplevel - The number of frames up to inspect.
 *
 * Return:
 *     OP* - The op that is used to return from the subroutine, or Nullop if not found.
 *
 * Description:
 *     This inspects the current cxstack or PL_retstack to find the return point for a sub.
 *
 * Internal:
 *     Used by ancestor_ops() to determine the return op for context analysis.
 */
OP*
find_return_op(pTHX_ I32 uplevel)
{
    PERL_CONTEXT *cx = upcontext(aTHX_ uplevel);
    if (!cx)
    {
        return Nullop;
    }
#if HAS_RETSTACK
    return PL_retstack[cx->blk_oldretsp - 1];
#else
    return cx->blk_sub.retop;
#endif
}

/*
 * find_start_cop - Returns the start COP (context op) for the subroutine frame.
 *
 * Arguments:
 *     I32 uplevel       - Call stack depth to inspect.
 *     bool end_of_block - If true, return the enclosing block cop.
 *
 * Return:
 *     OP* - The starting COP for the sub or block context, or Nullop if not found.
 *
 * Description:
 *     This function determines the starting COP (context op) for a subroutine or block
 *     at the specified call stack depth, helping to identify where execution begins.
 *
 * Internal:
 *     Used by ancestor_ops() to find the starting point for op tree traversal.
 */
OP*
find_start_cop(pTHX_ I32 uplevel, bool end_of_block)
{
    PERL_CONTEXT* cx = upcontext_plus(aTHX_ uplevel, end_of_block);
    if (!cx)
    {
        return Nullop;
    }
    return (OP*) cx->blk_oldcop;
}

/*
 * ancestor_ops - Produces a list of ancestor ops from sub start to return.
 *
 * Arguments:
 *     I32 uplevel        - Stack level to inspect.
 *     OP** return_op_out - Optional pointer to capture return op.
 *
 * Return:
 *     oplist* - A list of operations between sub entry and return, or NULL if not found.
 *
 * Description:
 *     This function walks the op tree using 'find_start_cop' and 'find_return_op',
 *     storing the trace path in an oplist. It is used to analyse the operations
 *     between a subroutine's entry and return points.
 *
 * Notes:
 *     The caller is responsible for freeing the returned oplist.
 *
 * Internal:
 *     Used by want_boolean() and want_assign() for context analysis.
 */
oplist*
ancestor_ops (I32 uplevel, OP** return_op_out)
{
    OP* return_op = find_return_op(aTHX_ uplevel);
    OP* start_cop = find_start_cop(aTHX_ uplevel,
        return_op ? return_op->op_type == OP_LEAVE : FALSE);

    if (!return_op || !start_cop)
    {
        if (return_op_out) *return_op_out = Nullop;
        return (oplist*)0;
    }

    if (return_op_out)
        *return_op_out = return_op;

    /* return find_ancestors_from(start_cop, return_op, 0); */
    oplist* result = find_ancestors_from(start_cop, return_op, 0);
    if (!result)
    {
        /* Free the oplist if find_ancestors_from allocated it but failed */
        free(result);  // This will be a no-op since result is NULL
        return (oplist*)0;
    }
    return result;
}

/*
 * parent_op - Retrieves the parent OP of the current OP in the call stack.
 *
 * Arguments:
 *     I32 uplevel - Stack level to begin inspection.
 *     OP **retop  - A pointer to receive the resolved OP.
 *
 * Return:
 *     OP* - The parent operation at the given level.
 *
 * Description:
 *     This walks the OP tree upward from the caller’s stack frame to find the relevant parent.
 *
 * Internal:
 *     Used by parent_op_name() and first_multideref_type().
 */
OP*
parent_op (I32 uplevel, OP** return_op_out)
{
    return lastop(ancestor_ops(uplevel, return_op_out));
}

/*
 * count_slice - Calculates the number of elements in a slice op.
 *
 * Arguments:
 *     OP* o - The slice op (e.g., OP_HSLICE or OP_ASLICE).
 *
 * Return:
 *     I32 - The number of elements being sliced, or -999 on error.
 *
 * Description:
 *     Recursively walks the op tree to count list elements involved in slicing,
 *     such as in array or hash slice operations.
 *
 * Internal:
 *     Used by count_list() to determine the size of sliced elements in assignments.
 */
I32
count_slice (OP* o)
{
    OP* pm;
    OP* l  = Nullop;

    if (!o) return -999;
    pm = cUNOPo->op_first;
    if (!pm || pm->op_type != OP_PUSHMARK)
        die("%s", "Wanted panicked: slice doesn't start with pushmark\n");

    if ( (l = OpSIBLING(pm)) && (l->op_type == OP_LIST || (l->op_type == OP_NULL && l->op_targ == OP_LIST)))
        return count_list(l, Nullop);

    else if (l)
        switch (l->op_type)
        {
            case OP_RV2AV:
            case OP_PADAV:
            case OP_PADHV:
            case OP_RV2HV:
                return 0;
            case OP_HSLICE:
            case OP_ASLICE:
                return count_slice(l);
            case OP_STUB:
                return 1;
            default:
                die("Wanted panicked: Unexpected op in slice (%s)\n", PL_op_name[l->op_type]);
        }

    else
        die("Wanted panicked: Nothing follows pushmark in slice\n");

    return -999;
}

/*
 * count_list - Counts the number of elements in a list op.
 *
 * Arguments:
 *     OP* parent    - The parent list op.
 *     OP* returnop  - Optional terminator to stop early.
 *
 * Return:
 *     I32 - The number of child ops, or 0 if none.
 *
 * Description:
 *     This function counts the number of child ops in a list op, helping to determine
 *     the number of left-hand-side variables in assignments (e.g., my( $a, $b ) = ...).
 *
 * Internal:
 *     Used by want_count() and want_assign() for assignment analysis.
 */
I32
count_list (OP* parent, OP* returnop)
{
    OP* o;
    I32 i = 0;

    if (!parent || ! (parent->op_flags & OPf_KIDS))
        return 0;

    for(o = cUNOPx(parent)->op_first; o; o=OpSIBLING(o))
    {
        if (returnop && o->op_type == OP_ENTERSUB && o->op_next == returnop)
            return i;
        if (o->op_type == OP_RV2AV || o->op_type == OP_RV2HV
         || o->op_type == OP_PADAV || o->op_type == OP_PADHV
         || o->op_type == OP_ENTERSUB)
            return 0;
        
        if (o->op_type == OP_HSLICE || o->op_type == OP_ASLICE)
        {
            I32 slice_length = count_slice(o);
            if (slice_length == 0)
                return 0;
            else
                i += slice_length - 1;
        }
        else ++i;
    }

    return i;
}

/*
 * countstack - Counts the number of stack values passed to a subroutine.
 *
 * Arguments:
 *     I32 uplevel - Stack frame level to inspect.
 *
 * Return:
 *     I32 - Number of items between oldmarksp and current mark, or -1 if context not found.
 *
 * Description:
 *     This function counts the number of values on the stack between the old mark and
 *     the current mark, used to estimate how many right-hand-side values exist in an assignment.
 *
 * Internal:
 *     Used by want_count() to analyse assignment contexts.
 */
I32
countstack(I32 uplevel)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    I32 oldmarksp;
    I32 mark_from;
    I32 mark_to;

    if (!cx) return -1;

    oldmarksp = cx->blk_oldmarksp;
    mark_from = PL_markstack[oldmarksp];
    mark_to   = PL_markstack[oldmarksp+1];
    return (mark_to - mark_from);
}

/*
 * copy_rvals - Returns an array of stack values passed to a subroutine.
 *
 * Arguments:
 *     I32 uplevel - Stack level to inspect.
 *     I32 skip    - Number of items to skip from the start.
 *
 * Return:
 *     AV* - An array of values beyond the 'skip' threshold, or Nullav if context not found.
 *
 * Description:
 *     This copies the right-hand-side values passed to an assignment into an AV for Perl-side use.
 *
 * Internal:
 *     Used by want_assign() to retrieve assignment values.
 */
AV*
copy_rvals(I32 uplevel, I32 skip)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    I32 oldmarksp;
    I32 mark_from;
    I32 mark_to;
    I32 i;
    AV* a;

    oldmarksp = cx->blk_oldmarksp;
    mark_from = PL_markstack[oldmarksp-1];
    mark_to   = PL_markstack[oldmarksp];

    if (!cx) return Nullav;
    a = newAV();
    for(i=mark_from+1; i<=mark_to; ++i)
        if (skip-- <= 0) av_push(a, newSVsv(PL_stack_base[i]));

    return a;
}

/*
 * copy_rval - Retrieves a single scalar value passed to a subroutine.
 *
 * Arguments:
 *     I32 uplevel - Stack level to inspect.
 *
 * Return:
 *     AV* - An array containing one value, or Nullav if context not found.
 *
 * Description:
 *     This function retrieves the last scalar value from the stack, wrapping it in an AV
 *     for Perl-side use. It is used in OP_SASSIGN cases to retrieve the sole value.
 *
 * Internal:
 *     Used by want_assign() for scalar assignment contexts.
 */
AV*
copy_rval(I32 uplevel)
{
    PERL_CONTEXT* cx = upcontext(aTHX_ uplevel);
    I32 oldmarksp;
    AV* a;

    oldmarksp = cx->blk_oldmarksp;
    if (!cx) return Nullav;
    a = newAV();
    av_push(a, newSVsv(PL_stack_base[PL_markstack[oldmarksp+1]]));

    return a;
}

// NOTE: Module

MODULE = Wanted           PACKAGE = Wanted          
PROTOTYPES: ENABLE

=begin comment
// NOTE: wantarray_up
/*
 * wantarray_up - Wrapper for Perl's wantarray at a given stack level.
 *
 * Arguments:
 *     I32 uplevel - Call stack level offset to use.
 *
 * Return:
 *     SV* - Returns &PL_sv_yes (true) for list context, &PL_sv_no (false) for scalar
 *           context, or &PL_sv_undef for void context.
 *
 * Description:
 *     This provides a consistent interface to Perl’s context detection at various call
 *     depths.
 *
 * Internal:
 *     Used by context(), want(), and _wantone().
 */
=cut
SV*
wantarray_up(uplevel)
I32 uplevel;
    PREINIT:
        U8 gimme = want_gimme(uplevel);
    CODE:
        switch(gimme)
        {
            case G_ARRAY:
                RETVAL = &PL_sv_yes;
                break;
            case G_SCALAR:
                RETVAL = &PL_sv_no;
                break;
            default:
                RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

=begin comment
// NOTE: want_lvalue
/*
 * want_lvalue - Detects if the current subroutine is being called in lvalue context.
 *
 * Arguments:
 *     I32 uplevel - Number of levels up the call stack to check.
 *
 * Return:
 *     int - Returns true (non-zero) if in lvalue context, false (0) otherwise.
 *
 * Description:
 *     This checks whether the subroutine is being evaluated in a context where the result
 *     can be assigned to, such as in `foo() = 42`.
 *
 * Usage:
 *     Called internally by Perl subroutines via want('LVALUE').
 *
 * Internal:
 *     Used by wantassign(), lnoreturn().
 */
=cut
U8
want_lvalue(uplevel)
I32 uplevel;
    PREINIT:
        PERL_CONTEXT* cx;
    CODE:
        cx = upcontext(aTHX_ uplevel);
        if (!cx) RETVAL = 0;
        
        if (CvLVALUE(cx->blk_sub.cv))
            RETVAL = CxLVAL(cx);
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

=begin comment
// NOTE: parent_op_name
/*
 * parent_op_name - Returns the name of the parent OP at the requested level.
 *
 * Arguments:
 *     I32 uplevel - How far up the call stack to look.
 *
 * Return:
 *     In scalar context: The stringified parent op name (e.g., "aassign", "method_call", "(none)").
 *     In list context: A two-element list containing the parent op name and the return op name.
 *
 * Description:
 *     This function resolves the parent op name by examining the OP tree.
 *     If the op is a `leavesub`, this typically means the context is not well-defined.
 *
 * Internal:
 *     Used by wantref(), bump_level(), and debugging tools.
 */
=cut
void
parent_op_name(uplevel)
I32 uplevel;
    PREINIT:
        OP *r;
        OP *o = parent_op(uplevel, &r);
        OP *first, *second;
        char *retval;
    PPCODE:
        if (!o || !r)
        {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVpv("(none)", 0)));
            PUSHs(sv_2mortal(newSVpv("(none)", 0)));
        }
        else
        {
            if (o->op_type == OP_ENTERSUB && (first = cUNOPo->op_first)
                  && (second = OpSIBLING(first)) && OpSIBLING(second) != Nullop)
                retval = "method_call";
            else
                retval = (char *)PL_op_name[o->op_type];
            if (GIMME == G_ARRAY)
            {
                EXTEND(SP, 2);
                PUSHs(sv_2mortal(newSVpv(retval, 0)));
                PUSHs(sv_2mortal(newSVpv(PL_op_name[r->op_type], 0)));
            }
            else
            {
                EXTEND(SP, 1);
                PUSHs(sv_2mortal(newSVpv(retval, 0)));
            }
        }

=begin comment
// NOTE: want_count
/*
 * want_count - Determines how many return values are expected by the caller.
 *
 * Arguments:
 *     I32 uplevel - Number of levels up to look for the list evaluation context.
 *
 * Return:
 *     int - A count of expected return items. Returns -1 if unlimited, 0 for void, or a positive count.
 *
 * Description:
 *     This enables subs to detect how many return values the caller is expecting,
 *     like in `my ($a, $b) = sub();`.
 *
 * Internal:
 *     Used by howmany(), want('COUNT'), and _wantone().
 */
=cut
I32
want_count(uplevel)
I32 uplevel;
    PREINIT:
        OP* returnop;
        OP* o = parent_op(uplevel, &returnop);
        U8 gimme = want_gimme(uplevel);
    CODE:
        if (!o)
        {
            RETVAL = (gimme == G_SCALAR ? 1 : gimme == G_ARRAY ? -1 : 0);
        }
        else if (o->op_type == OP_AASSIGN)
        {
            I32 lhs = count_list(cBINOPo->op_last,  Nullop  );
            I32 rhs = countstack(uplevel);
            if      (lhs == 0) RETVAL = -1;
            else if (rhs >= lhs-1) RETVAL =  0;
            else RETVAL = lhs - rhs - 1;
        }
        else switch(gimme)
        {
            case G_ARRAY:
                RETVAL = -1;
                break;
            case G_SCALAR:
                RETVAL = 1;
                break;
            default:
                RETVAL = 0;
        }
    OUTPUT:
        RETVAL

=begin comment
// NOTE: want_boolean
/*
 * want_boolean - Determines whether the current expression is evaluated in boolean context.
 *
 * Arguments:
 *     I32 uplevel - Stack level to examine.
 *
 * Return:
 *     int - Boolean true/false indicating if this is boolean context.
 *
 * Description:
 *     This inspects the op tree to determine if the result of the function is
 *     being evaluated as a truth value (e.g., `if(foo())` or `foo() && 1`).
 *
 * Internal:
 *     Used by want('BOOL').
 */
=cut
bool
want_boolean(uplevel)
I32 uplevel;
    PREINIT:
        oplist* l = ancestor_ops(uplevel, 0);
        U16 i;
        bool truebool = FALSE, pseudobool = FALSE;
    CODE:
        if (!l)
        {
            RETVAL = FALSE;
        }
        else
        {
            for( i=0; i < l->length; ++i )
            {
                OP* o = l->ops[i].numop_op;
                U16 n = l->ops[i].numop_num;
                bool v = (OP_GIMME(o, -1) == G_VOID);
                switch(o->op_type)
                {
                    case OP_NOT:
                    case OP_XOR:
                        truebool = TRUE;
                        break;
                    case OP_AND:
                        if (truebool || v)
                            truebool = TRUE;
                        else
                            pseudobool = (pseudobool || n == 0);
                        break;
                    case OP_OR:
                        if (truebool || v)
                            truebool = TRUE;
                        else
                            truebool = FALSE;
                        break;
                    case OP_COND_EXPR:
                        truebool = (truebool || n == 0);
                        break;
                    case OP_NULL:
                        break;
                    default:
                        truebool   = FALSE;
                        pseudobool = FALSE;
                }
            }
            free(l);
            RETVAL = truebool || pseudobool;
        }
    OUTPUT:
        RETVAL

=begin comment
// NOTE: want_assign
/*
 * want_assign - Retrieves the right-hand-side values in an assignment context.
 *
 * Arguments:
 *     I32 uplevel - Number of levels up the call stack to inspect.
 *
 * Return:
 *     SV* - A reference to an array containing the right-hand-side (RHS) values,
 *           or &PL_sv_undef if not in assignment context.
 *
 * Description:
 *     This XS function inspects the current call context to determine if a subroutine is
 *     being assigned to. If so, it captures and returns the values being assigned.
 *
 * Internal:
 *     Used by wantassign() to expose assignment RHS values to Perl.
 */
=cut
SV*
want_assign(uplevel)
U32 uplevel;
    PREINIT:
        AV* r;
        OP* returnop;
        oplist* os = ancestor_ops(uplevel, &returnop);
        numop* lno = os ? lastnumop(os) : (numop*)0;
        OPCODE type;
    PPCODE:
        if (!lno)
        {
            r = Nullav;
        }
        else
        {
            type = lno->numop_op->op_type;
            if (lno && (type == OP_AASSIGN || type == OP_SASSIGN) && lno->numop_num == 1)
            {
                if (type == OP_AASSIGN)
                {
                    I32 lhs_count = count_list(cBINOPx(lno->numop_op)->op_last,  returnop);
                    if (lhs_count == 0) r = newAV();
                    else
                    {
                        r = copy_rvals(uplevel, lhs_count-1);
                    }
                }
                else r = copy_rval(uplevel);
            }
            else
            {
                r = Nullav;
            }
        }
        if (os) free(os);

    EXTEND(SP, 1);
    PUSHs(r ? sv_2mortal(newRV_noinc((SV*) r)) : &PL_sv_undef);

=begin comment
// NOTE: double_return
/*
 * double_return - Restores nested return context.
 *
 * Description:
 *     This function simulates a return from a subroutine by manipulating the context stack.
 *     It is tightly coupled to Perl's internal context stack and was originally implemented
 *     in version 1 of Want. It has been retained as-is for compatibility.
 *
 * Notes:
 *     Wrapped in PERL_VERSION_GE(5, 8, 8) and ENABLE_DOUBLE_RETURN_HACKS for safety.
 *     ⚠️ Do not modify unless you deeply understand the implications, as changes can
 *     lead to crashes or undefined behaviour.
 *
 * Internal:
 *     Used by rreturn() and lnoreturn() to implement early returns in Perl code.
 */
=cut
void
double_return(...)
    PREINIT:
        PERL_CONTEXT *ourcx, *cx;
    PPCODE:
#  if PERL_VERSION_GE(5, 8, 8) && ENABLE_DOUBLE_RETURN_HACKS
        ourcx = upcontext(aTHX_ 0);
        cx    = upcontext(aTHX_ 1);
        if (!cx)
            Perl_croak(aTHX_ "Can't return outside a subroutine");
#ifdef POPBLOCK
        ourcx->cx_type = CXt_NULL;
        CvDEPTH(ourcx->blk_sub.cv)--;
#  if HAS_RETSTACK
        if (PL_retstack_ix > 0)
            --PL_retstack_ix;
#  endif
#else
        /* In 5.23.8 or later, PL_curpad is saved in the context stack and
         * restored by cx_popsub(), rather than being saved on the savestack
         * and restored by LEAVE; so just CXt_NULLing the parent sub
         * skips the PL_curpad restore and so everything done during the
         * second part of the return will have the wrong PL_curpad.
         * So instead, fix up the first return so that it thinks the
         * op to continue at is iteself, forcing it to do a double return.
         */
        assert(PL_op->op_next->op_type == OP_RETURN);
        /* force the op following the 'return' to be 'return' again */
        ourcx->blk_sub.retop = PL_op->op_next;
        assert(PL_markstack + ourcx->blk_oldmarksp + 1 == PL_markstack_ptr);
        ourcx->blk_oldmarksp++;
        ourcx->blk_gimme = cx->blk_gimme;
#endif

        return;
#  else
        Perl_croak(aTHX_ "double_return not supported on Perl %d.%d.%d (requires >= 5.8.8)",
                   PERL_REVISION, PERL_VERSION, PERL_SUBVERSION);
#  endif /* PERL_VERSION_GE && ENABLE_DOUBLE_RETURN_HACKS */

=begin comment
// NOTE: disarm_temp
/*
 * disarm_temp - Prevents premature destruction of temporary SVs.
 *
 * Arguments:
 *     SV* sv - A scalar value which would normally be discarded or freed.
 *
 * Return:
 *     SV* - A new scalar that holds the value of the temporary, protected from auto-cleanup.
 *
 * Description:
 *     This is used to hold a temporary value in a persistent form for use in lvalue context.
 *     It ensures the SV is detached from temporary cleanup scopes.
 *
 * Usage:
 *     return disarm_temp(newSViv(0)); // safe to return from XS
 *
 * Internal:
 *     Used by lnoreturn() to safely return placeholder values.
 */
=cut
SV *
disarm_temp(sv)
SV *sv;
    CODE:
        RETVAL = sv_2mortal(SvREFCNT_inc(SvREFCNT_inc(sv)));
    OUTPUT:
        RETVAL

INCLUDE: FirstMultideref.xsh
