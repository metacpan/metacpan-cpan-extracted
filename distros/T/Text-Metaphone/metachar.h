#ifndef __METACHAR_H__
#define __METACHAR_H__

/* Metachar.h ... little bits about characters for metaphone */


/*-- Character encoding array & accessing macros --*/
/* Stolen directly out of the book... */
char _codes[26] = {
	1,16,4,16,9,2,4,16,9,2,0,2,2,2,1,4,0,2,4,4,1,0,0,0,8,0
/*  a  b c  d e f g  h i j k l m n o p q r s t u v w x y z */
};


#define ENCODE(c) (isalpha(c) ? _codes[((toupper(c)) - 'A')] : 0)

#define isvowel(c)	(ENCODE(c) & 1)		/* AEIOU */

/* These letters are passed through unchanged */
#define NOCHANGE(c)	(ENCODE(c) & 2) 	/* FJMNR */

/* These form dipthongs when preceding H */
#define AFFECTH(c)	(ENCODE(c) & 4) 	/* CGPST */

/* These make C and G soft */
#define MAKESOFT(c)	(ENCODE(c) & 8) 	/* EIY */

/* These prevent GH from becoming F */
#define NOGHTOF(c)	(ENCODE(c) & 16) 	/* BDH */



#endif
