//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of a RowSet type.

#include <utest/Utest.h>
#include <string.h>

#include <type/AllTypes.h>
#include <type/HoldRowTypes.h>

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

UTESTCASE rowset(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	RowType::FieldVec fld;
	mkfields(fld);

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	fld[0].name_ = "A";
	Autoref<RowType> rt3 = new CompactRowType(fld);
	UT_ASSERT(rt3->getErrors().isNull());

	// make the sets

	// a good one
	Autoref<RowSetType> set1 = initialize(RowSetType::make()
		->addRow("one", rt1)
		->addRow("two", rt2)
	);
	UT_ASSERT(set1->getErrors().isNull());
	UT_ASSERT(set1->isInitialized());
	// an equal one but not frozen
	Autoref<RowSetType> set2 = RowSetType::make()
		->addRow("one", rt1)
		->addRow("two", rt2);
	UT_ASSERT(set2->getErrors().isNull());
	UT_ASSERT(!set2->isInitialized());
	// a matching one
	Autoref<RowSetType> set3 = RowSetType::make()
		->addRow("one", rt1)
		->addRow("xxx", rt2);
	UT_ASSERT(set3->getErrors().isNull());
	// another matching one
	Autoref<RowSetType> set4 = RowSetType::make()
		->addRow("one", rt1)
		->addRow("two", rt3);
	UT_ASSERT(set4->getErrors().isNull());
	// a non-matching one
	Autoref<RowSetType> set5 = RowSetType::make()
		->addRow("one", rt1)
		->addRow("two", rt2)
		->addRow("three", rt3);
	UT_ASSERT(set5->getErrors().isNull());
	
	// bad ones
	{
		Autoref<RowSetType> badset = RowSetType::make()
			->addRow("one", rt1)
			->addRow("", rt2);
		UT_ASSERT(!badset->getErrors().isNull());
		UT_IS(badset->getErrors()->print(), "row name at position 2 must not be empty\n");
	}
	{
		Autoref<RowSetType> badset = RowSetType::make()
			->addRow("one", rt1)
			->addRow("one", rt2);
		UT_ASSERT(!badset->getErrors().isNull());
		UT_IS(badset->getErrors()->print(), "duplicate row name 'one'\n");
	}
	{
		Autoref<RowSetType> badset = RowSetType::make()
			->addRow("one", (RowType *)NULL)
			->addRow("two", rt2);
		UT_ASSERT(!badset->getErrors().isNull());
		UT_IS(badset->getErrors()->print(), "null row type with name 'one'\n");
	}

	UT_ASSERT(set1->equals(set2));
	UT_ASSERT(set2->equals(set1));
	UT_ASSERT(!set1->equals(set3));
	UT_ASSERT(!set1->equals(set4));
	UT_ASSERT(!set1->equals(set5));

	UT_ASSERT(set1->match(set2));
	UT_ASSERT(set1->match(set3));
	UT_ASSERT(set1->match(set4));
	UT_ASSERT(!set1->match(set5));

	// try to add to an initialized set
	{
		msg.clear();
		try {
			set1->addRow("three", rt3);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Triceps API violation: attempt to add row 'three' to an initialized row set type.\n");
	}

	// getters
	{
		const RowSetType::NameVec &names = set1->getRowNames();
		UT_IS(names.size(), 2);
		UT_IS(names[0], "one");
		UT_IS(names[1], "two");
	}
	{
		const RowSetType::RowTypeVec &types = set1->getRowTypes();
		UT_IS(types.size(), 2);
		UT_IS(types[0].get(), rt1.get());
		UT_IS(types[1].get(), rt2.get());
	}

	UT_IS(set1->size(), 2);
	UT_IS(set5->size(), 3);

	UT_IS(set1->findName("one"), 0);
	UT_IS(set1->findName("two"), 1);
	UT_IS(set1->findName("zzz"), -1);

	UT_IS(set1->getRowType("one"), rt1.get());
	UT_IS(set1->getRowType("two"), rt2.get());
	UT_IS(set1->getRowType("zzz"), NULL);

	UT_IS(set1->getRowType(0), rt1.get());
	UT_IS(set1->getRowType(1), rt2.get());
	UT_IS(set1->getRowType(-1), NULL);
	UT_IS(set1->getRowType(2), NULL);

	UT_IS(*(set1->getRowTypeName(0)), "one");
	UT_IS(*(set1->getRowTypeName(1)), "two");
	UT_IS(set1->getRowTypeName(-1), NULL);
	UT_IS(set1->getRowTypeName(2), NULL);

	// print
	UT_IS(set1->print("  ", "  "), 
		"rowset {\n"
		"    row {\n"
		"      uint8[10] a,\n"
		"      int32[] b,\n"
		"      int64 c,\n"
		"      float64 d,\n"
		"      string e,\n"
		"    } one,\n"
		"    row {\n"
		"      uint8[10] a,\n"
		"      int32[] b,\n"
		"      int32 c,\n"
		"      float64 d,\n"
		"      string e,\n"
		"    } two,\n"
		"  }");

	UT_IS(set1->print(NOINDENT), 
		"rowset {"
		" row {"
		" uint8[10] a,"
		" int32[] b,"
		" int64 c,"
		" float64 d,"
		" string e,"
		" } one,"
		" row {"
		" uint8[10] a,"
		" int32[] b,"
		" int32 c,"
		" float64 d,"
		" string e,"
		" } two,"
		" }");

	// deep copy
	Autoref<RowSetType> set6 = initialize(RowSetType::make()
		->addRow("one", rt1)
		->addRow("two", rt1)
	);
	UT_ASSERT(set6->getErrors().isNull());
	UT_ASSERT(set6->isInitialized());

	Autoref<RowSetType> set7 = set6->deepCopy(); // with default NULL holder
	UT_ASSERT(set7->equals(set7));
	UT_ASSERT(!set7->isInitialized());

	Autoref<HoldRowTypes> hrt = new HoldRowTypes;
	Autoref<RowSetType> set8 = set6->deepCopy(hrt);
	UT_ASSERT(set8->equals(set8));
	UT_ASSERT(!set8->isInitialized());
	UT_IS(set8->getRowType(0), set8->getRowType(1)); // both refer to the same type
}
