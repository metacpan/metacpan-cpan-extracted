//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The control interface and object for the Triceps Thread.

#ifndef __Triceps_TrieadOwner_h__
#define __Triceps_TrieadOwner_h__

#include <app/Triead.h>
#include <app/App.h>
#include <app/Facet.h>
#include <app/FileInterrupt.h>

namespace TRICEPS_NS {

// This is a special interface class that opens up the control API
// of the Triead to a single thread that owns it. The Triead and TrieadOwner
// creation is wrapped even farther, through App. The owner class is an Starget
// by design, it must be accessible to one thread only. 
//
// Also includes all the control information that should not be visible
// from outside the owner thread.
//
// And also includes a reference to the App. This allows to avoid the reference
// loops, with references going in the direction TrieadOwner->App->Triead.
//
// When the TrieadOwner is destroyed, the Triead gets marked as dead
// and gets cleared and disconnected from the App (but not disposed of until
// the reference count goes to 0).
class TrieadOwner : public Starget
{
	friend class App;
	
protected:
	// An intermediate helper object for convenience of making the nexuses.
	// It's protected, so the end-users can only call it in a chained
	// fashion.
	// It's really a syntactic sugar, so if you're building a facet non-chained,
	// just build it directly, without this helper.
	class NexusMaker
	{
		friend class TrieadOwner;
		friend class TrieadOwnerGuts;
	public:
		// This is a combination of construction methods from FnReturn and Facet.
		// Obviously, the return type differs, for chaining of the calls.
		// When the first Facet method is called, the FnReturn part
		// becomes initialized and can not be called any more.
		//
		// The chain must always end in 
		//   ->complete();
		// or the built-up facet will be simply thrown away.

		// from FnReturn
		NexusMaker *addFromLabel(const string &lname, Autoref<Label>from)
		{
			fret_->addFromLabel(lname, from);
			return this;
		}
		NexusMaker *addLabel(const string &lname, const_Autoref<RowType>rtype)
		{
			fret_->addLabel(lname, rtype);
			return this;
		}
		// Very unlikely to be needed but just in case.
		NexusMaker *setContext(Onceref<FnContext> ctx)
		{
			fret_->setContext(ctx);
			return this;
		}

		// from Facet
		NexusMaker *exportRowType(const string &name, Onceref<RowType> rtype)
		{
			mkfacet();
			facet_->exportRowType(name, rtype);
			return this;
		}
		NexusMaker *exportTableType(const string &name, Onceref<TableType> tt)
		{
			mkfacet();
			facet_->exportTableType(name, tt);
			return this;
		}
		NexusMaker *setReverse(bool on = true)
		{
			mkfacet();
			facet_->setReverse(on);
			return this;
		}

#if 0  // {
		NexusMaker *setUnicast(bool on = true)
		{
			mkfacet();
			facet_->setUnicast(on);
			return this;
		}
#endif // }

		NexusMaker *setQueueLimit(int limit)
		{
			mkfacet();
			facet_->setQueueLimit(limit);
			return this;
		}

		// Actually exports the facet and returns it.
		// After that the object doesn't have an FnReturn not a Facet in it.
		Autoref<Facet> complete();

	protected:
		NexusMaker(TrieadOwner *ow): // only the TrieadOwner can create it
			ow_(ow)
		{ }

		// Initialize for a new run
		void init(Unit *unit, const string &name, bool writer, bool import);

		// If the facet has not been created yet, creates it.
		void mkfacet();

		Autoref<FnReturn> fret_;
		Autoref<Facet> facet_;
		TrieadOwner *ow_; // owner of this maker
		bool writer_; // the facet will be a writer
		bool import_; // the facet will be imported back

	private:
		NexusMaker();
		NexusMaker(const NexusMaker &);
		void operator=(const NexusMaker &);
	};
	
public:
	typedef Triead::NexusMap NexusMap;
	typedef Triead::FacetMap FacetMap;

	// The list of units in this thread, also determines their predictable
	// scheduling order.
	typedef list<Autoref<Unit> > UnitList;

	// The constructor is protected, called through App.
	// The destruction clears labels in all the thread's units.
	~TrieadOwner();

	// Get the owned Triead.
	// Reasonably safe to assume that the TrieadOwner should be long-lived
	// and will survive any use of the returned pointer (at least until it
	// gets stored into another Autoref), and will hold the Triead in the
	// meantime. As a consequence, don't break this assumption, don't release
	// and destory the TrieadOwner until you're done with the returned pointer!
	Triead *get() const
	{
		return triead_.get();
	}

	// Get the App where this thread belongs.
	App *app() const
	{
		return app_.get();
	}

	// Check whether the thread was requested to die.
	bool isRqDead() const
	{
		return triead_->rqDead_;
	}

	// The way to disconnect from the nexuses while the thread is
	// exiting on its own. For example, if it's going to dump its
	// data to a large file that takes half an hour to write,
	// it's a bad practice to keep the other threads stuck due to the
	// overflowing buffers. Marking the thread dead before writing
	// is also not a good idea beceuse it will keep the join() stuck.
	// So this call provides the solution.
	void requestMyselfDead()
	{
		triead_->requestDead();
	}

	// Get the main unit that get created with the thread and shares its name.
	// Assumes that TrieadOwner won't be destroyed while the result is used.
	Unit *unit() const
	{
		return mainUnit_;
	}

	// Add a unit to the thread, it's OK if it has been already added 
	// (extra addition will be ignored).
	// There is no easy way to find it back other than going through the
	// list of all the known units, so keep your own reference too.
	// @param u - unit to register.
	void addUnit(Autoref<Unit> u);

	// Forget a unit and remove it from the list.
	// The main unit can not be forgotten.
	// @param u - unit to forget
	// @return - true if unit was successfully forgotten, false if the unit was
	//     not known or is the main unit
	bool forgetUnit(Unit *u);

	// Get the list of all the units, in the order they were added.
	// This includes the main unit in the first position.
	const UnitList &listUnits() const
	{
		return units_;
	}

	// Mark that the thread has constructed and exported all of its
	// nexuses.
	void markConstructed()
	{
		app_->markTrieadConstructed(this);
	}

	// Mark that the thread has completed all its connections and
	// is ready to run. This also implies Constructed, and can be
	// used to set both flags at once.
	//
	// The last thread marked ready triggers the check of the
	// App topology that may throw an Exception.
	void markReady()
	{
		app_->markTrieadReady(this);
	}

	// Mark the thread as ready, and wait for all the threads in
	// the app to become ready.
	//
	// The last thread marked ready triggers the check of the
	// App topology that may throw an Exception.
	void readyReady();

	// Abort the thread and with it the whole app.
	// Typically used if a fatal error is found during initialization.
	// @param msg - message that can communicate the reason fo abort
	void abort(const string &msg) const
	{
		app_->abortBy(triead_->getName(), msg);
	}

	// Mark the thread as dead and free its resources.
	// It's automatically called as a part of TrieadOwner destructor,
	// so normally there should be no need to call it manually.
	// Unless you have some other weird references to TrieadOwner
	// and really want to mark the death right now.
	//
	// This also deletes the references to the units, including the
	// main unit.
	//
	// If the thread was not ready before, it will be marked
	// ready now, and if it was the last one to become ready,
	// that will trigger the loop check in the App. However
	// if a loop is found and an Exception is thrown, it will
	// be caught and ignored. However the App will still be
	// marked aborted.
	//
	// And it triggers the thread join by the harvester, so the
	// OS-level theread should exit soon.
	void markDead();

	// Find a thread by name.
	// Will wait if the thread has not completed its construction yet.
	// If the thread refers to itself (i.e. the name is of the same thread
	// owner), returns the thread back even if it's not fully constructed yet.
	//
	// Throws an Exception if no such thread is declared nor made,
	// or the thread is declared but not constructed within the App timeout.
	//
	// @param tname - name of the thread to find
	// @param immed - flag: find immediate, which means that the thread will be
	//        returned even if it's not constructed yet and there will never be
	//        a wait, so if the thread is declared but not defined yet, an Exception
	//        will be thrown
	Onceref<Triead> findTriead(const string &tname, bool immed = false)
	{
		return app_->findTriead(this, tname, immed);
	}

	// Export a nexus in this thread.
	// Throws an Exception on any errors are found (such as errors in the
	// facet or a duplicate name).
	//
	// If this thread was already requested to die, the facet will
	// be left in a semi-imported state: it will be marked as imported for
	// the thread's code benefit but won't actually be connected to the
	// nexus nor show in the list of imports nor facets.
	//
	// @param facet - Facet used to create the Nexus. Its name will also
	//        determine the Nexus'es name in the thread.
	// @param import - flag: import the nexus right back through the
	//        same facet and make it available to the constructing thread.
	//        If false, the facet will be left un-imported, and can be
	//        discarded.
	// @return - the same facet, for a convenient chaining of the calls, like:
	//        Autoref<Facet> myfacet = to->exportNexus(
	//            Facet::makeWriter(FnReturn::make("My")->...)
	//            ->setReverse()
	//            ->exportTableType(Table::make(...)->...)
	//        );
	Onceref<Facet> exportNexus(Autoref<Facet> facet, bool import = true);
	// A syntactic sugar: export with no automatic re-import.
	Onceref<Facet> exportNexusNoImport(Autoref<Facet> facet)
	{
		return exportNexus(facet, false);
	}

	// Import a nexus from a thread by name, producing its local facet.
	//
	// The facet will have its FnReturn created in the thread's main unit.
	//
	// If this thread was already requested to die, the facet will
	// be left in a semi-imported state: it will be marked as imported for
	// the thread's code benefit but won't actually be connected to the
	// nexus nor show in the list of imports nor facets.
	//
	// If this nexus has been already imported, will return the previously
	// imported copy. The as-name and the direction (read or write) must match
	// or an Exception will not be throw. You may not import the same nexus
	// for both reading and writing into the same thread.
	//
	// Normally will wait if the thread has not completed its construction yet.
	// The target thread must be at least declared, or the import will fail right away.
	//
	// But if the immediate flag is set, the wait for construction is skipped
	// and the nexus is looked up in the thread immediately. If the thread or
	// nexus in it has not been defined yet, the immediate import will fail.
	// If the thread refers to itself (i.e. the name is of the same thread
	// as this thread owner), it always works as immediate.
	//
	// Throws an Exception if no such nexus exists within the App timeout.
	//
	// @param tname - name of the target thread that owns the nexus
	// @param nexname - name of the nexus in it
	// @param asname - name of the facet to be created from this nexus, very
	//        much like the SQL "AS clause", which allows to avoid both the
	//        local duplicates and the long full names. If empty, will
	//        be set to the same as the nexus name.
	// @param writer - flag: this thread will be writing into the nexus,
	//        otherwise reading from it
	// @param immed - flag: the nexus lookup is immediate, not waiting for its
	//        thread to be fully constructed
	// @return - the imported facet reference.
	Onceref<Facet> importNexus(const string &tname, const string &nexname, const string &asname, 
		bool writer, bool immed = false);
	// Syntactic sugar varieties.
	Onceref<Facet> importNexusImmed(const string &tname, const string &nexname, const string &asname,
		bool writer)
	{
		return importNexus(tname, nexname, asname, writer, true);
	}
	Onceref<Facet> importReader(const string &tname, const string &nexname, const string &asname = "",
		bool immed=false)
	{
		return importNexus(tname, nexname, asname, false, immed);
	}
	Onceref<Facet> importWriter(const string &tname, const string &nexname, const string &asname = "",
		bool immed=false)
	{
		return importNexus(tname, nexname, asname, true, immed);
	}
	Onceref<Facet> importReaderImmed(const string &tname, const string &nexname, const string &asname = "")
	{
		return importNexus(tname, nexname, asname, false, true);
	}
	Onceref<Facet> importWriterImmed(const string &tname, const string &nexname, const string &asname = "")
	{
		return importNexus(tname, nexname, asname, true, true);
	}

	// Convenience wrappers that forward to the Triead.
	void exports(NexusMap &ret) const
	{
		return triead_->exports(ret);
	}
	void imports(FacetMap &ret) const
	{
		return triead_->facets(ret);
	}

	// The convenience way of making nexuses in a chained way.
	// They are all used in the same way, so just one example:
	//
	// Autoref<Facet> myfacet = ow->makeNexusReader("my")
	//     ->addLabel("one", rt1)
	//     ->addFromLabel("two", lb2)
	//     ->setContext(new MyFnContext)
	//     ->setReverse()
	//     ->complete();
	//
	// All the calls duplicated from FnReturn must always go before
	// any of the calls duplicated from Facet. The last call must
	// be complete() which will always return the constructed facet,
	// even with NoImport.
	//
	// The FnReturn is constructed on the main unit of this thread.
	// If you need more flexibility, there is always the manual way
	// of building the FnReturn and Facet.
	//
	// makeNexusReader - on export also import this nexus for reading
	// makeNexusWriter - on export also import this nexus for writing
	// makeNexusNoImport - on export do not import this nexus
	//
	// @param name - name of the nexus
	NexusMaker *makeNexusReader(const string &name);
	NexusMaker *makeNexusWriter(const string &name);
	NexusMaker *makeNexusNoImport(const string &name);

	// Send the collected non-empty Xtrays on the writer facets.
	//
	// Throws an Exception if the thread has not completed yet
	// the wait for App readiness readyReady().
	//
	// @return - true if the flush was completed, false if the thread
	//         was requested to die, and the data has been discarded;
	//         the false generally means that the thread needs to exit
	//         (can also call isRqDead() to get this indication)
	bool flushWriters()
	{
		return triead_->flushWriters();
	}

	// Get the next Xtray from the read facets (sleep if needed),
	// process it and send through the write facets.
	// If requested to wait, will wait for more input, unless all the
	// readers are dead and/or the thread has been requested to die. 
	// With no wait, will return false as soon as the no more readily available
	// buffers in the queues.
	//
	// May propagate an Exception (in this case the unprocessed part of the
	// Xtray contents will be discarded).
	// Will throw an Exception if this thread didn't complete readyReady().
	// Will throw an exception if attempted to call recursively.
	// 
	// @param wait - flag: when the queue is consumed, wait for more
	// @param abstime - the time limit, passing a NULL address disables the
	//        time limit; wait==false returns immediately irrespective of
	//        the time limit
	// @return - true normally, false when the thread was requested to die
	//         (or with wait==false, when no more data in the queues, or
	//         with the time limit when the limit has expired)
	bool nextXtray(bool wait = true, 
		const struct timespec &abstime = *(const struct timespec *)NULL);

	// A convenience wrapper.
	bool nextXtrayNoWait()
	{
		return nextXtray(false);
	}

	// Wrapper that invokes nextXtray() with a relative timeout limit.
	// @param sec - the whole seconds part of the timeout
	// @param nsec - the nanoseconds part of the timeout
	// @return - true normally, false when the thread was requested to die
	//         or when timeout has expired
	bool nextXtrayTimeout(int64_t sec, int32_t nsec);

	// The easy way to process all the input data until the thread
	// is requested to die.
	// Calls nextXtray() repeatedly until it returns false. Then marks
	// the thread as dead.
	void mainLoop();

	// Check if the drain is currently requested.
	// It allows the thread code to stop generating the data
	// out of nowhere when the drain is requested.
	bool isRqDrain()
	{
		return triead_->qev_->isRqDrain();
	}

	// The convenience wrapper interface for drains. 
	// See the long descriptions in App.
	void requestDrainShared()
	{
		app_->requestDrain();
	}
	void requestDrainExclusive()
	{
		app_->requestDrainExclusive(this);
	}
	void waitDrain()
	{
		app_->waitDrain();
	}
	bool isDrained()
	{
		return app_->isDrained();
	}
	void drainShared()
	{
		app_->drain();
	}
	void drainExclusive()
	{
		app_->drainExclusive(this);
	}
	void undrain()
	{
		app_->undrain();
	}

public:
	// A convenient place to store the file interruptor.
	// Feel free to use it. The TrieadOwner itself doesn't care
	// about it in any way.
	Autoref<FileInterrupt> fileInterrupt_;

protected:
	// Called through App::makeTriead().
	// Creates the thread's "main" same-named unit.
	// @param app - app where this thread belongs
	// @param th - thread, whose control API to represent.
	TrieadOwner(App *app, Triead *th);

	// Try to find the next xtray in the next round (the reader facets
	// of the same priority get collected in the same round).
	// Continues the search from the last position remembered in 
	// vec.idx_. If finds an xtray, its facet's index will be also
	// left in vec.idx_. If doesn't find then vec.idx_ will cycle back
	// to the original position.
	// @param vec - the round to search through
	// @return - the found xtray, or NULL if not found
	Xtray *pickNextRound(Triead::FacetPtrRound &vec);

	// Try to refill the readers in the round from their writer-side queues.
	// @return - true if any reader found the new data
	bool refillRound(Triead::FacetPtrRound &vec);

	// Convert the Xtray entries to Rowops and run them through the
	// Facet's FnReturn. The Xtray must match the Facet.
	//
	// May propagate an Exception.
	void processXtray(Xtray *xt, Facet *facet);

	// Drain any scheduled rowops from all the units. Done after
	// executing every rowop from Xtray.
	void drainUnits();

	// Get the QueEvent.
	QueEvent *queEvent()
	{
		return triead_->queEvent();
	}

protected:
	Autoref<App> app_; // app where the thread belongs
	Autoref<Triead> triead_; // the thread owned here
	Autoref<Unit> mainUnit_; // the main unit, created with the thread
	UnitList units_; // units of this thread, including the main one
	NexusMaker nexusMaker_; // helper for convenient nexus making
	bool appReady_; // waited for App to be ready, permits the processing
	bool busy_; // flag: processing an Xtray

private:
	TrieadOwner();
	TrieadOwner(const TrieadOwner &);
	void operator=(const TrieadOwner &);
};

}; // TRICEPS_NS

#endif // __Triceps_TrieadOwner_h__
