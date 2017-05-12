//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of Autoref methods, applied on Starget.

#include <utest/Utest.h>

#include <mem/Starget.h>

class tg : public Starget
{
public:
	static int outstanding; // count of outstanding objects

	tg() :
		data_(0)
	{
		++outstanding;
	}

	~tg() 
	{
		--outstanding;
	}

	static Autoref<tg> factory()
	{
		return new tg;
	}

	static Onceref<tg> optfactory()
	{
		return new tg;
	}

	int data_;
};
int tg::outstanding = 0;

class tg2 : public tg
{
public:
	static Autoref<tg2> factory()
	{
		return new tg2;
	}
};

// Now, this is a bit funny, since strprintf() is used inside the etst infrastructure
// too. But if it all works, it should be all good.

UTESTCASE nullref(Utest *utest)
{
	Autoref<tg> p;

	UT_ASSERT(p.isNull());
	UT_ASSERT(p.get() == NULL);
	UT_ASSERT((tg *)p == NULL);
}

UTESTCASE construct(Utest *utest)
{
	UT_ASSERT(tg::outstanding == 0);
	{
		Autoref<tg2> p(new tg2);
		UT_ASSERT(tg::outstanding == 1);
		Autoref<tg> p2(p);
		UT_ASSERT(tg::outstanding == 1);
	}
	UT_ASSERT(tg::outstanding == 0);
}

UTESTCASE factory(Utest *utest)
{
	UT_ASSERT(tg::outstanding == 0);

	Autoref<tg> p;
	UT_ASSERT(p.isNull());
	p = tg::factory();
	UT_ASSERT(tg::outstanding == 1);
	p = NULL;
	UT_ASSERT(tg::outstanding == 0);
}

UTESTCASE assign(Utest *utest)
{
	UT_ASSERT(tg::outstanding == 0);
	Autoref<tg> p2;
	{
		Autoref<tg2> p(new tg2);
		UT_ASSERT(tg::outstanding == 1);
		p = p;
		UT_ASSERT(tg::outstanding == 1);
		UT_ASSERT(p2 != p);
		p2 = p;
		UT_ASSERT(p2 == p);
		UT_ASSERT(tg::outstanding == 1);
		p2 = p;
		UT_ASSERT(tg::outstanding == 1);

		UT_ASSERT(p2->data_ == 0);
		p->data_ = 1;
		UT_ASSERT(p2->data_ == 1);

		p = tg2::factory();
		UT_ASSERT(tg::outstanding == 2);
	}
	UT_ASSERT(tg::outstanding == 1);
	p2 = 0;
	UT_ASSERT(tg::outstanding == 0);
}

UTESTCASE swap(Utest *utest)
{
	UT_ASSERT(tg::outstanding == 0);
	{
		Autoref<tg> p(new tg);
		Autoref<tg> p2;
		UT_ASSERT(tg::outstanding == 1);

		tg *obj = p.get();

		p.swap(p2); // swap to NULL
		UT_ASSERT(tg::outstanding == 1);
		UT_IS(p.get(), 0);
		UT_IS(p2.get(), obj);

		p.swap(p2); // swap from NULL
		UT_ASSERT(tg::outstanding == 1);
		UT_IS(p.get(), obj);
		UT_IS(p2.get(), 0);

		p.swap(p); // swap from itself
		UT_ASSERT(tg::outstanding == 1);
		UT_IS(p.get(), obj);

		p2 = new tg;
		UT_ASSERT(tg::outstanding == 2);

		tg *obj2 = p2.get();

		p.swap(p2); // two objects
		UT_ASSERT(tg::outstanding == 2);
		UT_IS(p.get(), obj2);
		UT_IS(p2.get(), obj);
	}
	UT_ASSERT(tg::outstanding == 0);
}

UTESTCASE onceref(Utest *utest)
{
	UT_ASSERT(tg::outstanding == 0);

	Autoref<tg> p;
	UT_ASSERT(p.isNull());

	p = tg::optfactory();
	UT_ASSERT(tg::outstanding == 1);

	Autoref<tg> p2(tg::optfactory());
	UT_ASSERT(tg::outstanding == 2);

	{
		Onceref<tg> o1(tg::factory());
		UT_ASSERT(tg::outstanding == 3);

		Onceref<tg> o2(p);
		UT_ASSERT(tg::outstanding == 3);

		Onceref<tg> o3 = o1;
		UT_ASSERT(tg::outstanding == 3);

		Onceref<tg> o4;
		o4 = o1;
		UT_ASSERT(tg::outstanding == 3);
	}
	UT_ASSERT(tg::outstanding == 2);

	p = NULL;
	p2 = NULL;
	UT_ASSERT(tg::outstanding == 0);
} 

Onceref<tg> once_arg(Onceref<tg> arg)
{
	return arg;
}

Autoref<tg> auto_arg(Autoref<tg> arg)
{
	return arg;
}

template <class T>
Onceref<T> tmpl_once_arg(Onceref<T> arg)
{
	return arg;
}

template <class T>
Autoref<T> tmpl_auto_arg(Autoref<T> arg)
{
	return arg;
}

UTESTCASE onceref_casts(Utest *utest)
{
	Onceref<tg> o;
	o = tg::factory();

	Autoref<tg> a;
	a = o;
	o = a;

	o = once_arg(a);
	a = auto_arg(o);

#if 0 // in templates the auto-casting doesn't work
	o = tmpl_once_arg(a);
	a = tmpl_auto_arg(o);
#endif
}

