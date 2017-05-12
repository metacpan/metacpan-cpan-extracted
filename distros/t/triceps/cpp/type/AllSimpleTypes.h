//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Collection of definitions for all the simple types.

#ifndef __Triceps_AllSimpleTypes_h__
#define __Triceps_AllSimpleTypes_h__

#include <common/Common.h>
#include <type/SimpleType.h>

namespace TRICEPS_NS {

// Later, when there will be own language, these definitions may become
// more complex and be split into their separate files.

class VoidType : public SimpleType
{
public:
	VoidType() :
		SimpleType(TT_VOID, 0) // should Void even be a simple type?
	{ }
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;
};

class Uint8Type : public SimpleType
{
public:
	Uint8Type() :
		SimpleType(TT_UINT8, 1)
	{ }
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;
};

class Int32Type : public SimpleType
{
public:
	Int32Type() :
		SimpleType(TT_INT32, sizeof(int32_t))
	{ }
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;
};

class Int64Type : public SimpleType
{
public:
	Int64Type() :
		SimpleType(TT_INT64, sizeof(int64_t))
	{ }
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;
};

class Float64Type : public SimpleType
{
public:
	Float64Type() :
		SimpleType(TT_FLOAT64, sizeof(double))
	{ }
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;
};

class StringType : public SimpleType
{
public:
	// string is not really a simple type, it's an array of uint8, with an extra \0 added
	StringType() :
		SimpleType(TT_STRING, 1)
	{ }
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;
};

}; // TRICEPS_NS

#endif // __Triceps_AllSimpleTypes_h__

