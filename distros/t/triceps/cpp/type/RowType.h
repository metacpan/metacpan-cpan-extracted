//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The row type definition.

#ifndef __Triceps_RowType_h__
#define __Triceps_RowType_h__

#include <type/SimpleType.h>
#include <common/Common.h>
#include <mem/Row.h>
#include <map>

namespace TRICEPS_NS {

class RowType;
class Fdata;
class FdataVec;

// Type of a record that can be stored in a Window.
// Its subclasses know how to actually work with various concrete
// record formats.
class RowType : public Type
{
public:

	// A field of a record type. Since they aren't created that often
	// at run-time, keep them simple and copy by values.
	class Field
	{
	public:
		// The default constructor creates an invalid field.
		Field() :
			arsz_(-1) // a scalar by default
		{ }

		// the default copy and assignment are good enough
		
		// XXX add constructor and assign() from the type name, including
		// the array type recognition like in RowType.xs
		
		Field(const string &name, Autoref<const Type> t, int arsz = -1) :
			name_(name),
			type_(t),
			arsz_(arsz)
		{ }

		void assign(const string &name, Autoref<const Type> t, int arsz = -1)
		{
			name_ = name;
			type_ = t;
			arsz_ = arsz;
		}

	public:
		string name_; // field name
		Autoref <const Type> type_; // field type, must really be a simple type
		// hint of array size, 0 means variable,  <0 means a scalar;
		// there is no enforcement in the core code, it's just a suggestion
		// for the script language wrapper on the best representation
		enum {
			AR_SCALAR = -1,
			AR_VARIABLE = 0
		};
		int arsz_; 
	}; // Field

	typedef vector<Field> FieldVec;

	// The constructor parses the error definition into the
	// internal format. To get the errors, use getErrors();
	RowType(const FieldVec &fields);

	// Essentially a factory, that creates another row type with the
	// same internal format.
	virtual RowType *newSameFormat(const FieldVec &fields) const = 0;

	// Create a copy.
	RowType *copy() const
	{
		return newSameFormat(fields_);
	}

	// from Type
	virtual Erref getErrors() const;
	virtual bool equals(const Type *t) const;
	virtual bool match(const Type *t) const;
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;

	// just make the guts visible read-only to anyone
	const vector<Field> &fields() const
	{
		return fields_;
	}

	// find a field by name
	// @param fname - field name
	// @return - pointer to the field or NULL
	const Field *find(const string &fname) const;

	// find a field's index by name
	// @param fname - field name
	// @return - index of the field or -1
	int findIdx(const string &fname) const;

	// Get the count of fields
	int fieldCount() const;

	// {
	// Operations on a row of this format.
	// Since they take row pointers, the row must be held in some
	// other Autoptr to avoid it being destroyed.

	// Check whether a field is NULL
	// @param row - row to operate on
	// @param nf - field number, starting from 0
	virtual bool isFieldNull(const Row *row, int nf) const = 0;

	// Get information to access the field data.
	// @param row - row to operate on
	// @param nf - field number, starting from 0
	// @param ptr - returned pointer to field data
	// @param len - returned field data length; for a NULL field will be 0
	// @return - true if field is NOT null
	virtual bool getField(const Row *row, int nf, const char *&ptr, intptr_t &len) const = 0;

	// the rows are immutable, so the only way to change a row 
	// is by building a new one
	
	// Split the contents of a row into a data vector. Does not fill in the row_ references.
	// A convenience function working through setFrom().
	// @param row - row to split
	// @param data - vector to return the data into (its old contents will be overwritten
	//    away and vector resized to the number of fields, but no guarantees about
	//    resetting the row_ references)
	void splitInto(const Row *row, FdataVec &data) const;

	// Make a new row from the specified field values. If the vector is too
	// short, it gets extended with nulls.
	// @param data - data to put into the row (not const because of possible nulls extension)
	virtual Row *makeRow(FdataVec &data) const = 0;
	
	// Destroy a row of this type.
	// The caller must be sure that the row is of this type.
	virtual void destroyRow(Row *row) const = 0;
	
	// Copy a row without any changes. A convenience function, implemented
	// through splitInto and makeRow. It doesn't care about the data types,
	// their meaning and such. It just blindly copies the binary data.
	// @param rtype - type of original row, used to extract the contents
	// @param row - row to copy
	// @return - the newly created row
	Row *copyRow(const RowType *rtype, const Row *row) const;

	// A convenience function for building vectors: extends the vector,
	// filling it with nulls. Never shrinks the vector.
	// @param v - vector to fill
	// @param nf - fill to this number of fields
	static void fillFdata(FdataVec &v, int nf);

	// For debugging, hex dump the row contects, appending to a string.
	// (this is not including the ref counter and anything before it)
	// @param dest - string to append to
	// @param row - row to dump
	// @param indent - indenting after the line feeds
	virtual void hexdumpRow(string &dest, const Row *row, const string &indent="") const = 0;

	// Compare two rows for absolute data equality.
	// XXX maybe also add a method for equality to a row of different type
	// @param row1 - one row to compare
	// @parem row2 - another row to compare
	// @return - true if the rows contain the same data.
	virtual bool equalRows(const Row *row1, const Row *row2) const = 0;

	// Check whether the row has no payload, i.e. all the fields in it are empty.
	// Technically, the fields don't have to be null, any 0-length fields are
	// considered empty.
	// @return - true if all the fields are empty
	virtual bool isRowEmpty(const Row *row) const = 0;
	// }
	
	// {
	// Convenience functions to read values of assorted types.
	// Work internally through getField(). For null values they work like
	// Perl, returning the numeric 0 or empty string. If the field array
	// doesn't have enough elements for the required position, this is also 
	// treated as null.
	//
	// Common arguments:
	// @param row - row to operate on
	// @param nf - field number, starting from 0
	// @param pos - position of element in field array, 0 by default
	uint8_t getUint8(const Row *row, int nf, int pos = 0) const;
	int32_t getInt32(const Row *row, int nf, int pos = 0) const;
	int64_t getInt64(const Row *row, int nf, int pos = 0) const;
	double getFloat64(const Row *row, int nf, int pos = 0) const;
	const char *getString(const Row *row, int nf) const;
	// }

protected:
	// parse the definition and return the errors, called from the constructor
	Erref parse();

	FieldVec fields_; // what it consists of
	typedef map <string, size_t> IdMap;
	IdMap idmap_; // quick access by name
	Erref errors_; // errors collected during parsing

private:
	RowType();
};

// The row class needs its private kind of autoref because it's
// not virtual, so the reference would have to remember the right
// row type to provide the imitation of virtuality.

class Rowref
{
public:
	// XXX add the convenience wrappers for all the RowType's methods on rows
	typedef Row *RowPtr;

	Rowref() :
		row_(NULL)
	{ }

	// Constructor from a plain pointer.
	// @param t - the type of the row (may be NULL if row is NULL)
	// @param r - the row, may be NULL
	Rowref(const RowType *t, Row *r = NULL) :
		type_(t), 
		row_(r)
	{
		if (r)
			r->incref();
	}
	// Constructor from a field value set.
	// @param t - the type of the row (may be NULL if row is NULL)
	// @param data - data to put into the row (not const because of possible nulls extension)
	Rowref(const RowType *t, FdataVec &data) :
		type_(t), 
		row_(t->makeRow(data))
	{
		if (row_)
			row_->incref();
	}

	// Constructor from another Rowref
	Rowref(const Rowref &ar) :
		type_(ar.type_),
		row_(ar.row_)
	{
		if (row_)
			row_->incref();
	}

	~Rowref()
	{
		drop();
	}

	// A dereference
	Row &operator*() const
	{
		return *row_; // works fine even with NULL (until that thing gets dereferenced)
	}

	Row *operator->() const
	{
		return row_; // works fine even with NULL (until that thing gets dereferenced)
	}

	// Getting the internal pointer
	Row *get() const
	{
		return row_;
	}
	const RowType *getType() const // should this return Autoref?
	{
		return type_.get();
	}

	// same but transparently, as a type conversion
	operator RowPtr() const
	{
		return row_;
	}

	// A convenience comparison to NULL
	bool isNull() const
	{
		return (row_ == 0);
	}

	Rowref &operator=(const Rowref &ar)
	{
		if (&ar != this) { // assigning to itself is a null-op that might cause a mess
			drop();
			type_ = ar.type_;
			Row *r = ar.row_;
			row_ = r;
			if (r)
				r->incref();
		}
		return *this;
	}
	// change only the row, keep the same type
	Rowref &operator=(Row *r)
	{
		drop();
		row_ = r;
		if (r) {
			assert(type_);
			r->incref();
		}
		return *this;
	}
	// for multiple arguments, have to use a method...
	void assign(const RowType *t, Row *r)
	{
		drop();
		type_ = t;
		row_ = r;
		if (r)
			r->incref();
	}
	
	// Make a new row from the specified field values with the type in the ref.
	// A shortcut for calling makeRow() on that type and then assigning.
	// @param data - data to put into the row (not const because of possible nulls extension)
	Rowref &operator=(FdataVec &data)
	{
		(*this) = type_->makeRow(data);
		return *this;
	}
	// Copy a row without any changes. 
	// A shortcut for calling copyRow() on that type and then assigning.
	// @param rtype - type of original row, used to extract the contents
	// @param row - row to copy
	// @return - the newly created row
	Rowref &copyRow(const RowType *rtype, const Row *row)
	{
		(*this) = type_->copyRow(rtype, row);
		return *this;
	}
	Rowref &copyRow(const Rowref &ar)
	{
		(*this) = type_->copyRow(ar.type_, ar.row_);
		return *this;
	}

	bool operator==(const Rowref &ar)
	{
		return (row_ == ar.row_);
	}
	bool operator!=(const Rowref &ar)
	{
		return (row_ != ar.row_);
	}

	bool isRowEmpty() const
	{
		return type_->isRowEmpty(row_);
	}

	uint8_t getUint8(int nf, int pos = 0) const
	{
		return type_->getUint8(row_, nf, pos);
	}
	int32_t getInt32(int nf, int pos = 0) const
	{
		return type_->getInt32(row_, nf, pos);
	}
	int64_t getInt64(int nf, int pos = 0) const
	{
		return type_->getInt64(row_, nf, pos);
	}
	double getFloat64(int nf, int pos = 0) const
	{
		return type_->getFloat64(row_, nf, pos);
	}
	const char *getString(int nf) const
	{
		return type_->getString(row_, nf);
	}

protected:
	// Drop the current reference
	inline void drop()
	{
		Row *r = row_;
		if (r)
			if (r->decref() <= 0)
				type_->destroyRow(r);
		// don't delete the type, likely the same type will be assigned again,
		// and it will save on decreasing/increaing the type reference
	}

protected:
	const_Autoref<RowType> type_;
	Row *row_;
};

// Data to be stored in a field of a record.
// The field data are normally passed as a vector. If a row type has N fields,
// then the first N data elements determine the size of the fields and provide
// the initial filling.
// 
// If there are more field data elements, they are treated as overrides:
// fill more data into the existing fields. This allows to assemble the
// field values from multiple sources. The overrides can't go past the
// end of fields, and can not put data into the null fields.
class Fdata 
{
public:
	Fdata() :
		notNull_(false)
	{ }

	// set the field to null
	void setNull()
	{
		notNull_ = false;
	}
	// Set the field to point to a buffer
	void setPtr(bool notNull, const void *data, intptr_t len)
	{
		notNull_ = notNull;
		data_ = (const char *)data;
		len_ = len;
	}
	// Set the field by copying it from other row
	// (doesn't add a reference to that row, if needed add manually).
	inline void setFrom(const RowType *rtype, const Row *row, int nf)
	{
		notNull_ = rtype->getField(row, nf, data_, len_);
	}

	// Set the field as an override. 
	void setOverride(int nf, intptr_t off, const void *data, intptr_t len)
	{
		nf_ = nf;
		off_ = off;
		data_ = (const char *)data;
		len_ = len;
	}

	// Constructors with the same meaning
	Fdata(bool notNull, const void *data, intptr_t len)
	{
		notNull_ = notNull;
		data_ = (const char *)data;
		len_ = len;
	}
	Fdata(int nf, intptr_t off, const void *data, intptr_t len)
	{
		nf_ = nf;
		off_ = off;
		data_ = (const char *)data;
		len_ = len;
	}

public:
	Rowref row_; // in case if data comes from another row, can be used
		// to keep a hold on it, but doesn't have to if the row won't be deleted anyway
	const char *data_; // data to store, may be NULL to just zero-fill
	intptr_t len_; // length of data to store
	intptr_t off_; // for overrides only: offset into the field
	int nf_; // for overrides only: index of field to fill
	bool notNull_; // this field is not null (only for non-overrides)
};

class FdataVec : public  vector<Fdata>
{
public:
	FdataVec()
	{ }

	FdataVec(size_t n) :
		vector<Fdata>(n)
	{ }
};

}; // TRICEPS_NS

#endif // __Triceps_RowType_h__
