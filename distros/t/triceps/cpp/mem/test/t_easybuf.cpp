//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of a EasyBuffer allocation and destruction.

#include <utest/Utest.h>

#include <mem/EasyBuffer.h>
#include <string.h>

class stype
{
public:
	static int outstanding; // count of outstanding objects

	static Onceref<EasyBuffer> factory(const char *text)
	{
		int tlen = strlen(text)+1;
		EasyBuffer *s = new(tlen) EasyBuffer;
		memcpy(s->data_, text, tlen);
		return s;
	}
};
int stype::outstanding = 0;

UTESTCASE buf(Utest *utest)
{
	// fprintf(stderr, "sizeof(EasyBuffer) = %d sizeof(EasyBuffer) = %d\n", (int)sizeof(EasyBuffer), (int)sizeof(EasyBuffer));

	const char t1[] = "text1";
	const char t2[] = "this is a longer text, longer than DEFSIZE";
	EasyBuffer *p;
	{
		Autoref<EasyBuffer> s1 = stype::factory(t1);
		Autoref<EasyBuffer> s2 = stype::factory(t2);

		if (UT_ASSERT(!strcmp(t1, s1->data_))) {
			printf("s1=\"%s\"\n", (char *)s1.get());
			fflush(stdout);
		}

		if (UT_ASSERT(!strcmp(t2, s2->data_))) {
			printf("s2=\"%s\"\n", (char *)s2.get());
			fflush(stdout);
		}

		p = s2;
		p->incref(); // destroy it manualy later
	}

	UT_ASSERT(p->decref() == 0);
	delete p;
}

