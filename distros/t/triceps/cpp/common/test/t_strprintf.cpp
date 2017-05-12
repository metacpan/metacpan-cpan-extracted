//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of strprintf().

#include <utest/Utest.h>

#include <common/Strprintf.h>

// Now, this is a bit funny, since strprintf() is used inside the etst infrastructure
// too. But if it all works, it should be all good.

std::string wrapper(const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	std::string s = vstrprintf(fmt, ap);
	va_end(ap);
	return s;
}

UTESTCASE mkshort(Utest *utest)
{
	std::string s = strprintf("%s", "aa");
	UT_ASSERT(s.size() == 2);
}

UTESTCASE mkvshort(Utest *utest)
{
	std::string s = wrapper("%s", "aa");
	UT_ASSERT(s.size() == 2);
}

UTESTCASE mklong(Utest *utest)
{
	std::string s = strprintf("%1000s", "bc");
	UT_ASSERT(s.size() == 1000);
}

UTESTCASE mkvlong(Utest *utest)
{
	std::string s = wrapper("%1000s", "bc");
	UT_ASSERT(s.size() == 1000);
}

