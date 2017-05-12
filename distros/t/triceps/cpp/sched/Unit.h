//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The basic execution unit.

#ifndef __Triceps_Unit_h__
#define __Triceps_Unit_h__

#include <common/Common.h>
#include <sched/Tray.h>
#include <sched/Label.h>
#include <sched/FrameMark.h>
#include <list>
#include <map>

namespace TRICEPS_NS {

class Unit;
class RowType;

// One frame of the Unit's scheduling queue.
class UnitFrame : public Tray
{
	friend class Unit;
public:
	// clears the marks as well
	~UnitFrame();

	// Mark this frame
	// @param - Unit identity, to pass to the mark
	// @param mk - mark added to this frame (if it happens to point to another frame,
	//    it will be removed from there first).
	void mark(Unit *unit, Onceref<FrameMark> mk);

	// Check whether this frame has any marks on it.
	bool isMarked() const
	{
		return !markList_.isNull();
	}

	// Clear the marks and any leftover rowops from frame when it's moved from queue
	// into the free pool
	void clear();

protected:
	Autoref <FrameMark> markList_; // head of the single-linked list of marks at this frame

	// A mark that is being reassigned points to this frame.
	// Free it up for reassignment by dropping from this frame's list.
	void dropFromList(FrameMark *what);
};

// The basic execution unit ties together a buch of tables, code and scheduling.
// It lives inside one thread and always executes sequentially. But nothing really
// stops a thread from having multiple execution units in it.
//
// The scheduling queue is composed of nested frames. The next rowop to execute is
// always taken from the front of the innermost frame. If a rowop is completed
// and its frame is found empty, the frame gets popped. The outermost frame
// is never popped from the stack even when it's completely empty.
//
// There are 4 ways to add rowops to the queue:
// 1. To the tail of the outermost frame. It's to schedule some delayed processing
//    for later, when the whole current queue is consumed.
//    [schedule]
// 2. To the tail of the current frame. This delays the processing of that rowop until
//    the processing of the current rowop completes.
//    [fork]
// 3. To the tail of another (ancestor) frame, pointed to by the FrameMark. 
//    This delays the processing of that rowop until that ancestor rowop completes.
//    [loopAt]
// 4. To push a new frame, add the rowop there, and immediately start executing it.
//    This works like a function call, making sure that all the effects from that
//    rowop are finished before the current processing resumes.
//    [call]
//
// Since the Units in different threads need to communicate, it's an Mtarget.
//
// When an Exception is thrown, the state of the unit will be left in some
// consistent shape, so that the execution could potentially be continued.
// The queue will be cleared to the same condition as if the call had returned normally.
// But if the operation consists of multiple parts, such as a tray, there
// might be no way to tell, what where went broken, and which parts were
// executed and which weren't, and this may mess up the application logic. 
// So the Exceptions should really be treated as fatal errors.
class Unit : public Mtarget
{
public:
	// @param name - a human-readable name of this unit, for tracing
	Unit(const string &name);
	~Unit();

	// Append a rowop to the end of the outermost queue frame.
	void schedule(Onceref<Rowop> rop);
	// Append the contents of a tray to the end of the outermost queue frame.
	void scheduleTray(const_Onceref<Tray> tray);

	// Append a rowop to the end of the current inner queue frame.
	void fork(Onceref<Rowop> rop);
	// Append the contents of a tray to the end of the current inner queue frame.
	void forkTray(const_Onceref<Tray> tray);

	// Push a new frame and execute the rowop on it, until the frame empties.
	// Then pop that frame, restoring the stack of queues.
	// May throw an Exception on fatal error.
	void call(Onceref<Rowop> rop);
	// Push a new frame with the copy of this tray and execute the ops until the frame empties.
	// Then pop that frame, restoring the stack of queues.
	// May throw an Exception on fatal error.
	void callTray(const_Onceref<Tray> tray);

	// Call a label like as if it were chained: reusing the current frame,
	// and overriding the label specified in the rowop.
	//
	// This methdod is fundamentally dangerous and must be used with
	// great care, ensuring the correct arguments.
	//
	// The caller must keep references to all the arguments for the
	// duration of the call. So for example you can't just pass a
	// "new Rowop(...)" as an argument. You have to assign it to an
	// Autoref<Rowop> and then you can use it as an argument.
	//
	// @param label - label to call
	// @param rop - rowop to execute, the label from it will be ignored
	//        (however the row type of the label argument and of the label in
	//        rowop must match, or things will crash)
	// @param chainedFrom - the label from which the called one has been virtually
	//        chained; may be NULL
	void callAsChained(const Label *label, Rowop *rop, const Label *chainedFrom)
	{
		label->call(this, rop, chainedFrom);
	}

	// Enqueue the rowop with the chosen mode. This is mostly for convenience
	// of Perl code but can be used in other places too, performs a switch
	// and calls one of the actula methods.
	// May throw an Exception on fatal error.
	// @param em - enqueuing mode, Gadget::EnqMode
	// @param rop - Rowop
	void enqueue(int em, Onceref<Rowop> rop);
	// Enqueue the tray with the chosen mode. This is mostly for convenience
	// of Perl code but can be used in other places too, performs a switch
	// and calls one of the actula methods.
	// May throw an Exception on fatal error.
	// @param em - enqueuing mode, Gadget::EnqMode
	// @param tray - tray of rowops
	void enqueueTray(int em, const_Onceref<Tray> tray);

	// Enqueue each record from the tray according to its enqMode.
	// "Delayed" here doesn't mean that the processing will be delayed,
	// it's for use in case if a Gadget collects the rowops instead
	// of processin gthem immediately, and only then (thus already "delayed")
	// enqueues them.
	// No similar call for Rowop, because it can be easily replaced 
	// with enqueue(rop->getEnqMode(), rop).
	// May throw an Exception on fatal error.
	void enqueueDelayedTray(const_Onceref<Tray> tray);

	// Set the start-of-loop mark to the parent frame.
	// The frame one higher than current is used because the current
	// executing label is the first label of the loop, and when it
	// started execution, it had a new frame created. When a rowop will
	// be enqueued at the mark and eventually executed, it will also
	// have a new frame created for it. For that frame to be at the
	// same level as the current frame, the label must be one level up.
	// If the unit is at the outermost frame (which could happen only
	// if someone calls setMark() outside of the scheduled execution),
	// the mark will be cleared. This will cause the data queued to
	// that mark to go to the outermost frame.
	// @param mark - mark to set
	void setMark(Onceref<FrameMark> mark);
	// Append a rowop to the end of the queue frame pointed by mark.
	// (The frame gets marked at the start of the loop).
	// If the mark points to no frame, append to the outermost queue frame:
	// the logic here is that if a record in the loop gets delayed by
	// time wait, when it continues, it should be scheduled there.
	// May throw an Exception on fatal error.
	void loopAt(FrameMark *mark, Onceref<Rowop> rop);
	// Append the contents of a tray to the end of the queue frame pointed by mark.
	// If the mark points to no frame, append to the outermost queue frame.
	// May throw an Exception on fatal error.
	void loopTrayAt(FrameMark *mark, const_Onceref<Tray> tray);

	// Extract and execute the next record from the innermost frame.
	// May throw an Exception on fatal error.
	void callNext();
	// Execute callNext() until the current stack frame drains.
	// Normally used only on the outermost frame.
	// May throw an Exception on fatal error.
	void drainFrame();

	// Check whether the queue is empty.
	// @return - true if no rowops in the whole queue
	bool empty() const;

	// Check whether the current frame is empty.
	// @return - true if the current frame is empty
	bool isFrameEmpty() const
	{
		return innerFrame_->empty();
	}

	// Check whether the unit is in the outer frame (i.e. not
	// in the middle of a call).
	// @return - true if the current frame is the outer frame
	bool isInOuterFrame() const
	{
		return innerFrame_ == outerFrame_;
	}

	// Get the human-readable name
	const string &getName() const
	{
		return name_;
	}

	// Get the depth of the frame stack in the queue.
	// Very useful for debugging of the stack growtn.
	int getStackDepth() const
	{
		return stackDepth_;
	}

	// There is an issue with potential circular references, when the labels
	// refer to each other with Autorefs, and the topology includes a loop.
	// Then the labels in the loop will never be freed. A solution used here
	// is for the unit to keep track of all the labels in it, and let the
	// user program send a clearing request to all of them.
	// The Unit and all its labels are normally constructed and used in a
	// single thread (except for the inter-unit communication). So these calls
	// must be used only from this thread and don't need synchronization.
	// {
	
	// Clear all the labels, then drop the references from Unit to them.
	// Normally should be called only when the thread is about to exit!
	// Does NOT throw an Exception. If it catches any exceptions, they are
	// all collected and printed to stderr.
	void clearLabels();

	// Remember the label. Called from the label constructor.
	void rememberLabel(Label *lab);

	// Forget one label. May be useful in case if the label needs to
	// be deleted early, or some such. This does not clear the label!
	void  forgetLabel(Label *lab);

	// An empty row type is convenient for creation of labels that do
	// nothing but do the clearing of some objects when told to.
	// The idea is that rather than abusing some related row type for
	// each of these labels, could as well just make one empty row type
	// for all of them. And the Unit is a convenient place to create
	// and keep track of this one copy of the empty row type that can 
	// be happily reused for as many labels as needed.
	// The empty row type has no fields in it.
	RowType *getEmptyRowType() const
	{
		return emptyRowType_;
	}

	// } Label management

	// Tracing interface.
	// Often it's hard to figure out, how a certain result got produced.
	// This allows the user to trace the whole execution sequence.
	// {

	// The tracer function is called multiple times during the processing of a rowop,
	// with the indication of when it's called.
	// The full sequence is:
	// TW_BEFORE
	// TW_BEFORE_CHAINED - only if has chained labels
	// TW_AFTER_CHAINED  /
	// TW_AFTER
	// TW_BEFORE_DRAIN - only if had forked/looped rowops
	// TW_AFTER_DRAIN  /
	enum TracerWhen {
		// The values go starting from 0 in before-after pairs
		TW_BEFORE, // before calling the label's execution as such
		TW_AFTER, // after all the execution is done
		TW_BEFORE_CHAINED, // after execution, before calling the chained labels (if they are present)
		TW_AFTER_CHAINED, // after calling the chained labels (if they were present)
		TW_BEFORE_DRAIN, // before draining the label's frame if it's not empty
		TW_AFTER_DRAIN, // after draining the label's frame if was not empty
		// XXX should there be events on enqueueing?
	};

	// convert the when-code to a string
	static const char *tracerWhenString(int when, const char *def = "???");
	static int stringTracerWhen(const char *when);
	
	// convert the when-code to a more human-readable string (better for debug messages and such)
	static const char *tracerWhenHumanString(int when, const char *def = "???");
	static int humanStringTracerWhen(const char *when);

	// Determines if the code is "before" or "after" (or maybe neither).
	static bool tracerWhenIsBefore(int when)
	{
		return !(when & 1);
	}
	static bool tracerWhenIsAfter(int when)
	{
		return (when & 1);
	}

	// The type of tracer callback functor: inherit from it and redefine your own execute()
	class Tracer : public Mtarget
	{
	public:
		// The printing of the rowop structure and of the contents of the
		// rows is split into two separate methods, allowing to redefine them
		// separately. One controls the formatting of the call chain,
		// the other one knows how to print the contents of the rows.
		// The first method is expected to call the second one appropriately.

		// There are two ways to specify the row printing, that may come
		// handy in different situations:
		// 1. Inherit and re-define the virtual method for it.
		// 2. Pass a simple C-like function pointer, for the very simple cases.
		// The default implementation of the virtual method just calls
		// the C-like function pointer (if it's not NULL). If you define
		// your own virtual method, you probably don't care about the C-like
		// function, don't need to call it, and probably set the pointer
		// always to NULL.
		//
		// This is the type of that function pointer. It must start
		// by appending a space (since the general formatting in execute()
		// would not normally know if there is any printing and would not
		// put a space in front).
		typedef void RowPrinter(string &res, const RowType *rt, const Row *row);
	
		// XXX eventually provide a good default row printer

		// @param rp - the row printer function
		Tracer(RowPrinter *rp = NULL);
		virtual ~Tracer();

		// The callback on some event related to rowop execution happens
		// May throw an Exception on fatal error.
		//
		// Should normally call printRow() to append the row contents to
		// the trace data.
		//
		// @param unit - unit from where the tracer is called
		// @param label - label that is being called
		// @param fromLabel - during the chained calls, the parent label, otherwise NULL
		// @param rop - rop operation that is executed
		// @param when - the kind of event
		virtual void execute(Unit *unit, const Label *label, const Label *fromLabel, Rowop *rop, TracerWhen when) = 0;

		// The method that appends the contents of a row to the trace string.
		// Gets normally called by execute().
		// The default implementation calls rowPrinter_ if it's not NULL,
		// so the very default effect is to just do nothing.
		// 
		// When appending the printout, it must start by appending a space
		// (since the general formatting in execute() would not normally know
		// if there is any printing and would not put a space in front).
		//
		// @param res - the trace string, to which the row printout should be
		//        appended (append, not replace!)
		// @param rt - the type of the row
		// @param row - the row to print
		virtual void printRow(string &res, const RowType *rt, const Row *row);

		// Get back the buffer of messages(with the default implementation it
		// can also be used to add messages to the buffer).
		// A subclass is free to redefine it in any way or just leave default.
		virtual Erref getBuffer();

		// Replace the message buffer with a clean one.
		// The old one gets simply dereferenced, so if you have a reference, you can keep it.
		virtual void clearBuffer();

	protected:
		RowPrinter *rowPrinter_;
		Erref buffer_; // buffer for collecting the trace
			// a subclass doesn't have to use it but can if it wants to
	};

	// For convenience, a concrete tracer class that collects the trace information
	// into an Errors object. It's a very typical usage to track the sequence of execution
	// and get it back as a string (Errors here takes the task of converting to string).
	class StringTracer : public Tracer
	{
	public:
		// @param verbose - if true, record all the events, otherwise only the TW_BEFORE records
		StringTracer(bool verbose = false, RowPrinter *rp = NULL);

		// from Tracer
		virtual void execute(Unit *unit, const Label *label, const Label *fromLabel, Rowop *rop, TracerWhen when);

	protected:
		bool verbose_;
	};

	// Another version of string tracer that doesn't print the object addresses, 
	// prints only names.
	class StringNameTracer : public StringTracer
	{
	public:
		// @param verbose - if true, record all the events, otherwise only the TW_BEFORE records
		StringNameTracer(bool verbose = false, RowPrinter *rp = NULL);

		// from Tracer
		virtual void execute(Unit *unit, const Label *label, const Label *fromLabel, Rowop *rop, TracerWhen when);
	};

	// Set the new tracer
	void setTracer(Onceref<Tracer> tracer);

	// Get back the current tracer
	Onceref<Tracer> getTracer() const
	{
		return tracer_;
	}

	// A callback for the Label, to trace its execution
	// May throw an Exception on fatal error.
	void trace(const Label *label, const Label *fromLabel, Rowop *rop, TracerWhen when);

	// } Tracing
	
	// In some cases the recursion may be desired.
	// This allows to enable the recursion.
	// {

	// Set the maximal allowed Triceps call stack depth for this unit.
	// When the unit is constructed, the default is unlimited (0).
	//
	// In practice there is also always the implicit limit of the C++ thread
	// stack size, but it's usually difficult to overrun without recursion.
	// See the comment for setMaxRecursionDepth().
	//
	// @param v - the limit; <=0 means "unlimited".
	void setMaxStackDepth(int v)
	{
		maxStackDepth_ = v;
	}

	int maxStackDepth() const
	{
		return maxStackDepth_;
	}

	// Set the maximal allowed label recursion depth for this unit.
	// I.e. it's the number of times a label can be present on the call stack.
	//
	// 1 means only call once, no recursion. 2 means that the label may call
	// itself (directly or indirectly) once. And so on.
	// When the unit is constructed, the default is 1 (no recursion).
	//
	// Setting this limit higher than the maximal stack depth makes no sense.
	//
	// Be careful with the unlimted and other very high values: 
	// you still have an implicit limit in the form of the C++ thread stack
	// size. If you overrun the stack, the process will die and (optionally)
	// dump core.
	//
	// @param v - the limit; <=0 means "unlimited".
	void setMaxRecursionDepth(int v)
	{
		maxRecursionDepth_ = v;
	}

	int maxRecursionDepth() const
	{
		return maxRecursionDepth_;
	}
	// } Recursion control
	
protected:
	// Push a new frame onto the stack.
	void pushFrame();

	// Pop the current frame from stack.
	void popFrame();

	// A common internal implementation for call(). 
	// @param rop - rowop to call. It must be held by the caller until returned.
	void callGuts(Rowop *rop);

	// API for the Label execution machinery. Not intended to be called
	// directly by the user.
	// {
	
	// Extract and execute the next record from the innermost frame.
	// Does not push a new frame, executes directly in the parent's frame
	// May throw an Exception on fatal error.
	void callNextForked();
	// Execute callNextForked() the current stack frame drains.
	// Calls the tracing notifications around it.
	// Normally used to process the forked records after a label call returns.
	// May throw an Exception on fatal error.
	// @param lab - Label that has created the frame. Used for the tracing
	//     notification and error messages.
	// @param rop - Rowop that has created the frame. Used for the tracing
	//     notification.
	void drainForkedFrame(const Label *lab, Rowop *rop);

	// } Label execution.

protected:
	// the scheduling queue, trays work as stack frames on it
	// (there might be a more efficient way to do it, but for now it's good enough)
	typedef list< Autoref<UnitFrame> > FrameList;
	FrameList queue_;
	FrameList freePool_; // when frames are popped from queue, they're cached here
	UnitFrame *outerFrame_; // the outermost frame
	UnitFrame *innerFrame_; // the current innermost frame (may happen to be the same as outermost)
	Autoref<Tracer> tracer_; // the tracer object
	string name_; // human-readable name for tracing and messages
	Autoref <RowType> emptyRowType_; // a convenience copy of row type with no fields
	int stackDepth_; // number of frames in the queue
	// Keeping track of labels
	typedef map<Label *, Autoref<Label> > LabelMap;
	LabelMap labelMap_;
	int maxStackDepth_; // limit on the call stack depth, <= 0 means unlimited
	int maxRecursionDepth_; // limit on the recursive calls of the same label, <= 0 means unlimited
	bool clearing_; // prevents the recursive calls to clearLabels & friends

private:
	Unit(const Unit &);
	void operator=(const Unit &);
};

// The idea here is to have an object that definitely would not be involved in
// circular references, even if the Unit is. So when the trigger object 
// goes out of scope, it can trigger the clearLabels()
// call in the Unit. Of course, if you use it, it's your responsibility to not
// involve it in the circular references!
// The UnitClearingTrigger object must be owned by the same thread as its Unit.
class UnitClearingTrigger : public Mtarget
{
public:
	UnitClearingTrigger(Unit *unit);
	~UnitClearingTrigger();

protected:
	Autoref<Unit> unit_; // makes sure that the unit doesn't disappear
};

}; // TRICEPS_NS

#endif // __Triceps_Unit_h__
