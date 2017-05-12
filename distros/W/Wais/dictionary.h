/*                               -*- Mode: C -*- 
 * dictionary.h -- 
 * ITIID           : $ITI$ $Header $__Header$
 * Author          : Ulrich Pfeifer
 * Created On      : Fri Nov 10 15:35:13 1995
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Mon Jul  1 17:37:13 1996
 * Language        : C
 * Update Count    : 24
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1995, Universität Dortmund, all rights reserved.
 * 
 * $Locker:  $
 * $Log: dictionary.h,v $
 * Revision 2.3  1997/02/06 09:31:06  pfeifer
 * Switched to CVS
 *
 * Revision 2.2  1996/08/19 17:15:20  pfeifer
 * perl5.003
 *
 * Revision 2.1.1.3  1996/07/16 16:38:55  pfeifer
 * patch10: Modified for building from installed freeWAIS-sf libraries
 * patch10: and include files.
 *
 * Revision 2.1.1.2  1996/04/30 07:40:55  pfeifer
 * patch9: Moved defined clash fixes to dictionary.h.
 * patch9: This is not too clean - but dictionary.h is included
 * patch9: in all C-Files.
 *
 * Revision 2.1.1.1  1995/12/28 16:31:50  pfeifer
 * patch1:
 *
 * Revision 2.1  1995/12/13  14:56:31  pfeifer
 * *** empty log message ***
 *
 * Revision 2.0.1.2  1995/11/16  12:23:55  pfeifer
 * patch11: Added document.
 *
 * Revision 2.0.1.1  1995/11/10  14:52:51  pfeifer
 * patch9: Extern definitions.
 *
 */

#ifndef DICTIONARY_H
#define DICTIONARY_H

#include "Wais.h"

extern int find_word        _AP((char *database_name, char *field_name, 
                                 char *word, long offset, long *matches));
extern int postings         _AP((char *database_name, char *field_name, 
                                 char *word, long *number_of_postings));
extern char *headline       _AP((char *database_name, long docid));
extern char *document       _AP((char *database_name, long docid));

#endif
