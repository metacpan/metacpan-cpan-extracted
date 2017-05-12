//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Logic for interrupting the thread's wait on a file descriptor.

#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <app/FileInterrupt.h>

namespace TRICEPS_NS {

FileInterrupt::FileInterrupt():
	interrupted_(false)
{ }

void FileInterrupt::trackFd(int fd)
{
	pw::lockmutex lm(mutex_);
	fds_.insert(fd);
	// to avoid the race, need to revoke it right away
	if (interrupted_)
		interruptL();
}

void FileInterrupt::forgetFd(int fd)
{
	pw::lockmutex lm(mutex_);
	fds_.erase(fd);
}

void FileInterrupt::interrupt()
{
	pw::lockmutex lm(mutex_);
	interruptL();
}

void FileInterrupt::interruptL()
{
	interrupted_ = true;

	if (fds_.empty())
		return;

	int null = open("/dev/null", O_RDONLY);
	if (null < 0) {
		throw Exception::fTrace("Can not open /dev/null: %s", strerror(errno));
	}

	for (FdSet::iterator it = fds_.begin(); it != fds_.end(); ++it) {
		dup2(null, *it);
	}
	close(null);

	fds_.clear();
}

}; // TRICEPS_NS
