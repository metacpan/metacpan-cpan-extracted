//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of a MtBuffer allocation and destruction.

#include <utest/Utest.h>

#include <mem/MtBuffer.h>
#include <string.h>

// type of a ref-counted C string
class srow : public MtBuffer
{
public:
	const char *get()
	{
		return s_;
	}

protected:
	friend class stype;
	enum { DEFSIZE = 8 };
	char s_[DEFSIZE];
};

class stype : public MtBufferOwner
{
public:
	static int outstanding; // count of outstanding objects

	static Onceref<srow> factory(const char *text)
	{
		int tlen = strlen(text)+1;
		srow *s = new(tlen-srow::DEFSIZE) srow;
		memcpy(s->s_, text, tlen);
		return s;
	}

	static void dispose(srow *s)
	{
		callDeleteMtBuffer(s);
	}
};
int stype::outstanding = 0;

UTESTCASE buf(Utest *utest)
{
	// fprintf(stderr, "sizeof(srow) = %d sizeof(MtBuffer) = %d\n", (int)sizeof(srow), (int)sizeof(MtBuffer));

	const char t1[] = "text1";
	const char t2[] = "this is a longer text, longer than DEFSIZE";
	srow *p;
	{
		Autoref<srow> s1 = stype::factory(t1);
		Autoref<srow> s2 = stype::factory(t2);

		if (UT_ASSERT(!strcmp(t1, s1->get()))) {
			printf("s1=\"%s\"\n", (char *)s1.get());
			fflush(stdout);
		}

		if (UT_ASSERT(!strcmp(t2, s2->get()))) {
			printf("s2=\"%s\"\n", (char *)s2.get());
			fflush(stdout);
		}

		p = s2;
		p->incref(); // destroy it manualy later
	}

	UT_ASSERT(p->decref() == 0);
	stype::dispose(p);
}

// type of a virtual ref-counted C string
class vsrow : public VirtualMtBuffer
{
public:
	const char *get()
	{
		return s_;
	}

protected:
	friend class vstype;
	enum { DEFSIZE = 8 };
	char s_[DEFSIZE];
};

class vstype : public MtBufferOwner
{
public:
	static int outstanding; // count of outstanding objects

	static Onceref<vsrow> factory(const char *text)
	{
		int tlen = strlen(text)+1;
		vsrow *s = new(tlen-vsrow::DEFSIZE) vsrow;
		memcpy(s->s_, text, tlen);
		return s;
	}
};
int vstype::outstanding = 0;

UTESTCASE vbuf(Utest *utest)
{
	// fprintf(stderr, "sizeof(vsrow) = %d sizeof(MtBuffer) = %d\n", (int)sizeof(vsrow), (int)sizeof(MtBuffer));

	const char t1[] = "text1";
	const char t2[] = "this is a longer text, longer than DEFSIZE";

	Autoref<vsrow> s1 = vstype::factory(t1);
	Autoref<vsrow> s2 = vstype::factory(t2);

	if (UT_ASSERT(!strcmp(t1, s1->get()))) {
		printf("s1=\"%s\"\n", (char *)s1.get());
		fflush(stdout);
	}

	if (UT_ASSERT(!strcmp(t2, s2->get()))) {
		printf("s2=\"%s\"\n", (char *)s2.get());
		fflush(stdout);
	}

	Autoref<vsrow> s3 = s2;
	s2 = NULL;

	if (UT_ASSERT(!strcmp(t2, s3->get()))) {
		printf("s3=\"%s\"\n", (char *)s3.get());
		fflush(stdout);
	}

}

