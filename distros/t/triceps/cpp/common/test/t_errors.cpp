//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the structured errors.

#include <utest/Utest.h>

#include <common/Errors.h>

UTESTCASE simple(Utest *utest)
{
	Erref e1 = new Errors;
	UT_ASSERT(e1->isEmpty());
	UT_ASSERT(!e1->hasError());

	e1->appendMsg(false, "msg1");
	UT_ASSERT(!e1->isEmpty());
	UT_ASSERT(!e1->hasError());

	e1->appendMsg(true, "msg2");
	UT_ASSERT(!e1->isEmpty());
	UT_ASSERT(e1->hasError());

	Erref e2 = new Errors(true);
	UT_ASSERT(e2->isEmpty());
	UT_ASSERT(e2->hasError());

	UT_IS(e1->print(), "msg1\nmsg2\n");
	UT_IS(e2->print(), "");

	e1->clear();
	UT_ASSERT(!e1->hasError());
	UT_IS(e1->print(), "");

	Erref e3 = new Errors("msg3\nmsg4");
	UT_ASSERT(!e3->isEmpty());
	UT_ASSERT(e3->hasError());
	UT_IS(e3->print(), "msg3\nmsg4\n");

	Erref e4 = new Errors(string("msg5\nmsg6"));
	UT_ASSERT(!e4->isEmpty());
	UT_ASSERT(e4->hasError());
	UT_IS(e4->print(), "msg5\nmsg6\n");

	Erref e5 = new Errors(string("msg7\nmsg8"), e4);
	UT_ASSERT(!e5->isEmpty());
	UT_ASSERT(e5->hasError());
	UT_IS(e5->print(), "msg7\nmsg8\n  msg5\n  msg6\n");
}

UTESTCASE nested(Utest *utest)
{
	Erref e1 = new Errors;

	e1->appendMsg(false, "msg1");
	UT_ASSERT(!e1->hasError());
	UT_ASSERT(!e1->isEmpty());

	Erref e2 = new Errors;
	UT_ASSERT(e2->isEmpty());
	UT_ASSERT(!e2->hasError());

	UT_ASSERT(e2->append("from e1", e1) == true);
	UT_ASSERT(!e2->isEmpty());
	UT_ASSERT(!e2->hasError());

	UT_IS(e2->print(), "from e1\n  msg1\n");

	UT_ASSERT(e2->append("add empty", new Errors) == false);
	// empty child should get thrown away
	UT_ASSERT(!e2->hasError());
	UT_IS(e2->elist_.size(), 1);

	UT_ASSERT(e2->append("", new Errors(true)) == true);
	// empty child should get thrown away, except for error indication
	UT_ASSERT(e2->hasError());
	UT_IS(e2->elist_.size(), 2);
	UT_ASSERT(e2->elist_[1].child_.isNull());

	e2->replaceMsg("child error flag");
	UT_IS(e2->elist_[1].msg_, "child error flag");

	Erref e3 = new Errors;
	e3->appendMsg(true, "msg3");
	UT_ASSERT(e2->append("from e3", e3) == true);

	UT_IS(e2->print(), "from e1\n  msg1\nchild error flag\nfrom e3\n  msg3\n");

	Erref e4 = new Errors;
	UT_ASSERT(e4->append("from e2", e2) == true);
	UT_ASSERT(e4->hasError());

	e4->appendMsg(true, "msg4");
	UT_IS(e4->print(), "from e2\n  from e1\n    msg1\n  child error flag\n  from e3\n    msg3\nmsg4\n");

	Erref e5 = new Errors;
	e5->appendMultiline(true, "");
	UT_IS(e5->print(), "");
	e5->appendMultiline(true, "\n");
	UT_IS(e5->print(), "");
	e5->appendMultiline(true, "line1\nline2");
	UT_IS(e5->print(), "line1\nline2\n");
	e5->appendMultiline(true, "line3\nline4\n");
	UT_IS(e5->print(), "line1\nline2\nline3\nline4\n");
	e5->appendMultiline(true, "\nline5\n");
	UT_IS(e5->print(), "line1\nline2\nline3\nline4\nline5\n");
}

UTESTCASE absorb(Utest *utest)
{
	Erref e1 = new Errors;

	e1->appendMsg(false, "msg1");
	e1->appendMsg(false, "msg2");
	UT_ASSERT(!e1->hasError());
	UT_ASSERT(!e1->isEmpty());

	Erref e2 = new Errors;
	UT_ASSERT(e2->isEmpty());
	UT_ASSERT(!e2->hasError());

	UT_ASSERT(e2->absorb(e1) == true);
	UT_ASSERT(!e2->isEmpty());
	UT_ASSERT(!e2->hasError());

	UT_IS(e2->print(), "msg1\nmsg2\n");

	UT_ASSERT(e2->absorb(new Errors) == false);
	// empty child should get thrown away
	UT_ASSERT(!e2->hasError());
	UT_IS(e2->elist_.size(), 2);

	UT_ASSERT(e2->absorb(new Errors(true)) == true);
	// empty child should get thrown away, except for error indication
	UT_ASSERT(e2->hasError());
	UT_IS(e2->elist_.size(), 2);
}

UTESTCASE errefAppend(Utest *utest)
{
	Erref e1;
	UT_ASSERT(e1.isNull());

	UT_IS(e1.fAppend(new Errors("zzz"), "msg%d", 1), true);
	UT_ASSERT(!e1.isNull());
	UT_IS(e1->print(), "msg1\n  zzz\n");

	UT_IS(e1.fAppend(new Errors("xxx"), "msg%d", 2), true);
	UT_IS(e1->print(), "msg1\n  zzz\nmsg2\n  xxx\n");

	UT_IS(e1.fAppend(new Errors(false), "msg%d", 3), false);
	UT_IS(e1->print(), "msg1\n  zzz\nmsg2\n  xxx\n");

	Erref e2 = new Errors();
	e2->appendMsg(false, "yyy");
	UT_IS(e1.fAppend(e2, "msg%d", 4), false);
	UT_IS(e1->print(), "msg1\n  zzz\nmsg2\n  xxx\n");

	UT_IS(e1.fAppend(NULL, "msg%d", 5), false);
	UT_IS(e1->print(), "msg1\n  zzz\nmsg2\n  xxx\n");

	Erref e3;
	UT_ASSERT(e3.isNull());
	UT_IS(e3.fAppend(e2, "msg%d", 4), false);
	UT_ASSERT(e3.isNull());
	UT_IS(e3.fAppend(NULL, "msg%d", 5), false);
	UT_ASSERT(e3.isNull());

	Erref e4;
	UT_ASSERT(e4.isNull());
	e4.f("msg %d\nline %d", 1, 2);
	e4.f("msg %d\nline %d", 3, 4);
	UT_IS(e4->print(), "msg 1\nline 2\nmsg 3\nline 4\n");
}
