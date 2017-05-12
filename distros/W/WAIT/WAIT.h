/*                               -*- Mode: C -*- 
 * metaphone.h -- 
 * ITIID           : $ITI$ $Header $__Header$
 * Author          : Ulrich Pfeifer
 * Created On      : Fri Oct 11 13:29:13 1996
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Fri Oct 11 14:48:41 1996
 * Language        : C
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1996, Universität Dortmund, all rights reserved.
 * 
 * $Locker:  $
 * $Log: WAIT.h,v $
 * Revision 1.1  1999/05/17 13:37:10  k
 * Initial revision
 *
 * Revision 1.7  1997/02/04 15:44:32  pfeifer
 * *** empty log message ***
 *
 * Revision 1.0.1.1  1996/12/30 14:20:57  pfeifer
 * patch1: Converted to dist-3.0
 *
 */

#ifndef METAPHONE_H
#define METAPHONE_H
#ifdef __cplusplus
/* declare these as C style functions */
extern "C"
	{
#endif /* def __cplusplus */


extern bool IsAlpha _((unsigned char c));
extern bool IsVowel _((unsigned char c));
extern unsigned char ToUpper _((unsigned char c));
extern unsigned char ToLower _((unsigned char c));
extern unsigned char *isolc _((unsigned char * c, int len));
#ifdef __cplusplus
	}
#endif /* def __cplusplus */

#endif
