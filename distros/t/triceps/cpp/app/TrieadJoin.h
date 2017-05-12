//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The base class that knows how to do a join() for a thread.

#ifndef __Triceps_TrieadJoin_h__
#define __Triceps_TrieadJoin_h__

#include <common/Common.h>
#include <mem/Mtarget.h>
#include <app/FileInterrupt.h>

namespace TRICEPS_NS {

// The detached threads are generally a bad idea, since there is
// no way to tell that they have nicely terminated at the program exit.
// A much nicer implementation is to call join() on every thread after
// it exits. But what join? The C++ part can't just assume the Posix threads.
// The threads might be originating from the interpreted language, like
// the Perl threads. The join needs to be done in the same terms.
// This base class allows to define whatever code needed to store the
// thread's identity and to execute a join() on it.
class TrieadJoin: public Mtarget
{
public:
	// Creates and remembers a file interruptor object.
	// @param tname - thread name, for error reporting if any
	TrieadJoin(const string &name);

	virtual ~TrieadJoin();

	// Perform a join() on the thread identity stored in this object.
	//
	// The subclass must define this method. It must also define some
	// way to put the thread's identity into the object.
	//
	// The method will be called when the thread reports that it is
	// about to exit.
	//
	// It's allowed to throw an Exception on major errors.
	virtual void join() = 0;
	
	// Tell the thread that it should exit by interrupting its
	// wait on the external inputs.
	// The default implementation works by revoking the file descriptors.
	// But the subclass may override or extend it.
	virtual void interrupt();

	// Get the file interruptor object.
	FileInterrupt *fileInterrupt() const
	{
		return fi_.get();
	}

	// Get the therad name, for error reporting.
	const string &getName() const
	{
		return name_;
	}

protected:
	string name_; // thread name, to report errors if any
	Autoref<FileInterrupt> fi_; // may be NULL

private:
	TrieadJoin();
};

}; // TRICEPS_NS

#endif // __Triceps_TrieadJoin_h__
