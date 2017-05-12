//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of a CompactRow type.

#include <utest/Utest.h>
#include <string.h>

#include <type/AllTypes.h>
#include <type/HoldRowTypes.h>
#include <common/StringUtil.h>

// Make fields of all simple types
void mkfields(RowType::FieldVec &fields)
{
	fields.clear();
	fields.push_back(RowType::Field("a", Type::r_uint8, 10));
	fields.push_back(RowType::Field("b", Type::r_int32,0));
	fields.push_back(RowType::Field("c", Type::r_int64));
	fields.push_back(RowType::Field("d", Type::r_float64));
	fields.push_back(RowType::Field("e", Type::r_string));
}

uint8_t v_uint8[10] = "123456789";
int32_t v_int32 = 1234;
int64_t v_int64 = 0xdeadbeefc00c;
double v_float64 = 9.99e99;
char v_string[] = "hello world";

void mkfdata(FdataVec &fd)
{
	fd.resize(4);
	fd[0].setPtr(true, &v_uint8, sizeof(v_uint8));
	fd[1].setPtr(true, &v_int32, sizeof(v_int32));
	fd[2].setPtr(true, &v_int64, sizeof(v_int64));
	fd[3].setPtr(true, &v_float64, sizeof(v_float64));
	// test the constructor
	fd.push_back(Fdata(true, &v_string, sizeof(v_string)));
}

UTESTCASE rowtype(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	Autoref<RowType> rt2 = new CompactRowType(rt1);
	UT_ASSERT(rt2->getErrors().isNull());

	UT_ASSERT(rt1->equals(rt2));
	UT_ASSERT(rt2->equals(rt1));
	UT_ASSERT(rt1->match(rt2));
	UT_ASSERT(rt2->match(rt1));

	Autoref<RowType> rt1cp = rt1->copy();
	UT_ASSERT(rt1cp->getErrors().isNull());
	UT_ASSERT(rt1->equals(rt1cp));

	fld[0].name_ = "aa";
	Autoref<RowType> rt3 = rt1->newSameFormat(fld);
	UT_ASSERT(rt3->getErrors().isNull());

	UT_ASSERT(rt1->fields()[0].name_ == "a");
	UT_IS(rt3->fields()[0].name_, "aa");

	UT_ASSERT(!rt1->equals(rt3));
	UT_ASSERT(!rt3->equals(rt1));
	UT_ASSERT(rt1->match(rt3));
	UT_ASSERT(rt3->match(rt1));

	UT_IS(rt1->fieldCount(), fld.size());
	UT_IS(rt1->findIdx("b"), 1);
	UT_IS(rt1->findIdx("aa"), -1);
	UT_IS(rt1->find("b"), &rt1->fields()[1]);
	UT_IS(rt1->find("aa"), NULL);

	UT_IS(rt1->print("  ", "  "), 
		"row {\n"
		"    uint8[10] a,\n"
		"    int32[] b,\n"
		"    int64 c,\n"
		"    float64 d,\n"
		"    string e,\n"
		"  }");

	UT_IS(rt1->print(NOINDENT), 
		"row {"
		" uint8[10] a,"
		" int32[] b,"
		" int64 c,"
		" float64 d,"
		" string e,"
		" }");
}

// examples of field setting
UTESTCASE x_fields(Utest *utest)
{
	RowType::FieldVec fields1;
	fields1.push_back(RowType::Field("a", Type::r_int64)); // scalar by default
	fields1.push_back(RowType::Field("b", Type::r_int32, RowType::Field::AR_SCALAR));
	fields1.push_back(RowType::Field("c", Type::r_uint8, RowType::Field::AR_VARIABLE));

	RowType::FieldVec fields2(2);
	fields2[0].assign("a", Type::r_int64); // scalar by default
	fields2[1].assign("b", Type::r_int32, RowType::Field::AR_VARIABLE);

	fields1.push_back(RowType::Field("d", Type::findSimpleType("uint8"), RowType::Field::AR_VARIABLE));

	Autoref<RowType> rt1 = new CompactRowType(fields1);
	if (rt1->getErrors()->hasError())
		throw Exception(rt1->getErrors(), true);

	const RowType::FieldVec &f = rt1->fields();
	UT_ASSERT(&f != &fields1); // mostly to fool the "unused variable" warning

	RowType::FieldVec fields3 = rt1->fields();
	fields3.push_back(RowType::Field("z", Type::r_string));
	Autoref<RowType> rt3 = new CompactRowType(fields3);
	if (rt3->getErrors()->hasError())
		throw Exception(rt3->getErrors(), true);
}

// examples of field data setting
UTESTCASE x_data(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	FdataVec fd1;
	fd1.push_back(Fdata(true, &v_uint8, sizeof(v_uint8)-1)); // exclude \0
	fd1.push_back(Fdata(true, &v_int32, sizeof(v_int32)));
	fd1.push_back(Fdata(false, NULL, 0)); // a NULL field
	fd1.push_back(Fdata(true, &v_float64, sizeof(v_float64)));
	fd1.push_back(Fdata(true, &v_string, sizeof(v_string)));

	Rowref r1(rt1,  rt1->makeRow(fd1));
	UT_ASSERT(!rt1->isRowEmpty(r1));
	UT_ASSERT(!r1.isRowEmpty());

	Rowref r2(rt1,  fd1);

	FdataVec fd2(3);
	fd2[0].setPtr(true, &v_uint8, sizeof(v_uint8)-1); // exclude \0
	fd2[1].setNull();
	fd2[2].setFrom(r1.getType(), r1.get(), 2); // copy from r1 field 2

	Rowref r3(rt1,  fd2);

	RowType::FieldVec fields4;
	fields4.push_back(RowType::Field("a", Type::r_int64, RowType::Field::AR_VARIABLE));

	Autoref<RowType> rt4 = new CompactRowType(fields4);
	if (rt4->getErrors()->hasError())
		throw Exception(rt4->getErrors(), true);

	FdataVec fd4;
	Fdata fdtmp;
	fd4.push_back(Fdata(true, NULL, sizeof(v_float64)*10)); // allocate space
	fd4.push_back(Fdata(0, sizeof(v_int64)*2, &v_int64, sizeof(v_int64)));
	// fill a temporary element with setOverride and then insert it
	fdtmp.setOverride(0, sizeof(v_int64)*4, &v_int64, sizeof(v_int64));
	fd4.push_back(fdtmp);
	// manually copy an element from r1
	fdtmp.nf_ = 0;
	fdtmp.off_ = sizeof(v_int64)*5;
	r1.getType()->getField(r1.get(), 2, fdtmp.data_, fdtmp.len_);
	fd4.push_back(fdtmp);

	Rowref r4(rt4,  fd4);

	FdataVec fd5; // all empty
	Rowref r5(rt1,  fd5);
	UT_ASSERT(rt1->isRowEmpty(r5));
}

UTESTCASE parse_err(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	fld[0].name_ = "";
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(!rt2->getErrors().isNull());
	UT_IS(rt2->getErrors()->print(), "field 1 name must not be empty\n");

	mkfields(fld);
	fld[0].name_ = "c";
	rt2 = new CompactRowType(fld);
	UT_ASSERT(!rt2->getErrors().isNull());
	UT_IS(rt2->getErrors()->print(), "duplicate field name 'c' for fields 3 and 1\n");

	mkfields(fld);
	fld[1].type_ = rt1;
	rt2 = new CompactRowType(fld);
	UT_ASSERT(!rt2->getErrors().isNull());
	UT_IS(rt2->getErrors()->print(), "field 'b' type must be a simple type\n");

	mkfields(fld);
	fld[4].type_ = Type::r_void;
	rt2 = new CompactRowType(fld);
	UT_ASSERT(!rt2->getErrors().isNull());
	UT_IS(rt2->getErrors()->print(), "field 'e' type must not be void\n");
}

UTESTCASE mkrow(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));
	for (int i = 0; i < rt1->fieldCount(); i++) {
		if (UT_ASSERT(!rt1->isFieldNull(r1, i))) {
			printf("failed at field %d\n", i);
			fflush(stdout);
			return;
		}
	}

	const char *ptr;
	intptr_t len;
	for (int i = 0; i < rt1->fieldCount(); i++) {
		if ( UT_ASSERT(rt1->getField(r1, i, ptr, len))
		|| UT_IS(len, dv[i].len_)
		|| UT_ASSERT(!memcmp(dv[i].data_, ptr, len)) ) {
			printf("failed at field %d\n", i);
			fflush(stdout);
			char *p = (char *)r1.get();
			hexdump(stdout, p, sizeof(CompactRow)+5*sizeof(int32_t));
			fflush(stdout);
			hexdump(stdout, p, ((CompactRow*)r1.get())->getFieldPtr(rt1->fieldCount())-p);
			fflush(stdout);
			return;
		}
	}

	// try the get...() functions
	UT_IS(rt1->getUint8(r1, 0), '1');
	UT_IS(rt1->getUint8(r1, 0, 1), '2');
	UT_IS(rt1->getUint8(r1, 0, 100), 0); // null
	UT_IS(rt1->getInt32(r1, 1), 1234);
	UT_IS(rt1->getInt32(r1, 1, 0), 1234);
	UT_IS(rt1->getInt32(r1, 1, 1), 0); // null
	UT_IS(rt1->getInt64(r1, 2), 0xdeadbeefc00c);
	UT_IS(rt1->getInt64(r1, 2, 0), 0xdeadbeefc00c);
	UT_IS(rt1->getInt64(r1, 2, 1), 0); // null
	UT_IS(rt1->getFloat64(r1, 3), 9.99e99);
	UT_IS(rt1->getFloat64(r1, 3, 0), 9.99e99);
	UT_IS(rt1->getFloat64(r1, 3, 1), 0); // null
	UT_IS(string(rt1->getString(r1, 4)), "hello world");
	
	// try the get...() functions on a Rowref
	UT_IS(r1.getUint8(0), '1');
	UT_IS(r1.getUint8(0, 1), '2');
	UT_IS(r1.getUint8(0, 100), 0); // null
	UT_IS(r1.getInt32(1), 1234);
	UT_IS(r1.getInt32(1, 0), 1234);
	UT_IS(r1.getInt32(1, 1), 0); // null
	UT_IS(r1.getInt64(2), 0xdeadbeefc00c);
	UT_IS(r1.getInt64(2, 0), 0xdeadbeefc00c);
	UT_IS(r1.getInt64(2, 1), 0); // null
	UT_IS(r1.getFloat64(3), 9.99e99);
	UT_IS(r1.getFloat64(3, 0), 9.99e99);
	UT_IS(r1.getFloat64(3, 1), 0); // null
	UT_IS(string(r1.getString(4)), "hello world");

	// try to put a NULL in each of the fields
	for (int j = 0; j < rt1->fieldCount(); j++) {
		mkfdata(dv);
		dv[j].notNull_ = false;
		r1.assign(rt1, rt1->makeRow(dv));
		for (int i = 0; i < rt1->fieldCount(); i++) {
			if (i == j) {
				if ( UT_ASSERT(!rt1->getField(r1, i, ptr, len))
				|| UT_IS(len, 0)) {
					printf("failed at field %d, null in %d\n", i, j);
					fflush(stdout);
					return;
				}
			} else {
				if ( UT_ASSERT(rt1->getField(r1, i, ptr, len))
				|| UT_IS(len, dv[i].len_)
				|| UT_ASSERT(!memcmp(dv[i].data_, ptr, len)) ) {
					printf("failed at field %d, null in %d\n", i, j);
					fflush(stdout);
					char *p = (char *)r1.get();
					hexdump(stdout, p, sizeof(CompactRow)+5*sizeof(int32_t));
					fflush(stdout);
					hexdump(stdout, p, ((CompactRow*)r1.get())->getFieldPtr(rt1->fieldCount())-p);
					fflush(stdout);
					return;
				}
			}
		}
	}
	
	// try to put a NULL in all fields but one
	for (int j = 0; j < rt1->fieldCount(); j++) {
		mkfdata(dv);
		for (int i = 0; i < rt1->fieldCount(); i++) {
			if (i != j)
				dv[i].notNull_ = false;
		}
		r1.assign(rt1, rt1->makeRow(dv));
		for (int i = 0; i < rt1->fieldCount(); i++) {
			if (i != j) {
				if ( UT_ASSERT(!rt1->getField(r1, i, ptr, len))
				|| UT_IS(len, 0)) {
					printf("failed at field %d, null in %d\n", i, j);
					fflush(stdout);
					return;
				}
			} else {
				if ( UT_ASSERT(rt1->getField(r1, i, ptr, len))
				|| UT_IS(len, dv[i].len_)
				|| UT_ASSERT(!memcmp(dv[i].data_, ptr, len)) ) {
					printf("failed at field %d, null in %d\n", i, j);
					fflush(stdout);
					char *p = (char *)r1.get();
					hexdump(stdout, p, sizeof(CompactRow)+5*sizeof(int32_t));
					fflush(stdout);
					hexdump(stdout, p, ((CompactRow*)r1.get())->getFieldPtr(rt1->fieldCount())-p);
					fflush(stdout);
					return;
				}
			}
		}
	}

	// put NULL in all the fields
	mkfdata(dv);
	for (int i = 0; i < rt1->fieldCount(); i++) {
		dv[i].notNull_ = false;
	}
	r1.assign(rt1, rt1->makeRow(dv));
	for (int i = 0; i < rt1->fieldCount(); i++) {
		if ( UT_ASSERT(!rt1->getField(r1, i, ptr, len))
		|| UT_IS(len, 0)) {
			printf("failed at field %d\n", i);
			fflush(stdout);
			return;
		}
	}
	// try the get...() functions with null values
	UT_IS(rt1->getUint8(r1, 0), 0);
	UT_IS(rt1->getInt32(r1, 1), 0);
	UT_IS(rt1->getInt64(r1, 2), 0);
	UT_IS(rt1->getFloat64(r1, 3), 0);
	UT_IS(string(rt1->getString(r1, 4)), "");
}

UTESTCASE mkrowshort(Utest *utest)
{
	// test the auto-filling with NULLs
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	dv.resize(1);
	Rowref r1(rt1,  dv);
	if (UT_ASSERT(!rt1->isFieldNull(r1, 0))) return;

	for (int i = 1; i < rt1->fieldCount(); i++) {
		if ( UT_ASSERT(rt1->isFieldNull(r1, i))) {
			printf("failed at field %d\n", i);
			fflush(stdout);
			return;
		}
	}
}

UTESTCASE mkrowover(Utest *utest)
{
	// test the override fields
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);

	dv[0].data_ = 0; // test the zeroing

	Fdata fda;
	fda.setOverride(0, 0, "aa",  2);
	dv.push_back(fda);

	// for the rest, just use constructors
	dv.push_back(Fdata(0, 8, "bb", 2));
	dv.push_back(Fdata(1, -1, "bb", 2));
	dv.push_back(Fdata(2, 0, "bb", -1));
	dv.push_back(Fdata(3, 0, "01234567890123456789", 20));
	dv.push_back(Fdata(4, 0, NULL, 2));

	Rowref r1(rt1);
	r1 =  dv; // makeRow in assignment

	const char *ptr;
	intptr_t len;

	// field 0 will be filled in an interesting way
	if ( UT_ASSERT(rt1->getField(r1, 0, ptr, len))
	|| UT_IS(len, dv[0].len_)
	|| UT_ASSERT(!memcmp("aa\0\0\0\0\0\0bb", ptr, len)) ) {
		char *p = (char *)r1.get();
		hexdump(stdout, p, sizeof(CompactRow)+5*sizeof(int32_t));
		fflush(stdout);
		hexdump(stdout, p, ((CompactRow*)r1.get())->getFieldPtr(rt1->fieldCount())-p);
		fflush(stdout);
		return;
	}

	// the rest of fields should be unchanget
	for (int i = 1; i < rt1->fieldCount(); i++) {
		if ( UT_ASSERT(rt1->getField(r1, i, ptr, len))
		|| UT_IS(len, dv[i].len_)
		|| UT_ASSERT(!memcmp(dv[i].data_, ptr, len)) ) {
			printf("failed at field %d\n", i);
			fflush(stdout);
			char *p = (char *)r1.get();
			hexdump(stdout, p, sizeof(CompactRow)+5*sizeof(int32_t));
			fflush(stdout);
			hexdump(stdout, p, ((CompactRow*)r1.get())->getFieldPtr(rt1->fieldCount())-p);
			fflush(stdout);
			return;
		}
	}
}

UTESTCASE equal(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));
	Rowref r2(rt1,  rt1->makeRow(dv));

	dv[0].notNull_ = false;
	Rowref r3(rt1,  rt1->makeRow(dv));

	dv[1].data_ = NULL;
	Rowref r4(rt1,  rt1->makeRow(dv));

	UT_ASSERT(rt1->equalRows(r1, r1));
	UT_ASSERT(rt1->equalRows(r1, r2));
	UT_ASSERT(!rt1->equalRows(r1, r3));
	UT_ASSERT(!rt1->equalRows(r3, r4));
}


UTESTCASE hold_row_types(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	if (UT_ASSERT(rt2->getErrors().isNull())) return;

	Autoref<HoldRowTypes> hrt1 = new HoldRowTypes;

	Autoref<RowType> cp1 = hrt1->copy(rt1);
	UT_ASSERT(!cp1.isNull());
	UT_ASSERT(cp1 != rt1);

	Autoref<RowType> cp2 = hrt1->copy(rt2);
	UT_ASSERT(!cp2.isNull());
	UT_ASSERT(cp2 != rt2);
	UT_ASSERT(cp2 != cp1);

	Autoref<RowType> cp3 = hrt1->copy(rt1);
	UT_IS(cp1, cp3);

	Autoref<RowType> cp4 = hrt1->copy(NULL); // a NULL begets NULL
	UT_ASSERT(cp4.isNull());

	Autoref<HoldRowTypes> hrt2 = NULL; // a NULL holder causes dumb copies

	Autoref<RowType> cp5 = hrt2->copy(rt1);
	UT_ASSERT(!cp5.isNull());
	UT_ASSERT(cp5 != rt1);
	Autoref<RowType> cp6 = hrt2->copy(rt1);
	UT_ASSERT(!cp6.isNull());
	UT_ASSERT(cp6 != rt1);
	UT_ASSERT(cp6 != cp5);
}
