//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The general type definition.

#ifndef __Triceps_Type_h__
#define __Triceps_Type_h__

#include <mem/Mtarget.h>
#include <common/Common.h>
#include <common/StringUtil.h>

namespace TRICEPS_NS {

class SimpleType;

// This is a base class for both the simple and complex types.
// Note that the complex types should normally refer to their component
// types as const, sinc ethey have no business changing these components.
class Type : public Mtarget
{
public:
	// The identification of types that allows a switch on the implementation,
	// casting from the base class back to the subclasses
	enum TypeId {
		TT_VOID, // no value
		TT_UINT8, // unsigned 8-bit integer (byte)
		TT_INT32, // 32-bit integer
		TT_INT64,
		TT_FLOAT64, // 64-bit floating-point, what C calls "double"
		TT_STRING, // a string: a special kind of byte array
		TT_ROW, // a row of a table
		TT_RH, // row handle: item through which all indexes in the table own a row
		TT_TABLE, // data store of rows (AKA "window")
		TT_INDEX, // a table contains one or more indexes for its rows
		TT_AGGREGATOR, // user piece of code that does aggregation on the indexes
		TT_ROWSET, // an ordered set of rows
		// add the new types here
		TT_LAST_MARKER // for range checks, goes after all the real types
	};

	// @param simple - flag: this is a simple type (must be consistent with typeid)
	// @param id - 
	Type(bool simple, TypeId id, int size = 0) :
		typeId_(id),
		simple_(simple),
		size_(size)
	{ }
		
	virtual ~Type()
	{ }

	// @return - true if this is a simple type
	bool isSimple() const
	{
		return simple_;
	}

	// @return - the id value of this type
	TypeId getTypeId() const
	{
		return typeId_;
	}

	// @return - the size of a basic element, or 0 if not applicable
	int getSize() const
	{
		return size_;
	}

	// A convenience function to find a simple type by name (including void).
	// @param name - name of the type
	// @return - the type reference (one of r_*) or NULL if not found
	static Onceref<const SimpleType> findSimpleType(const char *name);

	// Get the errors collected when parsing this type.
	// The checkOrThrow() from common/Initialize.h can be used to throw on errors.
	// @return - errors reference, may be NULL
	virtual Erref getErrors() const = 0;

	// The types can be equal in one of 3 ways, in order or decreasting exactness:
	// 1. Exactly the same Type object.
	//    Compary the pointers.
	// 2. The contents, including the subtypes and the names of field matches exactly.
	//    The equals() and operator==()
	// 3. The names of fields may be different.
	//    The method match()
	bool operator==(const Type &t) const
	{
		return equals(&t);
	}
	// normally types are referred by autoref, so pointers are more convenient than references
	virtual bool equals(const Type *t) const;
	// By default match() calls the virtual equals(), which works well for most of the
	// types, at least the simple ones.
	// IMPORTANT: when the subtype's match() method wants to check if the Type part
	// matches, it must call Type::equals(), not Type::match()! This is because Type::match()
	// short-circuits to the virtual equals() and does a different thing than you expect.
	virtual bool match(const Type *t) const;

	// Append the human-readable type definition to a string
	// @param res - the resulting string to append to
	// @param indent - initial indentation characters, 
	//        passing NOINDENT prints everything in a single line
	// @param subindent - indentation characters to add on each level
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const = 0;

	// Return the human-readable type definition to a string
	// @param indent - initial indentation characters, 
	//        passing NOINDENT prints everything in a single line
	// @param subindent - indentation characters to add on each level
	// @return - the result string
	string print(const string &indent = "", const string &subindent = "  ") const;

	// Compare two values of this type. Returns -1 if the left value is less
	// than the right one, 1 if greater, and 0 if equal. Returns -2 (CMP_NOT_SUPPORTED)
	// if the comparison is not supported for this type.
	//
	// @param left - the left value to compare
	// @param szleft - size in bytes of the left value; if the values of this type
	//        are represented as fixed-length, the method may ignore this length
	// @param right - the right value to compare
	// @param szright - size in bytes of the right value; if the values of this type
	//        are represented as fixed-length, the method may ignore this length
	enum { CMP_NOT_SUPPORTED = -2 };
	virtual int cmpValue(const void *left, intptr_t szleft, const void *right, intptr_t szright) const = 0;

public:
	// the global copies of the simple types that can be reused everywhere
	static Autoref<const SimpleType> r_void;
	static Autoref<const SimpleType> r_uint8;
	static Autoref<const SimpleType> r_int32;
	static Autoref<const SimpleType> r_int64;
	static Autoref<const SimpleType> r_float64;
	static Autoref<const SimpleType> r_string;

protected:
	enum TypeId typeId_; // allows to do switching and casting on it
	bool simple_; // flag: this is a simple type
	int size_; // size of the basic element of this type (0 if not a simple type)

private:
	Type();
};

}; // TRICEPS_NS

#endif // __Triceps_Type_h__
