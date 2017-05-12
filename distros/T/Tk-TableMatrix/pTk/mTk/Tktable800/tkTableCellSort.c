/* 
 * tkTableCell.c --
 *
 *	This module implements cell sort functions for table
 *	widgets.  The MergeSort algorithm and other aux sorting
 *	functions were taken from tclCmdIL.c lsort command:

 * tclCmdIL.c --
 *
 *	This file contains the top-level command routines for most of
 *	the Tcl built-in commands whose names begin with the letters
 *	I through L.  It contains only commands in the generic core
 *	(i.e. those that don't depend much upon UNIX facilities).
 *
 * Copyright (c) 1987-1993 The Regents of the University of California.
 * Copyright (c) 1993-1997 Lucent Technologies.
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 * Copyright (c) 1998-1999 by Scriptics Corporation.

 *
 * Copyright (c) 1998-2002 Jeffrey Hobbs
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#include "tkTable.h"

#ifndef UCHAR
#define UCHAR(c) ((unsigned char) (c))
#endif

/*
 *----------------------------------------------------------------------
 *
 * TableSortCompareProc --
 *	This procedure is invoked by qsort to determine the proper
 *	ordering between two elements.
 *
 * Results:
 *	< 0 means first is "smaller" than "second", > 0 means "first"
 *	is larger than "second", and 0 means they should be treated
 *	as equal.
 *
 * Side effects:
 *	None, unless a user-defined comparison command does something
 *	weird.
 *
 *----------------------------------------------------------------------
 */
static int
TableSortCompareProc(first, second)
    CONST VOID *first, *second;		/* Elements to be compared. */
{
    int r1, c1, r2, c2;
    char *firstString;
    char *secondString; 
    firstString = LangString( *((Arg*) first));
    secondString = LangString(*((Arg*) second));


    /* This doesn't account for badly formed indices */
    sscanf(firstString, "%d,%d", &r1, &c1);
    sscanf(secondString, "%d,%d", &r2, &c2);
    if (r1 > r2) {
	return 1;
    } else if (r1 < r2) {
	return -1;
    } else if (c1 > c2) {
	return 1;
    } else if (c1 < c2) {
	return -1;
    }
    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * TableCellSort --
 *	Sort a list of table cell elements (of form row,col)
 *
 * Results:
 *	Returns the sorted list of elements.  Because Tcl_Merge allocs
 *	the space for result, it must later be Tcl_Free'd by caller.
 *
 * Side effects:
 *	Behaviour undefined for ill-formed input list of elements.
 *
 *----------------------------------------------------------------------
 */
Arg
TableCellSort(Table *tablePtr, char *str)
{
    int listArgc;
    Arg *listArgv;
    Arg  result;
    Arg  argstr;
    argstr = LangStringArg(str);
    if (Tcl_ListObjGetElements(tablePtr->interp, argstr, &listArgc, &listArgv) != TCL_OK) {
        ckfree((char *) argstr);
	return LangStringArg(str);
    }
    qsort((VOID *) listArgv, (size_t) listArgc, sizeof (char *),
	  TableSortCompareProc);
    result = Tcl_NewListObj(listArgc, listArgv);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * TableCellSortObj --
 *	Sorts a list of table cell elements (of form row,col) in place
 *
 * Results:
 *	Sorts list of elements in place.
 *
 * Side effects:
 *	Behaviour undefined for ill-formed input list of elements.
 *
 *----------------------------------------------------------------------
 */
Tcl_Obj *
TableCellSortObj(Tcl_Interp *interp, Tcl_Obj *listObjPtr)
{
    int length, i;
    Tcl_Obj* result;
    Tcl_Obj *sortedObjPtr, **listObjPtrs;

    if (Tcl_ListObjGetElements(interp, listObjPtr,
			       &length, &listObjPtrs) != TCL_OK) {
	return NULL;
    }
    if (length <= 0) {
	return listObjPtr;
    }
    qsort((VOID *) listObjPtrs, (size_t) length, sizeof (char *),
	  TableSortCompareProc);
	  
    result = Tcl_NewListObj(length, listObjPtrs);
    return result;

}
