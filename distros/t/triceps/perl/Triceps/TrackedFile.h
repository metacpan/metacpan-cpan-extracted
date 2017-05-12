//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The "wrapper" that stores the file tracker.

// Include TricepsPerl.h before this one.

#ifndef __TricepsPerl_TrackedFile_h__
#define __TricepsPerl_TrackedFile_h__

#include <common/Conf.h>
#include <app/TrieadOwner.h>
// #include "PerlCallback.h"

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

// The point of the TrackedFile object (at Perl level) is to make
// sure that the socket object won't get gestroyed (and thus
// automatically closed) before the TrieadOwner is told to forget
// its file descriptor. If that happens, it would cause a bad race
// potentially resulting in a completely unrelated file descriptor
// getting revoked.
//
// The race could happen if the Perl code in the thread dies.
// Then the socket variable will be freed as the code leaves the main function
// where it's defined but the forgetting in the TrieadOwner object won't
// happen until the enclosing block in the Triead::start exits.
//
// This object provides a two-way defense:
// First, it keeps a reference to the socket object, so that it won't
// get unreferenced and closed until this TrackedFile object is
// destroyed.
// Second, it provides the scoping semantics inside the main function,
// so that its destructor would be called when the main function exits,
// and then it will orderly make TrieadOwner forget the file descritpor,
// and then close and unreference the file descriptor.

extern WrapMagic magicWrapTrackedFile; // defined in TrackedFile.xs

// It's not really a wrapper, it's the actual tracking object,
// but named to look like the wrappers.
class WrapTrackedFile
{
public:
	// Starts the tracking and remembers the constituent parts.
	// @param owner - user here for the file tracking ability
	// @param svfile - Perl file handle object to track
	// @param afd - file descriptor extracted from the file handle
	//        (passed separately because the caller will likely have
	//        it conveniently available, and extracting it directly
	//        requires the cumbersome calling of the Perl code).
	//        The file descriptor must be already tracked, because
	//        it could throw an Exception and it's bad in a constructor.
	WrapTrackedFile(TrieadOwner *owner, SV *svfile, int afd);

	// The destrictor just forgets the Fd and drops the reference
	// to the file handle without explicitly closing it. 
	// If that was the last reference, Perl will close it by itself,
	// and if it wasn't then it's not our business closing it.
	~WrapTrackedFile();

	// Makes the TrieadOwner forget the file, then closes it
	// and dereferences the SV. 
	// Throws an Exception on errors.
	// Resets svfile_ to NULL and fd_ to -1. On a repeated call has no effect.
	void close();

	bool badMagic() const
	{
		return magic_ != magicWrapTrackedFile;
	}

	// The result may be -1 if the file is closed.
	int fd() const
	{
		return fd_;
	}

	// The result may be NULL if the file is closed.
	SV *sv() const
	{
		return svfile_;
	}

protected:
	WrapMagic magic_;
	Autoref<TrieadOwner> owner_; // used to track the file
	SV *svfile_; // the file handle object is held here
	int fd_; // the file descriptof from the file handle

private:
	WrapTrackedFile();
};

}; // Triceps::TricepsPerl
}; // Triceps

using namespace TRICEPS_NS::TricepsPerl;

#endif // __TricepsPerl_TrackedFile_h__
