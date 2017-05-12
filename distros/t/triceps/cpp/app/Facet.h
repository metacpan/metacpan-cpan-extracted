//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A facet represents a nexus imported into a thread.

#ifndef __Triceps_Facet_h__
#define __Triceps_Facet_h__

#include <common/Common.h>
#include <app/Nexus.h>
#include <sched/FnReturn.h>

namespace TRICEPS_NS {

// There are two ways to get a Facet:
// 1. Create it from the bits and pieces and then create and export
//    a nexus from it. The original facet becomes the representation
//    of that nexus in the owner thread (unless you opt out and then
//    that facet just gets discarded).
// 2. Import a nexus and receive a facet as its representation.
//
// A Facet is seen in only one thread, however during the analysis for loop
// the App reads all the Facets, and thus they must be accessible from
// outside the thread.
class Facet: public Mtarget
{
	friend class Triead;
	friend class TrieadOwner;
	friend class Nexus;
public:
	typedef Nexus::RowTypeMap RowTypeMap;
	typedef Nexus::TableTypeMap TableTypeMap;

	static const string BEGIN; // the _BEGIN_ label name
	static const string END; // the _END_ label name

	// Build API, used to build the facet for export
	// {

	enum {
		// The queue size limit for the nexus. Due to the dual-buffering,
		// the queue could actually contain up to twice this number of Xtrays.
		DEFAULT_QUEUE_LIMIT = 500,
	};

	// Create the Facet from the minimal set of fragments.
	// The extra row types and table types can be added later in
	// the chained fashion, as well as the reverse and unicast flags. 
	// Any errors found in the construction
	// will be saved and can be read later, or will cause an Exception
	// to be thrown at export time.
	//
	// @param fret - the FnReturn that will determine the type of the nexus'es
	//        queue. The FnReturn's name is used for the Facet's and Nexus'es
	//        name. The FnReturn may be not initialized yet, it will be then
	//        initialized.
	// @param writer - flag: the owner thread will be writing into this facet,
	//        otherwise reading from it; if it will be doing neither then
	//        you can use either value
	Facet(Onceref<FnReturn> fret, bool writer);

	// The destructor removes the Xtray from FnReturn and discards it.
	~Facet();

	static Facet *make(Onceref<FnReturn> fret, bool writer)
	{
		return new Facet(fret, writer);
	}

	// The convenience methods that make remembering the options
	// easier.
	static Facet *makeReader(Onceref<FnReturn> fret)
	{
		return new Facet(fret, false);
	}
	static Facet *makeWriter(Onceref<FnReturn> fret)
	{
		return new Facet(fret, true);
	}

	// Export a row type through the nexus. It won't be a part of the
	// queue, just a row type that can be imported by the other threads.
	//
	// If the Facet is imported, this will throw an Exception.
	// Also throws Exception on other errors.
	//
	// @param name - name of the row type, these are in a separate namespace from
	//         the types in the FnReturn
	// @param rtype - row type to export
	// @return - the same Facet
	Facet *exportRowType(const string &name, Onceref<RowType> rtype);

	// Export a table type through the nexus. It can be imported
	// by the other threads.
	//
	// If the Facet is imported, this will throw an Exception.
	//
	// @param name - name of the table type, these are in a separate namespace from
	//         the row types
	// @param tt - table type to export; if not correct or can not be correctly
	//        deep-copied, will record an error to be checked on export
	// @return - the same Facet
	Facet *exportTableType(const string &name, Autoref<TableType> tt);

	// Mark the future Nexus as going in the reverse direction ("upwards").
	// This has two implications:
	// * no queue size limit, no flow control
	// * this nexus will have a higher reading priority than the direct ones
	// May be called only until the Facet is exported or will throw an Exception.
	//
	// @param on - flag: the direction is reverse
	// @return - the same Facet
	Facet *setReverse(bool on = true);

#if 0  // {
	// Mark the future Nexus as unicast. The normal ("multicast") nexuses
	// send all the data passing through them to all the readers.
	// The unicast nexuses send each piece of the input to one
	// of the readers, chosen essentially at random. This allows
	// to implement the worker thread pools. A whole transaction
	// goes to the same reader.
	// May be called only until the Facet is exported or will throw an Exception.
	// @param on - flag: the unicast mode is on
	// @return - the same Facet
	Facet *setUnicast(bool on = true);
#endif // }

	// Set the nexus queue limit.
	// @param limit - the new limit value (make sure to keep it >0).
	Facet *setQueueLimit(int limit);
	
	// Get the collected errors.
	Erref getErrors() const
	{
		return err_;
	}

	// Building of the full name from components.
	static string buildFullName(const string &tname, const string &nxname)
	{
		return tname + "/" + nxname;
	}

	// } Build API
	// The rest is used for import from an already-built Facet
	// (either built here or imported).

	// Check whether this facet is imported (and that means, also exported).
	// As opposed to being in the middle of creation.
	// An imported facet is final. A non-imported facet can be constructed
	// further and eventually exported.
	bool isImported() const
	{
		return !nexus_.isNull();
	}

	// Check whether this is a writer.
	bool isWriter() const
	{
		return writer_;
	}

	// Check whether the underlying nexus is reverse.
	bool isReverse() const
	{
		return reverse_;
	}

#if 0  // {
	// Check whether the underlying nexus is unicast.
	bool isUnicast() const
	{
		return unicast_;
	}
#endif // }

	// Get the queue size limit.
	int queueLimit() const
	{
		return queueLimit_;
	}

	// Get back the FnReturn.
	// Since the caller is not expected to immediately destroy this object
	// with its reference, returning a pointer is safe enough.
	FnReturn *getFnReturn() const
	{
		return fret_;
	}

	// Get the short name of the FnReturn.
	const string &getShortName() const
	{
		return fret_->getName();
	}

	// Get the full name of the imported facet.
	// @return - for an imported facet, the name in format "thread_name/nexus_name",
	//           for a non-imported facet an empty string
	const string &getFullName() const
	{
		return name_;
	}

	// Get the map of defined individual row types.
	const RowTypeMap &rowTypes() const
	{
		return rowTypes_;
	}

	// Get the map of defined individual table types.
	const TableTypeMap &tableTypes() const
	{
		return tableTypes_;
	}

	// Get/import a row type by name.
	// (Unlike RowSetType, here is no order of the types, so no indexes).
	// @param name - the name of the row type, as was specified in exportRowType()
	// @return - the row type, or NULL if not found
	RowType *impRowType(const string &name) const;

	// Get/import a table type by name.
	// (Unlike RowSetType, here is no order of the types, so no indexes).
	// @param name - the name of the table type, as was specified in exportTableType()
	// @return - the table type, or NULL if not found
	TableType *impTableType(const string &name) const;

	// Get back the nexus.
	Nexus *nexus() const
	{
		return nexus_;
	}

	// Index of the _BEGIN_ label in the FnReturn.
	int beginIdx() const
	{
		return beginIdx_;
	}

	// Index of the _END_ label in the FnReturn.
	int endIdx() const
	{
		return endIdx_;
	}

	// If this facet is a writer and has a non-empty Xqueue,
	// flushes it to the nexus. Otherwise does nothing.
	//
	// Throws an Exception if the thread has not completed yet
	// the wait for App readiness, or if the facet
	// is not exported.
	//
	// @return - true if the flush was completed, false if the thread
	//         was requested to die, and the data has been discarded;
	//         the false generally means that the thread needs to exit
	bool flushWriter();

protected:
	// For importing of a nexus, create a facet from it.
	// @param unit - unit where the FnReturn will be created
	// @param nx - nexus being imported
	// @param fullname - the full name of the nexus, including its thread name
	// @param asname - short local name to use for the FnReturn
	// @param writer - flag: this facet will be writing into the nexus, 
	//        otherwise read from it
	Facet(Unit *unit, Autoref<Nexus> nx, const string &fullname, const string &asname, bool writer);

	// Check that the Facet is not ex/imported, or throw an Exception.
	void assertNotImported() const;

	// Mark the facet as imported.
	// A step in the export process, when the facet gets immediately
	// imported back.
	//
	// If this is a writer facet, and the FnReturn is already bound
	// to a writer facet, will throw an Exception.
	//
	// @param nexus - the nexus constructed from this facet
	// @param tname - name of the thread that owns it
	void reimport(Nexus *nexus, const string &tname);

	// Create the reader or writer interface and connect it to the
	// nexus. The nexus_ and writer_ must be already set before then.
	// Normally called from Triead::importFacet().
	// @param qev - queue event for the thread notification if this is
	//        a reader (ignored for a writer)
	// @param fake - flag: create the reader or writer interface as a
	//        placeholder but don't actually connect it to the nexus;
	//        used when the thread is requested dead before it's fully
	//        constructed
	void connectToNexus(QueEvent *qev, bool fake);

	// When the thread is marked dead, it disconnects from all the nexuses,
	// and clears its input queues.
	// 
	// THIS METHOD MAY BE CALLED FROM THE OTHER THREADS. These calls
	// will be synchronized between themselves, and between calls to
	// connectToNexus() with no more than one
	// at a time, but may happen in parallel with the calls of the
	// other methods.
	void disconnectFromNexus();

	// The internal version of flushWriter that bypasses the 
	// check for appReady_ and input-only synchronization.
	// These parts are expected to be done by the caller Triead in bulk.
	// "D" stands for "direct".
	void flushWriterD();

	// When the thread is requested to die and is not allowed to die
	// any more, this method is used to dispose of the data if it
	// keeps trying to write.
	void discardXtray();

	// called by the Triead/TrieadOwner
	void setAppReady()
	{
		appReady_ = true;
	}
	// Mark as belonging to an input-only thread.
	void setInputTriead()
	{
		inputTriead_ = true;
	}

	string name_; // the name is set only in the ex/imported facet:
		// it includes two parts separated by a "/": the nexus owner thread
		// name and the nexus name.
	Autoref<Nexus> nexus_; // nexus represented by this facet
	Autoref<ReaderQueue> rd_; // nexus reader interface, it a reader
	Autoref<NexusWriter> wr_; // nexus writer interface, if a writer
	Autoref<QueEvent> qev_;  // the thread's queue notifications
	bool writer_; // Flag: this thread is writing into the nexus;
		// ignored in the non-imported facets
	bool inputTriead_; // this writer belongs to an input-only thread

	Erref err_; // the collected errors

	// The elements that are either used to construct a nexus or are
	// deep-copied from a nexus. This gives each thread a private
	// set of types, making the reference-counting efficient.
	Autoref<FnReturn> fret_; // the interface to the nexus'es queue
	RowTypeMap rowTypes_; // the collection of row types
	TableTypeMap tableTypes_; // the collection of table types
	int queueLimit_; // the queue size limit for the nexus
	int beginIdx_; // index of the _BEGIN_ label
	int endIdx_; // index of the _END_ label
	bool reverse_; // flag: this nexus's main queue is pointed upwards
#if 0  // {
	bool unicast_; // flag: each row goes to only one reader, as opposed to copied to all readers
#endif // }
	bool appReady_; // flag: the App is ready, so the data passing can be done
	bool connected_; // flag: the facet is connected to the nexus

private:
	Facet();
	Facet(const Facet &);
	void operator=(const Facet &);
};

}; // TRICEPS_NS

#endif // __Triceps_Facet_h__
