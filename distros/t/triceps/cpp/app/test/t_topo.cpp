//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the App topology checking.

#include <utest/Utest.h>
#include <type/AllTypes.h>
#include "AppTest.h"

// construction of a graph
UTESTCASE mkgraph(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Triead *t1 = ow1->get();
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Triead *t2 = ow2->get();

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	Nexus *nx1 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	Nexus *nx2 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	
	// now build the graph
	{
		AppGuts::Graph g;
		AppGuts::NxTr *node;

		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		UT_IS(tnode1->tr_, t1);
		UT_IS(tnode1->nx_, NULL);
		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode1->mark_, false);
		UT_ASSERT(tnode1->links_.empty());

		node = g.addTriead(t1); // following additions return the same node
		UT_IS(node, tnode1);

		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		UT_ASSERT(tnode2 != tnode1);

		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		UT_IS(nnode1->tr_, NULL);
		UT_IS(nnode1->nx_, nx1);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(tnode1->mark_, false);
		UT_ASSERT(nnode1->links_.empty());

		node = g.addNexus(nx1); // following additions return the same node
		UT_IS(node, nnode1);

		AppGuts::NxTr *nnode2 = g.addNexus(nx2);
		UT_ASSERT(nnode2 != nnode1);

		// this really should not be mixed in the same graph
		// but it's fine for a test
		AppGuts::NxTr *cnode1 = g.addCopy(tnode1);
		UT_IS(cnode1->tr_, t1);
		UT_IS(cnode1->nx_, NULL);
		UT_IS(cnode1->ninc_, 0);
		UT_IS(tnode1->mark_, false);
		UT_ASSERT(cnode1->links_.empty());

		node = g.addCopy(tnode1); // following additions return the same node
		UT_IS(node, cnode1);

		AppGuts::NxTr *cnode2 = g.addCopy(nnode2);
		UT_IS(cnode2->tr_, NULL);
		UT_IS(cnode2->nx_, nx2);
		UT_ASSERT(cnode2 != cnode1);

		UT_IS(g.m_.size(), 6);
		UT_IS(g.l_.size(), 6);

		// printing
		UT_IS(tnode1->print(), "thread 't1'");
		UT_IS(nnode1->print(), "nexus 't1/nx1'");

		// connect the nodes
		tnode1->addLink(nnode1);
		UT_IS(tnode1->links_.size(), 1);
		UT_IS(tnode1->links_.back(), nnode1);
		UT_IS(nnode1->ninc_, 1);

		tnode1->addLink(nnode2);
		UT_IS(tnode1->links_.size(), 2);
		UT_IS(tnode1->links_.back(), nnode2);
		UT_IS(nnode1->ninc_, 1);

		tnode2->addLink(nnode1);
		UT_IS(tnode2->links_.size(), 1);
		UT_IS(tnode2->links_.back(), nnode1);
		UT_IS(nnode1->ninc_, 2);
	}

	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// reduction of the non-loop incoming twigs from the graph
UTESTCASE reduce(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Triead *t1 = ow1->get();
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Triead *t2 = ow2->get();
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Triead *t3 = ow3->get();
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");
	Triead *t4 = ow4->get();

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	Nexus *nx1 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	Nexus *nx2 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	Nexus *nx3 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx3")->addLabel("one", rt1)))->nexus();
	Nexus *nx4 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx4")->addLabel("one", rt1)))->nexus();

	// now build the graphs and reduce them
	
	// a disconnected graph
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		AppGuts::reduceGraphL(g); // a no-op here

		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(nnode2->ninc_, 0);
	}
	// a straight line
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		nnode1->addLink(tnode2);
		tnode2->addLink(nnode2);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(nnode2->ninc_, 0);
	}
	// a fork
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		tnode1->addLink(nnode2);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(nnode2->ninc_, 0);
	}
	// a join
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		tnode2->addLink(nnode1);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(nnode2->ninc_, 0);
	}
	// a join and a straight (Y-shaped)
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *tnode3 = g.addTriead(t3);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		tnode2->addLink(nnode1);
		nnode1->addLink(tnode3);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(tnode3->ninc_, 0);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(nnode2->ninc_, 0);
	}
	// a diamond
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		tnode1->addLink(nnode2);
		nnode1->addLink(tnode2);
		nnode2->addLink(tnode2);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(nnode2->ninc_, 0);
	}
	// an X
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *tnode3 = g.addTriead(t3);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		tnode2->addLink(nnode1);
		nnode1->addLink(tnode3);
		nnode1->addLink(nnode2); // not realistic but doesn't matter here

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 0);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(tnode3->ninc_, 0);
		UT_IS(nnode1->ninc_, 0);
		UT_IS(nnode2->ninc_, 0);
	}
	// a simple loop
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		nnode1->addLink(tnode1);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 1);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(nnode1->ninc_, 1);
		UT_IS(nnode2->ninc_, 0);
	}
	// a simple loop with a tail
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		nnode1->addLink(tnode1);
		nnode1->addLink(tnode2);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 1);
		UT_IS(tnode2->ninc_, 1); // tail will stay
		UT_IS(nnode1->ninc_, 1);
		UT_IS(nnode2->ninc_, 0);
	}
	// a simple loop with a incoming links
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		nnode1->addLink(tnode1);
		tnode2->addLink(nnode1);
		nnode2->addLink(tnode1);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 1);
		UT_IS(tnode2->ninc_, 0);
		UT_IS(nnode1->ninc_, 1);
		UT_IS(nnode2->ninc_, 0);
	}
	// a longer loop
	{
		AppGuts::Graph g;
		AppGuts::NxTr *tnode1 = g.addTriead(t1);
		AppGuts::NxTr *tnode2 = g.addTriead(t2);
		AppGuts::NxTr *nnode1 = g.addNexus(nx1);
		AppGuts::NxTr *nnode2 = g.addNexus(nx2);

		tnode1->addLink(nnode1);
		nnode1->addLink(tnode2);
		tnode2->addLink(nnode2);
		nnode2->addLink(tnode1);

		AppGuts::reduceGraphL(g);

		UT_IS(tnode1->ninc_, 1);
		UT_IS(tnode2->ninc_, 1);
		UT_IS(nnode1->ninc_, 1);
		UT_IS(nnode2->ninc_, 1);
	}
	// a horizontal figure 8 of 2 diamonds
	{
		AppGuts::Graph g;

		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addTriead(t1)->addLink(g.addNexus(nx2));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addNexus(nx2)->addLink(g.addTriead(t2));

		g.addTriead(t3)->addLink(g.addNexus(nx2));
		g.addTriead(t3)->addLink(g.addNexus(nx3));
		g.addNexus(nx2)->addLink(g.addTriead(t4));
		g.addNexus(nx3)->addLink(g.addTriead(t4));

		AppGuts::reduceGraphL(g);

		UT_IS(g.addTriead(t1)->ninc_, 0);
		UT_IS(g.addTriead(t2)->ninc_, 0);
		UT_IS(g.addTriead(t3)->ninc_, 0);
		UT_IS(g.addTriead(t4)->ninc_, 0);
		UT_IS(g.addNexus(nx1)->ninc_, 0);
		UT_IS(g.addNexus(nx2)->ninc_, 0);
		UT_IS(g.addNexus(nx3)->ninc_, 0);
	}
	// a vertical figure 8 of 2 diamonds
	{
		AppGuts::Graph g;

		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addTriead(t1)->addLink(g.addNexus(nx2));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addNexus(nx2)->addLink(g.addTriead(t2));

		g.addTriead(t2)->addLink(g.addNexus(nx3));
		g.addTriead(t2)->addLink(g.addNexus(nx4));
		g.addNexus(nx3)->addLink(g.addTriead(t3));
		g.addNexus(nx4)->addLink(g.addTriead(t3));

		AppGuts::reduceGraphL(g);

		UT_IS(g.addTriead(t1)->ninc_, 0);
		UT_IS(g.addTriead(t2)->ninc_, 0);
		UT_IS(g.addTriead(t3)->ninc_, 0);
		UT_IS(g.addTriead(t4)->ninc_, 0);
		UT_IS(g.addNexus(nx1)->ninc_, 0);
		UT_IS(g.addNexus(nx2)->ninc_, 0);
		UT_IS(g.addNexus(nx3)->ninc_, 0);
		UT_IS(g.addNexus(nx4)->ninc_, 0);
	}
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// detection and printing of a graph that has been already reduced
UTESTCASE check(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Triead *t1 = ow1->get();
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Triead *t2 = ow2->get();
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Triead *t3 = ow3->get();
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");
	Triead *t4 = ow4->get();

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	Nexus *nx1 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	Nexus *nx2 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	Nexus *nx3 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx3")->addLabel("one", rt1)))->nexus();
	Nexus *nx4 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx4")->addLabel("one", rt1)))->nexus();

	// a disconnected graph
	{
		AppGuts::Graph g;
		g.addTriead(t1);
		g.addTriead(t2);
		g.addTriead(t3);
		g.addTriead(t4);
		g.addNexus(nx1);
		g.addNexus(nx2);
		g.addNexus(nx3);
		g.addNexus(nx4);

		a1->checkGraphL(g, "direct"); // no loop, no Exception
	}
	// a simple loop
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addNexus(nx1)->addLink(g.addTriead(t1));

		{
			string msg;
			try {
				a1->checkGraphL(g, "direct");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, 
				"In application 'a1' detected an illegal direct loop:\n"
				"  thread 't1'\n"
				"  nexus 't1/nx1'\n"
				"  thread 't1'\n");
		}
	}
	// a longer loop
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addTriead(t2)->addLink(g.addNexus(nx2));
		g.addNexus(nx2)->addLink(g.addTriead(t1));

		{
			string msg;
			try {
				a1->checkGraphL(g, "direct");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, // printed in opposite direction
				"In application 'a1' detected an illegal direct loop:\n"
				"  thread 't2'\n"
				"  nexus 't1/nx2'\n"
				"  thread 't1'\n"
				"  nexus 't1/nx1'\n"
				"  thread 't2'\n");
		}
	}
	// a figure 8 of 2 touching loops
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addTriead(t2)->addLink(g.addNexus(nx2));

		g.addTriead(t3)->addLink(g.addNexus(nx2));
		g.addNexus(nx2)->addLink(g.addTriead(t4));
		g.addTriead(t4)->addLink(g.addNexus(nx3));
		g.addNexus(nx3)->addLink(g.addTriead(t3));

		// this link goes last, so that the walk by the first link
		// would never get back to t1
		g.addNexus(nx2)->addLink(g.addTriead(t1));

		{
			string msg;
			try {
				a1->checkGraphL(g, "reverse");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, // printed in opposite direction
				"In application 'a1' detected an illegal reverse loop:\n"
				"  thread 't4'\n"
				"  nexus 't1/nx3'\n"
				"  thread 't3'\n"
				"  nexus 't1/nx2'\n"
				"  thread 't4'\n");
		}
	}
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// the full reduction and check run
UTESTCASE reduce_check_graph(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Triead *t1 = ow1->get();
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Triead *t2 = ow2->get();
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Triead *t3 = ow3->get();
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");
	Triead *t4 = ow4->get();

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	Nexus *nx1 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	Nexus *nx2 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	Nexus *nx3 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx3")->addLabel("one", rt1)))->nexus();
	Nexus *nx4 = ow1->exportNexus(Facet::makeReader(
		FnReturn::make(ow1->unit(), "nx4")->addLabel("one", rt1)))->nexus();

	// a disconnected graph
	{
		AppGuts::Graph g;
		g.addTriead(t1);
		g.addTriead(t2);
		g.addTriead(t3);
		g.addTriead(t4);
		g.addNexus(nx1);
		g.addNexus(nx2);
		g.addNexus(nx3);
		g.addNexus(nx4);

		a1->reduceCheckGraphL(g, "direct");
	}
	// a diamond
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addTriead(t1)->addLink(g.addNexus(nx2));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addNexus(nx2)->addLink(g.addTriead(t2));

		a1->reduceCheckGraphL(g, "direct");
	}
	// a diamond with a tail
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addTriead(t1)->addLink(g.addNexus(nx2));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addNexus(nx2)->addLink(g.addTriead(t2));
		g.addTriead(t2)->addLink(g.addNexus(nx3));

		a1->reduceCheckGraphL(g, "direct");
	}
	// a horizontal figure 8
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addTriead(t1)->addLink(g.addNexus(nx2));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addNexus(nx2)->addLink(g.addTriead(t2));

		g.addTriead(t3)->addLink(g.addNexus(nx2));
		g.addTriead(t3)->addLink(g.addNexus(nx3));
		g.addNexus(nx2)->addLink(g.addTriead(t4));
		g.addNexus(nx3)->addLink(g.addTriead(t4));

		a1->reduceCheckGraphL(g, "direct");
	}
	// a vertical figure 8 of 2 diamonds
	{
		AppGuts::Graph g;

		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addTriead(t1)->addLink(g.addNexus(nx2));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addNexus(nx2)->addLink(g.addTriead(t2));

		g.addTriead(t2)->addLink(g.addNexus(nx3));
		g.addTriead(t2)->addLink(g.addNexus(nx4));
		g.addNexus(nx3)->addLink(g.addTriead(t3));
		g.addNexus(nx4)->addLink(g.addTriead(t3));

		a1->reduceCheckGraphL(g, "direct");
	}
	// a simple loop
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addNexus(nx1)->addLink(g.addTriead(t1));

		{
			string msg;
			try {
				a1->reduceCheckGraphL(g, "direct");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, 
				"In application 'a1' detected an illegal direct loop:\n"
				"  thread 't1'\n"
				"  nexus 't1/nx1'\n"
				"  thread 't1'\n"
				);
		}
	}
	// a longer loop
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addTriead(t2)->addLink(g.addNexus(nx2));
		g.addNexus(nx2)->addLink(g.addTriead(t1));

		{
			string msg;
			try {
				a1->reduceCheckGraphL(g, "direct");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, // printed in opposite direction
				"In application 'a1' detected an illegal direct loop:\n"
				"  thread 't1'\n"
				"  nexus 't1/nx2'\n"
				"  thread 't2'\n"
				"  nexus 't1/nx1'\n"
				"  thread 't1'\n"
				);
		}
	}
	// a longer loop, with incoming and outgoing twigs
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addTriead(t2)->addLink(g.addNexus(nx2));
		g.addNexus(nx2)->addLink(g.addTriead(t1));

		// here are the twigs
		g.addNexus(nx4)->addLink(g.addTriead(t1));
		g.addTriead(t3)->addLink(g.addNexus(nx1));
		g.addNexus(nx2)->addLink(g.addTriead(t4));
		g.addTriead(t4)->addLink(g.addNexus(nx3));

		{
			string msg;
			try {
				a1->reduceCheckGraphL(g, "direct");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, // printed in opposite direction
				"In application 'a1' detected an illegal direct loop:\n"
				"  thread 't1'\n"
				"  nexus 't1/nx2'\n"
				"  thread 't2'\n"
				"  nexus 't1/nx1'\n"
				"  thread 't1'\n");
		}
	}
	// a figure 8 of 2 touching loops
	{
		AppGuts::Graph g;
		g.addTriead(t1)->addLink(g.addNexus(nx1));
		g.addNexus(nx1)->addLink(g.addTriead(t2));
		g.addTriead(t2)->addLink(g.addNexus(nx2));
		g.addNexus(nx2)->addLink(g.addTriead(t1));

		g.addTriead(t3)->addLink(g.addNexus(nx2));
		g.addNexus(nx2)->addLink(g.addTriead(t4));
		g.addTriead(t4)->addLink(g.addNexus(nx3));
		g.addNexus(nx3)->addLink(g.addTriead(t3));

		{
			string msg;
			try {
				a1->reduceCheckGraphL(g, "reverse");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, // printed in opposite direction
				"In application 'a1' detected an illegal reverse loop:\n"
				"  thread 't1'\n"
				"  nexus 't1/nx2'\n"
				"  thread 't2'\n"
				"  nexus 't1/nx1'\n"
				"  thread 't1'\n"
				);
		}
	}
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// full-blown check, a horizontal figure 8 of 2 diamonds
UTESTCASE check_loops_diamond_horiz(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	//      t1      t2
	// nx1<   >nx2<   >nx3
	//      t3      t4
	ow1->exportNexus(Facet::makeWriter(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	ow1->exportNexus(Facet::makeWriter(
		FnReturn::make(ow1->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	ow2->exportNexus(Facet::makeWriter(
		FnReturn::make(ow2->unit(), "nx3")->addLabel("one", rt1)))->nexus();

	ow2->importWriterImmed("t1", "nx2");
	ow3->importReaderImmed("t1", "nx1");
	ow3->importReaderImmed("t1", "nx2");
	ow4->importReaderImmed("t1", "nx2");
	ow4->importReaderImmed("t2", "nx3");

	a1->checkLoopsL("t1");
	UT_ASSERT(!a1->isAborted());
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// full-blown check, a vertical figure 8 of 2 diamonds
UTESTCASE check_loops_diamond_vert(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	//      t1
	//  nx1<  >nx2
	//      t2
	//  nx3<  >nx4
	//      t3
	ow1->exportNexus(Facet::makeWriter(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	ow1->exportNexus(Facet::makeWriter(
		FnReturn::make(ow1->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	ow2->exportNexus(Facet::makeWriter(
		FnReturn::make(ow2->unit(), "nx3")->addLabel("one", rt1)))->nexus();
	ow2->exportNexus(Facet::makeWriter(
		FnReturn::make(ow2->unit(), "nx4")->addLabel("one", rt1)))->nexus();

	ow2->importReaderImmed("t1", "nx1");
	ow2->importReaderImmed("t1", "nx2");
	ow3->importReaderImmed("t2", "nx3");
	ow3->importReaderImmed("t2", "nx4");

	a1->checkLoopsL("t1");
	UT_ASSERT(!a1->isAborted());
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// full-blown check, two touching loops
UTESTCASE check_loops_touching(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	ow1->exportNexus(Facet::makeWriter(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	ow2->importReaderImmed("t1", "nx1");
	ow2->exportNexus(Facet::makeWriter(
		FnReturn::make(ow2->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	ow1->importReaderImmed("t2", "nx2");

	ow3->importWriterImmed("t2", "nx2");
	ow4->importReaderImmed("t2", "nx2");
	ow4->exportNexus(Facet::makeWriter(
		FnReturn::make(ow4->unit(), "nx3")->addLabel("one", rt1)))->nexus();
	ow3->importReaderImmed("t4", "nx3");

	{
		string msg;
		try {
			a1->checkLoopsL("t1");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, // printed in opposite direction
			"In application 'a1' detected an illegal direct loop:\n"
			"  thread 't1'\n"
			"  nexus 't1/nx1'\n"
			"  thread 't2'\n"
			"  nexus 't2/nx2'\n"
			"  thread 't1'\n"
			);
		UT_IS(a1->getAbortedBy(), "t1");
		UT_IS(a1->getAbortedMsg(), msg);
	}
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// full-blown check, one loop with twigs
UTESTCASE check_loops_twigs(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	ow1->exportNexus(Facet::makeWriter(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1))->setReverse())->nexus();
	// ow2 is an outgoing twig
	ow2->importReaderImmed("t1", "nx1");
	ow2->exportNexus(Facet::makeWriter(
		FnReturn::make(ow2->unit(), "nx2")->addLabel("one", rt1))->setReverse())->nexus();

	// ow3 continues the loop
	ow3->importReaderImmed("t1", "nx1");
	ow3->exportNexus(Facet::makeWriter(
		FnReturn::make(ow3->unit(), "nx3")->addLabel("one", rt1))->setReverse())->nexus();
	ow1->importReaderImmed("t3", "nx3");

	// ow4 is an incoming twig
	ow4->exportNexus(Facet::makeWriter(
		FnReturn::make(ow4->unit(), "nx4")->addLabel("one", rt1))->setReverse())->nexus();
	ow1->importReaderImmed("t4", "nx4");
	ow3->importReaderImmed("t4", "nx4");

	{
		string msg;
		try {
			a1->checkLoopsL("t1");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, // printed in opposite direction
			"In application 'a1' detected an illegal reverse loop:\n"
			"  thread 't1'\n"
			"  nexus 't1/nx1'\n"
			"  thread 't3'\n"
			"  nexus 't3/nx3'\n"
			"  thread 't1'\n");
		UT_IS(a1->getAbortedBy(), "t1");
		UT_IS(a1->getAbortedMsg(), msg);
	}
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// full-blown check, two touching loops, but with a reverse-direction
// breaking up one loop
UTESTCASE check_loops_twodir(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	// same as check_loops_touching() except for one nexus marked reverse
	ow1->exportNexus(Facet::makeWriter( // setReverse breaks up the 1st loop
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1))->setReverse())->nexus();
	ow2->importReaderImmed("t1", "nx1");
	ow2->exportNexus(Facet::makeWriter(
		FnReturn::make(ow2->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	ow1->importReaderImmed("t2", "nx2");

	ow3->importWriterImmed("t2", "nx2");
	ow4->importReaderImmed("t2", "nx2");
	ow4->exportNexus(Facet::makeWriter(
		FnReturn::make(ow4->unit(), "nx3")->addLabel("one", rt1)))->nexus();
	ow3->importReaderImmed("t4", "nx3");

	{
		string msg;
		try {
			a1->checkLoopsL("t1");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, // printed in opposite direction
			"In application 'a1' detected an illegal direct loop:\n"
			"  thread 't4'\n"
			"  nexus 't4/nx3'\n"
			"  thread 't3'\n"
			"  nexus 't2/nx2'\n"
			"  thread 't4'\n");
		UT_IS(a1->getAbortedBy(), "t1");
		UT_IS(a1->getAbortedMsg(), msg);
	}
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// full-blown check triggered on Ready mark, two touching loops
UTESTCASE check_ready(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	ow1->exportNexus(Facet::makeWriter(
		FnReturn::make(ow1->unit(), "nx1")->addLabel("one", rt1)))->nexus();
	ow2->importReaderImmed("t1", "nx1");
	ow2->exportNexus(Facet::makeWriter(
		FnReturn::make(ow2->unit(), "nx2")->addLabel("one", rt1)))->nexus();
	ow1->importReaderImmed("t2", "nx2");

	ow3->importWriterImmed("t2", "nx2");
	ow4->importReaderImmed("t2", "nx2");
	ow4->exportNexus(Facet::makeWriter(
		FnReturn::make(ow4->unit(), "nx3")->addLabel("one", rt1)))->nexus();
	ow3->importReaderImmed("t4", "nx3");

	ow1->markReady();
	ow2->markReady();
	ow3->markReady();
	{
		string msg;
		try {
			ow4->markReady();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, // printed in opposite direction
			"In application 'a1' detected an illegal direct loop:\n"
			"  thread 't1'\n"
			"  nexus 't1/nx1'\n"
			"  thread 't2'\n"
			"  nexus 't2/nx2'\n"
			"  thread 't1'\n"
			);
		UT_IS(a1->getAbortedBy(), "t4");
		UT_IS(a1->getAbortedMsg(), msg);
	}
	
	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	ow4->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// full-blown check triggered on Dead mark, two touching loops
UTESTCASE check_dead(Utest *utest)
{
	make_catchable();

	Autoref<AppGuts> a1 = (AppGuts *)App::make("a1").get();

	// these threads and nexuses will be just used as graph fodder,
	// nothing more;
	// the connections don't matter because the graphs will be connected manually
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");

	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	ow1->makeNexusWriter("nx1")
		->addLabel("one", rt1)
		->complete();
	ow2->importReaderImmed("t1", "nx1");
	ow2->makeNexusWriter("nx2")
		->addLabel("one", rt1)
		->complete();
	ow1->importReaderImmed("t2", "nx2");

	ow3->importWriterImmed("t2", "nx2");
	ow4->importReaderImmed("t2", "nx2");
	ow4->makeNexusWriter("nx3")
		->addLabel("one", rt1)
		->complete();
	ow3->importReaderImmed("t4", "nx3");

	// clean-up, since the apps catalog is global
	ow1->markReady();
	ow2->markReady();
	ow3->markReady();
	ow4->markDead(); // does NOT throw!!!
	UT_IS(a1->getAbortedBy(), "t4");
	UT_IS(a1->getAbortedMsg(),
		"In application 'a1' detected an illegal direct loop:\n"
		"  thread 't1'\n"
		"  nexus 't1/nx1'\n"
		"  thread 't2'\n"
		"  nexus 't2/nx2'\n"
		"  thread 't1'\n"
		);
	ow1->markDead();
	ow2->markDead();
	ow3->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// XXX add a test with real threads
