//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Nexus is a communication point between the threads, a set of labels
// for passing data downstream and upstream.

#include <app/Nexus.h>
#include <app/Facet.h>
#include <type/HoldRowTypes.h>

namespace TRICEPS_NS {

Nexus::Nexus(const string &tname, Facet *facet):
	tname_(tname),
	name_(facet->getShortName()),
	// the "no limit" for reverse nexus translates to a very large limit
	queueLimit_(facet->isReverse()? Xtray::QUE_ID_MAX: facet->queueLimit()),
	beginIdx_(facet->beginIdx_),
	endIdx_(facet->endIdx_),
	reverse_(facet->isReverse())
#if 0  // {
	unicast_(facet->isUnicast())
#endif // }
{ 
	// deep-copy the types
	Autoref<HoldRowTypes> holder = new HoldRowTypes;
	type_ = facet->getFnReturn()->getType()->deepCopy(holder);
	for (RowTypeMap::iterator it = facet->rowTypes_.begin(); it != facet->rowTypes_.end(); ++it)
		rowTypes_[it->first] = holder->copy(it->second);
	for (TableTypeMap::iterator it = facet->tableTypes_.begin(); it != facet->tableTypes_.end(); ++it)
		tableTypes_[it->first] = it->second->deepCopy(holder);
}

void Nexus::addReader(ReaderQueue *rq)
{
	pw::lockmutex lm(mutex_);

	// in the new reader vector set the next generation
	int gen = 0;
	if (!readers_.isNull())
		gen = readers_->gen()+1;

	// make the new vector, with the next generation
	Autoref<ReaderVec> rnew = new ReaderVec(gen);
	if (!readers_.isNull())
		rnew->v_ = readers_->v();
	rnew->v_.push_back(rq); // doesn't check for duplicates

	rq->setGenL(gen);

	// the first reader is used to issue the sequential ids to the
	// Xtrays in the queue, so use it also to synchronize the whole
	// set of readers
	if (!readers_.isNull() && !readers_->v().empty()) {
		ReaderVec::Vec::const_iterator it = readers_->v().begin();
		ReaderVec::Vec::const_iterator end = readers_->v().end();
		ReaderQueue *rfirst = *it++;

		pw::lockmutex lm(rfirst->mutex());

		rfirst->setGenL(gen);
		rq->prevId_ = rq->lastId_ = rfirst->lastId_;

		for (; it != end; ++it) {
			pw::lockmutex lm((*it)->mutex());
			(*it)->setGenL(gen);
		}

		for (WriterVec::iterator wit = writers_.begin(); wit != writers_.end(); ++wit)
			(*wit)->setReaderVec(rnew);
	} else {
		// the new reader is the first one
		rq->prevId_ = rq->lastId_ = 0; // any value is good, as long as it's the same

		for (WriterVec::iterator wit = writers_.begin(); wit != writers_.end(); ++wit)
			(*wit)->setReaderVec(rnew);
	}

	readers_ = rnew;
}
	
void Nexus::deleteReader(ReaderQueue *rq)
{
	pw::lockmutex lm(mutex_);

	if (readers_.isNull() || readers_->v().empty())
		// not sure why this call would be made at all
		return;

	// in the new reader vector set the next generation
	int gen = readers_->gen()+1;

	// make the new vector, with the next generation
	Autoref<ReaderVec> rnew = new ReaderVec(gen);
	ReaderVec::Vec::const_iterator it = readers_->v().begin();
	ReaderVec::Vec::const_iterator end = readers_->v().end();
	for (; it != end; ++it)
		if (*it != rq)
			rnew->v_.push_back(*it);

	{
		ReaderQueue *rfirst = *readers_->v().begin();

		pw::lockmutex lm(rfirst->mutex());

		rfirst->setGenL(gen);
		Xtray::QueId idx = rfirst->lastId_; // read before setting dead!

		if (rq == rfirst) {
			rq->markDeadL();
		} else {
			pw::lockmutex lm(rq->mutex());
			rq->markDeadL();
		}

		end = rnew->v().end();
		for (it = rnew->v().begin(); it != end; ++it) {
			if (*it == rfirst)
				continue;
			pw::lockmutex lm((*it)->mutex());
			(*it)->setLastIdL(idx);
			(*it)->setGenL(gen);
		}

		for (WriterVec::iterator wit = writers_.begin(); wit != writers_.end(); ++wit)
			(*wit)->setReaderVec(rnew);
	}

	readers_ = rnew;
}

void Nexus::addWriter(NexusWriter *wr)
{
	pw::lockmutex lm(mutex_);
	wr->setReaderVec(readers_);
	writers_.push_back(wr);
}

void Nexus::deleteWriter(NexusWriter *wr)
{
	{
		pw::lockmutex lm(mutex_);
		int sz = writers_.size();
		for (int i = 0; i< sz; i++)
			if (writers_[i].get() == wr) {
				// replace this element with the last one, and discard the last one
				if (i != sz-1)
					writers_[i] = writers_[sz-1];
				writers_.pop_back();
				break;
			}
	}
	wr->setReaderVec(NULL); // it won't be writing anything any more
}

}; // TRICEPS_NS
