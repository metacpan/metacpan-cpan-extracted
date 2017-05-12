//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the streaming function.

#include <utest/Utest.h>
#include <string.h>

#include <sched/FnReturn.h>
#include <sched/FnBinding.h>
#include <sched/Unit.h>
#include <type/CompactRowType.h>

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

class FnReturnGuts: public FnReturn
{
public:
	static Xtray *getXtray(FnReturn *fret)
	{
		const FnReturnGuts *frg = (FnReturnGuts *)fret;
		return frg->xtray_;
	}

	static bool isXtrayEmpty(FnReturn *fret)
	{
		const FnReturnGuts *frg = (FnReturnGuts *)fret;
		return frg->FnReturn::isXtrayEmpty();
	}

	static void swapXtray(FnReturn *fret, Autoref<Xtray> &other)
	{
		FnReturnGuts *frg = (FnReturnGuts *)fret;
		frg->FnReturn::swapXtray(other);
	}
};

class MyFnCtx: public FnContext
{
public:
	MyFnCtx():
		pushes_(0),
		pops_(0),
		throws_(false)
	{ }

	virtual void onPush(const FnReturn *fret)
	{
		fret_ = fret;
		if (throws_)
			throw Exception::f("push exception");
		++pushes_;
	}

	virtual void onPop(const FnReturn *fret)
	{
		fret_ = fret;
		if (throws_)
			throw Exception::f("pop exception");
		++pops_;
	}

	int pushes_, pops_;
	bool throws_;
	const FnReturn *fret_;
};

UTESTCASE fn_return(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit1 = new Unit("u");
	Autoref<Unit> unit2 = new Unit("u2");

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	fld[0].name_ = "A";
	Autoref<RowType> rt3 = new CompactRowType(fld);
	UT_ASSERT(rt3->getErrors().isNull());

	Autoref<Label> lb1 = new DummyLabel(unit1, rt1, "lb1");
	Autoref<Label> lb1x = new DummyLabel(unit2, rt1, "lb1x");
	Autoref<Label> lb2 = new DummyLabel(unit1, rt2, "lb2");
	Autoref<Label> lb3 = new DummyLabel(unit1, rt3, "lb3");

	// make the returns

	// a good one
	Autoref<MyFnCtx> ctx1 = new MyFnCtx;
	Autoref<FnReturn> fret1 = initialize(FnReturn::make(unit1, "fret1")
		->setContext(ctx1)
		->addFromLabel("one", lb1)
		->addLabel("two", rt2)
	);
	UT_ASSERT(fret1->getErrors().isNull());
	UT_ASSERT(fret1->isInitialized());
	UT_IS(fret1->getName(), "fret1");
	// an equal one but not initialized
	Autoref<FnReturn> fret2 = FnReturn::make(unit1, "fret2")
		->addLabel("one", rt1)
		->addLabel("two", rt2);
	UT_ASSERT(fret2->getErrors().isNull());
	UT_ASSERT(!fret2->isInitialized());
	// a matching one
	Autoref<FnReturn> fret3 = initializeOrThrow(FnReturn::make(unit1, "fret3")
		->addLabel("one", rt1)
		->addLabel("xxx", rt2)
	);
	UT_ASSERT(fret3->getErrors().isNull());

	UT_IS(fret1->getUnitPtr(), unit1);
	UT_IS(fret1->getUnitName(), "u");
	
	// bad ones
	{
		Autoref<FnReturn> fretbad = initialize(FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
			->addLabel("", rt2)
		);
		UT_ASSERT(!fretbad->getErrors().isNull());
		UT_IS(fretbad->getErrors()->print(), "row name at position 2 must not be empty\n");
	}
	{
		Autoref<FnReturn> fretbad = initialize(FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
			->addLabel("one", rt2)
		);
		UT_ASSERT(!fretbad->getErrors().isNull());
		UT_IS(fretbad->getErrors()->print(), "duplicate row name 'one'\n");
	}
	{
		Autoref<FnReturn> fretbad = initialize(FnReturn::make(unit1, "fretbad")
			->addLabel("one", (RowType *)NULL)
			->addLabel("two", rt2)
		);
		UT_ASSERT(!fretbad->getErrors().isNull());
		UT_IS(fretbad->getErrors()->print(), "null row type with name 'one'\n");
	}
	{
		Autoref<FnReturn> fretbad = initialize(FnReturn::make(unit1, "fretbad")
			->addFromLabel("one", lb1x)
			->addLabel("two", rt2)
		);
		UT_ASSERT(!fretbad->getErrors().isNull());
		UT_IS(fretbad->getErrors()->print(), "Can not include the label 'lb1x' into the FnReturn as 'one': it has a different unit, 'u2' vs 'u'.\n");
	}
	{
		// with throwing
		msg.clear();
		try {
			Autoref<FnReturn> fretbad = initializeOrThrow(FnReturn::make(unit1, "fretbad")
				->addLabel("one", rt1)
				->addLabel("", rt2)
			);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "row name at position 2 must not be empty\n");
	}

	UT_ASSERT(fret1->equals(fret2));
	UT_ASSERT(fret2->equals(fret1));
	UT_ASSERT(!fret1->equals(fret3));
	UT_ASSERT(fret1->match(fret2));
	UT_ASSERT(fret1->match(fret3));

	// try to add to an initialized return
	{
		msg.clear();
		try {
			fret1->addLabel("three", rt3);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to add label 'three' to an initialized FnReturn 'fret1'.\n");
	}
	{
		msg.clear();
		try {
			fret1->addFromLabel("three", lb3);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to add label 'three' to an initialized FnReturn 'fret1'.\n");
	}
	// try go get the type of uninitialized return
	{
		msg.clear();
		try {
			fret2->getType();
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to get the type from an uninitialized FnReturn 'fret2'.\n");
	}

	// getters
	{
		const RowSetType::NameVec &names = fret1->getLabelNames();
		UT_IS(names.size(), 2);
		UT_IS(names[0], "one");
		UT_IS(names[1], "two");
	}
	{
		const RowSetType::RowTypeVec &types = fret1->getRowTypes();
		UT_IS(types.size(), 2);
		UT_IS(types[0].get(), rt1.get());
		UT_IS(types[1].get(), rt2.get());
	}

	UT_IS(fret1->size(), 2);

	RowSetType *rst1 = fret1->getType();
	UT_ASSERT(rst1 != NULL);
	UT_IS(rst1->size(), 2);

	UT_IS(fret1->findLabel("one"), 0);
	UT_IS(fret1->findLabel("two"), 1);
	UT_IS(fret1->findLabel("zzz"), -1);

	UT_IS(fret1->getRowType("one"), rt1.get());
	UT_IS(fret1->getRowType("two"), rt2.get());
	UT_IS(fret1->getRowType("zzz"), NULL);

	UT_IS(fret1->getRowType(0), rt1.get());
	UT_IS(fret1->getRowType(1), rt2.get());
	UT_IS(fret1->getRowType(-1), NULL);
	UT_IS(fret1->getRowType(2), NULL);

	UT_IS(*(fret1->getLabelName(0)), "one");
	UT_IS(*(fret1->getLabelName(1)), "two");
	UT_IS(fret1->getLabelName(-1), NULL);
	UT_IS(fret1->getLabelName(2), NULL);

	UT_IS(fret1->getLabel("one")->getType(), rt1.get());
	UT_IS(fret1->getLabel("two")->getType(), rt2.get());
	UT_IS(fret1->getLabel("zzz"), NULL);

	UT_IS(fret1->getLabel(0)->getType(), rt1.get());
	UT_IS(fret1->getLabel(1)->getType(), rt2.get());
	UT_IS(fret1->getLabel(-1), NULL);
	UT_IS(fret1->getLabel(2), NULL);

	const FnReturn::ReturnVec &labels = fret1->getLabels();
	UT_IS(labels.size(), 2);
	UT_IS(labels[0]->getName(), "fret1.one");
	UT_IS(labels[1]->getName(), "fret1.two");

	// Clearing any label clears the context.
	UT_ASSERT(fret1->context() != 0);
	fret1->getLabel(0)->clear();
	UT_ASSERT(fret1->context() == 0);
	// and also clears the unit
	UT_IS(fret1->getUnitPtr(), NULL);
	UT_IS(fret1->getUnitName(), "[fn return cleared]");
}

UTESTCASE fn_binding(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit1 = new Unit("u");
	Autoref<Unit> unit2 = new Unit("u2");

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	fld[0].name_ = "A";
	Autoref<RowType> rt3 = new CompactRowType(fld);
	UT_ASSERT(rt3->getErrors().isNull()); // matches rt2

	Autoref<Label> lb1 = new DummyLabel(unit1, rt1, "lb1");
	Autoref<Label> lb1x = new DummyLabel(unit2, rt1, "lb1x");
	Autoref<Label> lb1a = new DummyLabel(unit1, rt1, "lb1a");
	Autoref<Label> lb2 = new DummyLabel(unit1, rt2, "lb2");
	Autoref<Label> lb2a = new DummyLabel(unit1, rt2, "lb2a");
	Autoref<Label> lb3 = new DummyLabel(unit1, rt3, "lb3");
	Autoref<Label> lb3a = new DummyLabel(unit1, rt3, "lb3a");

	// make the returns

	// a good one
	Autoref<FnReturn> fret1 = initialize(FnReturn::make(unit1, "fret1")
		->addLabel("one", rt1)
		->addLabel("two", rt2)
	);
	UT_ASSERT(fret1->getErrors().isNull());
	UT_ASSERT(fret1->isInitialized());
	// an equal one but not initialized
	Autoref<FnReturn> fret2 = FnReturn::make(unit1, "fret2")
		->addLabel("one", rt1)
		->addLabel("two", rt2);
	UT_ASSERT(fret2->getErrors().isNull());
	UT_ASSERT(!fret2->isInitialized());
	// a matching one
	Autoref<FnReturn> fret3 = initializeOrThrow(FnReturn::make(unit1, "fret3")
		->addLabel("one", rt1)
		->addLabel("xxx", rt2)
	);
	UT_ASSERT(fret3->getErrors().isNull());
	// an unmatching one
	Autoref<FnReturn> fret4 = initialize(FnReturn::make(unit1, "fret4")
		->addLabel("one", rt2)
		->addLabel("two", rt1)
	);
	UT_ASSERT(fret4->getErrors().isNull());
	UT_ASSERT(fret4->isInitialized());

	// make the bindings
	Autoref<FnBinding> bind1 = FnBinding::make("bind1", fret1)
		->addLabel("one", lb1a, true)
		->addLabel("two", lb3a, true); // matching
	UT_ASSERT(bind1->getErrors().isNull());
	UT_IS(bind1->getName(), "bind1");
	// labels from another unit are OK
	Autoref<FnBinding> bind2 = checkOrThrow(FnBinding::make("bind2", fret1)
		->addLabel("one", lb1x, true)
		->addLabel("two", lb3a, true)
	); // matching
	UT_ASSERT(bind2->getErrors().isNull());

	UT_ASSERT(fret1->equals(bind1));
	UT_ASSERT(bind1->equals(fret1));
	UT_ASSERT(fret1->match(bind1));
	UT_ASSERT(bind1->match(fret1));
	UT_ASSERT(fret3->match(bind1));
	UT_ASSERT(bind1->match(fret3));
	UT_ASSERT(!fret4->match(bind1));
	UT_ASSERT(!bind1->match(fret4));

	// Bad bindings
	{
		Autoref<FnBinding> bindbad = FnBinding::make("bindbad", fret2)
			->addLabel("one", lb1a, true)
			->addLabel("two", lb3a, true); // matching
		UT_ASSERT(!bindbad->getErrors().isNull());
		UT_IS(bindbad->getErrors()->print(), "Can not create a binding to an uninitialized FnReturn.\n");
	}
	{
		Autoref<FnBinding> bindbad = FnBinding::make("bindbad", fret1)
			->addLabel("zzz", lb1a, true)
			->addLabel("two", lb3a, true)
			->addLabel("two", lb2a, true)
			->addLabel("one", lb2a, true);
		UT_ASSERT(!bindbad->getErrors().isNull());
		UT_IS(bindbad->getErrors()->print(), 
			"Unknown return label name 'zzz'.\n"
			"Attempted to add twice a label to name 'two' (first 'lb3a', second 'lb2a').\n"
			"Attempted to add a mismatching label 'lb2a' to name 'one'.\n"
			"  The expected row type:\n"
			"  row {\n"
			"      uint8[10] a,\n"
			"      int32[] b,\n"
			"      int64 c,\n"
			"      float64 d,\n"
			"      string e,\n"
			"    }\n"
			"  The row type of actual label 'lb2a':\n"
			"  row {\n"
			"      uint8[10] a,\n"
			"      int32[] b,\n"
			"      int32 c,\n"
			"      float64 d,\n"
			"      string e,\n"
			"    }\n"
		);
	}
	{
		// with throwing
		msg.clear();
		try {
			Autoref<FnBinding> bindbad = checkOrThrow(FnBinding::make("bindbad", fret2)
				->addLabel("one", lb1a, true)
				->addLabel("two", lb3a, true)
			);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Can not create a binding to an uninitialized FnReturn.\n");
	}

	// getters
	{
		const RowSetType::NameVec &names = bind1->getLabelNames();
		UT_IS(names.size(), 2);
		UT_IS(names[0], "one");
		UT_IS(names[1], "two");
	}
	{
		const RowSetType::RowTypeVec &types = bind1->getRowTypes();
		UT_IS(types.size(), 2);
		UT_IS(types[0].get(), rt1.get());
		UT_IS(types[1].get(), rt2.get());
	}

	UT_IS(bind1->size(), 2);

	UT_IS(bind1->getRowType("one"), rt1.get());
	UT_IS(bind1->getRowType("two"), rt2.get());
	UT_IS(bind1->getRowType("zzz"), NULL);

	UT_IS(bind1->getRowType(0), rt1.get());
	UT_IS(bind1->getRowType(1), rt2.get());
	UT_IS(bind1->getRowType(-1), NULL);
	UT_IS(bind1->getRowType(2), NULL);

	UT_IS(*(bind1->getLabelName(0)), "one");
	UT_IS(*(bind1->getLabelName(1)), "two");
	UT_IS(bind1->getLabelName(-1), NULL);
	UT_IS(bind1->getLabelName(2), NULL);

	UT_IS(bind1->findLabel("one"), 0);
	UT_IS(bind1->findLabel("two"), 1);
	UT_IS(bind1->findLabel("zzz"), -1);

	UT_IS(bind1->getLabel(0), lb1a);
	UT_IS(bind1->getLabel(1), lb3a);
	UT_IS(bind1->getLabel(-1), NULL);
	UT_IS(bind1->getLabel(2), NULL);

	UT_IS(bind1->getLabel("one"), lb1a);
	UT_IS(bind1->getLabel("two"), lb3a);
	UT_IS(bind1->getLabel("zzz"), NULL);

	const FnBinding::LabelVec &labels = bind1->getLabels();
	UT_IS(labels.size(), 2);
	UT_IS(labels[0], lb1a);
	UT_IS(labels[1], lb3a);

	const FnBinding::BoolVec &clears = bind1->getAutoclear();
	UT_IS(clears.size(), 2);
	UT_IS(clears[0], true);
	UT_IS(clears[1], true);

	UT_IS(bind1->isAutoclear("one"), true);
	UT_IS(bind1->isAutoclear("two"), true);
	UT_IS(bind1->isAutoclear("unknown"), false);
}

UTESTCASE call_bindings(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit1 = new Unit("u");
	Autoref<Unit> unit2 = new Unit("u2");

	Autoref<Unit::StringNameTracer> trace1 = new Unit::StringNameTracer(true);
	unit1->setTracer(trace1);

	Autoref<Unit::StringNameTracer> trace2 = new Unit::StringNameTracer(true);
	unit2->setTracer(trace2);

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	// matching
	fld[0].name_ = "x";
	Autoref<RowType> rt1a = new CompactRowType(fld);
	UT_ASSERT(rt1a->getErrors().isNull());

	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	fld[0].name_ = "A";
	Autoref<RowType> rt3 = new CompactRowType(fld);
	UT_ASSERT(rt3->getErrors().isNull()); // matches rt2

	Autoref<Label> lb1 = new DummyLabel(unit1, rt1, "lb1");
	Autoref<Label> lb1x = new DummyLabel(unit2, rt1, "lb1x");
	Autoref<Label> lb1a = new DummyLabel(unit1, rt1, "lb1a");
	Autoref<Label> lb1z = new DummyLabel(unit1, rt1, "lb1z");
	Autoref<Label> lb2 = new DummyLabel(unit1, rt2, "lb2");
	Autoref<Label> lb2a = new DummyLabel(unit1, rt2, "lb2a");
	Autoref<Label> lb2z = new DummyLabel(unit1, rt2, "lb2z");
	Autoref<Label> lb3 = new DummyLabel(unit1, rt3, "lb3");
	Autoref<Label> lb3a = new DummyLabel(unit1, rt3, "lb3a");

	// to test the chaining order, chain lb[12]z first, and then
	// it will get displaced
	UT_ASSERT(!lb1->chain(lb1z)->hasError());
	UT_ASSERT(!lb2->chain(lb2z)->hasError());

	// make the return
	Autoref<MyFnCtx> ctx1 = new MyFnCtx;
	Autoref<FnReturn> fret1 = initialize(FnReturn::make(unit1, "fret1")
		->setContext(ctx1)
		->addFromLabel("one", lb1)
		->addFromLabel("two", lb2, false)
	);
	UT_ASSERT(fret1->getErrors().isNull());
	UT_ASSERT(fret1->isInitialized());

	UT_IS(fret1->context(), ctx1);
	UT_IS(fret1->contextIn<MyFnCtx>(), ctx1);
	
	// a return of a matching type
	Autoref<FnReturn> fret1a = initialize(FnReturn::make(unit1, "fret1a")
		->addLabel("a", rt1)
		->addLabel("b", rt2)
	);
	UT_ASSERT(fret1a->getErrors().isNull());
	UT_ASSERT(fret1a->isInitialized());

	// an uninitialized return
	Autoref<FnReturn> fret1b = FnReturn::make(unit1, "fret1b")
		->addLabel("one", rt1)
		->addLabel("two", rt2);
	UT_ASSERT(!fret1b->isInitialized());

	// a return of a non-matching type
	Autoref<FnReturn> fret2 = initialize(FnReturn::make(unit1, "fret2")
		->addLabel("one", rt2)
		->addLabel("two", rt1)
	);
	UT_ASSERT(fret2->getErrors().isNull());
	UT_ASSERT(fret2->isInitialized());

	// make the bindings
	Autoref<FnBinding> bind1 = FnBinding::make("bind1", fret1)
		->addLabel("one", lb1a, true)
		->addLabel("two", lb3a, true); // matching
	UT_ASSERT(bind1->getErrors().isNull());
	// binding of a matching type
	Autoref<FnBinding> bind1a = FnBinding::make("bind1a", fret1a)
		->addLabel("a", lb1a, true)
		->addLabel("b", lb3a, true); // matching
	UT_ASSERT(bind1->getErrors().isNull());
	// labels from another unit are OK
	Autoref<FnBinding> bind2 = FnBinding::make("bind2", fret1)
		->addLabel("one", lb1x, true) // in unit2
		->addLabel("two", lb2a, true);
	UT_ASSERT(bind2->getErrors().isNull());
	// missing bindings for some labels are OK
	Autoref<FnBinding> bind3 = FnBinding::make("bind3", fret1);
	UT_ASSERT(bind3->getErrors().isNull());

	// make the rows to send
	FdataVec dv; // just leave the contents all NULL
	Autoref<Rowop> op1 = new Rowop(lb1, Rowop::OP_INSERT, rt1->makeRow(dv));
	Autoref<Rowop> op2 = new Rowop(lb2, Rowop::OP_INSERT, rt2->makeRow(dv));

	// call with no binding
	unit1->call(op1);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb1' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb1' op OP_INSERT {\n"
		"unit 'u' before label 'fret1.one' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'fret1.one' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' before label 'lb1z' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'lb1z' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb1' op OP_INSERT }\n"
		"unit 'u' after label 'lb1' op OP_INSERT }\n"
	);

	// call with binding, of matching type
	UT_IS(ctx1->pushes_, 0);
	fret1->push(bind1a);
	UT_IS(ctx1->pushes_, 1);
	UT_IS(ctx1->fret_, fret1.get());
	unit1->call(op2);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb2' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb2' op OP_INSERT {\n"
		"unit 'u' before label 'lb2z' (chain 'lb2') op OP_INSERT {\n"
		"unit 'u' after label 'lb2z' (chain 'lb2') op OP_INSERT }\n"
		"unit 'u' before label 'fret1.two' (chain 'lb2') op OP_INSERT {\n"

		"unit 'u' before label 'lb3a' (chain 'fret1.two') op OP_INSERT {\n"
		"unit 'u' after label 'lb3a' (chain 'fret1.two') op OP_INSERT }\n"

		"unit 'u' after label 'fret1.two' (chain 'lb2') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb2' op OP_INSERT }\n"
		"unit 'u' after label 'lb2' op OP_INSERT }\n"
	);
	// no pop yet!

	// nest a binding and call to another unit
	fret1->pushUnchecked(bind2);
	UT_IS(ctx1->pushes_, 2);
	unit1->call(op1);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb1' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb1' op OP_INSERT {\n"
		"unit 'u' before label 'fret1.one' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'fret1.one' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' before label 'lb1z' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'lb1z' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb1' op OP_INSERT }\n"
		"unit 'u' after label 'lb1' op OP_INSERT }\n"
	);
	msg = trace2->getBuffer()->print();
	trace2->clearBuffer();
	UT_IS(msg, 
		"unit 'u2' before label 'lb1x' op OP_INSERT {\n"
		"unit 'u2' after label 'lb1x' op OP_INSERT }\n"
	);

	// detection of popping the wrong binding
	{
		msg.clear();
		try {
			fret1->pop(bind1);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, 
			"Attempted to pop an unexpected binding 'bind1' from FnReturn 'fret1'.\n"
			"The bindings on the stack (top to bottom) are:\n"
			"  bind2\n"
			"  bind1a\n");
	}
	// pop the right binding
	UT_IS(ctx1->pops_, 0);
	fret1->pop(bind2);
	UT_IS(ctx1->pops_, 1);
	UT_IS(ctx1->fret_, fret1.get());
	
	// call with binding that has no labels
	fret1->push(bind3);
	unit1->call(op1);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb1' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb1' op OP_INSERT {\n"
		"unit 'u' before label 'fret1.one' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'fret1.one' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' before label 'lb1z' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'lb1z' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb1' op OP_INSERT }\n"
		"unit 'u' after label 'lb1' op OP_INSERT }\n"
	);

	// pop any binding
	fret1->pop(); // bind3
	UT_IS(ctx1->pops_, 2);

	// repeat a call with bind1a, just to be sure
	unit1->call(op2);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb2' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb2' op OP_INSERT {\n"
		"unit 'u' before label 'lb2z' (chain 'lb2') op OP_INSERT {\n"
		"unit 'u' after label 'lb2z' (chain 'lb2') op OP_INSERT }\n"
		"unit 'u' before label 'fret1.two' (chain 'lb2') op OP_INSERT {\n"

		"unit 'u' before label 'lb3a' (chain 'fret1.two') op OP_INSERT {\n"
		"unit 'u' after label 'lb3a' (chain 'fret1.two') op OP_INSERT }\n"

		"unit 'u' after label 'fret1.two' (chain 'lb2') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb2' op OP_INSERT }\n"
		"unit 'u' after label 'lb2' op OP_INSERT }\n"
	);

	// clear the label and have it called again
	{
		lb3a->clear();
		msg.clear();
		try {
			unit1->call(op2);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, 
			"FnReturn 'fret1' attempted to call a cleared label 'lb3a' in FnBinding 'bind1a'.\n"
			"Called through the label 'fret1.two'.\n"
			"Called chained from the label 'lb2'.\n"
		);
	}
	
	// pop any binding
	fret1->pop(); // bind1a

	// detection of pushing a wrong binding
	{
		msg.clear();
		try {
			fret2->push(bind1);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to push a mismatching binding 'bind1' on the FnReturn 'fret2'.\n");
	}
	// detection of pushing on an uninitialized return
	{
		msg.clear();
		try {
			fret1b->push(bind1);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to push a binding on an uninitialized FnReturn 'fret1b'.\n");
	}
	{
		msg.clear();
		try {
			fret1b->pushUnchecked(bind1);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to push a binding on an uninitialized FnReturn 'fret1b'.\n");
	}
	// detection of popping past the end of the stack
	{
		msg.clear();
		try {
			fret1->pop();
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to pop from an empty FnReturn 'fret1'.\n");
	}
	{
		msg.clear();
		try {
			fret1->pop(bind1);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to pop from an empty FnReturn 'fret1'.\n");
	}
	// an exception in onPush()
	{
		ctx1->throws_ = true;
		msg.clear();
		try {
			fret1->push(bind3);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "push exception\n");

		msg.clear();
		try {
			fret1->pushUnchecked(bind3);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "push exception\n");

		ctx1->throws_ = false;
	}
	// an exception in onPush()
	{
		fret1->push(bind3); // something to pop

		ctx1->throws_ = true;
		msg.clear();
		try {
			fret1->pop(bind3);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "pop exception\n");

		msg.clear();
		try {
			fret1->pop();
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "pop exception\n");

		ctx1->throws_ = false;
		fret1->pop(bind3); // restore the stack
	}
	

	// do the scoped binding
	UT_IS(fret1->bindingStackSize(), 0);
	{
		ScopeFnBind ab(fret1, bind1);
		UT_IS(fret1->bindingStackSize(), 1);
	}
	UT_IS(fret1->bindingStackSize(), 0);

	// exceptions in a scoped binding
	{
		msg.clear();
		try {
			ScopeFnBind ab(fret1b, bind1);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to push a binding on an uninitialized FnReturn 'fret1b'.\n");
	}
	{
		msg.clear();
		try {
			ScopeFnBind ab(fret1, bind1);
			fret1->pop(); // disrupt the stack
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to pop from an empty FnReturn 'fret1'.\n");
	}

	// the other scoped binding
	UT_IS(fret1->bindingStackSize(), 0);
	UT_IS(fret1a->bindingStackSize(), 0);
	{
		Autoref<AutoFnBind> ab = new AutoFnBind;

		// use fret1 twice, to test the pop order
		ab->add(fret1, bind1)->add(fret1, bind1a)->add(fret1a, bind1);
		UT_IS(fret1->bindingStackSize(), 2);
		UT_IS(fret1a->bindingStackSize(), 1);

		const FnReturn::BindingVec &stack = fret1->bindingStack();
		UT_IS(stack.size(), 2);
		UT_IS(stack[0], bind1);
		UT_IS(stack[1], bind1a);
	}
	UT_IS(fret1->bindingStackSize(), 0);
	UT_IS(fret1a->bindingStackSize(), 0);
	{
		Autoref<AutoFnBind> ab = new AutoFnBind;

		ab->add(fret1, bind1)->add(fret1a, bind1a);
		UT_IS(fret1->bindingStackSize(), 1);
		UT_IS(fret1a->bindingStackSize(), 1);

		ab->clear(); // clear before destruction
		UT_IS(fret1->bindingStackSize(), 0);
		UT_IS(fret1a->bindingStackSize(), 0);
	}

	// exceptions in the other scoped binding
	{
		msg.clear();
		try {
			Autoref<AutoFnBind> ab = new AutoFnBind;
			ab->add(fret1b, bind1);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to push a binding on an uninitialized FnReturn 'fret1b'.\n");
	}
	{
		msg.clear();
		try {
			Autoref<AutoFnBind> ab = new AutoFnBind;
			ab->add(fret1, bind1)->add(fret1a, bind1a);
			// disrupt the order
			fret1->push(bind2);
			fret1a->push(bind2);

			ab->clear(); // a plain destructor would lose memory when throwing
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "AutoFnBind::clear: caught an exception at position 1\n"
			"  Attempted to pop an unexpected binding 'bind1a' from FnReturn 'fret1a'.\n"
			"  The bindings on the stack (top to bottom) are:\n"
			"    bind2\n"
			"    bind1a\n"
			"AutoFnBind::clear: caught an exception at position 0\n"
			"  Attempted to pop an unexpected binding 'bind1' from FnReturn 'fret1'.\n"
			"  The bindings on the stack (top to bottom) are:\n"
			"    bind2\n"
			"    bind1\n"
		);
	}
}

UTESTCASE tray_bindings(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable
	Autoref<Tray> t;

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit1 = new Unit("u");
	Autoref<Unit> unit2 = new Unit("u2");

	Autoref<Unit::StringNameTracer> trace1 = new Unit::StringNameTracer(true);
	unit1->setTracer(trace1);

	Autoref<Unit::StringNameTracer> trace2 = new Unit::StringNameTracer(true);
	unit2->setTracer(trace2);

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	// matching
	fld[0].name_ = "x";
	Autoref<RowType> rt1a = new CompactRowType(fld);
	UT_ASSERT(rt1a->getErrors().isNull());

	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	fld[0].name_ = "A";
	Autoref<RowType> rt3 = new CompactRowType(fld);
	UT_ASSERT(rt3->getErrors().isNull()); // matches rt2

	Autoref<Label> lb1 = new DummyLabel(unit1, rt1, "lb1");
	Autoref<Label> lb1x = new DummyLabel(unit2, rt1, "lb1x");
	Autoref<Label> lb1a = new DummyLabel(unit1, rt1, "lb1a");
	Autoref<Label> lb2 = new DummyLabel(unit1, rt2, "lb2");
	Autoref<Label> lb2a = new DummyLabel(unit1, rt2, "lb2a");
	Autoref<Label> lb3 = new DummyLabel(unit1, rt3, "lb3");
	Autoref<Label> lb3a = new DummyLabel(unit1, rt3, "lb3a");

	// make the return
	Autoref<FnReturn> fret1 = initialize(FnReturn::make(unit1, "fret1")
		->addFromLabel("one", lb1)
		->addFromLabel("two", lb2)
	);
	UT_ASSERT(fret1->getErrors().isNull());
	UT_ASSERT(fret1->isInitialized());

	// make the bindings
	Autoref<FnBinding> bind1 = FnBinding::make("bind1", fret1)
		->addLabel("one", lb1a, true)
		->addLabel("two", lb3a, true) // matching
		->withTray(true);
	UT_ASSERT(bind1->getErrors().isNull());
	UT_ASSERT(bind1->getTray() != NULL);

	bind1->withTray(false);
	UT_ASSERT(bind1->getTray() == NULL);
	bind1->callTray(); // does nothing
	bind1->withTray(true);
	UT_ASSERT(bind1->getTray() != NULL);
	t = bind1->getTray();
	bind1->withTray(true);
	UT_IS(bind1->getTray(), t);

	// labels from another unit are OK
	Autoref<FnBinding> bind2 = FnBinding::make("bind2", fret1)
		->addLabel("one", lb1x, true) // in unit2
		->addLabel("two", lb2a, true);
	UT_ASSERT(bind2->getErrors().isNull());
	UT_ASSERT(bind2->getTray() == NULL);

	bind2->withTray(true);
	UT_ASSERT(bind2->getTray() != NULL);

	// missing bindings for some labels are OK
	Autoref<FnBinding> bind3 = FnBinding::make("bind3", fret1)
		->withTray(true);
	UT_ASSERT(bind3->getErrors().isNull());

	// make the rows to send
	FdataVec dv; // just leave the contents all NULL
	Autoref<Rowop> op1 = new Rowop(lb1, Rowop::OP_INSERT, rt1->makeRow(dv));
	Autoref<Rowop> op2 = new Rowop(lb2, Rowop::OP_INSERT, rt2->makeRow(dv));

	// call with binding
	fret1->push(bind1);
	unit1->call(op2);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	// the bindings are collected and not executed
	UT_IS(msg, 
		"unit 'u' before label 'lb2' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb2' op OP_INSERT {\n"

		"unit 'u' before label 'fret1.two' (chain 'lb2') op OP_INSERT {\n"
		"unit 'u' after label 'fret1.two' (chain 'lb2') op OP_INSERT }\n"

		"unit 'u' after-chained label 'lb2' op OP_INSERT }\n"
		"unit 'u' after label 'lb2' op OP_INSERT }\n"
	);

	t = bind1->getTray();
	UT_IS(t->size(), 1);
	UT_IS(bind1->swapTray(), t);
	UT_ASSERT(bind1->getTray() != NULL);
	UT_ASSERT(bind1->getTray() != t);

	unit1->callTray(t);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb3a' op OP_INSERT {\n"
		"unit 'u' after label 'lb3a' op OP_INSERT }\n"
	);

	fret1->pop(bind1);

	// nest a binding and call to another unit
	fret1->pushUnchecked(bind2);
	unit1->call(op1);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb1' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb1' op OP_INSERT {\n"
		"unit 'u' before label 'fret1.one' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'fret1.one' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb1' op OP_INSERT }\n"
		"unit 'u' after label 'lb1' op OP_INSERT }\n"
	);

	t = bind2->getTray();
	UT_IS(t->size(), 1);

	msg = trace2->getBuffer()->print();
	trace2->clearBuffer();
	UT_IS(msg, "");

	// now call the tray
	bind2->callTray();
	UT_ASSERT(bind2->getTray() != NULL);
	UT_ASSERT(bind2->getTray() != t);
	msg = trace2->getBuffer()->print();
	trace2->clearBuffer();
	UT_IS(msg, 
		"unit 'u2' before label 'lb1x' op OP_INSERT {\n"
		"unit 'u2' after label 'lb1x' op OP_INSERT }\n"
	);

	fret1->pop(bind2);
	
	// call with binding that has no labels
	fret1->push(bind3);
	unit1->call(op1);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	UT_IS(msg, 
		"unit 'u' before label 'lb1' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb1' op OP_INSERT {\n"
		"unit 'u' before label 'fret1.one' (chain 'lb1') op OP_INSERT {\n"
		"unit 'u' after label 'fret1.one' (chain 'lb1') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb1' op OP_INSERT }\n"
		"unit 'u' after label 'lb1' op OP_INSERT }\n"
	);

	t = bind3->getTray();
	UT_IS(t->size(), 0);

	bind3->callTray(); // calling an empty tray does nothing
	UT_ASSERT(bind3->getTray() != NULL);
	UT_IS(bind3->getTray(), t);

	UT_IS(bind3->swapTray(), t); // swapping does swap even an epmty tray
	UT_ASSERT(bind3->getTray() != t);

	fret1->pop(bind3);

	// call a cleared label
	fret1->push(bind1);
	unit1->call(op2);
	msg = trace1->getBuffer()->print();
	trace1->clearBuffer();
	// the bindings are collected and not executed
	UT_IS(msg, 
		"unit 'u' before label 'lb2' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lb2' op OP_INSERT {\n"
		"unit 'u' before label 'fret1.two' (chain 'lb2') op OP_INSERT {\n"
		"unit 'u' after label 'fret1.two' (chain 'lb2') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lb2' op OP_INSERT }\n"
		"unit 'u' after label 'lb2' op OP_INSERT }\n"
	);

	t = bind1->getTray();
	UT_IS(t->size(), 1);

	lb3a->clear();

	{
		msg.clear();
		try {
			bind1->callTray();
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "FnBinding::callTray: attempted to call a cleared label 'lb3a'.\n");
	}

	UT_ASSERT(bind1->getTray() != NULL);
	UT_ASSERT(bind1->getTray() != t);

	// keep the same bind1

	// a label that is already cleared will throw right away
	{
		fret1->push(bind1);
		msg.clear();
		try {
			unit1->call(op2);
		} catch (Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, 
			"FnReturn 'fret1' attempted to call a cleared label 'lb3a' in FnBinding 'bind1'.\n"
			"Called through the label 'fret1.two'.\n"
			"Called chained from the label 'lb2'.\n"
		);
	}

	t = bind1->getTray();
	UT_IS(t->size(), 0);

	fret1->pop(bind1);
	
}

UTESTCASE xtray(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable
	Autoref<Tray> t;

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit1 = new Unit("u");

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	Autoref<Label> lb1 = new DummyLabel(unit1, rt1, "lb1");
	Autoref<Label> lb2 = new DummyLabel(unit1, rt2, "lb2");

	// make the return
	Autoref<FnReturn> fret1 = initialize(FnReturn::make(unit1, "fret1")
		->addFromLabel("one", lb1)
		->addFromLabel("two", lb2)
	);
	UT_ASSERT(fret1->getErrors().isNull());
	UT_ASSERT(fret1->isInitialized());

	// no xtray by default
	UT_ASSERT(!fret1->isFaceted());
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fret1));
	UT_IS(FnReturnGuts::getXtray(fret1), NULL);
	
	// set the xtray
	Autoref<Xtray> xt1 = new Xtray(fret1->getType());
	Xtray *xtp1 = xt1;
	FnReturnGuts::swapXtray(fret1, xt1);
	UT_IS(xt1.get(), NULL); // old value
	UT_ASSERT(fret1->isFaceted());
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fret1));
	UT_IS(FnReturnGuts::getXtray(fret1), xtp1);

	// make the rows to send
	FdataVec dv; // just leave the contents all NULL
	Autoref<Rowop> op1 = new Rowop(lb1, Rowop::OP_INSERT, rt1->makeRow(dv));
	Autoref<Rowop> op2 = new Rowop(lb2, Rowop::OP_DELETE, rt2->makeRow(dv));

	// send the data
	unit1->call(op1);
	UT_ASSERT(!FnReturnGuts::isXtrayEmpty(fret1));
	UT_IS(FnReturnGuts::getXtray(fret1)->size(), 1);
	unit1->call(op2);
	UT_ASSERT(!FnReturnGuts::isXtrayEmpty(fret1));
	UT_IS(FnReturnGuts::getXtray(fret1)->size(), 2);

	// swap the tray again
	xt1 = new Xtray(fret1->getType());
	Xtray *xtp2 = xt1;
	FnReturnGuts::swapXtray(fret1, xt1);
	UT_IS(xt1.get(), xtp1); // old value
	UT_ASSERT(fret1->isFaceted());
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fret1));
	UT_IS(FnReturnGuts::getXtray(fret1), xtp2);

	UT_IS(xt1->at(0).idx_, 0);
	UT_IS(xt1->at(0).row_, op1->getRow());
	UT_IS(xt1->at(0).opcode_, Rowop::OP_INSERT);
	UT_IS(xt1->at(1).idx_, 1);
	UT_IS(xt1->at(1).row_, op2->getRow());
	UT_IS(xt1->at(1).opcode_, Rowop::OP_DELETE);

	// reset the xtray to NULL
	xt1 = NULL;
	FnReturnGuts::swapXtray(fret1, xt1);
	UT_IS(xt1.get(), xtp2); // old value
	UT_ASSERT(!fret1->isFaceted());
}

int cleared;
int destroyed;

class MyDummyLabel : public DummyLabel
{
public:
	MyDummyLabel(Unit *u, RowType *rt, const string &name) :
		DummyLabel(u, rt, name)
	{ }
	~MyDummyLabel()
	{
		// fprintf(stderr, "ZZZ destroying %s\n", name_.c_str());
		destroyed++;
	}
	virtual void clearSubclass()
	{
		// fprintf(stderr, "ZZZ clearing %s\n", name_.c_str());
		cleared++;
	}
};

// check that the labels get cleared (if requested) when the
// binding that owns them goes away
UTESTCASE fn_binding_memory(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit1 = new Unit("u");

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	// make the return
	Autoref<FnReturn> fret1 = initialize(FnReturn::make(unit1, "fret1")
		->addLabel("one", rt1)
		->addLabel("two", rt2)
	);
	UT_ASSERT(fret1->getErrors().isNull());
	UT_ASSERT(fret1->isInitialized());

	// with clearing
	cleared = 0;
	destroyed = 0;
	{
		Autoref<Label> lb1 = new MyDummyLabel(unit1, rt1, "lb1");
		Autoref<Label> lb2 = new MyDummyLabel(unit1, rt2, "lb2");

		// make the binding
		Autoref<FnBinding> bind1 = FnBinding::make("bind1", fret1)
			->addLabel("one", lb1, true)
			->addLabel("two", lb2, true); // matching
		UT_ASSERT(bind1->getErrors().isNull());
	}
	UT_IS(cleared, 2);
	UT_IS(destroyed, 2);

	// with no clearing
	cleared = 0;
	destroyed = 0;
	{
		Autoref<Label> lb1 = new MyDummyLabel(unit1, rt1, "lb1");
		Autoref<Label> lb2 = new MyDummyLabel(unit1, rt2, "lb2");

		// make the binding
		Autoref<FnBinding> bind1 = FnBinding::make("bind1", fret1)
			->addLabel("one", lb1, false)
			->addLabel("two", lb2, false); // matching
		UT_ASSERT(bind1->getErrors().isNull());
	}
	UT_IS(cleared, 0);
	UT_IS(destroyed, 0);
}

// Check that the labels get cleared when the return goes away.
UTESTCASE fn_return_memory(Utest *utest)
{
	string msg;
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit1 = new Unit("u");

	// make the components
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());
	
	fld[2].type_ = Type::r_int32;
	Autoref<RowType> rt2 = new CompactRowType(fld);
	UT_ASSERT(rt2->getErrors().isNull());

	Autoref<Label> lb1 = new MyDummyLabel(unit1, rt1, "lb1");

	// make the return
	Autoref<FnReturn> fret1 = initialize(FnReturn::make(unit1, "fret1")
		->addFromLabel("one", lb1)
		->addLabel("two", rt2)
	);
	UT_ASSERT(fret1->getErrors().isNull());
	UT_ASSERT(fret1->isInitialized());

	Autoref<Label> lbret1 = fret1->getLabel(0);
	UT_ASSERT(!lbret1->isCleared());

	fret1 = NULL; // trigger the destruction
	UT_ASSERT(lbret1->isCleared());

	// send a row through it, just in case
	FdataVec dv; // just leave the contents all NULL
	Autoref<Rowop> op1 = new Rowop(lb1, Rowop::OP_INSERT, rt1->makeRow(dv));
	unit1->call(op1);
}
