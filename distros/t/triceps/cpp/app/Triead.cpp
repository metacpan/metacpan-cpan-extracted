//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A Triceps Thread.  It keeps together the Nexuses defined by the thread and
// is also used to track the state of the app initialization.

#include <app/Triead.h>

namespace TRICEPS_NS {

Triead::Triead(const string &name, const string &fragname, DrainApp *drain) :
	name_(name),
	frag_(fragname),
	qev_(new QueEvent(drain)),
	inputOnly_(false),
	appReady_(false),
	rqDead_(false),
	constructed_(false),
	ready_(false),
	dead_(false)
{ }

void Triead::clear()
{
	pw::lockmutex lm(mutex_);
	exports_.clear();
}

Triead::~Triead()
{
	clear();
}

void Triead::markConstructed()
{
	constructed_ = true;
}

void Triead::markReady()
{
	markConstructed();
	if (!ready_) {
		ready_ = true;
		if (readersHi_.empty() && readersLo_.empty()) {
			inputOnly_ = true;
			qev_->setWriteMode();
			for (FacetPtrVec::iterator it = writers_.begin(); it != writers_.end(); ++it)
				(*it)->setInputTriead();
		}
	}
}

void Triead::markDead()
{
	markReady();
	dead_ = true;
	qev_->markDead();

	{
		pw::lockmutex lm(imports_mutex_);
		// and disconnect all the nexuses, clearing their queues
		for (FacetMap::iterator it = imports_.begin(); it != imports_.end(); ++it)
			it->second->disconnectFromNexus();

		// and get rid of all the facet references; this is important for Perl:
		// otherwise the facets won't be freed until after the Triead object
		// is freed, and thay would happen only after join() and in a different
		// thread, which drives the Perl memory management crazy
		readersHi_.clear();
		readersLo_.clear();
		writers_.clear();
		imports_.clear();
	}
}

void Triead::exportNexus(const string &appName, Nexus *nexus)
{
	pw::lockmutex lm(mutex_);

	if (constructed_)
		throw Exception::fTrace("Can not export the nexus '%s' in app '%s' thread '%s' that is already marked as constructed.",
			nexus->getName().c_str(), appName.c_str(), name_.c_str());

	if (exports_.find(nexus->getName()) != exports_.end())
		// the message is intentionally different than in TrieadOwner::exportNexus
		throw Exception::fTrace("Can not export the nexus with duplicate name '%s' in app '%s' thread '%s'.",
			nexus->getName().c_str(), appName.c_str(), name_.c_str());
	exports_[nexus->getName()] = nexus;
}

void Triead::exports(NexusMap &ret) const
{
	pw::lockmutex lm(mutex_);

	if (!ret.empty())
		ret.clear();

	// copy a snapshot of the exports map to the return value
	for (NexusMap::const_iterator it = exports_.begin(); it != exports_.end(); ++it)
		ret.insert(*it);
}

void Triead::imports(NexusMap &ret) const
{
	pw::lockmutex lm(imports_mutex_);

	if (!ret.empty())
		ret.clear();

	// copy a snapshot of the exports map to the return value
	for (FacetMap::const_iterator it = imports_.begin(); it != imports_.end(); ++it)
		ret[it->first] = it->second->nexus();
}

void Triead::readerImports(NexusMap &ret) const
{
	pw::lockmutex lm(imports_mutex_);

	if (!ret.empty())
		ret.clear();

	// copy a snapshot of the exports map to the return value
	for (FacetMap::const_iterator it = imports_.begin(); it != imports_.end(); ++it) {
		if (!it->second->isWriter())
			ret[it->first] = it->second->nexus();
	}
}

void Triead::writerImports(NexusMap &ret) const
{
	pw::lockmutex lm(imports_mutex_);

	if (!ret.empty())
		ret.clear();

	// copy a snapshot of the exports map to the return value
	for (FacetMap::const_iterator it = imports_.begin(); it != imports_.end(); ++it) {
		if (it->second->isWriter())
			ret[it->first] = it->second->nexus();
	}
}

void Triead::facets(FacetMap &ret) const
{
	pw::lockmutex lm(imports_mutex_);

	if (!ret.empty())
		ret.clear();

	// copy a snapshot of the exports map to the return value
	for (FacetMap::const_iterator it = imports_.begin(); it != imports_.end(); ++it)
		ret.insert(*it);
}

Onceref<Nexus> Triead::findNexus(const string &srcName, const string &appName, const string &name) const
{
	pw::lockmutex lm(mutex_);

	NexusMap::const_iterator it = exports_.find(name);
	if (it == exports_.end())
		throw Exception::fTrace("For thread '%s', the nexus '%s' is not found in application '%s' thread '%s'.", 
			srcName.c_str(), name.c_str(), appName.c_str(), name_.c_str());

	return it->second;
}

void Triead::importFacet(Onceref<Facet> facet)
{
	pw::lockmutex lm(imports_mutex_);

	facet->connectToNexus(qev_, rqDead_);

	if (facet->isWriter())
		writers_.push_back(facet.get());
	else if (facet->isReverse())
		readersHi_.push_back(facet.get());
	else
		readersLo_.push_back(facet.get());

	// last, since it erases the Onceref value
	imports_[facet->getFullName()] = facet;
}

void Triead::setAppReady()
{
	appReady_ = true;
	for (FacetMap::iterator it = imports_.begin(); it != imports_.end(); ++it)
		it->second->setAppReady();
}

void Triead::drain()
{
	// This happens to cover both normal and input-only threads.
	qev_->requestDrain();
}

void Triead::undrain()
{
	// This happens to cover both normal and input-only threads.
	qev_->requestUndrain();
}

void Triead::requestDead()
{
	rqDead_ = true; // this is set-only, and at very least the mutex in qev_ will synchronize the CPU caches
	if (inputOnly_)
		qev_->markDead(); // the special case
	else
		// this might mark it as undrained but after the thread 
		// dies, it will be drained again
		qev_->signal(); 
	{
		pw::lockmutex lm(imports_mutex_);
		// and disconnect all the nexuses, clearing their queues;
		// this complicates the Facet logic by allowing the disconnectFromNexus()
		// to be called from other threads but overall is useful because
		// it prevents the nexuses from being stuck on the filled queue of 
		// a thread requested to die until it actually dies
		for (FacetMap::iterator it = imports_.begin(); it != imports_.end(); ++it)
			it->second->disconnectFromNexus();
	}
}

bool Triead::flushWriters()
{
	if (!appReady_) {
		throw Exception::fTrace("Can not flush the thread '%s' before waiting for App readiness.",
			name_.c_str());
	}

	if (inputOnly_) {
		if (!qev_->beforeWrite()) {
			Triead::FacetPtrVec::iterator it = writers_.begin();
			Triead::FacetPtrVec::iterator end = writers_.end();
			for (; it != end; ++it)
				(*it)->discardXtray();
			return false;
		}
	}

	Triead::FacetPtrVec::iterator it = writers_.begin();
	Triead::FacetPtrVec::iterator end = writers_.end();
	for (; it != end; ++it)
		(*it)->flushWriterD();

	if (inputOnly_)
		qev_->afterWrite();
	return true;
}

#if 0 // {
int Triead::exportsCount() const
{
	pw::lockmutex lm(mutex_);
	return (int)exports_.size();
}
#endif // }

}; // TRICEPS_NS
