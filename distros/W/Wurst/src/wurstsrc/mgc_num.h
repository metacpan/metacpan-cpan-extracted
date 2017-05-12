/* 27 May 96
 * rcsid = $Id: mgc_num.h,v 1.1 2007/09/28 16:57:06 mmundry Exp $
 * Can only be included after <stdio.h>
 */

#ifndef __MGC_NUM_H
#define __MGC_NUM_H

enum byte_magic {
    BYTE_STRAIGHT,
    BYTE_REVERSE,
    BYTE_BROKEN
};

int              write_magic_num ( FILE *fp );
enum byte_magic  read_magic_num  ( FILE *fp );
/* Why do we define our byte swapper ? We could use htonl() and ntohl().
 * The trouble is that we have to include
    sys/types.h & netinet/in.h under solaris and Irix6.something
    netinet.h under linux,
    arpa/inet.h according to the Open group's posix definition !!!
 * Let's avoid this by saying..
 */


/* This next macro does an in-place byte-swap, that is, it changes its 
 * argument
 */
#define BYTE_REVERSE_4(x) \
    *(unsigned int *)(&x)=\
    ((((*(unsigned int *)(&x)) & 0x000000ffU) << 24) | \
     (((*(unsigned int *)(&x)) & 0x0000ff00U) <<  8) | \
     (((*(unsigned int *)(&x)) & 0x00ff0000U) >>  8) | \
     (((*(unsigned int *)(&x)) & 0xff000000U) >> 24)); \

#define BYTE_REVERSE_2(x) \
    *(short int *) (&x)=\
    ((((*(short int *)(&x)) & 0x00ff) << 8) | \
     (((*(short int *)(&x)) & 0xff00) >> 8));


#endif  /* __MGC_NUM_H */
