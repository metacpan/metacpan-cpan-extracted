/*                               -*- Mode: C -*- 
 * HTWAIS.h -- 
 * ITIID           : $ITI$ $Header $__Header$
 * Author          : Ulrich Pfeifer
 * Created On      : Fri Nov 10 15:41:36 1995
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Thu Jun 13 16:30:32 1996
 * Language        : C
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1995, Universität Dortmund, all rights reserved.
 * 
 * $Locker:  $
 * $Log: HTWAIS.h,v $
 * Revision 2.3  1997/02/06 09:30:55  pfeifer
 * Switched to CVS
 *
 * Revision 2.2  1996/08/19 17:15:20  pfeifer
 * perl5.003
 *
 * Revision 2.1.1.2  1996/07/16 16:32:46  pfeifer
 * patch10: Modified for building from installed freeWAIS-sf libraries
 * patch10: and include files.
 *
 * Revision 2.1.1.1  1996/04/09 13:05:43  pfeifer
 * patch8: Avoid some redifinition warnings.
 *
 * Revision 2.1  1995/12/13  14:53:14  pfeifer
 * *** empty log message ***
 *
 * Revision 2.0.1.1  1995/11/10  14:52:19  pfeifer
 * patch9: Extern definitions.
 *
 */

#ifndef HTWAIS_H
#include "Wais.h"
extern int WAISsearch _AP((char *host, int port, char *database, char *keywords,
                              SV *diag, SV *headl, SV *text));

extern int WAISretrieve _AP((char *host, int port, char *database, char *docid,
                              SV *diag, SV *headl, SV *text));
#endif
