//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A Triceps Thread.  It keeps together the Nexuses defined by the thread and
// is also used to track the state of the app initialization.

#ifndef __Triceps_Triead_h__
#define __Triceps_Triead_h__

#include <map>
#include <vector>
#include <pw/ptwrap2.h>
#include <common/Common.h>
#include <sched/Unit.h>
#include <app/Nexus.h>
#include <app/Facet.h>

namespace TRICEPS_NS {

// Even though the class name is funny, it's still pronounced as "thread". :-)
// (I want to avoid the name conflicts with the word "thread" that is used all
// over the place). 
class Triead : public Mtarget
{
	friend class TrieadOwner;
	friend class App;
public:
	typedef map<string, Autoref<Nexus> > NexusMap;
	typedef map<string, Autoref<Facet> > FacetMap;
	typedef vector<Facet *> FacetPtrVec;
	struct FacetPtrRound: public FacetPtrVec
	{
		FacetPtrRound():
			idx_(0)
		{ }

		// Pop the front Xtray in the facet pointed by idx_;
		// The caller must be done processing that Xtray.
		void popread()
		{
			(*this)[idx_]->rd_->popread();
		}

		int idx_; // last index, for round-robin iteration
	};

	// No public constructor! Use App!

	~Triead();

	// Get the name
	const string &getName() const
	{
		return name_;
	}

	// Check if all the nexuses have been constructed.
	// Not const since the value might change between the calls,
	// if marked by the owner of this thread.
	bool isConstructed() const
	{
		return constructed_;
	}

	// Check if all the connections have been completed and the
	// thread is ready to run.
	// Not const since the value might change between the calls,
	// if marked by the owner of this thread.
	bool isReady() const
	{
		return ready_;
	}

	// Check if the thread has already exited. The dead thread
	// is also always marked as completed and ready. It could happen
	// that some threads are still waiting for readiness of the app while the
	// other threads have already found the readiness, executed and exited.
	// Though it should not happen much in the normal operation.
	bool isDead() const
	{
		return dead_;
	}

	// Check if this thread is input-only (i.e. has no reader facets).
	// This flag will be valid only after the thread has been marked as
	// ready; before then it always shows False.
	bool isInputOnly() const
	{
		return inputOnly_;
	}

	// Get the fragment name where this thread belongs.
	// @return - the name, or empty if in no fragment
	const string &fragment() const
	{
		return frag_;
	}

	// List all the defined Nexuses, for introspection.
	// @param - a map where all the defined Nexuses will be returned.
	//     It will be cleared before placing any data into it.
	void exports(NexusMap &ret) const;

	// List all the imported Nexuses, for introspection.
	// This doesn't differentiate between readers and writers.
	// @param - a map where all the imported Nexuses will be returned.
	//     It will be cleared before placing any data into it.
	void imports(NexusMap &ret) const;

	// List all the Nexuses imported for reading, for introspection.
	// @param - a map where all the imported Nexuses will be returned.
	//     It will be cleared before placing any data into it.
	void readerImports(NexusMap &ret) const;

	// List all the Nexuses imported for writing, for introspection.
	// @param - a map where all the imported Nexuses will be returned.
	//     It will be cleared before placing any data into it.
	void writerImports(NexusMap &ret) const;

#if 0 // {
	// Get the count of exports.
	int exportsCount() const;
#endif // }

	// Find a nexus with the given name.
	// Throws an Error if not found.
	// @param srcName - name of the Triead that initiated the request
	// @param appName - name of the App where this thread belongs, for error messages
	// @param name - name of the nexus to find
	Onceref<Nexus> findNexus(const string &srcName, const string &appName, const string &name) const;

protected:
	// Called through App::makeThriead().
	// @param name - name of this thread (within the App).
	// @param fragname - name of the app fragment where the threda belongs.
	// @param drain - the drain state of the App.
	Triead(const string &name, const string &fragname, DrainApp *drain);

	// Clear all the direct or indirect references to the other threads.
	// Called by the App at the destruction time.
	void clear();

	// Report to the App when the thread is drained (i.e. not processing
	// and not producing any data).
	void drain();
	// Stop reporting to the App about the thread drains.
	void undrain();
	
	// Tell the thread that it should die. (Usually the App does this).
	// To make it clear, markDead() is the thread itself telling that
	// it's done and exiting, while requestDead() is a request from
	// outside telling the thread to exit when it can.
	//
	// This disables the reading of any further Xtrays from the input
	// queues (though whatever has been moved to the read side of the
	// queues will still be consumed).
	//
	// It also disconnects the facets from the nexuses and prevents the
	// new facets if any from being connected to the nexuses. The 
	// disconnection causes the writer-side queue in the nexus to
	// be cleared and if there are writers waiting for the flow control,
	// they will wake up.
	void requestDead();

	// The TrieadOwner API.
	// Naturally, it can be called from only one thread, the owner one.
	// These calls usually also involve the inter-thread signaling
	// done by the ThreadOwner through App.
	// {

	// Mark that the thread has constructed and exported all of its
	// nexuses.
	void markConstructed();

	// Mark that the thread has completed all its connections and
	// is ready to run. This also implies Constructed, and can be
	// used to set both flags at once.
	void markReady();

	// Mark the thread that is has completed the execution and exited.
	// Also will mark the QueEvent and all the reader facets as dead.
	void markDead();

	// Get the queue event object.
	QueEvent *queEvent() const
	{
		return qev_;
	}

	// Send the collected non-empty Xtrays on the writer facets.
	//
	// Throws an Exception if the thread has not completed yet
	// the wait for App readiness.
	//
	// @return - true if the flush was completed, false if the thread
	//         was requested to die, and the data has been discarded;
	//         the false generally means that the thread needs to exit
	bool flushWriters();

	// }
protected:
	// The initialization is done in two stages:
	// 1. Construction: the thread defines its own nexuses and locates
	// the nexuses of other threads (in any order), performs connections
	// between them, and of course initializes its internals. After it
	// reports itself constructed, it may not add any new nexuses nor
	// perform connections, and whatever it has defined becomes visible to
	// the other threads.
	// 2. Readiness: the thread waits for all the dependent threads to
	// become ready, before it declares itself ready. The whole application
	// becomes ready when all the threads in it are ready.
	//
	// Note that both stages imply the dependency graphs, but these graphs
	// may be very different. So far it looks more likely that these graphs
	// will have the opposite direction of the edges. The cycles are not
	// allowed in either of the graphs. The cycles get detected and 
	// mean the application initialization failure.
	
	// List all the imported Facets, for introspection.
	// @param - a map where all the imported Facets will be returned.
	//     It will be cleared before placing any data into it.
	void facets(FacetMap &ret) const;

	// Export a nexus. Called from TrieadOwner. The nexus must be already
	// marked as exported.
	// Throws an Exception if the name is duplicate or if the thread is already
	// marked as constructed.
	// @param appName - App name, for error messages
	// @param nexus - the nexus to export (TriedOwner keeps a reference to it
	//        during the call)
	void exportNexus(const string &appName, Nexus *nexus);

	// Add the facet to the list of imports.
	// @param facet - facet to import
	void importFacet(Onceref<Facet> facet);

	// Access from TrieadOwner. 
	// The "L" means in this case that the owner thread doesn't even
	// need to lock the mutex.
	FacetMap::const_iterator importsFindL(const string &name) const
	{
		return imports_.find(name);
	}
	FacetMap::const_iterator importsEndL() const
	{
		return imports_.end();
	}

	// Notification from TrieadOwner that it had waited for the
	// app to become ready, so now all the facets can be notified
	// of that.
	void setAppReady();
	
	string name_; // name of the thread, read-only
	string frag_; // name of the fragment, read-only
	mutable pw::pmutex mutex_; // mutex synchronizing this Triead
	NexusMap exports_; // the nexuses exported from this thread
	Autoref<QueEvent> qev_; // the thread's queue notification

	// The set of imports is modified only by the TrieadOwner, so the owner
	// thread may read it without locking.  However the imports themselves may
	// be disconnected from their nexuses by the other threads when they
	// request this one dead, so any modifications of the list or the
	// connection/disconnection must be done under lock.  Any other
	// modifications and reading by anyone else also have to be done under
	// lock. However the good news is that the disconnection request doesn't
	// touch the state of the Facet itself in any way other than passing the
	// disconnection request to the Nexus. So any other work can be done by the
	// owner of this thread without locking.
	//
	// This all also means that any work with writers_ and writers_ doesn't
	// have to be protected by a mutex, since technically it doesn't change
	// the imports_ object, and any other threads can't change the object
	// itself either (they just pass through it and through facets to the nexuses).
	//
	// Just to make exra sure that this disconnection by the other threads
	// never blocks for a long time, imports are protected by a separate
	// mutex that has no other dependencies. This lock has to be used 
	// when either changing the imports_ object itself or when connecting/
	// disconnecting the facets in it. If you need to lock both
	// mutex_ and imports_mutex_, lock the mutex_ first.
	mutable pw::pmutex imports_mutex_; // mutex for synchronizing imports_
	FacetMap imports_; // the imported facets

	// All these are duplicates from references in imports_, so
	// just keep simple pointers.
	FacetPtrRound readersHi_; // the high-priority (reverse) readers
	FacetPtrRound readersLo_; // the low-priority (normal) readers
	FacetPtrVec writers_; // the writers

	bool inputOnly_; // flag: this thread is input-only (computed in setAppReady())
	bool appReady_; // flag: the App has been marked all ready
	bool rqDead_; // flag: App requested this thread to exit

	// The flags are interacting with the App's state and
	// are synchronized by the App's mutex.
	// {
	// Flag: all the nexuses of this thread have been defined.
	// When this flag is set, the nexuses become visible.
	bool constructed_;
	// Flag: the thread has been fully initialized, including
	// waiting on readiness of the other threads.
	bool ready_;
	// Flag: the thread has completed execution and exited.
	bool dead_;
	// }

private:
	Triead();
	Triead(const Triead &);
	void operator=(const Triead &);
};
}; // TRICEPS_NS

#endif // __Triceps_Triead_h__
