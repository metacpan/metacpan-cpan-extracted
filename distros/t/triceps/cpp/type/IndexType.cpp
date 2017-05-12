//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Type for creation of indexes in the tables.

#include <set>
#include <type/TableType.h>
#include <type/GroupHandleType.h>
#include <type/AggregatorType.h>
#include <type/HoldRowTypes.h>
#include <table/Index.h>
#include <table/Table.h>
#include <table/Aggregator.h>
#include <common/StringUtil.h>
#include <common/Exception.h>

namespace TRICEPS_NS {

/////////////////////// IndexTypeRef ////////////////////////////

IndexTypeRef::IndexTypeRef(const string &n, IndexType *it) :
	name_(n),
	index_(it)
{ }

IndexTypeRef::IndexTypeRef()
{ }

/*
IndexTypeRef::IndexTypeRef(const IndexTypeRef &orig) :
	name_(orig.name_),
	index_(orig.index_)
{ }
*/

/////////////////////// IndexTypeVec ////////////////////////////

IndexTypeVec::IndexTypeVec()
{ }

IndexTypeVec::IndexTypeVec(size_t size):
	vector<IndexTypeRef>(size)
{ }

IndexTypeVec::IndexTypeVec(const IndexTypeVec &orig, bool flat)
{
	if (!flat) {
		size_t n = orig.size();
		for (size_t i = 0; i < n; i++) 
			push_back(IndexTypeRef(orig[i].name_, orig[i].index_->copy()));
	}
}

IndexTypeVec::IndexTypeVec(const IndexTypeVec &orig, HoldRowTypes *holder)
{
	size_t n = orig.size();
	for (size_t i = 0; i < n; i++) 
		push_back(IndexTypeRef(orig[i].name_, orig[i].index_->deepCopy(holder)));
}

void IndexTypeVec::initialize(TableType *tabtype, IndexType *parent, Erref parentErr)
{
	if (!checkDups(parentErr))
		return;

	// XXX add a check for loops in the topology (or simply a limit on nesting levels?)

	size_t n = size();
	for (size_t i = 0; i < n; i++) {
		if (at(i).name_.empty()) {
			parentErr.f("nested index %d is not allowed to have an empty name", (int)i+1);
			continue;
		}
		IndexType *st = (*this)[i].index_;
		if (st == NULL) {
			parentErr.f("nested index %d '%s' reference must not be NULL", (int)i+1, at(i).name_.c_str());
			continue;
		}
		st->setNestPos(tabtype, parent, i);
		st->initialize();
	}
	if (parentErr->hasError())
		return; // don't even try the nested stuff
	// do it in the depth-last order
	for (size_t i = 0; i < n; i++) {
		at(i).index_->initializeNested();
		Erref se = at(i).index_->getErrors();
		parentErr.fAppend(se, "nested index %d '%s':", (int)i+1, at(i).name_.c_str());
	}
}

bool IndexTypeVec::checkDups(Erref parentErr)
{
	size_t n = size();
	if (n == 0)
		return true;

	set<string> known;

	bool res = true;
	for (size_t i = 0; i < n; i++) {
		const string &name = at(i).name_;
		if (known.find(name) != known.end()) {
			parentErr.f("nested index %d name '%s' is used more than once", (int)i+1, name.c_str());
			res = false;
		}
		known.insert(name);
	}
	return res;
}

void IndexTypeVec::printTo(string &res, const string &indent, const string &subindent) const
{
	for (IndexTypeVec::const_iterator i = begin(); i != end(); ++i) {
		newlineTo(res, indent);
		i->index_->printTo(res, indent, subindent);
		res.append(" ");
		res.append(i->name_);
		res.append(","); // extra comma after last field doesn't hurt
	}
}

void IndexTypeVec::initRowHandle(RowHandle *rh) const
{
	size_t n = size();
	for (size_t i = 0; i < n; i++) 
		(*this)[i].index_->initRowHandle(rh);
}

void IndexTypeVec::clearRowHandle(RowHandle *rh) const
{
	size_t n = size();
	for (size_t i = 0; i < n; i++) 
		(*this)[i].index_->clearRowHandle(rh);
}

IndexType *IndexTypeVec::find(const string &name) const
{
	// since the size is usually pretty small, linear search is fine
	size_t n = size();
	for (size_t i = 0; i < n; i++) 
		if((*this)[i].name_ == name)
			return (*this)[i].index_;
	return NULL;
}

IndexType *IndexTypeVec::findByIndexId(int it) const
{
	size_t n = size();
	for (size_t i = 0; i < n; i++) 
		if((*this)[i].index_->getIndexId() == it)
			return (*this)[i].index_;
	return NULL;
}

/////////////////////// IndexType ////////////////////////////

IndexType::IndexType(IndexId it) :
	Type(false, TT_INDEX),
	tabtype_(NULL),
	parent_(NULL),
	indexId_(it),
	initialized_(false)
{ }

IndexType::IndexType(const IndexType &orig, bool flat) :
	Type(false, TT_INDEX),
	nested_(orig.nested_, flat),
	tabtype_(NULL),
	parent_(NULL),
	agg_( (flat || orig.agg_.isNull())? NULL : orig.agg_->copy()),
	indexId_(orig.indexId_),
	initialized_(false)
{ 
}

IndexType::IndexType(const IndexType &orig, HoldRowTypes *holder) :
	Type(false, TT_INDEX),
	nested_(orig.nested_, holder),
	tabtype_(NULL),
	parent_(NULL),
	agg_(orig.agg_.isNull()? NULL : orig.agg_->deepCopy(holder)),
	indexId_(orig.indexId_),
	initialized_(false)
{ 
}

IndexType::~IndexType()
{ }

IndexType *IndexType::addSubIndex(const string &name, Onceref<IndexType> index)
{
	if (initialized_) {
		Autoref<IndexType> cleaner = this;
		throw Exception::fTrace("Attempted to add a sub-index '%s' to an initialized index type", name.c_str());
	}
	if (index.isNull())
		nested_.push_back(IndexTypeRef(name, NULL));
	else
		nested_.push_back(IndexTypeRef(name, index->copy()));
	return this;
}

IndexType *IndexType::setAggregator(Onceref<AggregatorType> agg)
{
	if (initialized_) {
		Autoref<IndexType> cleaner = this;
		throw Exception::fTrace("Attempted to set an aggregator on an initialized index type");
	}
	if (agg.isNull())
		agg_ = NULL;
	else
		agg_ = agg->copy();
	return this;
}

Erref IndexType::getErrors() const
{
	return errors_;
}

bool IndexType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t))
		return false;
	
	const IndexType *it = static_cast<const IndexType *>(t);
	if (indexId_ != it->getIndexId())
		return false;

	size_t n = nested_.size();
	if (n != it->nested_.size())
		return false;

	for (size_t i = 0; i < n; i++) {
		if (nested_[i].name_ != it->nested_[i].name_
		|| !nested_[i].index_->equals(it->nested_[i].index_))
			return false;
	}

	if ((agg_ != 0) ^ (it->agg_ != 0))
		return false;
	if (agg_ && !agg_->equals(it->agg_))
		return false;
		
	return true;
}

bool IndexType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t)) // same as match()
		return false;
	
	const IndexType *it = static_cast<const IndexType *>(t);
	if (indexId_ != it->getIndexId())
		return false;

	size_t n = nested_.size();
	if (n != it->nested_.size())
		return false;

	for (size_t i = 0; i < n; i++) {
		if (!nested_[i].index_->match(it->nested_[i].index_))
			return false;
	}

	if ((agg_ != 0) ^ (it->agg_ != 0))
		return false;
	if (agg_ && !agg_->match(it->agg_))
		return false;
		
	return true;
}

void IndexType::initializeNested()
{
	assert(isInitialized());

	if (errors_.isNull())
		errors_ = new Errors;

	int n = (int)nested_.size();

	groupAggs_.clear();
	if (n != 0) {
		// Collect the aggregators from the immediately nested indexes
		for (int i = 0; i < n; i++) {
			IndexType *si = nested_[i].index_;
			if (si == NULL)
				continue;
			AggregatorType *sag = si->agg_;
			if (sag == NULL)
				continue;
			groupAggs_.push_back(IndexAggTypePair(si, sag));
		}
		// remember, how much of handle was needed to get here
		group_ = new GroupHandleType(*tabtype_->rhType()); // copies the current size
		ghOffset_ = group_->allocate(sizeof(GhSection) + (n-1) * sizeof(Index *));
		ghAggOffset_ = group_->allocate(groupAggs_.size() * sizeof(Aggregator *));
	} else {
		group_ = NULL;
	}

	nested_.initialize(tabtype_, this, errors_);
	
	if (errors_->hasError())
		return; // skip the aggregators

	// initialize the aggregators
	if (!agg_.isNull()) {
		agg_->initialize(tabtype_, this);
		Erref se = agg_->getErrors();
		errors_.fAppend(se, "aggregator '%s':", agg_->getName().c_str());
		if (agg_->getRowType() == NULL)
			errors_.f("aggregator '%s' internal error: the result row type is not initialized",
				agg_->getName().c_str());
	}

	// optimize by nullifying the empty error set
	if (!errors_->hasError() && errors_->isEmpty())
		errors_ = NULL;
}

void IndexType::collectAggregators(IndexAggTypeVec &aggs)
{
	if (!agg_.isNull())
		aggs.push_back(IndexAggTypePair(this, agg_));

	int n = (int)nested_.size();
	for (int i = 0; i < n; i++) {
		IndexType *ni = nested_[i].index_;
		if (ni)
			ni->collectAggregators(aggs);
	}
}

void IndexType::printSubelementsTo(string &res, const string &indent, const string &subindent) const
{
	string bufindent;
	const string &passni = nextindent(indent, subindent, bufindent);

	if (!nested_.empty()) {
		res.append(" {");
		nested_.printTo(res, passni, subindent);
		newlineTo(res, indent);
		res.append("}");
	}
	if (!agg_.isNull()) {
		res.append(" {");
		newlineTo(res, passni);
		agg_->printTo(res, passni, subindent);
		newlineTo(res, indent);
		res.append("}");
	}
}

void IndexType::copyGroupHandle(GroupHandle *rh, const RowHandle *fromrh) const
{
	copyRowHandleSection(rh, fromrh);
	if (parent_ != NULL)
		parent_->copyGroupHandle(rh, fromrh);
}

void IndexType::clearGroupHandle(GroupHandle *rh) const
{
	clearRowHandleSection(rh);
	if (parent_ != NULL)
		parent_->clearGroupHandle(rh);
}

GroupHandle *IndexType::makeGroupHandle(const RowHandle *rh, Table *table) const
{
	const Row *r = rh->getRow();
	r->incref();
	GroupHandle *gh = group_->makeHandle(r);
	copyGroupHandle(gh, rh); // copy the key portions

	// now create and connect the sub-indexes
	GhSection *gs = getGhSection(gh);

	gs->size_ = 0; // empty yet

	int n = (int)nested_.size();
	for (int i = 0; i < n; i++) {
		Index *idx = nested_[i].index_->makeIndex(tabtype_, table);
		gs->subidx_[i] = idx;
		idx->incref(); // hold on to it manually
	}

	// create the aggregator instances
	n = (int)groupAggs_.size();
	if (n != 0) {
		Aggregator **aggs = getGhAggs(gh);
		for (int i = 0; i < n; i++) {
			const IndexAggTypePair &iap = groupAggs_[i];
			aggs[i] = iap.agg_->makeAggregator(table, table->getAggregatorGadget(iap.agg_->getPos()));
		}
	}

	return gh;
}

void IndexType::destroyGroupHandle(GroupHandle *gh) const
{
	GhSection *gs = getGhSection(gh);

	int n = (int)nested_.size();
	for (int i = 0; i < n; i++) {
		Index *idx = gs->subidx_[i];
		if (idx->decref() <= 0)
			delete idx;
	}
	
	// delete the aggregator instances
	n = (int)groupAggs_.size();
	if (n != 0) {
		Aggregator **aggs = getGhAggs(gh);
		for (int i = 0; i < n; i++) 
			delete aggs[i];
	}

	if (gh->getRow()->decref() <= 0) {
		tabtype_->rowType()->destroyRow(const_cast<Row *>(gh->getRow()));
	}

	delete gh;
}

RowHandle *IndexType::beginIteration(GroupHandle *gh) const
{
	if (gh == NULL)
		return NULL;

	GhSection *gs = getGhSection(gh);
	return gs->subidx_[0]->begin();
}

RowHandle *IndexType::nextIteration(GroupHandle *gh, const RowHandle *cur) const
{
	// fprintf(stderr, "DEBUG IndexType::nextIteration(this=%p, gh=%p, cur=%p)\n", this, gh, cur);
	if (gh == NULL)
		return NULL;

	GhSection *gs = getGhSection(gh);
	return gs->subidx_[0]->next(cur);
}

RowHandle *IndexType::last(GroupHandle *gh) const
{
	if (gh == NULL)
		return NULL;

	GhSection *gs = getGhSection(gh);
	return gs->subidx_[0]->last();
}

RowHandle *IndexType::beginIterationIdx(const Table *table) const
{
	// logically it's very much like findRecord(), only allows the non-leaf types too
	
	// fprintf(stderr, "DEBUG IndexType::beginIterationIdx(this=%p, table=%p)\n", this, table);
	const Index *myidx = parent_->findNestedIndex(nestPos_, table, NULL);
	if (myidx == NULL)
		return NULL;

	return myidx->begin();
}

RowHandle *IndexType::nextIterationIdx(const Table *table, const RowHandle *cur) const
{
	// logically it's very much like findRecord(), only allows the non-leaf types too
	
	// fprintf(stderr, "DEBUG IndexType::nextIterationIdx(this=%p, table=%p, cur=%p)\n", this, table, cur);

	const GroupHandle *parentgh = parent_->findGroupHandle(table, cur);
	if (parentgh == NULL) {
		// fprintf(stderr, "DEBUG IndexType::nextIterationIdx(this=%p, table=%p, cur=%p) parent NULL\n", this, table, cur);
		return NULL;
	}

	// Now we've got the handle of the group where the last record belonged.
	// The group handle is better here than the actual index because the group
	// handle allows to go up and to the next group while the index pointer doesn't.
	// This comes handy when the end of current group is reached.
	const GhSection *parentgs = parent_->getGhSection(parentgh);
	RowHandle *nextRow = parentgs->subidx_[nestPos_]->next(cur);

	// fprintf(stderr, "DEBUG IndexType::nextIterationIdx(this=%p, table=%p, cur=%p) nextRow=%p\n", this, table, cur, nextRow);
	while(nextRow == NULL) {
		parentgh = parent_->nextGroupHandle(table, parentgh);
		if (parentgh == NULL) {
			// fprintf(stderr, "DEBUG IndexType::nextIterationIdx(this=%p, table=%p, cur=%p) in loop parent NULL\n", this, table, cur);
			return NULL;
		}
		parentgs = parent_->getGhSection(parentgh);
		nextRow = parentgs->subidx_[nestPos_]->begin();
		// fprintf(stderr, "DEBUG IndexType::nextIterationIdx(this=%p, table=%p, cur=%p) nextRow=%p\n", this, table, cur, nextRow);
	}

	// fprintf(stderr, "DEBUG IndexType::nextIterationIdx(this=%p, table=%p, cur=%p) return %p\n", this, table, cur, nextRow);
	return nextRow;
}

RowHandle *IndexType::firstOfGroupIdx(const Table *table, const RowHandle *cur) const
{
	// logically it's very much like findRecord(), only allows the non-leaf types too
	
	// fprintf(stderr, "DEBUG IndexType::firstOfGroupIdx(this=%p, table=%p, cur=%p)\n", this, table, cur);

	const Index *myidx = parent_->findNestedIndex(nestPos_, table, cur);
	if (myidx == NULL)
		return NULL;
	RowHandle *first = myidx->begin();
	// fprintf(stderr, "DEBUG IndexType::firstOfGroupIdx(this=%p, table=%p, cur=%p) return %p\n", this, table, cur, first);
	return first;
}

RowHandle *IndexType::lastOfGroupIdx(const Table *table, const RowHandle *cur) const
{
	// logically it's very much like findRecord(), only allows the non-leaf types too
	
	// fprintf(stderr, "DEBUG IndexType::lastOfGroupIdx(this=%p, table=%p, cur=%p)\n", this, table, cur);

	const Index *myidx = parent_->findNestedIndex(nestPos_, table, cur);
	if (myidx == NULL)
		return NULL;
	RowHandle *last = myidx->last();
	// fprintf(stderr, "DEBUG IndexType::lastOfGroupIdx(this=%p, table=%p, cur=%p) return %p\n", this, table, cur, last);
	return last;
}

RowHandle *IndexType::nextGroupIdx(const Table *table, const RowHandle *cur) const
{
	// logically it's very much like findRecord(), only allows the non-leaf types too
	
	// fprintf(stderr, "DEBUG IndexType::nextGroupIdx(this=%p, table=%p, cur=%p)\n", this, table, cur);

	const GroupHandle *parentgh = parent_->findGroupHandle(table, cur);
	if (parentgh == NULL) {
		// fprintf(stderr, "DEBUG IndexType::nextGroupIdx(this=%p, table=%p, cur=%p) parent NULL\n", this, table, cur);
		return NULL;
	}
	// Now we've got the handle of the group where the last record belonged.
	// Step to the next group.
	parentgh = parent_->nextGroupHandle(table, parentgh);
	if (parentgh == NULL) {
		// fprintf(stderr, "DEBUG IndexType::nextGroupIdx(this=%p, table=%p, cur=%p) next parent NULL\n", this, table, cur);
		return NULL;
	}

	const GhSection *parentgs = parent_->getGhSection(parentgh);
	RowHandle *nextRow = parentgs->subidx_[nestPos_]->begin();

	// fprintf(stderr, "DEBUG IndexType::nextGroupIdx(this=%p, table=%p, cur=%p) nextRow=%p\n", this, table, cur, nextRow);
	while(nextRow == NULL) {
		parentgh = parent_->nextGroupHandle(table, parentgh);
		if (parentgh == NULL) {
			// fprintf(stderr, "DEBUG IndexType::nextGroupIdx(this=%p, table=%p, cur=%p) in loop parent NULL\n", this, table, cur);
			return NULL;
		}
		parentgs = parent_->getGhSection(parentgh);
		nextRow = parentgs->subidx_[nestPos_]->begin();
		// fprintf(stderr, "DEBUG IndexType::nextGroupIdx(this=%p, table=%p, cur=%p) nextRow=%p\n", this, table, cur, nextRow);
	}

	// fprintf(stderr, "DEBUG IndexType::nextGroupIdx(this=%p, table=%p, cur=%p) return %p\n", this, table, cur, nextRow);
	return nextRow;
}

// here the "what" record is known to be already present in the table
const GroupHandle *IndexType::findGroupHandle(const Table *table, const RowHandle *what) const
{
	// fprintf(stderr, "DEBUG IndexType::findGroupHandle(this=%p, table=%p, what=%p)\n", this, table, what);
	if (isLeaf())
		return NULL;

	const GroupHandle *gh;
	if (parent_ == NULL) {
		gh = table->getRoot()->toGroup(what);
	} else {
		const GroupHandle *parentgh = parent_->findGroupHandle(table, what);
		if (parentgh == NULL) {
			gh = NULL;
		} else {
			const GhSection *parentgs = parent_->getGhSection(parentgh);
			gh = parentgs->subidx_[nestPos_]->toGroup(what);
		}
	}
	
	// fprintf(stderr, "DEBUG IndexType::findGroupHandle(this=%p, table=%p, what=%p) return=%p\n", this, table, what, gh);
	return gh;
}

const GroupHandle *IndexType::nextGroupHandle(const Table *table, const GroupHandle *cur) const
{
	// fprintf(stderr, "DEBUG IndexType::nextGroupHandle(this=%p, table=%p, cur=%p)\n", this, table, cur);
	if (isLeaf() || cur == NULL)
		return NULL;

	const GroupHandle *gh;
	if (parent_ == NULL) {
		return NULL; // a special case: root index has only one group
	} else {
		const GroupHandle *parentgh = parent_->findGroupHandle(table, cur);
		if (parentgh == NULL) {
			gh = NULL;
		} else {
			const GhSection *parentgs = parent_->getGhSection(parentgh);
			gh = parentgs->subidx_[nestPos_]->nextGroup(cur);
			while (gh == NULL) { // reached the end of parent index
				parentgh = parent_->nextGroupHandle(table, parentgh);
				if (parentgh == NULL)
					return NULL;
				parentgs = parent_->getGhSection(parentgh);
				gh = parentgs->subidx_[nestPos_]->beginGroup();
			}
		}
	}

	// fprintf(stderr, "DEBUG IndexType::nextGroupHandle(this=%p, table=%p, cur=%p) return %p\n", this, table, cur, gh);
	return gh;
}

Index *IndexType::groupToIndex(GroupHandle *gh, size_t nestPos) const
{
	if (gh == NULL || nestPos >= nested_.size())
		return NULL;

	GhSection *gs = getGhSection(gh);
	return gs->subidx_[nestPos];
}

bool IndexType::groupReplacementPolicy(GroupHandle *gh, RowHandle *rh, RhSet &replaced) const
{
	if (gh == NULL)
		return true;

	GhSection *gs = getGhSection(gh);
	int n = (int)nested_.size();
	for (int i = 0; i < n; i++) {
		if ( !gs->subidx_[i]->replacementPolicy(rh, replaced))
			return false;
	}
	return true;
}

void IndexType::groupInsert(GroupHandle *gh, RowHandle *rh) const
{
	assert(gh != NULL);

	GhSection *gs = getGhSection(gh);
	int n = (int)nested_.size();
	for (int i = 0; i < n; i++) {
		gs->subidx_[i]->insert(rh);
	}
	++gs->size_; // a record got inserted
}

void IndexType::groupRemove(GroupHandle *gh, RowHandle *rh) const
{
	assert(gh != NULL);

	GhSection *gs = getGhSection(gh);
	int n = (int)nested_.size();
	for (int i = 0; i < n; i++) {
		gs->subidx_[i]->remove(rh);
	}
	--gs->size_; // a record got deleted
}


void IndexType::groupAggregateBefore(Tray *dest, Table *table, GroupHandle *gh, const RhSet &rows, const RhSet &already) const
{
	assert(gh != NULL);
	if (rows.empty())
		return;

	GhSection *gs = getGhSection(gh);
	int nn = (int)nested_.size();

	// any record present on the "already" set means that this
	// group has already been modified, so AO_BEFORE_MOD needs not be called again;
	// also the groups that have never been aggregated (just created) need to be skipped
	if (!groupAggs_.empty() && already.empty() && (gh->flags_ & GroupHandle::F_GROUP_AGGREGATED) ) {
		int an = (int)groupAggs_.size();
		Aggregator **aggs = getGhAggs(gh);

		for (int i = 0; i < an; i++) {
			const IndexAggTypePair &iap = groupAggs_[i];
			// no matter how many rows are in the set, call only once per group
			aggs[i]->handle(table, table->getAggregatorGadget(iap.agg_->getPos()), 
				gs->subidx_[iap.index_->nestPos_], this, gh, dest,
				Aggregator::AO_BEFORE_MOD, Rowop::OP_DELETE, NULL);
		}
	}

	for (int i = 0; i < nn; i++) {
		gs->subidx_[i]->aggregateBefore(dest, rows, already);
	}
}

void IndexType::groupAggregateAfter(Tray *dest, Aggregator::AggOp aggop, Table *table, GroupHandle *gh, const RhSet &rows, const RhSet &future) const
{
	assert(gh != NULL);
	if (rows.empty())
		return;

	GhSection *gs = getGhSection(gh);
	int nn = (int)nested_.size();

	if (!groupAggs_.empty()) {
		if (aggop == Aggregator::AO_AFTER_INSERT)
			gh->flags_ |= GroupHandle::F_GROUP_AGGREGATED;

		int an = (int)groupAggs_.size();
		Aggregator **aggs = getGhAggs(gh);

		const RowHandle *lastRow = NULL; // one, for which to send OP_INSERT
		if (future.empty()) {
			// if future is not empty then the final update will occur later
			lastRow = *rows.rbegin();
		}

		for (int i = 0; i < an; i++) {
			const IndexAggTypePair &iap = groupAggs_[i];
			AggregatorGadget *gadget = table->getAggregatorGadget(iap.agg_->getPos());
			Index *subidx = gs->subidx_[iap.index_->nestPos_];

			for (RhSet::const_iterator rit = rows.begin(); rit != rows.end(); ++rit) {
				aggs[i]->handle(table, gadget, subidx, this, gh, dest, aggop, 
					(*rit == lastRow ? Rowop::OP_INSERT : Rowop::OP_NOP), 
					*rit);
			}
		}
	}

	for (int i = 0; i < nn; i++) {
		gs->subidx_[i]->aggregateAfter(dest, aggop, rows, future);
	}
}

bool IndexType::groupCollapse(Tray *dest, GroupHandle *gh, const RhSet &replaced) const
{
	assert(gh != NULL);

	GhSection *gs = getGhSection(gh);
	bool res = (gs->size_ == 0);

	// even if the size != 0, still must go through recursion, because
	// there may be collapsible sub-groups
	int n = (int)nested_.size();
	// fprintf(stderr, "DEBUG IndexType::groupCollapse(this=%p, gh=%p, rhset size=%d) gsize=%d, nested=%d\n", this, gh, (int)replaced.size(), (int)gs->size_, n);
	for (int i = 0; i < n; i++) {
		res = (gs->subidx_[i]->collapse(dest, replaced) && res);
	}

	return res;
}

size_t IndexType::groupSize(const GroupHandle *gh) const
{
	if (gh == NULL)
		return 0;

	GhSection *gs = getGhSection(gh);
	return gs->size_;
}

void IndexType::groupClearData(GroupHandle *gh) const
{
	if (gh == NULL)
		return;

	GhSection *gs = getGhSection(gh);
	int n = (int)nested_.size();
	for (int i = 0; i < n; i++) {
		gs->subidx_[i]->clearData();
	}
	gs->size_ = 0; // all records got deleted
}

void IndexType::aggregateCollapse(Tray *dest, Table *table, GroupHandle *gh) const
{
	assert(gh != NULL);

	if ( !(gh->flags_ & GroupHandle::F_GROUP_AGGREGATED) )
		return; // this is a blind group that was created and immediately collapsed

	int n = (int)groupAggs_.size();
	if (n != 0) {
		GhSection *gs = getGhSection(gh);
		Aggregator **aggs = getGhAggs(gh);
		for (int i = 0; i < n; i++) {
			const IndexAggTypePair &iap = groupAggs_[i];
			aggs[i]->handle(table, table->getAggregatorGadget(iap.agg_->getPos()), 
				gs->subidx_[iap.index_->nestPos_], this, gh, dest,
				Aggregator::AO_COLLAPSE, Rowop::OP_NOP, NULL);
		}
	}
}

RowHandle *IndexType::findRecord(const Table *table, const RowHandle *what) const
{
	// fprintf(stderr, "DEBUG IndexType::findRecord(this=%p, table=%p, what=%p)\n", this, table, what);
	if (isLeaf()) {
		const Index *myidx = parent_->findNestedIndex(nestPos_, table, what);
		// fprintf(stderr, "DEBUG IndexType::findRecord(this=%p, table=%p, what=%p) found idx=%p\n", this, table, what, myidx);
		if (myidx == NULL)
			return NULL;
		return myidx->find(what);
	} else {
		const Index *subidx = findNestedIndex(0, table, what);
		if (subidx == NULL)
			return NULL;
		return subidx->begin();
	}
}

Index *IndexType::findInstance(const Table *table, const RowHandle *what) const
{
	// fprintf(stderr, "DEBUG IndexType::findInstance(this=%p, table=%p, what=%p)\n", this, table, what);
	Index *myidx = parent_->findNestedIndex(nestPos_, table, what);
	return myidx;
}

Index *IndexType::findNestedIndex(int nestPos, const Table *table, const RowHandle *what) const
{
	// fprintf(stderr, "DEBUG IndexType::findNestedIndex(this=%p, nestPos=%d, table=%p, what=%p)\n", this, nestPos, table, what);
	if (isLeaf())
		return NULL;

	Index *myinst;
	if (parent_ == NULL) {
		myinst = table->getRoot();
	} else {
		myinst = parent_->findNestedIndex(nestPos_, table, what);
	}
	if (myinst == NULL)
		return NULL;
	return myinst->findNested(what, nestPos);
}

size_t IndexType::groupSizeOfRecord(const Table *table, const RowHandle *what) const
{
	if (isLeaf())
		return 0;

	if (!what->isInTable()) {
		what = findRecord(table, what);
		if (what == NULL)
			return 0;
	}
	// now "what" is known to be in the table
	
	return groupSize(findGroupHandle(table, what));
}

Valname indexids[] = {
	{ IndexType::IT_ROOT, "IT_ROOT" },
	{ IndexType::IT_HASHED, "IT_HASHED" },
	{ IndexType::IT_FIFO, "IT_FIFO" },
	{ IndexType::IT_SORTED, "IT_SORTED" },
	{ IndexType::IT_LAST, "IT_LAST" },
	{ -1, NULL }
};

const char *IndexType::indexIdString(int enval, const char *def)
{
	return enum2string(indexids, enval, def);
}

int IndexType::stringIndexId(const char *str)
{
	return string2enum(indexids, str);
}

}; // TRICEPS_NS
