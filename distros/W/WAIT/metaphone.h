/*                               -*- Mode: C -*- 
 * metaphone.h -- 
 * ITIID           : $ITI$ $Header $__Header$
 * Author          : Ulrich Pfeifer
 * Created On      : Fri Oct 11 13:29:13 1996
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Fri Oct 11 14:02:15 1996
 * Language        : C
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1996, Universität Dortmund, all rights reserved.
 * 
 * $Locker:  $
 * $Log: metaphone.h,v $
 * Revision 1.1  1999/05/17 13:37:10  k
 * Initial revision
 *
 * Revision 1.7  1997/02/04 15:44:38  pfeifer
 * *** empty log message ***
 *
 * Revision 1.0.1.1  1996/12/30 14:22:18  pfeifer
 * patch1: Added Copyright notice.
 *
 */

#ifndef METAPHONE_H
#define METAPHONE_H
#ifdef __cplusplus
/* declare these as C style functions */
extern "C"
	{
#endif /* def __cplusplus */


char * metaphone _((char *word, char *code, int codesize));

#ifdef __cplusplus
	}
#endif /* def __cplusplus */

#endif
