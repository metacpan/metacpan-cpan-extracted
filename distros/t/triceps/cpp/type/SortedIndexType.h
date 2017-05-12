//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An index that implements a unique primary key with an explicit sort order.

#ifndef __Triceps_SortedIndexType_h__
#define __Triceps_SortedIndexType_h__

#include <type/TreeIndexType.h>

namespace TRICEPS_NS {

class RowType;
class SortedIndexType;

// The user inherits from this class to create a sort condition.
// Then a concrete object of the user's class is passed to SortedIndexType
// to define the row order.
//
// If some information about the row needs to be cached in the RowHandle,
// also define your own subclass of TreeIndexType::BasicRhSection
// and add any extra fields you need.
//
// TreeIndexType::Less is an Mtarget.
class SortedIndexCondition : public TreeIndexType::Less
{
public:
	SortedIndexCondition() :
		TreeIndexType::Less(NULL), // a placeholder value
		rhOffset_(0) // a placeholder value
	{ }

	// Constructor for tableCopy().
	// This is called with an initialized argument and produces an
	// initialized copy.
	SortedIndexCondition(const SortedIndexCondition *other, Table *t) :
		TreeIndexType::Less(other, t),
		rhOffset_(other->rhOffset_)
	{ }

	// Will be called at the table type initialization time.
	// By default does nothing.
	//
	// The TreeIndexType::Less::rt_ will be already set by that time.
	// @param errors - buffer to report the errors.
	// @param tabtype - table type where this object belongs
	// @param indtype - index type where this object belongs
	virtual void initialize(Erref &errors, TableType *tabtype, SortedIndexType *indtype);

	// from TreeIndexType::Less
	//
	// Redefine this method to create a per-Index copy with Table link.
	// virtual TreeIndexType::Less *tableCopy(Table *t) const;
	//
	// Redefine this method to perform the actual comparison of Less.
	// Must return true if r1 is less than r2, false if r1 ir greater or equal to r2.
	// virtual bool operator() (const RowHandle *r1, const RowHandle *r2) const = 0;
	
	// For type comparison.
	// By this time sc is guaranteed to be of the same derived type, or
	// SortedIndexType would return false before it gets here.
	// SortedIndexType compares them using typeid().
	//
	// If the sorting condition is hardcoded and takes no arguments,
	// simply return true.
	//
	// The TreeIndexType::Less::rt_ will be likely NOT set yet at this time!!!
	virtual bool equals(const SortedIndexCondition *sc) const = 0;
	virtual bool match(const SortedIndexCondition *sc) const = 0;

	// Print the custom index description in a human-readable form.
	// The calling code will already take care to prepend it with "index "
	// and follow by the listing of the nested indexes.
	// The typical implementation is like this:
	// void MySortedIndex::printTo(string &res, const string &indent, const string &subindent) const
	// {
	//     res.append("MySortedIndex(");
	//     // print whatever parameters for the sorting order
	//     res.append(")");
	// }
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const = 0;

	// Copy the condition object by calling the copy constructor.
	//
	// The typical implementation is like this:
	// IndexType *MySortCondition::copy() const
	// {
	//     return new MySortCondition(*this);
	// }
	//
	// The copy constructor should follow the common IndexType convention,
	// and if it keeps the initialization flag, make the copy
	// un-initialized.
	virtual SortedIndexCondition *copy() const = 0;

	// Deep-copy the condition object by calling the copy constructor,
	// nicely cloning the row types. It also comes handy for the Perl
	// indexes to re-compile the code snippets in the new thread, because
	// the major reason for this call is for importing the table types
	// through a nexus to another thread.
	//
	// The defalult implementation just calls copy() since most simple index
	// conditions would not have any row types nor any Perl snippets.
	//
	// If redefined, the typical implementation is like this:
	// IndexType *MySortCondition::deepCopy(HoldRowTypes *holder) const
	// {
	//     return new MySortCondition(*this, holder);
	// }
	//
	// The copy constructor should follow the common IndexType convention,
	// and if it keeps the initialization flag, make the copy
	// un-initialized.
	virtual SortedIndexCondition *deepCopy(HoldRowTypes *holder) const;
	
public:
	// The rest of virtual functions are not =0 and don't have to be redefined.

	// Return the list of key fields used by this index,
	// if it's known. If unknown, may return NULL.
	// The default implementation returns NULL.
	// XXX add API to rememeber the keys in this object
	virtual const NameSet *getKey() const;
	
	// If defining your own subclass of TreeIndexType::BasicRhSection, 
	// return its size here.
	// This call will be done after initialize(), so if the required size
	// is not fixed, initialize() may calculate it.
	// By default returns sizeof(TreeIndexType::BasicRhSection).
	virtual size_t sizeOfRhSection() const;

	// Mirroring the calls from IndexType.
	// The default implementation constructs TreeIndexType::BasicRhSection.
	//
	// The typical overridden implementation would look like:
	//
	// void MySortCondition::initRowHandleSection(RowHandle *rh) const
	// {
	//     MyRhSection *rs = rh->get<MyRhSection>(rhOffset_);
	//     // initialize the iterator by calling its constructor in the placement
	//     // (at this point rh->getRow() can be used to get the row data)
	//     new(rs) MyRhSection(rh);
	// }
	// 
	// void MySortCondition::clearRowHandleSection(RowHandle *rh) const
	// { 
	//     // clear the iterator by calling its destructor
	//     MyRhSection *rs = rh->get<MyRhSection>(rhOffset_);
	//     rs->~MyRhSection();
	// }
	// 
	// void MySortCondition::copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const
	// {
	//     MyRhSection *rs = rh->get<MyRhSection>(rhOffset_);
	//     MyRhSection *fromrs = fromrh->get<MyRhSection>(rhOffset_);
	//     
	//     // initialize the iterator by calling its copy constructor inside the placement
	//     new(rs) MyRhSection(*fromrs);
	// }
	virtual void initRowHandleSection(RowHandle *rh) const;
	virtual void clearRowHandleSection(RowHandle *rh) const;
	virtual void copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const;

public:
	// After the row handle type is built, this call is used
	// to remember the offset of this index'es section in it for future use.
	// The other methods (like operator() above) can then use
	// the following code to get access to the section of concrete
	// row handles:
	//    MyRhSection *rs = rh->get<MyRhSection>(rhOffset_);
	void setRhOffset(intptr_t off) 
	{
		rhOffset_ = off;
	}

	// The first step of the initialization: remember the row type.
	void setRowType(const RowType *rt)
	{
		rt_ = rt;
	}

protected:
	intptr_t rhOffset_; // offset of this index's data in table's row handle
};

class SortedIndexType : public TreeIndexType
{
public:
	// @param sc - the object defining the sorting order 
	SortedIndexType(Onceref<SortedIndexCondition> sc);
	// Constructors duplicated as make() for syntactically better usage.
	static SortedIndexType *make(Onceref<SortedIndexCondition> sc)
	{
		return new SortedIndexType(sc);
	}

	// Get back the condition, just in case.
	SortedIndexCondition *getCondition() const
	{
		return sc_.get();
	}

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
	// used by copy(), copies sc_
	SortedIndexType(const SortedIndexType &orig, bool flat);
	// used by deepCopy(), deep-copies sc_
	SortedIndexType(const SortedIndexType &orig, HoldRowTypes *holder);

protected:
	Autoref<SortedIndexCondition> sc_; // the code that handles the user specifics
};

}; // TRICEPS_NS

#endif // __Triceps_SortedIndexType_h__
