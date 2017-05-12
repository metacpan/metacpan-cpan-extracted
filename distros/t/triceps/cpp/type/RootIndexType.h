//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A special service index type that represents the root of the index type
// tree in a table type.

#ifndef __Triceps_RootIndexType_h__
#define __Triceps_RootIndexType_h__

#include <type/IndexType.h>

namespace TRICEPS_NS {

class RootIndexType : public IndexType
{
public:
	~RootIndexType();

	// from Type
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;

	// from IndexType
	virtual const NameSet *getKey() const;
	virtual IndexType *copy(bool flat = false) const;
	virtual IndexType *deepCopy(HoldRowTypes *holder) const;
	virtual void initialize();
	virtual Index *makeIndex(const TableType *tabtype, Table *table) const;
	virtual void initRowHandleSection(RowHandle *rh) const;
	virtual void clearRowHandleSection(RowHandle *rh) const;
	virtual void copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const;

protected:
	friend class TableType;

	// only the Table may create it
	RootIndexType();

	// used by copy()
	RootIndexType(const RootIndexType &orig, bool flat);
	// used by deepCopy()
	RootIndexType(const RootIndexType &orig, HoldRowTypes *holder);
};

}; // TRICEPS_NS

#endif // __Triceps_RootIndexType_h__
