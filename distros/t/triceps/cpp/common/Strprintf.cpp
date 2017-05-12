//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Assorted functions working on strings.

#include <common/Strprintf.h>
#include <stdarg.h>
#include <stdio.h>

namespace TRICEPS_NS {

// preserve a bit more efficiency of returning the result
// by implementing strprintf directly, not through vstrprintf()
string strprintf(const char *fmt, ...)
{
	char buf[500];
	va_list ap;

	va_start(ap, fmt);
	int n = vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	if (n < sizeof(buf))
		return string(buf);

	// a more complicated case, with a large string
	char *s = new char[n+1];
	va_start(ap, fmt);
	vsnprintf(s, n+1, fmt, ap);
	va_end(ap);
	string ret(s);
	delete[] s;
	return ret;
}

string vstrprintf(const char *fmt, va_list ap)
{
	char buf[500];
	va_list copy_ap;
	va_copy(copy_ap, ap); // needed for the 2nd attempt

	int n = vsnprintf(buf, sizeof(buf), fmt, ap);
	if (n < sizeof(buf)) {
		va_end(copy_ap);
		return string(buf);
	}

	// a more complicated case, with a large string
	char *s = new char[n+1];
	vsnprintf(s, n+1, fmt, copy_ap);
	va_end(copy_ap);
	string ret(s);
	delete[] s;
	return ret;
}

}; // TRICEPS_NS
