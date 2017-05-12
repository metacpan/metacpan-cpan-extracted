/*
 * Group.h -- Header for Group items.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Group.h,v 1.5 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 2002 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Group_h
#define _Group_h


ZnItem ZnGroupHead(ZnItem group);
ZnItem ZnGroupTail(ZnItem group);
ZnBool ZnGroupCallOm(ZnItem group);
ZnBool ZnGroupAtomic(ZnItem group);
void ZnGroupSetCallOm(ZnItem group, ZnBool set);
void ZnInsertDependentItem(ZnItem item);
void ZnExtractDependentItem(ZnItem item);
void ZnDisconnectDependentItems(ZnItem item);
void ZnGroupInsertItem(ZnItem group, ZnItem item, ZnItem mark_item, ZnBool before);
void ZnGroupExtractItem(ZnItem item);
void ZnGroupRemoveClip(ZnItem group, ZnItem clip);

#endif /* _Group_h */
