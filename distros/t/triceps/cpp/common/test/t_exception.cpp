//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the exceptions.

#include <utest/Utest.h>

#include <signal.h>
#include <setjmp.h>
#include <common/Exception.h>


UTESTCASE throw_catch(Utest *utest)
{
	UT_IS(Exception::abort_, true); // the default
	UT_IS(Exception::enableBacktrace_, true); // the default
	Exception::abort_ = false;
	UT_IS(Exception::abort_, false);

	// test the what() inheritance
	std::exception *exc = new Exception("msg", false);
	UT_IS(string(exc->what()), "msg\n");
	delete exc;

	try {
		throw Exception("message", false);
	} catch (Exception e) {
		string what = e.what();
		UT_IS(what, "message\n");
	}

	try {
		throw Exception::f("message %d", 99);
	} catch (Exception e) {
		string what = e.what();
		UT_IS(what, "message 99\n");
	}

	try {
		Erref err = new Errors;
		err->appendMsg(true, "message");
		throw Exception(err, false);
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what, "message\n");
	}

	try {
		Erref err = new Errors;
		err->appendMsg(true, "message");
		throw Exception(err, "wrapper");
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what, "wrapper\n  message\n");
	}

	try {
		Erref err = new Errors;
		err->appendMsg(true, "message");
		throw Exception(err, string("wrapper"));
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what, "wrapper\n  message\n");
	}

	try {
		Erref err = new Errors;
		err->appendMsg(true, "message");
		throw Exception::f(err, "wrapper %d", 99);
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what, "wrapper 99\n  message\n");
	}

	try {
		try {
			throw Exception("message", false);
		} catch (Exception e) {
			throw Exception(e, "wrapper");
		}
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what, "wrapper\n  message\n");
	}

	try {
		try {
			throw Exception("message", false);
		} catch (Exception e) {
			throw Exception::f(e, "wrapper %d", 99);
		}
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what, "wrapper 99\n  message\n");
	}

	// same with a stack trace
	try {
		throw Exception("message", true);
	} catch (Exception e) {
		string what = e.what();
		UT_IS(what.find("message\nStack trace:\n  "), 0);
	}

	try {
		throw Exception::fTrace("message %d", 99);
	} catch (Exception e) {
		string what = e.what();
		UT_IS(what.find("message 99\nStack trace:\n  "), 0);
	}

	try {
		Erref err = new Errors;
		err->appendMsg(true, "message");
		throw Exception(err, true);
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what.find("message\nStack trace:\n  "), 0);
	}

	try {
		Erref err = new Errors;
		err->appendMsg(true, "message");
		throw Exception::fTrace(err, "wrapper %d", 99);
	} catch (Exception e) {
		Erref err = e.getErrors();
		string what;
		err->printTo(what);
		UT_IS(what.find("wrapper 99\n  message\nStack trace:\n  "), 0);
	}

	// see that the stack trace ges disabled
	Exception::enableBacktrace_ = false;
	try {
		throw Exception("message", true);
	} catch (Exception e) {
		string what = e.what();
		UT_IS(what, "message\n");
	}


	Exception::abort_ = true; // restore back
	Exception::enableBacktrace_ = true; // restore back
}

bool aborted;

UTESTCASE abort(Utest *utest)
{
	Exception::__testAbort_ = &aborted; // prevent the abort

	UT_IS(Exception::abort_, true); // the default

	fprintf(stderr, "Expect an abort message:\n");
	aborted = false;
	try {
		throw Exception("test of an abort message", false);
	} catch (Exception e) {
	}
	UT_ASSERT(aborted);

	fprintf(stderr, "Expect an abort message:\n");
	aborted = false;
	try {
		Erref err = new Errors;
		err->appendMsg(true, "test of an abort message");
		throw Exception(err, false);
	} catch (Exception e) {
	}
	UT_ASSERT(aborted);
}
