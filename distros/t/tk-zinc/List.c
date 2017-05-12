/*
 * List.c -- Implementation of list module.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Tue Mar 15 17:18:17 1994
 *
 * $Id: List.c,v 1.13 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


/*
 **********************************************************************************
 * 
 * This modules exports the following functions:
 *      - ZnListNew
 *      - ZnListDuplicate
 *      - ZnListEmpty
 *      - ZnListFromArray
 *      - ZnListArray
 *      - ZnListFree
 *      - ZnListSize
 *      - ZnListAssertSize
 *      - ZnListAdd
 *      - ZnListAt
 *      - ZnListAtPut
 *      - ZnListDelete
 *      - ZnListTruncate
 *      - ZnListDetect
 *      - ZnListDo
 *
 * To appear soon:
 *      - ZnListCollect
 *      - ZnListReject
 *
 * And the following variables:
 *
 **********************************************************************************
 */

/*
 **********************************************************************************
 *
 * Included files
 *
 **********************************************************************************
 */

#include "Types.h"
#include "List.h"

#include <stddef.h>
#include <memory.h>
#include <stdlib.h>


/*
 **********************************************************************************
 *
 * Constants
 *
 **********************************************************************************
 */
static const char rcs_id[]="$Id: List.c,v 1.13 2005/04/27 07:32:03 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";

#define MAX_CHUNCK_SIZE         1024

#define MAX(a, b)               ((a) > (b) ? (a) : (b))
#define MIN(a, b)               ((a) < (b) ? (a) : (b))


/*
 **********************************************************************************
 *
 * New types
 *
 **********************************************************************************
 */

typedef struct {
  char          *list;
  unsigned long elem_size;
  unsigned long alloc_size;
  unsigned long used_size;
} _ZnList;


/*
 **********************************************************************************
 *
 * GrowIfNeeded --
 *      Enlarge a list so that it has min_size available. Take care of
 *      static storage.
 *
 **********************************************************************************
 */

static void
GrowIfNeeded(_ZnList      *list,
             unsigned int min_size)
{
  if (list->used_size+min_size <= list->alloc_size) {
    return;
  }
  
  if (list->alloc_size == 0) {
    if (list->list == NULL) {
      /* Normal case if we have created a zero sized list */
      list->alloc_size = min_size;
      list->list = ZnMalloc(list->alloc_size*list->elem_size);
    }
    else {
      /* Case of a list made by ZnListFromArray. If we try to make
         it grow we need to reallocate and copy. */
      char      *new_list;

      list->alloc_size = list->used_size+min_size;
      new_list = ZnMalloc(list->alloc_size*list->elem_size);
      memcpy(new_list,
             list->list,
             list->used_size*list->elem_size);
      list->list = new_list;
    }
  }
  else {
    list->alloc_size = MAX(MIN(list->alloc_size*2, MAX_CHUNCK_SIZE),
                           list->alloc_size+min_size);
    
    list->list = ZnRealloc(list->list,
                           list->alloc_size*list->elem_size);
  }
  
  memset(list->list+(list->used_size*list->elem_size),
         0,
         (list->alloc_size-list->used_size)*list->elem_size);
}


/*
 **********************************************************************************
 *
 * ZnListNew --
 *      Return a new empty list 'initial_size' large.
 *
 **********************************************************************************
 */

ZnList
ZnListNew(unsigned int  initial_size,
          unsigned int  element_size)
{
  _ZnList       *new_list;

  if (element_size == 0) {
    element_size = 1;
  }

  new_list = ZnMalloc(sizeof(_ZnList));

  new_list->alloc_size = initial_size;
  new_list->used_size = 0;
  new_list->elem_size = element_size;

  if (initial_size) {
    unsigned long size = new_list->alloc_size*new_list->elem_size;

    new_list->list = ZnMalloc(size);
    memset(new_list->list, 0, size);
  }
  else {
    new_list->list = NULL;
  }
  
  return (ZnList) new_list;
}


/*
 **********************************************************************************
 *
 * ZnListDuplicate --
 *      Return a copy of the list given as parameter.
 *
 **********************************************************************************
 */

ZnList
ZnListDuplicate(ZnList  list)
{
  _ZnList       *cur_list = (_ZnList *) list;
  _ZnList       *new_list;

  new_list = ZnMalloc(sizeof(_ZnList));

  new_list->alloc_size = cur_list->alloc_size == 0 ? cur_list->used_size :
                                                     cur_list->alloc_size;
  new_list->used_size = cur_list->used_size;
  new_list->elem_size = cur_list->elem_size;

  if (new_list->alloc_size) {
    unsigned long used_size = new_list->used_size*new_list->elem_size;
    unsigned long size = new_list->alloc_size*new_list->elem_size;

    new_list->list = ZnMalloc(size);

    if (used_size) {
      memcpy(new_list->list, cur_list->list, used_size);
    }

    memset(new_list->list + used_size, 0, size - used_size);
  }
  else {
    new_list->list = NULL;
  }
    
  return (ZnList) new_list;
}


/*
 **********************************************************************************
 *
 * ZnListEmpty --
 *      Clear out a list, kkeping its allocated size.
 *
 **********************************************************************************
 */

void
ZnListEmpty(ZnList      list)
{
  _ZnList       *cur_list = (_ZnList *) list;

  cur_list->used_size = 0;
}


/*
 **********************************************************************************
 *
 * ZnListFromArray --
 *      Return a list filled from the given array.
 *
 **********************************************************************************
 */

ZnList
ZnListFromArray(void            *array,
                unsigned int    array_size,
                unsigned int    element_size)
{
  _ZnList       *new_list;

  new_list = (_ZnList *) ZnListNew(0, element_size);
  new_list->list = array;
  new_list->used_size = array_size;
  return (ZnList) new_list;
}


/*
 **********************************************************************************
 *
 * ZnListArray --
 *      Return a pointer to the array containing the list.
 *
 **********************************************************************************
 */

void *
ZnListArray(ZnList      list)
{
  _ZnList       *cur_list = (_ZnList *) list;

  return (void *) cur_list->list;
}


/*
 **********************************************************************************
 *
 * ZnListFree --
 *      Delete a list and free its memory. The entries
 *      still in the list are lost but no further deallocation
 *      is attempted.
 *
 **********************************************************************************
 */

void
ZnListFree(ZnList       list)
{
  _ZnList       *cur_list = (_ZnList *) list;

  if (cur_list->list != NULL && cur_list->alloc_size != 0) {
    ZnFree(cur_list->list);
  }

  ZnFree(cur_list);
}


/*
 **********************************************************************************
 *
 * ZnListSize --
 *      Return the current number of entries kept in list.
 *
 **********************************************************************************
 */

unsigned int
ZnListSize(ZnList       list)
{
  return ((_ZnList *)list)->used_size;
}


/*
 **********************************************************************************
 *
 * ZnListAssertSize --
 *      Set the list length to size.
 *
 **********************************************************************************
 */

void
ZnListAssertSize(ZnList         list,
                 unsigned int   size)
{
  _ZnList       *cur_list = (_ZnList *) list;

  if (cur_list->used_size < size) {
    GrowIfNeeded(cur_list, size - cur_list->used_size);
  }
  cur_list->used_size = size;
}


/*
 **********************************************************************************
 *
 * ZnListCopy --
 *      Destructively copy 'from' into 'to' starting at the first
 *      position. It is the same as saying ZnListEmpty and then
 *      ZnListAppend.
 *
 **********************************************************************************
 */

void
ZnListCopy(ZnList       to,
           ZnList       from)
{
  _ZnList       *to_list = (_ZnList *) to;
  _ZnList       *from_list = (_ZnList *) from;

  if (from_list->elem_size != to_list->elem_size) {
    return;
  }

  to_list->used_size = 0;
  GrowIfNeeded(to_list, from_list->used_size);
  memcpy(to_list->list,
         from_list->list,
         from_list->used_size*from_list->elem_size);
  to_list->used_size = from_list->used_size;
}


/*
 **********************************************************************************
 *
 * ZnListAppend --
 *      Append 'from' at the end of 'to' which is enlarged as needed.
 *
 **********************************************************************************
 */

void
ZnListAppend(ZnList     to,
             ZnList     from)
{
  _ZnList       *to_list = (_ZnList *) to;
  _ZnList       *from_list = (_ZnList *) from;

  if (from_list->elem_size != to_list->elem_size) {
    return;
  }

  GrowIfNeeded(to_list, from_list->used_size);
  memcpy(to_list->list+(to_list->used_size*to_list->elem_size),
         from_list->list,
         from_list->used_size*from_list->elem_size);
  to_list->used_size += from_list->used_size;
}


/*
 **********************************************************************************
 *
 * ZnListAdd --
 *      Add a new entry 'value' in the list before
 *      'index'. 'index' can be the position of a
 *      previous entry or the special values ZnListHead,
 *      ZnListTail. The entries have positions
 *      starting at 0.
 *
 **********************************************************************************
 */

void
ZnListAdd(ZnList        list,
          void          *value,
          unsigned int  index)
{
  _ZnList *cur_list = (_ZnList *) list;
  int     i;

  GrowIfNeeded(cur_list, 1);

  if (index < cur_list->used_size) {
    for (i = cur_list->used_size-1; i >= (int) index; i--) {
      memcpy(cur_list->list+((i+1)*cur_list->elem_size),
             cur_list->list+(i*cur_list->elem_size),
             cur_list->elem_size);
    }
  }
  else if (index > cur_list->used_size) {
    index = cur_list->used_size;
  }
  
  memcpy(cur_list->list+(index*cur_list->elem_size),
         (char *) value,
         cur_list->elem_size);

  (cur_list->used_size)++;
}


/*
 **********************************************************************************
 *
 * ZnListAt --
 *      Return the entry at 'index'. Indices start at 0.
 *      Indices out of the current range are constrained
 *      to fit in the range.
 *
 **********************************************************************************
 */

void *
ZnListAt(ZnList         list,
         unsigned int   index)
{
  if (!((_ZnList *) list)->used_size) {
    return NULL;
  }
  if (index >= ((_ZnList *) list)->used_size) {
    index = ((_ZnList *) list)->used_size - 1;
  }
  
  return (void *) (((_ZnList *) list)->list+(index*((_ZnList *) list)->elem_size));
}


/*
 **********************************************************************************
 *
 * ZnListAtPut --
 *      Set the entry at 'index' to 'value'.
 *      Indices start at 0. Indices out of the current
 *      range are constrained to fit in the range.
 *
 **********************************************************************************
 */

void
ZnListAtPut(ZnList       list,
            void         *value,
            unsigned int index)
{
  if (!((_ZnList *) list)->used_size) {
    return;
  }
  if (index >= ((_ZnList *) list)->used_size) {
    index = ((_ZnList *) list)->used_size - 1;
  }
  
  memcpy(((_ZnList *) list)->list+(index*((_ZnList *) list)->elem_size),
         (char *) value,
         ((_ZnList *) list)->elem_size);
}


/*
 **********************************************************************************
 *
 * ZnListDelete --
 *      Suppress the entry matching value, searching from position 
 *      'index'. If value is NULL suppress entry at index.
 *
 **********************************************************************************
 */

void
ZnListDelete(ZnList             list,
             unsigned int       index)
{
  _ZnList       *cur_list = (_ZnList *) list;
  unsigned int  i;

  if (!((_ZnList *) list)->used_size) {
    return;
  }
  if (index >= ((_ZnList *) list)->used_size) {
    index = ((_ZnList *) list)->used_size - 1;
  }

  for (i = index; i < cur_list->used_size-1; i++) {
    memcpy(cur_list->list+(i*cur_list->elem_size),
           cur_list->list+((i+1)*cur_list->elem_size),
           cur_list->elem_size);
  }
  (cur_list->used_size)--;
}

/*
 **********************************************************************************
 *
 * ZnListTruncate --
 *      Suppress the entries from position 'index' inclusive to the end.
 *
 **********************************************************************************
 */

void
ZnListTruncate(ZnList           list,
               unsigned int     index)
{
  _ZnList       *cur_list = (_ZnList *) list;

  if (index >= ((_ZnList *) list)->used_size) {
    return;
  }

  cur_list->used_size = index;
}
