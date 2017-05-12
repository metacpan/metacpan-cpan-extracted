/*
 * List.h -- Header of list module.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Tue Mar 15 17:24:51 1994
 *
 * $Id: List.h,v 1.12 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _List_h
#define _List_h


#ifdef __CPLUSPLUS__
extern "C" {
#endif


#define ZnListHead      0
#define ZnListTail      (~(1 << ((8*sizeof(int)) - 1)))


typedef void    *ZnList;


ZnList  ZnListNew(unsigned int  /* initial_size */,
                  unsigned int  /* element_size */);
ZnList  ZnListDuplicate(ZnList  /* list */);
void    ZnListEmpty(ZnList      /* list */);
ZnList  ZnListFromArray(void    * /* array */,
                        unsigned int    /* array_size */,
                        unsigned int    /* element_size */);
void    *ZnListArray(ZnList     /* list */);
void    ZnListFree(ZnList       /* list */);
unsigned int ZnListSize(ZnList  /* list */);
void    ZnListAssertSize(ZnList /* list */,
                         unsigned int   /* size */);
void    ZnListCopy(ZnList       /* to */,
                   ZnList       /* from */);
void    ZnListAppend(ZnList     /* to */,
                     ZnList     /* from */);
void    ZnListAdd(ZnList        /* list */,
                  void          * /* value */,
                  unsigned int  /* index */);
void    *ZnListAt(ZnList        /* list */,
                  unsigned int  /* index */);
void    ZnListAtPut(ZnList              /* list */,
                    void       * /* value */,
                    unsigned int /* index */);
void    ZnListDelete(ZnList             /* list */,
                     unsigned int       /* index */);
void    ZnListTruncate(ZnList           /* list */,
                       unsigned int     /* index */);

#ifdef __CPLUSPLUS__
}
#endif

#endif /* _List_h */
