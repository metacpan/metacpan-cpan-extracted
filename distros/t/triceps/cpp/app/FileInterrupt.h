//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Logic for interrupting the thread's wait on a file descriptor.

#ifndef __Triceps_FileInterupt_h__
#define __Triceps_FileInterupt_h__

#include <set>
#include <common/Common.h>
#include <pw/ptwrap2.h>
#include <mem/Mtarget.h>

namespace TRICEPS_NS {

// Keeps track of a set of file descriptors and revokes
// them when asked by dup2() over them of a /dev/null.
class FileInterrupt: public Mtarget
{
public:
	FileInterrupt();

	// Add a file descriptor to the set for interrupting.
	// @param fd - file descriptor to use for interrupting
	void trackFd(int fd);

	// Remove a file descriptor from the set for interrupting.
	// Call this before calling the actual close()!
	//
	// @param fd - file descriptor that was listed for interrupting
	void forgetFd(int fd);

	// Revoke the file descriptors.
	//
	// Sets the sticky flag interrupted_.
	//
	// This involves opening /dev/null, and of that fails, an
	// Exception will be thrown. Which should never happen.
	void interrupt();

	bool isInterrupted() const
	{
		return interrupted_;
	}

protected:
	typedef set<int> FdSet;

	// The internal version of interrupt()
	void interruptL();

	pw::pmutex mutex_;
	FdSet fds_;
	bool interrupted_; // flag: interrupt() was called
};

}; // TRICEPS_NS

#endif // __Triceps_FileInterupt_h__
