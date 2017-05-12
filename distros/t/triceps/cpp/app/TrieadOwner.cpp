//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//

#include <app/TrieadOwner.h>
#include <common/BusyMark.h>

namespace TRICEPS_NS {

TrieadOwner::TrieadOwner(App *app, Triead *th) :
	app_(app),
	triead_(th),
	mainUnit_(new Unit(th->getName())),
	nexusMaker_(this),
	appReady_(false),
	busy_(false)
{
	units_.push_back(mainUnit_);
}

TrieadOwner::~TrieadOwner()
{
	markDead();
}

void TrieadOwner::markDead()
{
	app_->markTrieadDead(this);
	for (UnitList::iterator it = units_.begin(); it != units_.end(); ++it)
		(*it)->clearLabels();
	units_.clear();
	mainUnit_ = NULL;
	// The references app_ and triead_ don't need to be cleared.
}

void TrieadOwner::readyReady()
{
	markReady();
	app_->waitReady();
	appReady_ = true;
	triead_->setAppReady();
}

void TrieadOwner::addUnit(Autoref<Unit> u)
{
	for (UnitList::iterator it = units_.begin(); it != units_.end(); ++it) {
		if (*it == u)
			return; // a repeated insert, ignore
	}
	units_.push_back(u);
}

bool TrieadOwner::forgetUnit(Unit *u)
{
	if (u == mainUnit_)
		return false; // can not forget the main unit

	for (UnitList::iterator it = units_.begin(); it != units_.end(); ++it) {
		if (it->get() == u) {
			units_.erase(it);
			return true;
		}
	}
	return false;
}

Onceref<Facet> TrieadOwner::exportNexus(Autoref<Facet> facet, bool import)
{
	const string &name = facet->getFnReturn()->getName();
	if (facet->isImported())
		throw Exception::fTrace("In app '%s' thread '%s' can not re-export the imported facet '%s'.",
			app_->getName().c_str(), get()->getName().c_str(), facet->getFullName().c_str());
	Erref err = facet->getErrors();
	if (err->hasError()) {
		throw Exception::fTrace(err, "In app '%s' thread '%s' can not export the facet '%s' with an error:",
			app_->getName().c_str(), get()->getName().c_str(), name.c_str());
	}
	Autoref<Nexus> nexus = new Nexus(get()->getName(), facet);
	triead_->exportNexus(app_->getName(), nexus); // adds to the map or throws if duplicate
	if (import) {
		facet->reimport(nexus, get()->getName());
		if (triead_->importsFindL(facet->getFullName()) != triead_->importsEndL())
			throw Exception::fTrace("On exporting a facet in app '%s' found a same-named facet '%s' already imported, did you mess with the funny names?",
				app_->getName().c_str(), facet->getFullName().c_str());
		triead_->importFacet(facet);
	}
	return facet;
}

Onceref<Facet> TrieadOwner::importNexus(const string &tname, const string &nexname, const string &asname, 
	bool writer, bool immed)
{
	if (triead_->isReady())
		throw Exception::fTrace("In app '%s' thread '%s' can not import the nexus '%s/%s' into a ready thread.",
			app_->getName().c_str(), get()->getName().c_str(), tname.c_str(), nexname.c_str());
		
	// first look in the imported list
	string fullName = Facet::buildFullName(tname, nexname);
	FacetMap::const_iterator it = triead_->importsFindL(fullName);
	if (it != triead_->importsEndL()) {
		if (writer != it->second->isWriter()) {
			throw Exception::fTrace("In app '%s' thread '%s' can not import the nexus '%s' for both reading and writing.",
				app_->getName().c_str(), get()->getName().c_str(), fullName.c_str());
		}
		return it->second;
	}

	Autoref<Triead> t = findTriead(tname, immed); // may throw
	Autoref<Nexus> nx = t->findNexus(get()->getName(), app_->getName(), nexname); // may throw
	Autoref<Facet> facet = new Facet(mainUnit_, nx, fullName, (asname.empty()? nexname: asname), writer);
	triead_->importFacet(facet);
	return facet;
}

TrieadOwner::NexusMaker *TrieadOwner::makeNexusReader(const string &name)
{
	nexusMaker_.init(mainUnit_, name, false, true);
	return &nexusMaker_;
}

TrieadOwner::NexusMaker *TrieadOwner::makeNexusWriter(const string &name)
{
	nexusMaker_.init(mainUnit_, name, true, true);
	return &nexusMaker_;
}

TrieadOwner::NexusMaker *TrieadOwner::makeNexusNoImport(const string &name)
{
	nexusMaker_.init(mainUnit_, name, false, false);
	return &nexusMaker_;
}

Xtray *TrieadOwner::pickNextRound(Triead::FacetPtrRound &vec)
{
	int sz = vec.size();
	if (sz == 0)
		return NULL;

	int idx = vec.idx_; // continue from the last spot
	if (idx >= sz)
		idx = 0;
	int start = idx;

	do {
		Xtray *xt = vec[idx]->rd_->frontread();
		if (xt != NULL) {
			vec.idx_ = idx; // remembers where the xtray came from
			return xt;
		}
		if (++idx >= sz)
			idx = 0;
	} while (idx != start);
	return NULL; // nothing found
}

bool TrieadOwner::refillRound(Triead::FacetPtrRound &vec)
{
	if (triead_->rqDead_)
		return false;
	int sz = vec.size();
	bool found = false;
	for (int idx = 0; idx < sz; idx++)
		found |= vec[idx]->rd_->refill();
	return found;
}

bool TrieadOwner::nextXtray(bool wait, const struct timespec &abstime)
{
	if (!appReady_)
		throw Exception::fTrace("Can not read the facets in thread '%s' before waiting for App readiness.",
			triead_->getName().c_str());
	if (busy_)
		throw Exception::fTrace("Can not call the queue processing in thread '%s' recursively.",
			triead_->getName().c_str());

	BusyMark bm(busy_);

	Xtray *xt;
	bool filled = false;
	
	while (true) {
		Triead::FacetPtrRound &rhi = triead_->readersHi_;
		// try really hard to do the high-priority first
		if (!rhi.empty()) {
			xt = pickNextRound(rhi);
			if (xt == NULL && (filled = refillRound(rhi)))
				xt = pickNextRound(rhi);
			if (xt != NULL) {
				try {
					processXtray(xt, rhi[rhi.idx_]);
				} catch (Exception e) {
					rhi.popread();
					throw;
				}
				rhi.popread();
				if (filled)
					triead_->qev_->reset();
				flushWriters();
				return true;
			}
		} else if (triead_->readersLo_.empty()) {
			// no more readers of either priority
			return false;
		}

		Triead::FacetPtrRound &rlo = triead_->readersLo_;
		xt = pickNextRound(rlo);
		if (xt == NULL && (filled = refillRound(rlo)))
			xt = pickNextRound(rlo);
		if (xt != NULL) {
			try {
				processXtray(xt, rlo[rlo.idx_]);
			} catch (Exception e) {
				rlo.popread();
				throw;
			}
			rlo.popread();
			if (filled)
				triead_->qev_->reset();
			flushWriters();
			return true;
		}

		// This code is optimized for the case when the data comes
		// in faster than it can be handled, so in case if there is
		// little data, it may do two passes, consuming the signal
		// from the data that got already refilled.
		if (wait) {
			if (triead_->rqDead_)
				return false;
			if (&abstime == NULL)
				triead_->qev_->wait(); // wait for more data
			else 
				if (triead_->qev_->timedwait(abstime) == ETIMEDOUT)
					return false;
			if (triead_->rqDead_)
				return false;
		} else
			return false;
	}
}

bool TrieadOwner::nextXtrayTimeout(int64_t sec, int32_t nsec)
{
	timespec tm;
	clock_gettime(CLOCK_REALTIME, &tm);
	tm.tv_sec += sec;
	tm.tv_nsec += nsec;
	if (tm.tv_nsec >= 1000000000) {
		tm.tv_nsec -= 1000000000;
		tm.tv_sec++;
	}
	return nextXtray(true, tm);
}

void TrieadOwner::mainLoop()
{
	while (nextXtray())
		{ }
}

void TrieadOwner::processXtray(Xtray *xt, Facet *facet)
{
	if (xt->empty()) // should never happen
		return;

	int sz = xt->size();
	FnReturn *fret = facet->getFnReturn();

	{
		int beginIdx = facet->beginIdx();
		if (xt->frontIdx() != beginIdx) {
			Label *beginLabel = fret->checkLabelChained(beginIdx);
			if (beginLabel != NULL) {
				// generate a synthetic _BEGIN_
				FdataVec fd;
				mainUnit_->call(new Rowop(
					beginLabel, Rowop::OP_INSERT, beginLabel->getType()->makeRow(fd)));
				drainUnits();
			}
		}
	}
	for (int i = 0; i < sz; i++) {
		const Xtray::Op &op = xt->at(i);
		mainUnit_->call(new Rowop(
			fret->getLabel(op.idx_), op.opcode_, op.row_));
		drainUnits();
	}

	{
		int endIdx = facet->endIdx();
		if (xt->backIdx() != endIdx) {
			Label *endLabel = fret->checkLabelChained(endIdx);
			if (endLabel != NULL) {
				// generate a synthetic _END_
				FdataVec fd;
				mainUnit_->call(new Rowop(
					endLabel, Rowop::OP_INSERT, endLabel->getType()->makeRow(fd)));
				drainUnits();
			}
		}
	}
}

void TrieadOwner::drainUnits()
{
	// an optimization for the frequent case
	if (units_.size() == 1) {
		mainUnit_->drainFrame();
	} else {
		// keep draining all the units until all of them are empty
		// (since they may be interconnected and schedule data for each other,
		// need to keep repeating).
		bool repeat;
		do {
			repeat = false;

			for (UnitList::iterator it = units_.begin(); it != units_.end(); ++it) {
				Unit *u = *it;
				// this method is not expected to be called when the units are not
				// in the outer frame, but just in case, do the check about the
				// current frame and not complete empty() to avoid the possibility
				// of the endless loops
				if (!u->isFrameEmpty()) {
					u->drainFrame();
					repeat = true;
				}
			}
		} while(repeat);
	}
}

// ---------------------------- TrieadOwner::NexusMaker ---------------------------------

void TrieadOwner::NexusMaker::init(Unit *unit, const string &name, bool writer, bool import)
{
	// XXX should it throw if there are leftovers from the previous attempts?
	fret_ = new FnReturn(unit, name);
	facet_ = NULL;
	writer_ = writer;
	import_ = import;
}

void TrieadOwner::NexusMaker::mkfacet()
{
	if (facet_.isNull())
		facet_ = new Facet(fret_, writer_);
}

Autoref<Facet> TrieadOwner::NexusMaker::complete()
{
	mkfacet();
	fret_ = NULL;
	ow_->exportNexus(facet_, import_);
	Autoref<Facet> fa = facet_;
	facet_ = NULL;
	return fa;
}

}; // TRICEPS_NS
