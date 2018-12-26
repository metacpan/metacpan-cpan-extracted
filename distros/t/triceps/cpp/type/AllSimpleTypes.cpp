//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Collection of definitions for all the simple types.

#include <string.h>
#include <type/AllSimpleTypes.h>
#include <common/Value.h>

namespace TRICEPS_NS {

void VoidType::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("void");
}
int VoidType::cmpValue(const void *left, intptr_t szleft, const void *right, intptr_t szright) const
{
	return 0; // all void values are the same
}

void Uint8Type::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("uint8");
}
int Uint8Type::cmpValue(const void *left, intptr_t szleft, const void *right, intptr_t szright) const
{
	uint8_t lv = *(uint8_t *)left;
	uint8_t rv = *(uint8_t *)right;
	if (lv < rv)
		return -1;
	else if (lv == rv)
		return 0;
	else
		return 1;
}

void Int32Type::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("int32");
}
int Int32Type::cmpValue(const void *left, intptr_t szleft, const void *right, intptr_t szright) const
{
	return cmpUnalignedVptr<int32_t>(left, szleft, right, szright);
}

void Int64Type::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("int64");
}
int Int64Type::cmpValue(const void *left, intptr_t szleft, const void *right, intptr_t szright) const
{
	return cmpUnalignedVptr<int64_t>(left, szleft, right, szright);
}

void Float64Type::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("float64");
}
int Float64Type::cmpValue(const void *left, intptr_t szleft, const void *right, intptr_t szright) const
{
	return cmpUnalignedVptr<double>(left, szleft, right, szright);
}

void StringType::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("string");
}
int StringType::cmpValue(const void *left, intptr_t szleft, const void *right, intptr_t szright) const
{
	// size 0 should never happen (it's a NULL value) but better be safe than sorry
	if (szleft == 0) {
		return (szright != 0);
	}
	if (szright == 0)
		return false;

	// just in case, enforce the 0-termination
	if (((char *)left)[szleft-1] != 0) {
		((char *)left)[szleft-1] = 0;
	}
	if (((char *)right)[szright-1] != 0) {
		((char *)right)[szright-1] = 0;
	}
	return strcoll((const char *)left, (const char *)right);
}

}; // TRICEPS_NS
