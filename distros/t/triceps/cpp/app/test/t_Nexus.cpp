//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the nexus-related calls in App and Trieads.

#include <assert.h>
#include <utest/Utest.h>
#include <type/AllTypes.h>
#include "AppTest.h"

// Facet construction
UTESTCASE make_facet(Utest *utest)
{
	make_catchable();

	// a simple test of static method
	UT_IS(Facet::buildFullName("a", "b"), "a/b");

	// prepare fragments
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	Autoref<App> a1 = App::make("a1");
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");

	Autoref<Unit> unit1 = ow1->unit();

	// With an uninitialized FnReturn
	Autoref<FnReturn> fret1 = FnReturn::make(unit1, "fret1")
		->addLabel("one", rt1)
		->addLabel("two", rt1)
		->addLabel("three", rt1)
	;
	UT_ASSERT(!fret1->isInitialized());
	Autoref<Facet> fa1 = Facet::make(fret1, false); // reader
	// this initializes the fret
	UT_ASSERT(fret1->isInitialized());
	UT_ASSERT(!fa1->isWriter());
	// and adds the _BEGIN_/_END_ labels
	UT_ASSERT(fret1->findLabel("_BEGIN_") >= 0);
	UT_ASSERT(fret1->findLabel("_END_") >= 0);

	UT_IS(fa1->getFnReturn(), fret1);
	UT_IS(fa1->getShortName(), "fret1");
	UT_IS(fa1->getFullName(), ""); // empty until exported
	UT_ASSERT(!fa1->isImported());

	// the reverse mode is more interesting for reimport
	fa1->setReverse();
	UT_ASSERT(fa1->isReverse());
	UT_IS(fa1->queueLimit(), Facet::DEFAULT_QUEUE_LIMIT);
	
	// reuse the same FnReturn, which is now initialized
	Autoref<Facet> fa2 = Facet::make(fret1, true); // writer
	UT_ASSERT(fa2->isWriter());

#if 0  // {
	UT_ASSERT(!fa2->isUnicast());
	fa2->setUnicast();
	UT_ASSERT(fa2->isUnicast());
#endif // }

	UT_ASSERT(!fa2->isReverse());
	fa2->setReverse();
	UT_ASSERT(fa2->isReverse());

#if 0  // {
	UT_ASSERT(fa2->isUnicast());
	fa2->setUnicast(false);
	UT_ASSERT(!fa2->isUnicast());
#endif // }

	UT_ASSERT(fa2->isReverse());
	fa2->setReverse(false);
	UT_ASSERT(!fa2->isReverse());

	UT_IS(fa2->queueLimit(), Facet::DEFAULT_QUEUE_LIMIT);
	fa2->setQueueLimit(100);
	UT_IS(fa2->queueLimit(), 100);

	// test the convenience wrappers
	Autoref<Facet> fa3 = Facet::makeReader(fret1);
	UT_ASSERT(!fa3->isWriter());
	Autoref<Facet> fa4 = Facet::makeWriter(fret1);
	UT_ASSERT(fa4->isWriter());
	
	// add more row types
	UT_IS(fa1->rowTypes().size(), 0);
	UT_IS(fa1->exportRowType("rt1", rt1), fa1.get());
	fa1->exportRowType("rt2", rt1);
	UT_IS(fa1->rowTypes().size(), 2);
	UT_IS(fa1->rowTypes().at("rt1"), rt1);
	UT_IS(fa1->rowTypes().at("rt2"), rt1);

	UT_IS(fa1->impRowType("rt1"), rt1.get());
	UT_IS(fa1->impRowType("zzz"), NULL);

	// add more table types
	Autoref<TableType> tt1 = TableType::make(rt1)
		->addSubIndex("primary", HashedIndexType::make(
			NameSet::make()->add("a")->add("e")))
	;
	UT_IS(fa1->tableTypes().size(), 0);
	UT_IS(fa1->exportTableType("tt1", tt1), fa1.get());
	fa1->exportTableType("tt2", tt1);
	UT_IS(fa1->tableTypes().size(), 2);
	UT_IS(fa1->tableTypes().at("tt1"), tt1);
	UT_IS(fa1->tableTypes().at("tt2"), tt1);

	UT_IS(fa1->impTableType("tt1"), tt1.get());
	UT_IS(fa1->impTableType("zzz"), NULL);

	// the basic export with reimport sets a bunch of things
	Autoref<Facet> fa1im = ow1->exportNexus(fa1);
	UT_IS(fa1im, fa1);
	UT_ASSERT(fa1->isImported());
	UT_IS(fa1->getFullName(), "t1/fret1");
	UT_IS(fa1->getShortName(), "fret1");
	UT_IS(fa1->queueLimit(), Xtray::QUE_ID_MAX);

	// an invalid FnReturn
	{
		Erref err;

		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
			->addLabel("one", rt1)
		;
		err = fretbad->getErrors();
		UT_ASSERT(err->hasError());
		UT_IS(err->print(), "duplicate row name 'one'\n");

		Autoref<Facet> fabad = Facet::makeReader(fretbad);
		err = fabad->getErrors();
		UT_ASSERT(err->hasError());
		UT_IS(err->print(), "Errors in the underlying FnReturn:\n  duplicate row name 'one'\n");

		// the exception gets thrown at export attempt
		{
			string msg;
			try {
				ow1->exportNexus(fabad);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, 
				"In app 'a1' thread 't1' can not export the facet 'fretbad' with an error:\n"
				"  Errors in the underlying FnReturn:\n"
				"    duplicate row name 'one'\n");
		}
	}

	// an FnReturn that already has an xtray
	{
		Erref err;

		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("_BEGIN_", rt1)
			->addLabel("_END_", rt1)
			->addLabel("one", rt1)
			->addLabel("two", rt1)
		;
		err = fretbad->getErrors();
		UT_ASSERT(!err->hasError());

		fretbad->initialize();

		Autoref<Xtray> xt1 = new Xtray(fretbad->getType());
		FnReturnGuts::swapXtray(fretbad, xt1);
		UT_ASSERT(fretbad->isFaceted());

		{
			Autoref<Facet> fabad = Facet::makeWriter(fretbad); // can't use a faceted FnReturn for a writer
			err = fabad->getErrors();
			UT_ASSERT(err->hasError());
			UT_IS(err->print(), "The FnReturn is already connected to a writer facet, can not do it twice.\n");

			UT_ASSERT(!fabad->isWriter()); // this error resets the writer flag

			// the exception gets thrown at export attempt
			{
				string msg;
				try {
					ow1->exportNexus(fabad);
				} catch(Exception e) {
					msg = e.getErrors()->print();
				}
				UT_IS(msg, 
					"In app 'a1' thread 't1' can not export the facet 'fretbad' with an error:\n"
					"  The FnReturn is already connected to a writer facet, can not do it twice.\n");
			}
		}

		// After the Facet with this error is destroyed, the FnReturn must stay faceted
		UT_ASSERT(fretbad->isFaceted());

		{
			// however that same FnReturn with Xtray can be used fine for a reader
			Autoref<Facet> fagood = Facet::makeReader(fretbad);
			UT_ASSERT(!fagood->getErrors()->hasError());
		}
		
		// After the reader Facet is destroyed, the FnReturn must stay faceted
		UT_ASSERT(fretbad->isFaceted());
	}

	// an initialized FnReturn with no _BEGIN_ and _END_
	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		fretbad->initialize();
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(),
			"If the FnReturn is initialized, it must already contain the _BEGIN_ label.\n"
			"If the FnReturn is initialized, it must already contain the _END_ label.\n");
	}

	// rowType failures
	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		UT_IS(fabad->exportRowType("rta", NULL), fabad);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), "Can not export a NULL row type with name 'rta'.\n");
	}

	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		fabad->exportRowType("", rt1);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), "Can not export a row type with an empty name.\n");
	}

	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		fabad->setQueueLimit(0);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), "Can not set the queue size limit to 0, must be greater than 0.\n");
	}

	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		fabad->exportRowType("rt1", rt1); // this one is OK
		fabad->exportRowType("rt1", rt1);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), "Can not export a duplicate row type name 'rt1'.\n");
	}

	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		RowType::FieldVec fld;
		mkfields(fld);
		fld[1].name_ = "a"; // a duplicate name
		Autoref<RowType> rtbad = new CompactRowType(fld);
		UT_ASSERT(rtbad->getErrors()->hasError());
		fabad->exportRowType("rtb", rtbad);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), 
			"Can not export a row type 'rtb' containing errors:\n"
			"  duplicate field name 'a' for fields 2 and 1\n");
	}

	// tableType failures
	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		UT_IS(fabad->exportTableType("tta", NULL), fabad);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), "Can not export a NULL table type with name 'tta'.\n");
	}

	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		fabad->exportTableType("", tt1);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), "Can not export a table type with an empty name.\n");
	}

	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		fabad->exportTableType("tt1", tt1); // this one is OK
		fabad->exportTableType("tt1", tt1);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), "Can not export a duplicate table type name 'tt1'.\n");
	}

	{
		Autoref<FnReturn> fretbad = FnReturn::make(unit1, "fretbad")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fabad = Facet::make(fretbad, true);
		RowType::FieldVec fld;
		mkfields(fld);
		fld[1].name_ = "a"; // a duplicate name
		Autoref<RowType> rtbad = new CompactRowType(fld);
		UT_ASSERT(rtbad->getErrors()->hasError());
		Autoref<TableType> ttbad = TableType::make(rtbad)
			->addSubIndex("primary", HashedIndexType::make(
				NameSet::make()->add("a")->add("e")))
		;
		fabad->exportTableType("ttb", ttbad);
		UT_ASSERT(fabad->getErrors()->hasError());
		UT_IS(fabad->getErrors()->print(), 
			"Can not export the table type 'ttb' containing errors:\n"
			"  row type error:\n"
			"    duplicate field name 'a' for fields 2 and 1\n");
	}

	// can not modify an imported Facet
	{
		string msg;
		try {
			fa1->setReverse();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Can not modify an imported facet 't1/fret1'.\n");
	}
#if 0  // {
	{
		string msg;
		try {
			fa1->setUnicast();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Can not modify an imported facet 't1/fret1'.\n");
	}
#endif // }
	{
		string msg;
		try {
			fa1->setQueueLimit(100);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Can not modify an imported facet 't1/fret1'.\n");
	}
	{
		string msg;
		try {
			fa1->exportRowType("rtx", rt1);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Can not modify an imported facet 't1/fret1'.\n");
	}
	{
		string msg;
		try {
			fa1->exportTableType("ttx", tt1);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Can not modify an imported facet 't1/fret1'.\n");
	}

	// clean-up, since the apps catalog is global
	ow1->markDead();
	a1->harvester();

	restore_uncatchable();
}

UTESTCASE export_import(Utest *utest)
{
	make_catchable();

	Autoref<FnReturn> fret3; // will be used to check facet destruction
	{
		Autoref<App> a1 = App::make("a1");
		a1->setTimeout(0); // will replace all waits with an Exception
		Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
		Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
		Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
		Autoref<TrieadOwner> ow4 = a1->makeTriead("t3/a"); // with a screwy name
		Autoref<TrieadOwner> ow5 = a1->makeTriead("t5"); // will be dead right away

		Triead::NexusMap exp;
		Triead::FacetMap imp;

		// initially no imports, no exports
		ow1->imports(imp);
		UT_ASSERT(imp.empty());
		ow1->get()->exports(exp);
		UT_ASSERT(exp.empty());

		// prepare fragments
		RowType::FieldVec fld;
		mkfields(fld);
		Autoref<RowType> rt1 = new CompactRowType(fld);

		Autoref<Unit> unit1 = ow1->unit();

		// With an uninitialized FnReturn
		Autoref<FnReturn> fret1 = FnReturn::make(unit1, "fret1")
			->addLabel("one", rt1)
			->addLabel("two", rt1)
			->addLabel("three", rt1)
		;
		Autoref<Facet> fa1 = Facet::makeReader(fret1)->setQueueLimit(100);

		// basic export of a reader with reimport
		Autoref<Facet> fa1im = ow1->exportNexus(fa1);
		UT_IS(fa1im, fa1);
		UT_ASSERT(fa1->isImported());
		UT_IS(fa1->queueLimit(), 100);

		ow1->imports(imp);
		UT_IS(imp.size(), 1);
		UT_IS(imp["t1/fret1"], fa1);

		ow1->get()->imports(exp); // test the list of imports from Triead
		UT_IS(exp.size(), 1);
		UT_IS(exp["t1/fret1"].get(), fa1->nexus());
		ow1->get()->readerImports(exp);
		UT_IS(exp.size(), 1);
		UT_IS(exp["t1/fret1"].get(), fa1->nexus());
		ow1->get()->writerImports(exp);
		UT_ASSERT(exp.empty());

		ow1->exports(exp);
		UT_IS(exp.size(), 1);
		UT_IS(exp["fret1"].get(), fa1->nexus());

		UT_ASSERT(!fa1->getFnReturn()->isFaceted()); // reader doesn't add xtray to the FnReturn

		// basic export with no reimport
		Autoref<FnReturn> fret2 = FnReturn::make(unit1, "fret2")
			->addLabel("one", rt1)
		;
		Autoref<Facet> fa2 = Facet::makeReader(fret2)
			->setReverse()->setQueueLimit(100); // limit would not change with no reimport
		Autoref<Facet> fa2im = ow1->exportNexusNoImport(fa2);
		UT_IS(fa2im, fa2);
		UT_ASSERT(!fa2->isImported());
		UT_ASSERT(fa2->nexus() == NULL);
		UT_ASSERT(fa2->getFullName().empty());
		UT_IS(fa2->queueLimit(), 100);

		UT_ASSERT(!fa2->getFnReturn()->isFaceted()); // reader doesn't add xtray to the FnReturn

		ow1->imports(imp);
		UT_IS(imp.size(), 1);

		ow1->exports(exp);
		UT_IS(exp.size(), 2);
		UT_IS(exp["fret2"].get()->getName(), "fret2");

		// import into the same thread, works immediately
		Autoref<Facet> fa3 = ow1->importNexus("t1", "fret2", "fret3", true);
		UT_ASSERT(fa3->getFnReturn()->equals(fa2->getFnReturn()));
		UT_IS(fa3->getFnReturn()->getUnitPtr(), ow1->unit());

		UT_IS(fa3->queueLimit(), Xtray::QUE_ID_MAX); // on import the limit is set to max for reverse nexus
		
		fret3 = fa3->getFnReturn();
		UT_ASSERT(fret3->isFaceted()); // writer adds xtray to the FnReturn

		ow1->imports(imp);
		UT_IS(imp.size(), 2);
		UT_IS(imp["t1/fret2"], fa3);
		ow1->get()->readerImports(exp);
		UT_IS(exp.size(), 1);
		UT_IS(exp["t1/fret1"].get(), fa1->nexus());
		ow1->get()->writerImports(exp);
		UT_IS(exp.size(), 1);
		UT_IS(exp["t1/fret2"].get(), fa3->nexus());

		// an import into another thread would wait for thread to be fully constructed
		// (and in this case fail on timeout)
		{
			string msg;
			try {
				ow2->importReader("t1", "fret2");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Thread 't1' in application 'a1' did not initialize within the deadline.\n");
		}

		// an immediate import into another thread would succeed
		Autoref<Facet> fa4 = ow2->importReaderImmed("t1", "fret2");
		UT_ASSERT(fa4->getFnReturn()->equals(fa2->getFnReturn()));
		UT_IS(fa4->nexus(), fa3->nexus());
		UT_IS(fa4->getShortName(), "fret2");
		UT_IS(fa4->getFnReturn()->getUnitPtr(), ow2->unit());
		
		UT_ASSERT(!fa4->getFnReturn()->isFaceted()); // reader doesn't add xtray to the FnReturn

		ow2->imports(imp);
		UT_IS(imp.size(), 1);
		UT_IS(imp["t1/fret2"], fa4);

		// test importWriterImmed success
		Autoref<Facet> fa5 = ow3->importWriterImmed("t1", "fret2", "fff");
		UT_ASSERT(fa5->getFnReturn()->equals(fa2->getFnReturn()));
		UT_IS(fa5->nexus(), fa3->nexus());
		UT_IS(fa5->getShortName(), "fff");
		
		UT_ASSERT(fa5->getFnReturn()->isFaceted()); // writer adds xtray to the FnReturn

		ow3->imports(imp);
		UT_IS(imp.size(), 1);
		UT_IS(imp["t1/fret2"], fa5);

		// a repeated import succeeds immediately even if it's not marked as such
		Autoref<Facet> fa6 = ow3->importWriter("t1", "fret2", "xxx");
		UT_IS(fa6, fa5); // same, ignoring the asname!
		ow3->imports(imp);
		UT_IS(imp.size(), 1);

		UT_ASSERT(fa6->getFnReturn()->isFaceted()); // writer adds xtray to the FnReturn

		// ----------------------------------------------------------------------
		// import/export on a thread that is already requested dead
		TrieadGuts::requestDead(ow5->get());

		Autoref<Facet> fa5b = ow5->importReaderImmed("t1", "fret2", "");
		UT_ASSERT(!fa5b.isNull());
		ReaderQueue *far5b = FacetGuts::readerQueue(fa5b);
		UT_ASSERT(far5b != NULL);

		// this uses a newer API than the rest of this function...
		Autoref<Facet> fa5m = ow5->makeNexusWriter("nxm")
			->addLabel("one", rt1)
			->complete()
		;
		UT_ASSERT(!fa5m.isNull());
		NexusWriter *faw5m = FacetGuts::nexusWriter(fa5m);
		UT_ASSERT(faw5m!= NULL);

		// Check that the exports and imports still show in the thread
		ow5->get()->exports(exp);
		UT_IS(exp.size(), 1);

		ow5->get()->imports(exp);
		UT_IS(exp.size(), 2);

		ow5->get()->readerImports(exp);
		UT_IS(exp.size(), 1);
		ow5->get()->writerImports(exp);
		UT_IS(exp.size(), 1);

		ow5->imports(imp);
		UT_IS(imp.size(), 2);

		// but don't show in the nexus
		ReaderVec *rv5b = NexusGuts::readers(fa5b->nexus());
		for (int i = 0; i < rv5b->v().size(); i++)
			UT_ASSERT(rv5b->v()[i].get() != far5b);

		Nexus::WriterVec *wv5m = NexusGuts::writers(fa5m->nexus());
		UT_ASSERT(wv5m->empty());
		
		ow5->markDead();

		// ----------------------------------------------------------------------
		// errors
		// exporting a facet with an error already tested in make_facet()
		{
			string msg;
			try {
				ow2->exportNexus(fa4);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "In app 'a1' thread 't2' can not re-export the imported facet 't1/fret2'.\n");
		}
		{
			string msg;
			try {
				ow3->importReader("t1", "fret2", "xxx");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "In app 'a1' thread 't3' can not import the nexus 't1/fret2' for both reading and writing.\n");
		}
		{
			string msg;
			try {
				ow3->importReaderImmed("t1", "fret99", "xxx");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "For thread 't3', the nexus 'fret99' is not found in application 'a1' thread 't1'.\n");
		}
		{
			string msg;
			try {
				ow1->exportNexusNoImport(fa2);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Can not export the nexus with duplicate name 'fret2' in app 'a1' thread 't1'.\n");
		}
		{
			string msg;

			Autoref<FnReturn> fretm1 = FnReturn::make(ow3->unit(), "a/nex") // a acrewy name
				->addLabel("one", rt1)
			;
			ow3->exportNexus(Facet::makeReader(fretm1)); // also tests the reference passing as the argument
			ow4->importReaderImmed("t3", "a/nex"); // has full name "t3/a/nex"
			
			Autoref<FnReturn> fretm2 = FnReturn::make(ow4->unit(), "nex")
				->addLabel("one", rt1)
			;

			try {
				ow4->exportNexus(Facet::makeReader(fretm2));
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "On exporting a facet in app 'a1' found a same-named facet 't3/a/nex' already imported, did you mess with the funny names?\n");
		}
		{
			string msg;

			Autoref<FnReturn> fretx = FnReturn::make(unit1, "faceted")
				->addLabel("one", rt1)
			;

			Autoref<Facet> fax = Facet::makeWriter(fretx);

			// mess with the Xtray after the facet hasbeen constructed
			Autoref<Xtray> xtx = new Xtray(fretx->getType());
			FnReturnGuts::swapXtray(fretx, xtx);
			UT_ASSERT(fretx->isFaceted());

			try {
				ow2->exportNexus(fax);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "The FnReturn 'faceted' in thread 't2' is already connected to a writer facet, can not do it twice.\n");
		}
		{
			string msg;

			ow1->markConstructed();
			Autoref<FnReturn> fretm1 = FnReturn::make(ow1->unit(), "more")
				->addLabel("one", rt1)
			;

			try {
				ow1->exportNexus(Facet::makeReader(fretm1));
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Can not export the nexus 'more' in app 'a1' thread 't1' that is already marked as constructed.\n");
		}
		{
			string msg;
			ow4->markReady();
			try {
				ow4->importReader("t1", "fret2", "xxx");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "In app 'a1' thread 't3/a' can not import the nexus 't1/fret2' into a ready thread.\n");
		}

		// the other mess
		{
			// basic export of a reader with reimport works fine even if the FnReturn is faceted
			Autoref<FnReturn> fret7 = FnReturn::make(unit1, "fret7")
				->addLabel("_BEGIN_", rt1)
				->addLabel("_END_", rt1)
				->addLabel("one", rt1)
			;
			fret7->initialize();
			Autoref<Xtray> xt7 = new Xtray(fret7->getType());
			FnReturnGuts::swapXtray(fret7, xt7);
			UT_ASSERT(fret7->isFaceted());

			Autoref<Facet> fa7 = Facet::makeReader(fret7);

			ow2->exportNexus(fa7);
			UT_ASSERT(fa7->isImported());

			// basic export of a writer with reimport
			Autoref<FnReturn> fret8 = FnReturn::make(unit1, "fret8")
				->addLabel("one", rt1)
			;
			UT_ASSERT(!fret8->isFaceted());

			Autoref<Facet> fa8 = Facet::makeWriter(fret8);

			ow2->exportNexus(fa8);
			UT_ASSERT(fa8->isImported());
			UT_ASSERT(fret8->isFaceted());

			// basic export of a writer with no reimport
			Autoref<FnReturn> fret9 = FnReturn::make(unit1, "fret9")
				->addLabel("one", rt1)
			;
			UT_ASSERT(!fret9->isFaceted());

			Autoref<Facet> fa9 = Facet::makeWriter(fret9);

			ow2->exportNexusNoImport(fa9);
			UT_ASSERT(!fa9->isImported());
			UT_ASSERT(!fret9->isFaceted()); // not faceted if not reimported
		}

		// clean-up, since the apps catalog is global
		ow1->markDead();
		ow2->markDead();
		ow3->markDead();
		ow4->markDead();
		ow5->markDead();
		a1->harvester();
	}

	// After a Facet is destroyed, its FnReturn must lose the Xtray.
	UT_ASSERT(!fret3->isFaceted());

	restore_uncatchable();
}

// copied from t_Fn.cpp
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

// the helper interface
UTESTCASE mknexus(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");
	a1->setTimeout(0); // will replace all waits with an Exception
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t3/a"); // with a screwy name

	Triead::NexusMap exp;
	Triead::FacetMap imp;

	// prepare fragments
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	Autoref<Label> lb1 = new DummyLabel(ow1->unit(), rt1, "lb1");
	Autoref<MyFnCtx> ctx1 = new MyFnCtx;

	// build a writer, with all the trimmings
	{
		Autoref<Facet> fa1 = ow1->makeNexusWriter("nx1")
			->addLabel("one", rt1)
			->addFromLabel("two", lb1)
			->setContext(ctx1)
#if 0  // {
			->setUnicast()
			->setUnicast(true)
#endif // }
			->setReverse()
			->setReverse(true)
			->setQueueLimit(3)
			->complete();

		UT_ASSERT(fa1->isImported());
		UT_ASSERT(fa1->isWriter());
#if 0  // {
		UT_ASSERT(fa1->isUnicast());
#endif // }
		UT_ASSERT(fa1->isReverse());
		UT_IS(fa1->queueLimit(), Xtray::QUE_ID_MAX); // auto-set for reverse
		UT_IS(fa1->getShortName(), "nx1");
		UT_IS(fa1->getFullName(), "t1/nx1");
		UT_IS(fa1->getFnReturn()->context(), ctx1);

		ow1->imports(imp);
		UT_IS(imp.size(), 1);
		UT_IS(imp["t1/nx1"], fa1);

		ow1->exports(exp);
		UT_IS(exp.size(), 1);
		UT_IS(exp["nx1"].get(), fa1->nexus());

		// the maker gets reset to NULL after completion
		UT_IS(TrieadOwnerGuts::nexusMakerFnReturn(ow1), NULL);
		UT_IS(TrieadOwnerGuts::nexusMakerFacet(ow1), NULL);
	}

	// build a reader
	{
		Autoref<Facet> fa1 = ow1->makeNexusReader("nx2")
			->addLabel("one", rt1)
			->complete();

		UT_ASSERT(fa1->isImported());
		UT_ASSERT(!fa1->isWriter());
	}

	{
		// build a no-import
		Autoref<Facet> fa1 = ow1->makeNexusNoImport("nx3")
			->addLabel("one", rt1)
			->complete();

		UT_ASSERT(!fa1->isImported());
	}

	{
		// incorrect initialization order
		string msg;
		try {
			Autoref<Facet> fa1 = ow1->makeNexusWriter("nx4")
				->setReverse()
				->addLabel("one", rt1)
				->complete();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Attempted to add label 'one' to an initialized FnReturn 'nx4'.\n");
	}

	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester();

	restore_uncatchable();
}

// check the connection of queues done when importing facets
UTESTCASE import_queues(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");
	a1->setTimeout(0); // will replace all waits with an Exception
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t3/a"); // with a screwy name

	// prepare fragments
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	Autoref<Unit> unit1 = ow1->unit();

	// start with a writer
	Autoref<Facet> fa1 = ow1->makeNexusWriter("nx1")
		->addLabel("one", rt1)
		->addLabel("two", rt1)
		->addLabel("three", rt1)
		->complete()
	;
	Nexus *nx1 = fa1->nexus();
	Nexus::WriterVec *wv;

	UT_ASSERT(FacetGuts::readerQueue(fa1) == NULL);
	NexusWriter *faw1 = FacetGuts::nexusWriter(fa1);
	UT_ASSERT(faw1 != NULL);

	ReaderVec *rv1 = NexusGuts::readers(nx1);
	wv = NexusGuts::writers(nx1);

	UT_IS(rv1, NULL);
	UT_IS(wv->size(), 1);
	UT_IS(wv->at(0).get(), faw1);
	UT_IS(NexusWriterGuts::readers(wv->at(0)), NULL);
	UT_IS(NexusWriterGuts::readersNew(wv->at(0)), NULL);

	ow1->markReady(); // make the nexus visible for import

	// as a little side-track test, write to a writer without any readers
	// (it will be discarded and must not get stuck)
	{
		Autoref<Xtray> xt = new Xtray(fa1->getFnReturn()->getType());
		faw1->write(xt);
	}

	// add a reader
	Autoref<Facet> fa2 = ow2->importReader("t1", "nx1", "");

	ReaderQueue *far2 = FacetGuts::readerQueue(fa2);
	UT_ASSERT(far2 != NULL);
	UT_ASSERT(FacetGuts::nexusWriter(fa2) == NULL);

	UT_ASSERT(!far2->isDead());

	ReaderVec *rv2 = NexusGuts::readers(nx1);

	UT_ASSERT(rv2 != NULL);
	UT_ASSERT(rv2 != rv1);
	UT_IS(rv2->v().size(), 1);
	UT_IS(wv->size(), 1);
	UT_IS(NexusWriterGuts::readers(wv->at(0)), NULL);
	UT_IS(NexusWriterGuts::readersNew(wv->at(0)), rv2);
	UT_IS(rv2->gen(), 0);
	UT_IS(rv2->v()[0].get(), far2);
	UT_IS(ReaderQueueGuts::gen(rv2->v()[0]), 0);

	// add another reader
	Autoref<Facet> fa3 = ow3->importReader("t1", "nx1", "");

	ReaderQueue *far3 = FacetGuts::readerQueue(fa3);
	UT_ASSERT(far3 != NULL);
	UT_ASSERT(FacetGuts::nexusWriter(fa3) == NULL);

	UT_ASSERT(!far3->isDead());

	ReaderVec *rv3 = NexusGuts::readers(nx1);

	UT_ASSERT(rv3 != NULL);
	UT_ASSERT(rv3 != rv2);
	UT_IS(rv3->v().size(), 2);
	UT_IS(wv->size(), 1);
	UT_IS(NexusWriterGuts::readers(wv->at(0)), NULL);
	UT_IS(NexusWriterGuts::readersNew(wv->at(0)), rv3);
	UT_IS(rv3->gen(), 1);
	UT_IS(rv3->v()[0].get(), far2);
	UT_IS(rv3->v()[1].get(), far3);
	UT_IS(ReaderQueueGuts::gen(rv3->v()[0]), 1);
	UT_IS(ReaderQueueGuts::gen(rv3->v()[1]), 1);

	// add another writer
	Autoref<Facet> fa4 = ow4->importWriter("t1", "nx1", "");

	UT_ASSERT(FacetGuts::readerQueue(fa4) == NULL);
	NexusWriter *faw4 = FacetGuts::nexusWriter(fa4);
	UT_ASSERT(faw4 != NULL);

	ReaderVec *rv4 = NexusGuts::readers(nx1);

	UT_ASSERT(rv4 != NULL);
	UT_ASSERT(rv4 == rv3);
	UT_IS(rv4->v().size(), 2);
	UT_IS(wv->size(), 2);
	UT_IS(faw1, wv->at(0));
	UT_IS(faw4, wv->at(1));
	UT_IS(NexusWriterGuts::readers(wv->at(1)), NULL);
	UT_IS(NexusWriterGuts::readersNew(wv->at(1)), rv4);
	UT_IS(rv4->gen(), 1);

	// ----------------------------------------------------------------------
	// Test the manual writing through the nexus, since everything is set up for it.

	UT_ASSERT(!QueEventGuts::isSignaled(TrieadOwnerGuts::qev(ow2)));
	UT_ASSERT(!QueEventGuts::isSignaled(TrieadOwnerGuts::qev(ow3)));

	Autoref<Xtray> xt1 = new Xtray(fa1->getFnReturn()->getType());
	faw1->write(xt1);

	// this makes the writer pick up the recent version of the reader vector
	UT_IS(NexusWriterGuts::readers(wv->at(0)), rv4);
	UT_IS(NexusWriterGuts::readersNew(wv->at(0)), rv4);
	// the other writer is still not updated
	UT_IS(NexusWriterGuts::readers(wv->at(1)), NULL);

	UT_IS(ReaderQueueGuts::prevId(far2), 0);
	UT_IS(ReaderQueueGuts::lastId(far2), 1);
	UT_IS(ReaderQueueGuts::writeq(far2).size(), 1);
	UT_IS(ReaderQueueGuts::writeq(far2)[0], xt1);
	UT_ASSERT(ReaderQueueGuts::wrReady(far2));
	UT_ASSERT(!ReaderQueueGuts::wrhole(far2));
	UT_ASSERT(QueEventGuts::isSignaled(TrieadOwnerGuts::qev(ow2)));
	
	UT_IS(ReaderQueueGuts::prevId(far3), 0);
	UT_IS(ReaderQueueGuts::lastId(far3), 1);
	UT_IS(ReaderQueueGuts::writeq(far3).size(), 1);
	UT_IS(ReaderQueueGuts::writeq(far3)[0], xt1);
	UT_ASSERT(ReaderQueueGuts::wrReady(far3));
	UT_ASSERT(!ReaderQueueGuts::wrhole(far3));
	UT_ASSERT(QueEventGuts::isSignaled(TrieadOwnerGuts::qev(ow3)));

	// second write
	Autoref<Xtray> xt2 = new Xtray(fa1->getFnReturn()->getType());
	faw4->write(xt2);

	// this makes the second writer pick up the recent version of the reader vector
	UT_IS(NexusWriterGuts::readers(wv->at(1)), rv4);
	UT_IS(NexusWriterGuts::readersNew(wv->at(1)), rv4);

	// a reduced set of checks for the 2nd tray
	UT_IS(ReaderQueueGuts::prevId(far2), 0);
	UT_IS(ReaderQueueGuts::lastId(far2), 2);
	UT_IS(ReaderQueueGuts::writeq(far2).size(), 2);
	UT_IS(ReaderQueueGuts::writeq(far2)[0], xt1);
	UT_IS(ReaderQueueGuts::writeq(far2)[1], xt2);

	UT_IS(ReaderQueueGuts::lastId(far3), 2);

	// ----------------------------------------------------------------------
	// Before deletion, mess a bit with the queues, which will create
	// interesting things to check in the deletion.

	ReaderQueueGuts::setLastId(far2, 5);
	UT_IS(ReaderQueueGuts::lastId(far2), 5);
	UT_IS(ReaderQueueGuts::writeq(far2).size(), 5);
	UT_ASSERT(ReaderQueueGuts::wrhole(far2));
	
	// ----------------------------------------------------------------------
	// Test the manual calls for deletion of readers and writers
	// (they are not normally accessible to the users).

	// delete the first reader
	NexusGuts::deleteReader(nx1, far2);

	ReaderVec *rvx2 = NexusGuts::readers(nx1);

	UT_ASSERT(rvx2 != NULL);
	UT_IS(rvx2->v().size(), 1);
	UT_IS(wv->size(), 2);
	UT_IS(NexusWriterGuts::readers(wv->at(0)), rv4);
	UT_IS(NexusWriterGuts::readersNew(wv->at(0)), rvx2);
	UT_IS(rvx2->gen(), 2);
	UT_IS(rvx2->v()[0].get(), far3); // shifted forward
	UT_IS(ReaderQueueGuts::gen(rvx2->v()[0]), 2);
	UT_ASSERT(far2->isDead());
	// the queue gets cleared when dead
	UT_IS(ReaderQueueGuts::writeq(far2).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(far2), 0);
	UT_IS(ReaderQueueGuts::lastId(far2), 0);
	// all the readers get updated with the last id from the first one
	UT_IS(ReaderQueueGuts::lastId(far3), 5);
	UT_IS(ReaderQueueGuts::writeq(far3).size(), 5);
	UT_ASSERT(ReaderQueueGuts::wrhole(far3));

	// delete the second and last reader
	NexusGuts::deleteReader(nx1, far3);

	ReaderVec *rvx3 = NexusGuts::readers(nx1);

	UT_ASSERT(rvx3 != NULL);
	UT_IS(rvx3->v().size(), 0);
	UT_IS(wv->size(), 2);
	UT_IS(NexusWriterGuts::readers(wv->at(0)), rv4);
	UT_IS(NexusWriterGuts::readersNew(wv->at(0)), rvx3);
	UT_IS(rvx3->gen(), 3);
	UT_ASSERT(far3->isDead());
	// the queue gets cleared when dead
	UT_IS(ReaderQueueGuts::writeq(far3).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(far3), 0);
	UT_IS(ReaderQueueGuts::lastId(far3), 0);

	// delete the first writer
	NexusGuts::deleteWriter(nx1, faw1);
	UT_IS(wv->size(), 1);
	UT_IS(wv->at(0).get(), faw4);

	// delete the second and last writer
	NexusGuts::deleteWriter(nx1, faw4);
	UT_IS(wv->size(), 0);

	// ----------------------------------------------------------------------
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester();

	restore_uncatchable();
}

class WriteHelperT: public Mtarget, public pw::pwthread
{
public:
	// will write this xtray to this queue at this id
	WriteHelperT(ReaderQueue *q, Autoref<Xtray> xt, Xtray::QueId id):
		q_(q),
		xt_(xt),
		id_(id)
	{ }

	virtual void *execute()
	{
		q_->write(xt_, id_);
		return NULL;
	}

	Autoref<ReaderQueue> q_;
	Autoref<Xtray> xt_;
	Xtray::QueId id_;
};

// a small-scale test of communication in the ReaderQueue from writer to reader
UTESTCASE queue_fill(Utest *utest)
{
	Autoref<QueEvent> qev = new QueEvent(NULL);
	Autoref<ReaderQueue> q = new ReaderQueue(qev, 5);
	Autoref<Xtray> xt = new Xtray(NULL); // this is an abuse but good enough here
	int n;
	Xtray::QueId id;

	// these will flip at some point, allows to keep track of it
	ReaderQueue::Xdeque &dq1 = ReaderQueueGuts::writeq(q);
	ReaderQueue::Xdeque &dq2 = ReaderQueueGuts::readq(q);

	UT_IS(ReaderQueueGuts::writeq(q).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(q), 0);
	UT_IS(ReaderQueueGuts::lastId(q), 0);
	UT_ASSERT(!ReaderQueueGuts::wrhole(q));
	UT_ASSERT(!ReaderQueueGuts::wrReady(q));
	UT_ASSERT(!QueEventGuts::isSignaled(qev));
	
	// ----------------------------------------------------------------------

	// refilling from an empty write queue does nothing
	UT_ASSERT(!q->refill());
	UT_IS(&dq1, &ReaderQueueGuts::writeq(q));
	UT_IS(&dq2, &ReaderQueueGuts::readq(q));
	// the read queue is empty
	UT_IS(q->frontread(), NULL);

	// write an xtray at a sequential id at the front
	q->write(xt, 1);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 1);
	UT_IS(ReaderQueueGuts::prevId(q), 0);
	UT_IS(ReaderQueueGuts::lastId(q), 1);
	UT_ASSERT(!ReaderQueueGuts::wrhole(q));
	UT_ASSERT(ReaderQueueGuts::wrReady(q));
	UT_ASSERT(QueEventGuts::isSignaled(qev));

	qev->wait(); // reset back the event
	UT_ASSERT(!QueEventGuts::isSignaled(qev));
	ReaderQueueGuts::wrReady(q) = false; // also reset

	// write another xtray at a sequential id
	q->write(xt, 2);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 2);
	UT_IS(ReaderQueueGuts::prevId(q), 0);
	UT_IS(ReaderQueueGuts::lastId(q), 2);
	UT_ASSERT(!ReaderQueueGuts::wrhole(q));
	// writing any block but the first doesn't dignal
	UT_ASSERT(!ReaderQueueGuts::wrReady(q));
	UT_ASSERT(!QueEventGuts::isSignaled(qev));

	ReaderQueueGuts::wrReady(q) = true; // restore, to let the refill work
	
	// ----------------------------------------------------------------------

	// refill the read queue from it
	UT_ASSERT(q->refill());
	// queues should get flipped
	UT_IS(&dq2, &ReaderQueueGuts::writeq(q));
	UT_IS(&dq1, &ReaderQueueGuts::readq(q));
	// write queue gets reset
	UT_IS(ReaderQueueGuts::readq(q).size(), 2);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(q), 2);
	UT_IS(ReaderQueueGuts::lastId(q), 2);
	UT_ASSERT(!ReaderQueueGuts::wrhole(q));
	UT_ASSERT(!ReaderQueueGuts::wrReady(q));

	// write an xtray with a hole
	q->write(xt, 5);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 3);
	UT_IS(ReaderQueueGuts::writeq(q)[0].get(), NULL);
	UT_IS(ReaderQueueGuts::writeq(q)[1].get(), NULL);
	UT_IS(ReaderQueueGuts::writeq(q)[2].get(), xt.get());
	UT_IS(ReaderQueueGuts::prevId(q), 2);
	UT_IS(ReaderQueueGuts::lastId(q), 5);
	UT_ASSERT(ReaderQueueGuts::wrhole(q));
	UT_ASSERT(!ReaderQueueGuts::wrReady(q));
	UT_ASSERT(!QueEventGuts::isSignaled(qev));

	// check that writeFirst works even if there are holes
	UT_ASSERT(q->writeFirst(ReaderQueueGuts::gen(q), xt, id));
	UT_IS(id, 6);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 4);
	UT_IS(ReaderQueueGuts::writeq(q)[0].get(), NULL);
	UT_IS(ReaderQueueGuts::writeq(q)[1].get(), NULL);
	UT_IS(ReaderQueueGuts::writeq(q)[2].get(), xt.get());
	UT_IS(ReaderQueueGuts::writeq(q)[3].get(), xt.get());
	UT_IS(ReaderQueueGuts::prevId(q), 2);
	UT_IS(ReaderQueueGuts::lastId(q), 6);
	UT_ASSERT(ReaderQueueGuts::wrhole(q));

	// write an xtray at the 1st position signals the readiness
	q->write(xt, 3);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 4);
	UT_IS(ReaderQueueGuts::writeq(q)[0].get(), xt.get());
	UT_IS(ReaderQueueGuts::prevId(q), 2);
	UT_IS(ReaderQueueGuts::lastId(q), 6);
	UT_ASSERT(ReaderQueueGuts::wrhole(q));
	UT_ASSERT(ReaderQueueGuts::wrReady(q));
	UT_ASSERT(QueEventGuts::isSignaled(qev));
	
	// ----------------------------------------------------------------------

	// refill attempt when the read queue is not empty does nothing
	UT_ASSERT(q->refill());
	// queues stay the same
	UT_IS(&dq2, &ReaderQueueGuts::writeq(q));
	UT_IS(&dq1, &ReaderQueueGuts::readq(q));
	UT_IS(ReaderQueueGuts::readq(q).size(), 2);
	UT_ASSERT(ReaderQueueGuts::wrReady(q));

	// read up the read queue
	UT_IS(q->frontread(), xt.get());
	n = xt->getref();
	q->popread();
	UT_IS(xt->getref(), n-1); // popping drops the reference
	UT_IS(ReaderQueueGuts::readq(q).size(), 1);
	n = xt->getref();
	q->popread();
	UT_IS(xt->getref(), n-1); // popping drops the reference
	UT_IS(ReaderQueueGuts::readq(q).size(), 0);
	UT_IS(q->frontread(), NULL);
	
	// ----------------------------------------------------------------------

	// now refill again, heeding the holes
	n = xt->getref();
	UT_ASSERT(q->refill());
	UT_IS(xt->getref(), n); // moving between the queues keeps the same ref count
	// queues stay the same, just the data moves
	UT_IS(&dq2, &ReaderQueueGuts::writeq(q));
	UT_IS(&dq1, &ReaderQueueGuts::readq(q));
	UT_IS(ReaderQueueGuts::readq(q).size(), 1);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 3);
	UT_IS(ReaderQueueGuts::prevId(q), 3);
	UT_IS(ReaderQueueGuts::lastId(q), 6);
	UT_ASSERT(ReaderQueueGuts::wrhole(q));
	UT_ASSERT(!ReaderQueueGuts::wrReady(q));

	// clear the reader queue
	ReaderQueueGuts::readq(q).clear();
	
	// ----------------------------------------------------------------------

	// fill the hole
	q->write(xt, 4);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 3);
	UT_IS(ReaderQueueGuts::writeq(q)[0].get(), xt.get());
	UT_IS(ReaderQueueGuts::writeq(q)[1].get(), xt.get());
	UT_IS(ReaderQueueGuts::writeq(q)[2].get(), xt.get());
	UT_IS(ReaderQueueGuts::prevId(q), 3);
	UT_IS(ReaderQueueGuts::lastId(q), 6);
	UT_ASSERT(ReaderQueueGuts::wrhole(q)); // doesn't know that it's filled yet
	UT_ASSERT(ReaderQueueGuts::wrReady(q));
	
	// refill again, finding that the hole is closed
	UT_ASSERT(q->refill());
	// queues stay the same, just the data moves
	UT_IS(&dq2, &ReaderQueueGuts::writeq(q));
	UT_IS(&dq1, &ReaderQueueGuts::readq(q));
	UT_IS(ReaderQueueGuts::readq(q).size(), 3);
	UT_IS(ReaderQueueGuts::writeq(q).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(q), 6);
	UT_IS(ReaderQueueGuts::lastId(q), 6);
	UT_ASSERT(!ReaderQueueGuts::wrhole(q)); // filled!
	UT_ASSERT(!ReaderQueueGuts::wrReady(q));

	// clear the reader queue
	ReaderQueueGuts::readq(q).clear();
	
	// ----------------------------------------------------------------------

	// now check that the queue limit is properly heeded
	Autoref<WriteHelperT> wh1 = new WriteHelperT(q, xt, 12); // last was 6 + limit 5 + 1 past
	Autoref<WriteHelperT> wh2 = new WriteHelperT(q, xt, 13); // next after it
	qev->reset();
	wh1->start(); // should get stuck writing
	wh2->start(); // should get stuck writing
	ReaderQueueGuts::waitCondfullSleep(q, 2);

	// nothing should get added to the queue yet
	UT_IS(ReaderQueueGuts::writeq(q).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(q), 6);
	UT_IS(ReaderQueueGuts::lastId(q), 6);

	// add 2 xtrays at the front, that would allow the refill to free both sleepers
	q->write(xt, 7);
	q->write(xt, 8);

	// the magic happens here
	UT_ASSERT(q->refill());

	// both writes must succeed now
	wh1->join();
	wh2->join();
	UT_IS(ReaderQueueGuts::writeq(q).size(), 5);
	UT_IS(ReaderQueueGuts::writeq(q)[3].get(), xt.get());
	UT_IS(ReaderQueueGuts::writeq(q)[4].get(), xt.get());
	UT_IS(ReaderQueueGuts::prevId(q), 8);
	UT_IS(ReaderQueueGuts::lastId(q), 13);
}

class WriteHelper2T: public Mtarget, public pw::pwthread
{
public:
	// will write this xtray to this NexusWriter
	WriteHelper2T(NexusWriter *nxw, Autoref<Xtray> xt):
		nxw_(nxw),
		xt_(xt)
	{ }

	virtual void *execute()
	{
		nxw_->write(xt_);
		return NULL;
	}

	Autoref<NexusWriter> nxw_;
	Autoref<Xtray> xt_;
};

// add and delete readers while the writers are writing
UTESTCASE dynamic_add_del(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");
	a1->setTimeout(0); // will replace all waits with an Exception
	Autoref<TrieadOwner> oww1 = a1->makeTriead("twr1");
	Autoref<TrieadOwner> oww2 = a1->makeTriead("twr2");

	Autoref<TrieadOwner> owr1 = a1->makeTriead("trd1");
	Autoref<TrieadOwner> owr2 = a1->makeTriead("trd2");
	Autoref<TrieadOwner> owr3 = a1->makeTriead("trd3");

	// prepare fragments
	Autoref<Xtray> xt = new Xtray(NULL); // this is an abuse but good enough here
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	// start with a writer
	Autoref<Facet> fw1 = oww1->makeNexusWriter("nx1")
		->addLabel("one", rt1)
		->addLabel("two", rt1)
		->addLabel("three", rt1)
		->setQueueLimit(2)
		->complete()
	;
	Nexus *nx1 = fw1->nexus();

	NexusWriter *faw1 = FacetGuts::nexusWriter(fw1);
	UT_ASSERT(faw1 != NULL);

	oww1->markReady(); // make the nexus visible for import

	// add another writer
	Autoref<Facet> fw2 = oww2->importWriter("twr1", "nx1", "");
	NexusWriter *faw2 = FacetGuts::nexusWriter(fw2);
	UT_ASSERT(faw2 != NULL);
	
	// add the first reader
	Autoref<Facet> fr1 = owr1->importReader("twr1", "nx1", "");
	ReaderQueue *far1 = FacetGuts::readerQueue(fr1);
	UT_ASSERT(far1 != NULL);

	// ----------------------------------------------------------------------

	// send a couple of xtrays to fill the queue
	faw1->write(xt);
	faw1->write(xt);

	// now set up two more writes in the background, they will be blocked
	// (two allows to have a race in writeFirst()
	Autoref<WriteHelper2T> wh1 = new WriteHelper2T(faw1, xt);
	Autoref<WriteHelper2T> wh2 = new WriteHelper2T(faw2, xt);
	wh1->start();
	wh2->start();
	ReaderQueueGuts::waitCondfullSleep(far1, 2);

	// add the second reader
	Autoref<Facet> fr2 = owr2->importReader("twr1", "nx1", "");
	ReaderQueue *far2 = FacetGuts::readerQueue(fr2);
	UT_ASSERT(far2 != NULL);

	// advance the 1st reader, letting the write proceed
	UT_ASSERT(far1->refill());
	ReaderQueueGuts::readq(far1).clear();
	wh1->join();
	wh2->join();

	// check that the write proceeded consistently
	UT_IS(ReaderQueueGuts::writeq(far1).size(), 2);
	UT_IS(ReaderQueueGuts::prevId(far1), 2);
	UT_IS(ReaderQueueGuts::lastId(far1), 4);
	UT_ASSERT(ReaderQueueGuts::wrReady(far1));

	UT_IS(ReaderQueueGuts::writeq(far2).size(), 2);
	UT_IS(ReaderQueueGuts::prevId(far2), 2);
	UT_IS(ReaderQueueGuts::lastId(far2), 4);
	UT_ASSERT(ReaderQueueGuts::wrReady(far2));

	// ----------------------------------------------------------------------

	// to make the write stop on 2nd reader, do the trick
	// with setting the 1st reader's queue limit higher
	ReaderQueueGuts::sizeLimit(far1)++;
	
	Autoref<WriteHelper2T> wh3 = new WriteHelper2T(faw1, xt);
	wh3->start();
	ReaderQueueGuts::waitCondfullSleep(far2, 1);

	// now add one more reader
	Autoref<Facet> fr3 = owr3->importReader("twr1", "nx1", "");
	ReaderQueue *far3 = FacetGuts::readerQueue(fr3);
	UT_ASSERT(far3 != NULL);

	// advance the old readers, letting the write proceed
	UT_ASSERT(far1->refill());
	ReaderQueueGuts::readq(far1).clear();
	UT_ASSERT(far2->refill());
	ReaderQueueGuts::readq(far2).clear();
	wh3->join();

	// the 1st reader will have all data consumed
	UT_IS(ReaderQueueGuts::writeq(far1).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(far1), 5);
	UT_IS(ReaderQueueGuts::lastId(far1), 5);
	UT_ASSERT(!ReaderQueueGuts::wrReady(far1));

	// the 2nd reader will have the new xtray in it
	UT_IS(ReaderQueueGuts::writeq(far2).size(), 1);
	UT_IS(ReaderQueueGuts::prevId(far2), 4);
	UT_IS(ReaderQueueGuts::lastId(far2), 5);
	UT_ASSERT(ReaderQueueGuts::wrReady(far2));

	// the 3rd (new) reader will just have the consistent ids
	UT_IS(ReaderQueueGuts::writeq(far3).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(far3), 5);
	UT_IS(ReaderQueueGuts::lastId(far3), 5);
	UT_ASSERT(!ReaderQueueGuts::wrReady(far3));
	
	// ----------------------------------------------------------------------

	// send one more xtray to fill the queue of far2
	faw1->write(xt);

	// reset the event for the reader about to be deleted
	TrieadOwnerGuts::qev(owr2)->reset();
	ReaderQueueGuts::wrReady(far2) = false;

	// the next write will get stuck on far2
	Autoref<WriteHelper2T> wh4 = new WriteHelper2T(faw1, xt);
	wh4->start();
	ReaderQueueGuts::waitCondfullSleep(far2, 1);

	// delete far2 from nexus, in a hackish way
	NexusGuts::deleteReader(nx1, far2);
	// it wakes up the writer
	wh4->join();

	// the 1st reader will have the data queued
	UT_IS(ReaderQueueGuts::writeq(far1).size(), 2);
	UT_IS(ReaderQueueGuts::prevId(far1), 5);
	UT_IS(ReaderQueueGuts::lastId(far1), 7);
	UT_ASSERT(ReaderQueueGuts::wrReady(far1));

	// the 2nd reader will be dead
	UT_IS(ReaderQueueGuts::writeq(far2).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(far2), 4);
	UT_IS(ReaderQueueGuts::lastId(far2), 4);
	UT_ASSERT(ReaderQueueGuts::wrReady(far2));
	UT_ASSERT(QueEventGuts::isSignaled(TrieadOwnerGuts::qev(owr2)));

	// the 3rd reader will have the same data queued
	UT_IS(ReaderQueueGuts::writeq(far3).size(), 2);
	UT_IS(ReaderQueueGuts::prevId(far3), 5);
	UT_IS(ReaderQueueGuts::lastId(far3), 7);
	UT_ASSERT(ReaderQueueGuts::wrReady(far3));
	
	// ----------------------------------------------------------------------

	// The next test wants to be stuck on the 1st reader.
	// The 2nd one is already gone. The 3rd needs to be cleaned.
	UT_ASSERT(far3->refill());
	ReaderQueueGuts::readq(far3).clear();
	// The 1st has the limit of 3, so plug one more xtray into it.
	faw1->write(xt);

	// reset the event for the reader about to be deleted
	TrieadOwnerGuts::qev(owr1)->reset();
	ReaderQueueGuts::wrReady(far1) = false;

	// the next write will get stuck on far1
	Autoref<WriteHelper2T> wh5 = new WriteHelper2T(faw1, xt);
	wh5->start();
	ReaderQueueGuts::waitCondfullSleep(far1, 1);

	// delete far1 from nexus, in a hackish way
	NexusGuts::deleteReader(nx1, far1);
	// it wakes up the writer
	wh5->join();

	// the 1st reader will be dead
	UT_IS(ReaderQueueGuts::writeq(far1).size(), 0);
	UT_IS(ReaderQueueGuts::prevId(far1), 5);
	UT_IS(ReaderQueueGuts::lastId(far1), 5);
	UT_ASSERT(ReaderQueueGuts::wrReady(far1));
	UT_ASSERT(QueEventGuts::isSignaled(TrieadOwnerGuts::qev(owr1)));

	// the 3rd reader will have the same data queued
	UT_IS(ReaderQueueGuts::writeq(far3).size(), 2);
	UT_IS(ReaderQueueGuts::prevId(far3), 7);
	UT_IS(ReaderQueueGuts::lastId(far3), 9);
	UT_ASSERT(ReaderQueueGuts::wrReady(far3));
	
	// ----------------------------------------------------------------------

	// clean-up, since the apps catalog is global
	oww1->markDead();
	oww2->markDead();
	owr1->markDead();
	owr2->markDead();
	owr3->markDead();
	a1->harvester();

	restore_uncatchable();
}

// the row printer for tracing
void printB(string &res, const RowType *rt, const Row *row)
{
	int32_t b = rt->getInt32(row, 1, 0); // field b at idx 1
	res.append(strprintf(" b=%d", (int)b));
}

// a class that forwards the rows into a writer facet
// if the autodecreased field "b" (at index 1) is > 0
class RewriteLabel: public Label
{
public:
	RewriteLabel(Unit *unit, Onceref<RowType> rtype, const string &name,
			Facet *fa, int idx) :
		Label(unit, rtype, name),
		fa_(fa),
		idx_(idx),
		rt_(fa_->getFnReturn()->getType()->getRowType(idx))
	{ }

	virtual void execute(Rowop *arg) const
	{ 
		int32_t val = rt_->getInt32(arg->getRow(), 1, 0);
		if (--val > 0) {
			FdataVec dv;
			rt_->splitInto(arg->getRow(), dv);
			dv[1].setPtr(true, &val, sizeof(val));

			Autoref<Xtray> xt = new Xtray(fa_->getFnReturn()->getType());
			xt->push_back(idx_, rt_->makeRow(dv), arg->getOpcode());
			FacetGuts::nexusWriter(fa_)->write(xt);
		}
	}

	Facet *fa_;
	int idx_; // index of row type in xtray
	RowType *rt_; // used to extract the field 1
};

// check the high-level passing of data
UTESTCASE pass_data(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");
	a1->setTimeout(0); // will replace all waits with an Exception
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");

	// prepare fragments
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	FdataVec dv;
	mkfdata(dv);
	int32_t val = 2;
	dv[1].setPtr(true, &val, sizeof(val));
	Rowref r1(rt1,  rt1->makeRow(dv));

	Autoref<Unit> unit1 = ow1->unit();
	Autoref<Unit> unit2 = ow2->unit();
	Autoref<Unit::Tracer> trace2 = new Unit::StringNameTracer(false, printB);
	unit2->setTracer(trace2);
	Autoref<Unit> unit3 = ow3->unit();
	Autoref<Unit::Tracer> trace3 = new Unit::StringNameTracer(false, printB);
	unit3->setTracer(trace3);

	// start with a writer
	Autoref<Facet> fa1a = ow1->makeNexusWriter("nxa")
		->addLabel("one", rt1)
		->addLabel("two", rt1)
		->addLabel("three", rt1)
		->complete()
	;
	// Nexus *nxa = fa1a->nexus();

	Autoref<Facet> fa1b = ow1->makeNexusWriter("nxb")
		->addLabel("data", rt1)
		->setReverse()
		->complete()
	;
	// Nexus *nxb = fa1b->nexus();

	Autoref<Facet> fa1c = ow1->makeNexusNoImport("nxc")
		->addLabel("data", rt1)
		->complete()
	;

	ow1->markReady(); // make the nexus visible for import

	// add a reader
	Autoref<Facet> fa2a = ow2->importReader("t1", "nxa", "");
	ReaderQueue *far2a = FacetGuts::readerQueue(fa2a);
	UT_ASSERT(far2a != NULL);

	Autoref<Facet> fa2b = ow2->importReader("t1", "nxb", "");
	ReaderQueue *far2b = FacetGuts::readerQueue(fa2b);
	UT_ASSERT(far2b != NULL);

	// add a nexus from ow2 to ow3
	Autoref<Facet> fa2c = ow2->makeNexusWriter("nxc")
		->addLabel("one", rt1)
		->complete()
	;
	// this nexus is technically from ow2 to ow3 but it will
	// be used in a creative way
	Autoref<Facet> fa2d = ow2->makeNexusWriter("nxd")
		->addLabel("data", rt1)
		->setReverse()
		->complete()
	;

	ow2->markReady(); // make the nexus visible for import

	Autoref<Facet> fa3c = ow3->importReader("t2", "nxc", "");
	ReaderQueue *far3c = FacetGuts::readerQueue(fa3c);
	UT_ASSERT(far3c != NULL);
	Autoref<Facet> fa3d = ow3->importReader("t2", "nxd", "");
	ReaderQueue *far3d = FacetGuts::readerQueue(fa3d);
	UT_ASSERT(far3d != NULL);

	// and interconnect inside ow2
	fa2a->getFnReturn()->getLabel("one")->chain(fa2c->getFnReturn()->getLabel("one"));
	fa2b->getFnReturn()->getLabel("data")->chain(fa2c->getFnReturn()->getLabel("one"));

	// and do the looped connection inside ow3
	// (this uses a test backdoor to send the rows pretending that it came from
	// ow2, sending directly to its writer, to come back as a high-priority Xtray)
	Autoref<RewriteLabel> rwl = new RewriteLabel(ow3->unit(), rt1, "rwl", fa2d, 0);
	fa3c->getFnReturn()->getLabel("one")->chain(rwl);
	fa3d->getFnReturn()->getLabel("data")->chain(rwl);
	
	// ----------------------------------------------------------------------

	// check that writing and reading with facets won't work until the App
	// is found ready by the thread
	{
		string msg;
		try {
			ow1->flushWriters();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, 
			"Can not flush the thread 't1' before waiting for App readiness.\n");
	}
	{
		string msg;
		try {
			fa1a->flushWriter();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, 
			"Can not flush the facet 't1/nxa' before waiting for App readiness.\n");
	}
	{
		string msg;
		try {
			ow1->nextXtray();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, 
			"Can not read the facets in thread 't1' before waiting for App readiness.\n");
	}

	ow1->markReady();
	ow2->markReady();
	ow3->markReady();
	ow4->markReady();

	ow1->readyReady();
	ow2->readyReady();
	ow3->readyReady();
	ow4->readyReady();

	{
		string msg;
		try {
			fa1c->flushWriter();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, 
			"Can not flush a non-exported facet 'nxc'.\n");
	}

	// ----------------------------------------------------------------------

	// send the data
	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));
	unit1->call(new Rowop(fa1b->getFnReturn()->getLabel("data"), 
		Rowop::OP_INSERT, r1));
	ow1->flushWriters();

	// check that it arrived
	UT_IS(ReaderQueueGuts::writeq(far2a).size(), 1);
	UT_IS(ReaderQueueGuts::writeq(far2b).size(), 1);

	// check that flushing a facet with no data is a no-op
	fa1a->flushWriter();
	UT_IS(ReaderQueueGuts::writeq(far2a).size(), 1);
	
	// check that flushing a reader facet is a no-op
	fa2a->flushWriter();
	
	// ----------------------------------------------------------------------

	// read and process the data
	UT_ASSERT(ow2->nextXtray());
	// this must have picked the high-priority message from fa2b
	UT_IS(ReaderQueueGuts::writeq(far2a).size(), 1);
	UT_IS(ReaderQueueGuts::writeq(far2b).size(), 0);

	UT_ASSERT(ow2->nextXtray());
	UT_IS(ReaderQueueGuts::writeq(far2a).size(), 0);
	UT_IS(ReaderQueueGuts::writeq(far2b).size(), 0);

	UT_ASSERT(!ow2->nextXtray(false)); // nothing else to read

	string tlog = trace2->getBuffer()->print();
	string expect1 =
		"unit 't2' before label 'nxb.data' op OP_INSERT b=2\n"
		"unit 't2' before label 'nxc.one' (chain 'nxb.data') op OP_INSERT b=2\n"
		"unit 't2' before label 'nxa.one' op OP_INSERT b=2\n"
		"unit 't2' before label 'nxc.one' (chain 'nxa.one') op OP_INSERT b=2\n"
	;
	if (UT_IS(tlog, expect1)) printf("Expected: \"%s\"\n", expect1.c_str());
	
	// and the records should make it through
	UT_IS(ReaderQueueGuts::writeq(far3c).size(), 2);

	// ----------------------------------------------------------------------

	// test the priority handling in ow3:
	// the rowops will be looped through the high-priority facet, so they
	// will be read first
	
	while (ow3->nextXtrayNoWait());
	tlog = trace3->getBuffer()->print();
	string expect2 =
		"unit 't3' before label 'nxc.one' op OP_INSERT b=2\n"
		"unit 't3' before label 'rwl' (chain 'nxc.one') op OP_INSERT b=2\n"
		"unit 't3' before label 'nxd.data' op OP_INSERT b=1\n"
		"unit 't3' before label 'rwl' (chain 'nxd.data') op OP_INSERT b=1\n"
		"unit 't3' before label 'nxc.one' op OP_INSERT b=2\n"
		"unit 't3' before label 'rwl' (chain 'nxc.one') op OP_INSERT b=2\n"
		"unit 't3' before label 'nxd.data' op OP_INSERT b=1\n"
		"unit 't3' before label 'rwl' (chain 'nxd.data') op OP_INSERT b=1\n"
	;
	if (UT_IS(tlog, expect2)) printf("Expected: \"%s\"\n", expect2.c_str());

	// ----------------------------------------------------------------------

	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester();

	restore_uncatchable();
}

// sending to the _BEGIN_ and _END_ labels
UTESTCASE pass_begin_end(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");
	a1->setTimeout(0); // will replace all waits with an Exception
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");
	Autoref<TrieadOwner> ow5 = a1->makeTriead("t5");

	// prepare fragments
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	FdataVec dv;
	Rowref r0(rt1,  rt1->makeRow(dv)); // an empty row
	mkfdata(dv);
	int32_t val = 2;
	dv[1].setPtr(true, &val, sizeof(val));
	Rowref r1(rt1,  rt1->makeRow(dv)); // a non-empty row

	Autoref<Unit> unit1 = ow1->unit();
	Autoref<Unit> unit2 = ow2->unit();
	Autoref<Unit::Tracer> trace2 = new Unit::StringNameTracer(false);
	unit2->setTracer(trace2);
	Autoref<Unit> unit3 = ow3->unit();
	Autoref<Unit::Tracer> trace3 = new Unit::StringNameTracer(false);
	unit3->setTracer(trace3);
	Autoref<Unit> unit4 = ow4->unit();
	Autoref<Unit> unit5 = ow5->unit();
	Autoref<Unit::Tracer> trace5 = new Unit::StringNameTracer(false);
	unit5->setTracer(trace5);

	// start with a writer
	Autoref<Facet> fa1a = ow1->makeNexusWriter("nxa")
		->addLabel("_BEGIN_", rt1)
		->addLabel("_END_", rt1)
		->addLabel("one", rt1)
		->complete()
	;
	// Nexus *nxa = fa1a->nexus();

	ow1->markReady(); // make the nexus visible for import

	// add a reader
	Autoref<Facet> fa2a = ow2->importReader("t1", "nxa", "");
	ReaderQueue *far2a = FacetGuts::readerQueue(fa2a);
	UT_ASSERT(far2a != NULL);

	ow2->markReady();

	// add a reader
	Autoref<Facet> fa3a = ow3->importReader("t1", "nxa", "");
	ReaderQueue *far3a = FacetGuts::readerQueue(fa3a);
	UT_ASSERT(far3a != NULL);

	// in t3 add the begin/end label chainings
	Autoref<Label> lb3begin = new DummyLabel(unit3, rt1, "begin");
	fa3a->getFnReturn()->getLabel("_BEGIN_")->chain(lb3begin);
	Autoref<Label> lb3end = new DummyLabel(unit3, rt1, "end");
	fa3a->getFnReturn()->getLabel("_END_")->chain(lb3end);

	ow3->markReady();

	// ow4 will be used to check that the _BEGIN_ and _END_
	// also work properly in an imported nexus
	Autoref<Facet> fa4a = ow4->importWriter("t1", "nxa", "");

	ow4->markReady();

	// ow5 is very much like ow3, only with chaining from a binding
	// add a reader
	Autoref<Facet> fa5a = ow5->importReader("t1", "nxa", "");
	ReaderQueue *far5a = FacetGuts::readerQueue(fa5a);
	UT_ASSERT(far5a != NULL);

	// in t5 add the begin/end label chainings
	Autoref<Label> lb5begin = new DummyLabel(unit5, rt1, "begin");
	Autoref<Label> lb5end = new DummyLabel(unit5, rt1, "end");

	Autoref<FnBinding> bind5 = FnBinding::make("bind5", fa5a->getFnReturn())
		->addLabel("_BEGIN_", lb5begin, true)
		->addLabel("_END_", lb5end, true);

	fa5a->getFnReturn()->push(bind5);

	ow5->markReady();

	ow1->readyReady();
	ow2->readyReady();
	ow3->readyReady();
	ow4->readyReady();
	ow5->readyReady();

	// ----------------------------------------------------------------------

	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa4a->getFnReturn()));

	// sending the BEGIN with no data and OP_INSERT puts nothing into the Xdata
	
	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_INSERT, r0));
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));
	UT_ASSERT(!ow2->nextXtray(false));

	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_INSERT, r0));
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa4a->getFnReturn()));
	UT_ASSERT(!ow2->nextXtray(false));

	// sending the END with no data and OP_INSERT puts nothing into the Xdata

	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r0));
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));
	UT_ASSERT(!ow2->nextXtray(false));

	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r0));
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa4a->getFnReturn()));
	UT_ASSERT(!ow2->nextXtray(false));

	// ----------------------------------------------------------------------

	// send a row through without an explicit BEGIN/END

	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));
	ow1->flushWriters();

	UT_ASSERT(ow2->nextXtray());
	{
		string tlog = trace2->getBuffer()->print();
		trace2->clearBuffer();
		string expect =
			"unit 't2' before label 'nxa.one' op OP_INSERT\n"
		;
		if (UT_IS(tlog, expect)) printf("Expected: \"%s\"\n", expect.c_str());
	}

	// when the handlers are chained, begin/end get called
	UT_ASSERT(ow3->nextXtray());
	{
		string tlog = trace3->getBuffer()->print();
		trace3->clearBuffer();
		string expect =
			"unit 't3' before label 'nxa._BEGIN_' op OP_INSERT\n"
			"unit 't3' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
			"unit 't3' before label 'nxa.one' op OP_INSERT\n"
			"unit 't3' before label 'nxa._END_' op OP_INSERT\n"
			"unit 't3' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
		;
		if (UT_IS(tlog, expect)) printf("Expected: \"%s\"\n", expect.c_str());
	}

	// when the handlers are chained from a binding, begin/end get called
	UT_ASSERT(ow5->nextXtray());
	{
		string tlog = trace5->getBuffer()->print();
		trace5->clearBuffer();
		string expect =
			"unit 't5' before label 'nxa._BEGIN_' op OP_INSERT\n"
			"unit 't5' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
			"unit 't5' before label 'nxa.one' op OP_INSERT\n"
			"unit 't5' before label 'nxa._END_' op OP_INSERT\n"
			"unit 't5' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
		;
		if (UT_IS(tlog, expect)) printf("Expected: \"%s\"\n", expect.c_str());
	}

	// ----------------------------------------------------------------------

	// send a row through with the BEGIN/END that become implicit

	UT_ASSERT(!ow2->nextXtray(false)); // _END_ will flush

	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_INSERT, r0));
	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));

	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r0));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));

	// same on ow4
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_INSERT, r0));
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));

	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r0));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa4a->getFnReturn()));

	for (int i = 0; i < 2; i++) {
		UT_ASSERT(ow2->nextXtray());
		{
			string tlog = trace2->getBuffer()->print();
			trace2->clearBuffer();
			string expect =
				"unit 't2' before label 'nxa.one' op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		// when the handlers are chained, begin/end get called
		UT_ASSERT(ow3->nextXtray());
		{
			string tlog = trace3->getBuffer()->print();
			trace3->clearBuffer();
			string expect =
				"unit 't3' before label 'nxa._BEGIN_' op OP_INSERT\n"
				"unit 't3' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
				"unit 't3' before label 'nxa.one' op OP_INSERT\n"
				"unit 't3' before label 'nxa._END_' op OP_INSERT\n"
				"unit 't3' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		// when the handlers are chained from a binding, begin/end get called
		UT_ASSERT(ow5->nextXtray());
		{
			string tlog = trace5->getBuffer()->print();
			trace5->clearBuffer();
			string expect =
				"unit 't5' before label 'nxa._BEGIN_' op OP_INSERT\n"
				"unit 't5' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
				"unit 't5' before label 'nxa.one' op OP_INSERT\n"
				"unit 't5' before label 'nxa._END_' op OP_INSERT\n"
				"unit 't5' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}
	}

	// ----------------------------------------------------------------------

	// send a row through with an explicit BEGIN/END

	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_NOP, r0));
	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));
	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_NOP, r0));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));

	// same on ow4
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_NOP, r0));
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_NOP, r0));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));

	for (int i = 0; i < 2; i++) {
		UT_ASSERT(ow2->nextXtray());
		{
			string tlog = trace2->getBuffer()->print();
			trace2->clearBuffer();
			string expect =
				"unit 't2' before label 'nxa._BEGIN_' op OP_NOP\n"
				"unit 't2' before label 'nxa.one' op OP_INSERT\n"
				"unit 't2' before label 'nxa._END_' op OP_NOP\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		UT_ASSERT(ow3->nextXtray());
		{
			string tlog = trace3->getBuffer()->print();
			trace3->clearBuffer();
			string expect =
				"unit 't3' before label 'nxa._BEGIN_' op OP_NOP\n"
				"unit 't3' before label 'begin' (chain 'nxa._BEGIN_') op OP_NOP\n"
				"unit 't3' before label 'nxa.one' op OP_INSERT\n"
				"unit 't3' before label 'nxa._END_' op OP_NOP\n"
				"unit 't3' before label 'end' (chain 'nxa._END_') op OP_NOP\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		UT_ASSERT(ow5->nextXtray());
		{
			string tlog = trace5->getBuffer()->print();
			trace5->clearBuffer();
			string expect =
				"unit 't5' before label 'nxa._BEGIN_' op OP_NOP\n"
				"unit 't5' before label 'begin' (chain 'nxa._BEGIN_') op OP_NOP\n"
				"unit 't5' before label 'nxa.one' op OP_INSERT\n"
				"unit 't5' before label 'nxa._END_' op OP_NOP\n"
				"unit 't5' before label 'end' (chain 'nxa._END_') op OP_NOP\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}
	}

	// ----------------------------------------------------------------------

	// send a row through with the BEGIN/END that carry data

	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_INSERT, r1));
	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));
	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r1));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));

	// same on ow4
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_BEGIN_"), 
		Rowop::OP_INSERT, r1));
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("one"), 
		Rowop::OP_INSERT, r1));
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r1));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa4a->getFnReturn()));

	for (int i = 0; i < 2; i++) {
		UT_ASSERT(ow2->nextXtray());
		{
			string tlog = trace2->getBuffer()->print();
			trace2->clearBuffer();
			string expect =
				"unit 't2' before label 'nxa._BEGIN_' op OP_INSERT\n"
				"unit 't2' before label 'nxa.one' op OP_INSERT\n"
				"unit 't2' before label 'nxa._END_' op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		UT_ASSERT(ow3->nextXtray());
		{
			string tlog = trace3->getBuffer()->print();
			trace3->clearBuffer();
			string expect =
				"unit 't3' before label 'nxa._BEGIN_' op OP_INSERT\n"
				"unit 't3' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
				"unit 't3' before label 'nxa.one' op OP_INSERT\n"
				"unit 't3' before label 'nxa._END_' op OP_INSERT\n"
				"unit 't3' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		UT_ASSERT(ow5->nextXtray());
		{
			string tlog = trace5->getBuffer()->print();
			trace5->clearBuffer();
			string expect =
				"unit 't5' before label 'nxa._BEGIN_' op OP_INSERT\n"
				"unit 't5' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
				"unit 't5' before label 'nxa.one' op OP_INSERT\n"
				"unit 't5' before label 'nxa._END_' op OP_INSERT\n"
				"unit 't5' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}
	}

	// ----------------------------------------------------------------------

	// send just an END with data

	unit1->call(new Rowop(fa1a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r1));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa1a->getFnReturn()));

	// same on ow4
	unit4->call(new Rowop(fa4a->getFnReturn()->getLabel("_END_"), 
		Rowop::OP_INSERT, r1));
	// _END_ flushes the writer
	UT_ASSERT(FnReturnGuts::isXtrayEmpty(fa4a->getFnReturn()));

	for (int i = 0; i < 2; i++) {
		UT_ASSERT(ow2->nextXtray());
		{
			string tlog = trace2->getBuffer()->print();
			trace2->clearBuffer();
			string expect =
				"unit 't2' before label 'nxa._END_' op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		UT_ASSERT(ow3->nextXtray());
		{
			string tlog = trace3->getBuffer()->print();
			trace3->clearBuffer();
			string expect =
				"unit 't3' before label 'nxa._BEGIN_' op OP_INSERT\n"
				"unit 't3' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
				"unit 't3' before label 'nxa._END_' op OP_INSERT\n"
				"unit 't3' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}

		UT_ASSERT(ow5->nextXtray());
		{
			string tlog = trace5->getBuffer()->print();
			trace5->clearBuffer();
			string expect =
				"unit 't5' before label 'nxa._BEGIN_' op OP_INSERT\n"
				"unit 't5' before label 'begin' (chain 'nxa._BEGIN_') op OP_INSERT\n"
				"unit 't5' before label 'nxa._END_' op OP_INSERT\n"
				"unit 't5' before label 'end' (chain 'nxa._END_') op OP_INSERT\n"
			;
			if (UT_IS(tlog, expect)) printf("Pass %d Expected: \"%s\"\n", i, expect.c_str());
		}
	}

	// ----------------------------------------------------------------------

	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	ow5->markDead();
	a1->harvester();

	restore_uncatchable();
}
