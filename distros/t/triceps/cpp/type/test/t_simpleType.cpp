//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of simple type creation.

#include <utest/Utest.h>
#include <string.h>

#include <type/AllTypes.h>
#include <common/StringUtil.h>

UTESTCASE findSimpleType(Utest *utest)
{
	UT_ASSERT(Type::findSimpleType("void") == Type::r_void);
	UT_ASSERT(Type::findSimpleType("uint8") == Type::r_uint8);
	UT_ASSERT(Type::findSimpleType("int32") == Type::r_int32);
	UT_ASSERT(Type::findSimpleType("int64") == Type::r_int64);
	UT_ASSERT(Type::findSimpleType("string") == Type::r_string);
	UT_ASSERT(Type::findSimpleType("float64") == Type::r_float64);

	UT_ASSERT(Type::findSimpleType("int33").isNull());

	UT_ASSERT(!Type::findSimpleType("int32").isNull());
}

UTESTCASE print(Utest *utest)
{
	UT_IS(Type::r_void->print(), "void");
	UT_IS(Type::r_void->print(NOINDENT), "void");

	UT_IS(Type::r_uint8->print(), "uint8");
	UT_IS(Type::r_uint8->print(NOINDENT), "uint8");

	UT_IS(Type::r_int32->print(), "int32");
	UT_IS(Type::r_int32->print(NOINDENT), "int32");

	UT_IS(Type::r_int64->print(), "int64");
	UT_IS(Type::r_int64->print(NOINDENT), "int64");

	UT_IS(Type::r_float64->print(), "float64");
	UT_IS(Type::r_float64->print(NOINDENT), "float64");

	UT_IS(Type::r_string->print(), "string");
	UT_IS(Type::r_string->print(NOINDENT), "string");
}
