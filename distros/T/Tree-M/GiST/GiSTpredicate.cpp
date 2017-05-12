// -*- Mode: C++ -*-

//          GiSTpredicate.cpp
//
// Copyright (c) 1996, Regents of the University of California
// $Header: /cvsroot/Tree-M/GiST/GiSTpredicate.cpp,v 1.1 2001/05/06 00:45:52 root Exp $

#include <string.h>

#include "GiST.h"

int PtrPredicate::Consistent(const GiSTentry& entry) const
{
	return !entry.IsLeaf()||entry.Ptr()==page;
}

GiSTobject* PtrPredicate::Copy() const
{
	return new PtrPredicate(page);
}

#ifdef PRINTING_OBJECTS
void PtrPredicate::Print(ostream& os) const
{
	os << "ptr = " << page;
}
#endif
