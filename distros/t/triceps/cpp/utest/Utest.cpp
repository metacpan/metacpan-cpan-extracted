//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Definition of the simple unit test infrastructure.

#include <assert.h>
#include <utest/Utest.h>

Utest::Utest(int ac, char **av) :
	rc_(0),
	lastcase_(NULL),
	curcase_(0)
{
	// XXX parse the arguments...
}

void Utest::addcase(Testcase *fn, const char *name)
{
	cases_.push_back(fn);

	CaseInfo inf;
	inf.status_ = CS_UNKNOWN;
	if (name)
		inf.name_ = name;
	else
		inf.name_ = strprintf("%p", fn); // better than nothing
	info_[fn] = inf;
}

bool Utest::require(Testcase *pre)
{
	if (lastcase_ == pre)
		return false; // just ran it, succeed immediately

	Testcase *fn = curcase_; // remember
	TcInfo::iterator tinf = info_.find(fn);
	assert(tinf != info_.end());

	TcInfo::iterator it = info_.find(pre);
	if (it == info_.end()) {
		printf("      FAIL: prereq %p is unknown\n", pre);
		fflush(stdout);
		tinf->second.status_ = CS_FAIL;
		rc_ = 1;
		return true;
	}
	CaseStatus st = it->second.status_;
	if (st == CS_UNKNOWN || st == CS_OK) {
		curcase_ = pre;

		printf("    prereq %s\n", it->second.name_.c_str()); 
		fflush(stdout);
		curcase_(this); // run the case

		curcase_ = fn; // restore back

		st = it->second.status_;
		if (st == CS_UNKNOWN || st == CS_OK) {
			it->second.status_ = CS_OK;
			lastcase_ = pre;
			printf("    back to %s\n", tinf->second.name_.c_str()); 
			return false; // success
		}
	}

	printf("      SKIP: prereq %s did not succeed previously\n", it->second.name_.c_str());
	fflush(stdout);
	tinf->second.status_ = CS_SKIP;
	rc_ = 1;
	return true;
}

bool Utest::fail(const char *file, int line, string msg)
{
	printf("      FAIL at %s(%d): %s\n", file, line, msg.c_str());
	fflush(stdout);
	TcInfo::iterator tinf = info_.find(curcase_);
	assert(tinf != info_.end());
	tinf->second.status_ = CS_FAIL;
	rc_ = 1;
	return true;
}

int Utest::run()
{
	size_t ncases = cases_.size();
	lastcase_ = NULL;

	for (size_t i = 0; i < ncases; i++) {
		Testcase *fn = cases_[i];
		TcInfo::iterator tinf = info_.find(fn);
		assert(tinf != info_.end());
		if (tinf->second.status_ != CS_UNKNOWN)
			continue; // already ran, probably as some prerequisite
		curcase_ = fn;

		printf("  case %d/%d: %s\n", (int)i+1, (int)ncases, tinf->second.name_.c_str()); 
		fflush(stdout);
		curcase_(this); // run the case

		if (tinf->second.status_ == CS_UNKNOWN) {
			tinf->second.status_ = CS_OK; // if not reported FAIL then must be OK
			lastcase_ = fn; // remember only on success
		} else {
			lastcase_ = NULL; 
		}
	}

	return rc_;
}
