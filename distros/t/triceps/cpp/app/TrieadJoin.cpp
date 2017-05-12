//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The base class that knows how to do a join() for a thread.

#include <app/TrieadJoin.h>

namespace TRICEPS_NS {

TrieadJoin::TrieadJoin(const string &name):
	name_(name),
	fi_(new FileInterrupt)
{ }

TrieadJoin::~TrieadJoin()
{ }

void TrieadJoin::interrupt()
{
	fi_->interrupt();
}

}; // TRICEPS_NS
