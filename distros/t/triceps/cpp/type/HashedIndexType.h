//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An index that implements a unique primary key with an unpredictable order.

#ifndef __Triceps_HashedIndexType_h__
#define __Triceps_HashedIndexType_h__

#include <type/TreeIndexType.h>
#include <common/Hash.h>

namespace TRICEPS_NS {

class RowType;

class HashedIndexType : public TreeIndexType
{
public:
	// Keeps a reference of key. If key is not specified, it
	// must be set later, before initialization.
	HashedIndexType(NameSet *key = NULL);
	// Constructors duplicated as make() for syntactically better usage.
	static HashedIndexType *make(NameSet *key = NULL)
	{
		return new HashedIndexType(key);
	}
	
	// Set tke key later (until initialized, afterwards will throw an Exception).
	// If an Exception is thrown, tries to free the unreferenced (this).
	// Keeps a reference of key.
	HashedIndexType *setKey(NameSet *key);

	// from Type
	virtual bool equals(const Type *t) const;
	virtual bool match(const Type *t) const;
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
	// specialization from TreeIndex

	// section in the RowHandle, placed at rhOffset_
	struct RhSection : public BasicRhSection
	{
		Hash::Value hash_; // for quicker comparison
	};

	
	// Comparator class for the row objects
	class Less : public TreeIndexType::Less
	{
	public:
		Less(const RowType *rt, intptr_t rhOffset, const vector<int32_t> &keyFld);

		// from TreeIndexType::Less
		virtual TreeIndexType::Less *tableCopy(Table *t) const;
		virtual bool operator() (const RowHandle *r1, const RowHandle *r2) const;

	protected:
		// Internals of the tableCopy();
		Less(const Less *other, Table *t);

		const vector<int32_t> &keyFld_; // indexes of key fields in the record
		intptr_t rhOffset_; // offset of this index's data in table's row handle

	private:
		Less();
	};

protected:
	// used by copy()
	HashedIndexType(const HashedIndexType &orig, bool flat);
	// used by deepCopy()
	HashedIndexType(const HashedIndexType &orig, HoldRowTypes *holder);

protected:
	Autoref<Less> less_;
	Autoref<NameSet> key_;
	vector<int32_t> keyFld_; // indexes of key fields in the record
};

}; // TRICEPS_NS

#endif // __Triceps_HashedIndexType_h__
