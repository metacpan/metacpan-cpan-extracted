//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An index that implements a unique primary key with explicit order.

#ifndef __Triceps_OrderedIndexType_h__
#define __Triceps_OrderedIndexType_h__

#include <type/TreeIndexType.h>
#include <common/Hash.h>

namespace TRICEPS_NS {

class RowType;

class OrderedIndexType : public TreeIndexType
{
public:
	// Keeps a reference of key. If key is not specified, it
	// must be set later, before initialization.
	//
	// The field names that are prefixed by "!" are used in the reverse order,
	// the rest in the direct order.
	OrderedIndexType(NameSet *key = NULL);
	// Constructors duplicated as make() for syntactically better usage.
	static OrderedIndexType *make(NameSet *key = NULL)
	{
		return new OrderedIndexType(key);
	}
	
	// Set tke key later (until initialized, afterwards will throw an Exception).
	// If an Exception is thrown, tries to free the unreferenced (this).
	// Keeps a reference of key.
	OrderedIndexType *setKey(NameSet *key);

	// from Type
	virtual bool equals(const Type *t) const;
	virtual bool match(const Type *t) const;
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;

	// from IndexType
	virtual const NameSet *getKey() const;
	virtual const NameSet *getKeyExpr() const;
	virtual IndexType *copy(bool flat = false) const;
	virtual IndexType *deepCopy(HoldRowTypes *holder) const;
	virtual void initialize();
	virtual Index *makeIndex(const TableType *tabtype, Table *table) const;
	virtual void initRowHandleSection(RowHandle *rh) const;
	virtual void clearRowHandleSection(RowHandle *rh) const;
	virtual void copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const;

protected:
	// specialization from TreeIndex

	// Comparator class for the row objects
	class Less : public TreeIndexType::Less
	{
	public:
		Less(const RowType *rt, intptr_t rhOffset, const vector<int32_t> &keyFld, const vector<bool> &asc);

		// from TreeIndexType::Less
		virtual TreeIndexType::Less *tableCopy(Table *t) const;
		virtual bool operator() (const RowHandle *r1, const RowHandle *r2) const;

	protected:
		// Internals of the tableCopy();
		Less(const Less *other, Table *t);

		const vector<int32_t> &keyFld_; // indexes of key fields in the record
		const vector<bool> &asc_; // for each key field, true if the order is ascending, false if descending
		intptr_t rhOffset_; // offset of this index's data in table's row handle

	private:
		Less();
	};

protected:
	// used by copy()
	OrderedIndexType(const OrderedIndexType &orig, bool flat);
	// used by deepCopy()
	OrderedIndexType(const OrderedIndexType &orig, HoldRowTypes *holder);

protected:
	Autoref<Less> less_;
	Autoref<NameSet> key_; // only the names of fields, without descending indicator
	Autoref<NameSet> fullKey_; // the full definition of the key with "!" prepended to the descending fields
	vector<int32_t> keyFld_; // indexes of key fields in the record
	vector<bool> asc_; // for each key field, true if the order is ascending, false if descending
};

}; // TRICEPS_NS

#endif // __Triceps_OrderedIndexType_h__
