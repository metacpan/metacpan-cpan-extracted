//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Helper functions working with strings

#ifndef __Triceps_StringUtil_h__
#define __Triceps_StringUtil_h__

#include <common/Common.h>
#include <stdio.h>

namespace TRICEPS_NS {

// A special reference to a string, passed around to indicate that the
// printing must be done without line breaks.
// Doesn't work on all printing functions, just where supported.
extern const string &NOINDENT;

// Compute the print indent string to pass to the next level.
// This is a bit complicated by the NOINDENT that has to be passed
// through as is. Because of this, the return value is a reference,
// and the location to store the proper extended string is passed 
// as the target argument.
// @param indent - indent string of the previous level
// @param subindent - characters to append for the next indent level
// @param target - buffer to store the extended indent string
// @return - if indent was NOINDENT, then reference to NOINDENT, otherwise reference to target
const string &nextindent(const string &indent, const string &subindent, string &target);

// Append a newline in the value printing. If the indent is NOINDENT
// then just add a space, otherwise a newline and the proper indenting.
// @param res - result string to append to
// @param indent - the indent string for appending
void newlineTo(string &res, const string &indent);

// Print a byte buffer in hex
// @param dest - file to print to
// @param bytes - bytes to dump
// @param n - number of bytes
// @param indent - indent string
void hexdump(FILE *dest, const void *bytes, size_t n, const char *indent = "");

// same, append to a string
void hexdump(string &dest, const void *bytes, size_t n, const char *indent = "");

// For conversion between enums and strings. Usually passed as an array,
// with the last one having a val of -1 and name of NULL.
struct Valname
{
	int val_;
	const char *name_;
};

// Convert a string to integer value by reference table.
// @param reft - reference table
// @param name - value to convert
// @return - the value from table, or -1 if not found
int string2enum(const Valname *reft, const char *name);

// Convert an integer constant to string by reference table.
// @param reft - reference table
// @param val - value to convert
// @param def - default value, to use if no match found
// @return - the table value, or default
const char *enum2string(const Valname *reft, int val, const char *def = "???");

}; // TRICEPS_NS

#endif // __Triceps_StringUtil_h__
