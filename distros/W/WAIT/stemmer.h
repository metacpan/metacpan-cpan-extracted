/* WIDE AREA INFORMATION SERVER SOFTWARE
   No guarantees or restrictions.  See the readme file for the full standard
   disclaimer.  
  
*/

/* Copyright (c) CNIDR (see stemmer.c) */


#ifndef STEMMER_H
#define STEMMER_H

#ifdef __cplusplus
/* declare these as C style functions */
extern "C"
	{
#endif /* def __cplusplus */


/* main stemmer routine */
int Stem _((char *word));

#ifdef __cplusplus
	}
#endif /* def __cplusplus */

#endif /* STEMMER_H */
