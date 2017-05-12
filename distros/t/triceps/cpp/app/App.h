//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The Application class that manages the threads. There may be multiple
// Apps in one program, each with a different name.

#ifndef __Triceps_App_h__
#define __Triceps_App_h__

#include <map>
#include <list>
#include <pw/ptwrap.h>
#include <common/Common.h>
#include <app/Triead.h>
#include <app/TrieadJoin.h>
#include <app/QueHelpers.h>

namespace TRICEPS_NS {

class Triead; // The Triceps Thread
class TrieadOwner; // The Triceps Thread's Owner interface
class Nexus;

class App : public Mtarget
{
	friend class TrieadOwner;

public:
	// the static interface {

	// Create an app with a given name and remember it in the directory
	// of apps. This set the deadline with default timeout (which can
	// be changed later, before the creation of the first thread).
	// 
	// Throws an Exception if the App with this name already exists.
	//
	// @param name - name of the app to create, must be unique.
	// @return - reference to the newly created application, in case if
	//     it's about to be used, so that there is no need to immediately
	//     look it up.
	static Onceref<App> make(const string &name);

	// Find a named App.
	//
	// Throws an Exception if the app is not found.
	//
	// @param name - name of the app to find, it must already be created.
	// @return - reference to the app.
	static Onceref<App> find(const string &name);

	// List all the defined Apps, for introspection.
	// @param - a map where all the defined Apps will be returned.
	//     It will be cleared before placing any data into it.
	typedef map<string, Autoref<App> > Map;
	static void listApps(Map &ret);

	// Dereference the app from the list. The object will
	// still exist until all the links to it are gone.
	// If the App is already dereferenced, does nothing.
	// @param app - the App to drop
	static void drop(Onceref<App> app);

	// } static interface

public:
	typedef map<string, Autoref<Triead> > TrieadMap;

	// XXX have separate timeouts for Constructed and Ready
	enum {
		// The default timeout (seconds) when waiting for the threads
		// to initialize.
		DEFAULT_TIMEOUT = 30,
	};

	virtual ~App();

	// Get the name
	const string &getName() const
	{
		return name_;
	}

	// Set an explicit timeout (counting from now) for the initialization
	// deadline.
	// Since the full initial construction may take longer than the short
	// creation of the fragments later, allows to set a separate timeout for
	// the fragments. 
	// This shorter frag timeout would not create a race because the full
	// initialization should be completed before any threads go and create
	// more fragments.
	//
	// Throws an Exception if any thread exists in the App.
	// @param sec - timeout in seconds for the initial construction
	// @param fragsec - timeout in seconds for the fragment construction,
	//        if <0 then the same as for the initial
	void setTimeout(int sec, int fragsec = -1);

	// Set an explicit absolute initialization deadline.
	// This adjusts only the initial deadline, the timeout for fragments
	// stays unchanged.
	//
	// The use of this function has became tricky because now any thread
	// declaration or definition refreshes the deadline, possibly delaying
	// and overriding it.
	//
	// Throws an Exception if any thread exists in the App.
	// @param dl - deadline, absolute value
	void setDeadline(const timespec &dl);

	// Refresh the deadline before creating a fragment.
	// Uses the fragment timeout defined in setTimeout() (or default).
	// Will never move the dealine backwards.
	void refreshDeadline();

	// Create a new thread.
	//
	// Also refreshes the deadline.
	//
	// Throws an Exception if the name is empty or not unique.
	//
	// @param tname - name of the thread to create. Must be unique in the App.
	// @param fragname - name of the disposable fragment where the thread belongs
	//        (an empty string for no fragment)
	Onceref<TrieadOwner> makeTriead(const string &tname, const string &fragname = "");

	// Declare a thread's name.
	// After that the thread can be found: it will wait for the thread's
	// construction and not throw an error. Not needed if the thread is known
	// to already exist. It's OK to declare a Triead that already exists,
	// then it becomes a no-op.
	//
	// I.e. if a parent C++ thread creates a Triead and then gives its name
	// to a child C++ thread as a source of data, there is no need for declaration
	// because the parent thread is already defined.
	// But if a parent C++ thread creates a child C++ thread, giving it a Triead 
	// name to use, and then wants to connect to that child Triead, it has to
	// declare that Triead first to avoid the race with the child thread not
	// being able to define a Triead before the parent trying to use it.
	// 
	// There are two caveats though:
	// 1. The child thread still might die before it completes the initialization.
	//    For this, there is a timeout.
	// 2. If the parent thread tries to connect to the child AND the child tries
	//    to connect to the parent, avoid the race by fully constructing the
	//    parent Triead and only then starting the child thread. Otherwise a
	//    deadlock is possible. It will be detected reliably, but then still
	//    you would have to fix it like this.
	//
	// Also refreshes the deadline if this thread was not declared nor defined yet.
	//
	// @param tname - name of the thread to declare. If already declared, this
	//        method will do nothing.
	void declareTriead(const string &tname);

	// Define a join object for the thread. Called by the parent thread.
	// May be left undefined if the thread is detached (not the best idea but doable). 
	// The normal sequence would be:
	// * declare a thread from its parent
	// * start the thread and get its identity
	// * construct a joiner object with this identity and define it
	// The threda identity is not known until it's constructed, so it has to be
	// done after the thread runs but the thread has to be declared before it
	// starts because (1) otherwise the child thread might not define itsels yet
	// and defineJoin() would fail and (2) because some other threads may be
	// waiting for everything being ready, so the parent thread must declare the
	// child threads before it reports itself ready.
	//
	// Will throw an Exception if no such thread is declared nor defined.
	//
	// Theoretically, this method can be called multiple times for the same
	// thread to change or remove (with NULL argument) the joiner but
	// practically it's probably not a good idea.
	//
	// @param tname - name of the thread to define a joiner for; the thread must
	//        be already declared or defined
	// @param j - the joiner, the App will keep a reference to it until the join is done
	void defineJoin(const string &tname, Onceref<TrieadJoin> j);
	
	// Get all the threads defined and declared in the app.
	// The declared but undefined threads will have the value of NULL.
	// @param ret - map where to put the return values (it will be cleared first).
	void getTrieads(TrieadMap &ret) const;

	// Mark the app as aborted. This is done when a thread detects a fatal
	// error after which it could not continue the initialization. The App
	// normally can not continue without any of its threads, so it's better to
	// abort right away than to wait for the thread timeout to expire.
	// The abort immediately makes the App ready, wakes up all the waits
	// for threads, and immediately throws Exception on all the future waits. 
	// But it takes all the threads to be collected as usual for the App to
	// become dead.
	//
	// @param tname - name of the failed thread that calls the abort
	// @param msg - the abort message, allowing to propagate the error info
	void abortBy(const string &tname, const string &msg);

	// Check whether the app was marked as aborted.
	bool isAborted() const;

	// Get the name of the thread that caused the app abort
	// (will be empty if not aborted).
	// The result is NOT a reference but a copy of the string!
	string getAbortedBy() const;
	// Get the message from the aborted thread.
	// The result is NOT a reference but a copy of the string!
	string getAbortedMsg() const;

	// Check whether the app is dead (naturally or aborted).
	// (This check may be called with mutex_ not held or held).
	bool isDead();

	// Wait for the App to become dead.
	void waitDead();

	// Request the App to shut down. All the ready thread will be
	// requested to die. Any new threads will be requested to die
	// when they become ready.
	//
	// May throw an Exception if the iterrupt or join logic
	// fails.
	void shutdown();

	// Request a fragment to shut down. All the threads from this
	// fragment will be requested to die and unreferenced by the
	// App. All of them must be ready, or the call will throw an
	// Exception (this basically means that the fragment must be fully
	// initialized, and waited for the readiness of the App before this
	// call can be made). The threads outside the fragment are not
	// affected. If there are no threads left in this fragment,
	// the call has no effect.
	//
	// May throw an Exception if a thread iterruption fails.
	//
	// @param fragname - name of the fragment to shutdown
	void shutdownFragment(const string &fragname);

	// Returns, whether the App is shutting down.
	bool isShutdown();

	// The harvester API.
	// XXX should harvester be renamed "reaper"?
	// The harvester would normally run in a "master" thread. It would
	// join the threads as they die, and after all of them are dead,
	// drop the App.
	// There is expected to be only on eharvester thread, or many
	// assumptions will break.
	// {

	// Do one run of the harvester. Join all the threads that have
	// died since the last run. Resets the "need harvest" flag, unless
	// the whole App is dead.
	//
	// May throw an Exception if a thread join fails.
	//
	// @return - whether the App is dead. Combining the check into this
	//           method allows to avoid a race that would leave the
	//           last thread(s) unharvested.
	bool harvestOnce();

	// Wait for either more threads become harvestable of for the
	// app to become dead.
	// (This check may be called with mutex_ not held or held).
	void waitNeedHarvest();

	// Run the harvester thread logic, harvesting the threads
	// as they die, and after the whole App is dead, drop it.
	// Note that the caller is expected to keep a reference to the App,
	// so the dead App won't be actually destroyed until that reference
	// is destroyed.
	//
	// The exceptions from harvestOnce() will be caught and collected
	// until the harvesting completes. Then a single exception with the
	// combined text will be rethrown. If throwAbort is true and an abort
	// is detected, its message will be merged into the same exception.
	//
	// @param throwAbort - flag: if an app abort is detected, propagate it by throwing
	//         an exception after disposing of the App
	void harvester(bool throwAbort = true);

	// }


	// The drain API.
	//
	// The drain and undrain requests must go in matching pairs, or the App will
	// be left drained forever. Nested requests are OK. 
	// You can not assume that the App will continue on its way right after
	// you call the undrain, since there may be the other drain requests.
	// {
	
	// Start the drain sequence for a shared full drain (where all the threads
	// get drained). As the name suggests, multiple requests for shared drains
	// may be active at the same time without conflicting.
	// May sleep if an exclusive drain is currently in progress.
	void requestDrain();

	// Start the drain sequence for an exclusive drain (where all the threads
	// except one get drained). Only one exclusive drain may be active at
	// a time, all the other requests will sleep until this drain is done,
	// and this request will sleep if there is another drain in progress.
	//
	// MAY NOT BE CALLED RECURSIVELY FROM THE SAME THREAD.
	// MAY NOT BE MIXED RECURSIVELY WITH A SHARED DRAIN FROM THE SAME THREAD.
	//
	// Normally the caller is expected to represent and control the excepted
	// thread, which would normally be an input-only thread. All the other
	// input-only threads get stuck on a drain but the excepted one may
	// continue sending data.
	//
	// The typical use of the exclusive drain is to send a batch of data
	// in the controlled fashion: 
	//   * request an axclusive drain,
	//   * wait for the drain to complete (not sending anything from the
	//     excepted thread),
	//   * send the data from the excepted thread,
	//   * wait for the drain to complete again,
	//   * undrain.
	// This guarantees that the data from the excepted thread goes through the
	// App completely by itself, not mixing with any data from before or after.
	//
	// @param to - owner of the excepted thread
	void requestDrainExclusive(TrieadOwner *to);

	// Wait for the drain to complete. May be called repeatedly while drained.
	// Can be used with both shared and exclusive drains.
	// Do not call when the drain is not requested, or it will be stuck forever.
	// Returns immediately if the app is dead.
	void waitDrain();

	// Quickly check whether the drain has completed.
	// Can be used with both shared and exclusive drains.
	// Can be called even without the preceding requestDrain*() but
	// in that case it will likely return garbage.
	bool isDrained();

	// Start the shared drain sequence and wait for the drain to complete.
	void drain()
	{
		requestDrain();
		waitDrain();
	}

	// Start the exclusive drain sequence and wait for the drain to complete.
	//
	// MAY NOT BE CALLED RECURSIVELY FROM THE SAME THREAD.
	// MAY NOT BE MIXED RECURSIVELY WITH A SHARED DRAIN FROM THE SAME THREAD.
	//
	// @param to - owner of the excepted thread
	void drainExclusive(TrieadOwner *to)
	{
		requestDrainExclusive(to);
		waitDrain();
	}

	// End the drain sequence.
	void undrain();

	// }
	
	// Perl has issues with passing the file descriptors between
	// threads. So App has an API to help with this. It keeps a map
	// of file descriptors that can be stored and loaded.
	// If the App gets destroyed while some file descriptors are
	// still in the map (not a normal occurrence), they will be closed.
	// {

	// Store a file descriptor.
	//
	// Throws an Exception if a descriptor with this name is already
	// stored.
	//
	// @param name - a symbolic name
	// @param fd - the file descriptor number
	// @param className - name of the class that contained this descriptor
	void storeFd(const string &name, int fd, const string &className);
	// The version without a known class name.
	// @param name - a symbolic name
	// @param fd - the file descriptor number
	void storeFd(const string &name, int fd);

	// Get a file descriptor back by name.
	// This does not erase it from the kept map!
	// @param name - a symbolic name
	// @param className - if not NULL, a string where the stored class
	//        name will be returned
	// @return - the file descriptor or -1 if the name is unknown
	int loadFd(const string &name, string *className = NULL) const;

	// Erase the file descriptor from the map.
	// @param name - a symbolic name
	// @return - true if erased, false if unknown to start with
	bool forgetFd(const string &name);

	// Close and erase the file descriptor from the map.
	// On close errors will leave errno set to non-0.
	// @param name - a symbolic name
	// @return - true if closed and erased, false if unknown to start with
	bool closeFd(const string &name);

	// }

protected:
	// The TrieadOwner's interface. These user calls are forwarded through TrieadOwner.

	// Find a thread by name.
	// Will wait if the thread has not completed its construction yet.
	// If the thread refers to itself (i.e. the name is of the same thread
	// owner, returns the thread back even if it's not fully constructed yet).
	//
	// Throws an Exception if no such thread is declared nor made,
	// or the thread is declared but not constructed within the timeout.
	//
	// @param to - identity of the calling thread (used for the deadlock detection).
	// @param tname - name of the thread
	// @param immed - flag: find immediate, which means that the thread will be
	//        returned even if it's not constructed yet and there will never be
	//        a wait, so if the thread is declared but not defined yet, an Exception
	//        will be thrown
	// @return - the thread reference.
	Onceref<Triead> findTriead(TrieadOwner *to, const string &tname, bool immed = false);

	// Find a nexus in a thread by name.
	// Will wait if the thread has not completed its construction yet.
	//
	// Throws an Exception if no such nexus exists.
	//
	// @param to - identity of the calling thread (used for the deadlock detection).
	// @param tname - name of the target thread
	// @paran nexname - name of the nexus in it
	// @param immed - flag: find immediate, which means that the thread will be
	//        returned even if it's not constructed yet and there will never be
	//        a wait, so if the thread is declared but not defined yet, an Exception
	//        will be thrown; it also means that it might be looking for nexus
	//        in an incomplete thread, and the nexus must be defined by then
	// @return - the nexus reference.
	Onceref<Nexus> findNexus(TrieadOwner *to, const string &tname, const string &nexname,
		bool immed = false);

	// Mark that the thread has constructed and exported all of its
	// nexuses. This wakes up anyone waiting.
	//
	// @param to - identity of the thread to be marked
	void markTrieadConstructed(TrieadOwner *to);

	// Mark that the thread has completed all its connections and
	// is ready to run. This also implies Constructed, and can be
	// used to set both flags at once.
	//
	// The last thread marked ready triggers the check of the
	// App topology that may throw an Exception.
	// Also the last thread marked resets the deadline to 0.
	//
	// @param to - identity of the thread to be marked
	void markTrieadReady(TrieadOwner *to);

	// Mark that the thread has exited.
	// This also implies Constructed and Ready, even though it should
	// not normally be used to mark all the flags at once.
	// This also triggers the thread's join by the harvester, 
	// so it should exit soon.
	//
	// If the thread was not ready before, it will be marked
	// ready now, and if it was the last one to become ready,
	// that will trigger the loop check in the App. However
	// if a loop is found and an Exception is thrown, it will
	// be caught and ignored. However the App will still be
	// marked aborted.
	//
	// @param to - identity of the thread to be marked
	void markTrieadDead(TrieadOwner *to);

	// Check whether the app is ready.
	// (This check may be called with mutex_ not held or held).
	bool isReady();

	// Wait for all the threads to become ready.
	// XXX should it be accessible outside of TrieadOwner?
	void waitReady();

protected:
	// Since there might be a need to wait for the initialization of
	// even the declared and not yet defined threads, the wait structures
	// exist separately.
	class TrieadUpd : public Mtarget
	{
	public:
		// The mutex would be normally the App object's mutex.
		TrieadUpd(pw::pmutex &mutex):
			waitFor_(NULL),
			dispose_(false),
			interrupted_(false),
			joining_(false),
			joined_(false),
			cond_(mutex)
		{ }

		// Signals the condvar and throws an Exception if it fails
		// (which should never happen but who knows).
		// The mutex should be already locked.
		//
		// @param appname - application name, for error messages
		void broadcastL(const string &appname);

		// Waits for the condition, time-limited to the App's timeout.
		// (To maintain the limit through repeated calls, it's built by
		// the caller and passed as an argument).
		// Throws an Exception if the wait times out or on any
		// other error.
		// The mutex should be already locked.
		//
		// @param appname - application name, for error messages
		// @param tname - thread name of this object, for error messages
		// @param abstime - the time limit
		void waitL(const string &appname, const string &tname, const timespec &abstime);

		// If has a joiner, call the interrupt() on it, and mark as
		// interrupted. If already interrupted, does nothing.
		// @return - the error if the interruptor throws an Exception,
		//           otherwise NULL
		Erref interruptL();

		// For testing: returns the current count of sleepers.
		// This allows the busy-wait until the sleepers get into position.
		// The mutex should be already locked.
		int _countSleepersL();

		Autoref<Triead> t_; // the thread object, will be NULL if only declared
		Autoref<TrieadJoin> j_; // the joiner object, may be NULL for detached or already joined threads

		TrieadUpd *waitFor_; // what thread is this one waiting for (or NULL), for deadlock detection

		bool dispose_; // the fragment of this thread has been shut down, dispose of it when dead
		bool interrupted_; // this thread has been interrupted
		bool joining_; // this thread's join has been started
		bool joined_; // this thread has been joined

	protected:
		// Condvar for waiting for any updates in the Triead status.
		pw::pchaincond cond_; // all chained from the App's mutex_

		// Condvar for waiting for any sleepers to wake up and go away.
		// pw::pchaincond freecond_; // all chained from the App's mutex_
	private:
		TrieadUpd();
		TrieadUpd(const TrieadUpd &);
		void operator=(const TrieadUpd &);
	};
	typedef map<string, Autoref<TrieadUpd> > TrieadUpdMap;
	typedef list<Autoref<TrieadUpd> > TrieadUpdList;

	// Use App::Make to create new objects.
	// @param name - name of the app.
	App(const string &name);

	// Internal version that relies on mutex_ being already locked.
	void abortByL(const string &tname, const string &msg);

	// Internal version that relies on mutex_ being already locked.
	void shutdownL();
	void shutdownFragmentL(const string &fragname);

	// Dispose of the reference to a thread. After that, it could not
	// be found any more. This is intended only for the threads in the
	// named fragments.
	// Relies on mutex_ being already locked.
	// The thread must be already dead and joined.
	// An unknown name will be silently ignored.
	// @param tname - name of the thread to dispose
	void disposeL(const string &tname);

	// Check whether the app was marked as aborted.
	// Relies on mutex_ being already locked.
	bool isAbortedL() const
	{
		return !abortedBy_.empty();
	}

	// Check that the app is not aborted. Otherwise throws an Exception.
	// Relies on mutex_ being already locked.
	void assertNotAbortedL() const;

	// Check that the thread belongs to this app.
	// If not, throws an Exception.
	// Relies on mutex_ being already locked.
	// @return - the updates entry for this thread
	TrieadUpd *assertTrieadL(Triead *th) const;
	TrieadUpd *assertTrieadOwnerL(TrieadOwner *to) const;

	// The internal versions. Require the mutex_ to be held
	// by the caller, and also assume that the Triead has been
	// already checked.
	// @param upd - the updates entry for the thread to be marked
	// @param t - the thread to be marked
	void markTrieadConstructedL(TrieadUpd *upd, Triead *t);
	void markTrieadReadyL(TrieadUpd *upd, Triead *t);
	void markTrieadDeadL(TrieadUpd *upd, Triead *t);

	// Create a timestamp for the initialization deadline.
	// @param sec - timeout in seconds from now
	void computeDeadlineL(int sec);

	// The internal implementation of refreshDeadline(), with an
	// ability to set an explicit deadline. 
	// @param sec - timeout in seconds from now, but it won't ever
	//        move the deadline back
	void refreshDeadlineL(int sec);

	// Check the inter-thread connectivity for loops.
	// The loops containing both the direct and reverse nexuses are OK,
	// only the loops of the nexuses of the same kind are an issue.
	// Throws an Exception and marks the App aborted if it finds any loops.
	//
	// @param tname - name of the thread that initiated the check,
	//        for the App abort
	void checkLoopsL(const string &tname);

	// The common part of logic for shared and exclusive drain.
	// @param t - excepted thread for exclusive, or NULL for shared
	void requestDrainCommon(Triead *exct);

protected:
	// The internal machinery of the topological loop finding.
	// {

	// The way the threads and nexuses are interconnected is very inconvenient
	// for finding the loops, so it's converted to an intermediate representation first.

	// A graph node representing a Nexus or a Triead. For the loop detection
	// purpose, they are the same, so it's easier to unify them and make
	// the code easier.
	struct NxTr: public Starget
	{
		// Construct from an original object.
		NxTr(Triead *tr);
		NxTr(Nexus *nx);

		// Copy constructor is used to copy the graphs.
		NxTr(const NxTr &nxtr);

		// Add a link, an edge going from this node to another one.
		// @param target - the target node
		void addLink(NxTr *target);

		// Returns the printable description of the underlying object.
		string print() const;

		Triead *tr_; // if it's a thread
		Nexus *nx_; // if it's a nexus
		int ninc_; // number of incoming connections
		bool mark_; // mark for the walk in the loop print
		typedef list<NxTr *> List;
		List links_; // edge links following the model topology
	};

	// A uni-directional graph of NxTr nodes.
	// This object serves 2 purposes:
	// 1. Hold the NxTr objects and eventually dispose of them.
	// 2. Map from the original Nexuses and Trieads and their NxTr nodes,
	//    so that each original object gets only one node.
	//
	// It's also used to map from one set of NxTr nodes to another set,
	// thus creating a modified copy of the graph.
	struct Graph
	{
		typedef map<void *, Autoref<NxTr> > Map;
		typedef list<NxTr *> List;

		// Add a node that represents an original object (Nexus, Triead or
		// an NxTr from another graph). If that original object was not seen yet,
		// will create and remember a new node. Otherwise will return the
		// previously created node. The created nodes are held by the
		// graph, so there is no need to create more references to it.
		//
		// @param tr, nx, nxtr - the original object
		// @return - the matching NxTr node
		NxTr *addTriead(Triead *tr);
		NxTr *addNexus(Nexus *nx);
		// this one is for copying graphs
		NxTr *addCopy(NxTr *nxtr);

		Map m_;
		List l_; // keeps the nodes in a consistent order, for predictable tests
	};

	// Half of the logic of checkLoopsL() that handles the loops with
	// nexuses going in one direction (either direct or reverse).
	// Throws an Exception if it finds a loop.
	// @param g - the parsed representation of the App's topology that
	//        includes only the nexuses of one direction.
	// @param direction - the human-readable string describing the
	//        direction of the nexuses for the error message, either
	//        "direct" or "reverse".
	void reduceCheckGraphL(Graph &g, const char *direction) const;

	// After the graph is reduced to loops only, check for their presence.
	// Throws an Exception if it finds a loop.
	// @param g - the reduced graph
	// @param direction - the human-readable string describing the
	//        direction of the nexuses for the error message, either
	//        "direct" or "reverse".
	void checkGraphL(Graph &g, const char *direction) const;

	// Logic that removes all the links leading from any start nodes
	// (i.e. nodes that have no incoming connections).
	// The checkGraphL() works by applying this function, reversing the
	// resulting graph, then applying this function again. Anything
	// left is the loops.
	static void reduceGraphL(Graph &g);

	// }

protected:
	// The single process-wide directory of all the apps, protected by a mutex.
	static Map apps_;
	static pw::pmutex apps_mutex_;

	mutable pw::pmutex mutex_; // mutex synchronizing this App
	string name_; // name of the App
	string abortedBy_; // name of the thread that aborted the app (empty if not aborted)
	string abortedMsg_; // an optional message from the aborted thread
	TrieadUpdMap threads_; // threads defined and declared
	TrieadUpdList zombies_; // the thread that have exited and need harvesting
	pw::event2 ready_; // will be set when all the threads are ready
	pw::event2 dead_; // will be set when all the threads are dead
	pw::event2 needHarvest_; // will be set when there are zombies to harvest
	timespec deadline_; // deadline for the initialization, set on or soon after App creation
	int timeout_; // the timeout that determines the deadline
	int unreadyCnt_; // count of threads that aren't ready yet
	int aliveCnt_; // count of threads that aren't dead yet
	bool shutdown_; // flag: has been requested to shut down

	Autoref<DrainApp> drain_; // the drain synchronization event (has its own mutex!)
	pw::prwlock drainRw_; // synchronize shared/exclusive drains
	Triead *drainExcept_; // drain all threads except this one (exclusively)
	int drainCnt_; // count of active drain requests, the app won't be undrained until it goes to 0

	struct FdInfo {
		FdInfo()
		{ }
		
		FdInfo(int fd, const string &className) :
			fd_(fd), class_(className)
		{ }

		FdInfo(int fd) :
			fd_(fd)
		{ }

		int fd_; // file descriptor
		string class_; // class name of the object that contained the descriptor,
			// so that on load an appropriate object can be reconstructed from the
			// descriptor (this is mainly for the benefit of Perl)
	};
	typedef map<string, FdInfo> FdMap;
	FdMap fdMap_;

private:
	App();
	App(const App &);
	void operator=(const App &);
};

}; // TRICEPS_NS

#endif // __Triceps_App_h__
