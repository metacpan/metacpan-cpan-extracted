//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Type for the tables.

#include <type/TableType.h>
#include <type/RootIndexType.h>
#include <type/AggregatorType.h>
#include <type/HoldRowTypes.h>
#include <table/Table.h>
#include <common/Exception.h>

namespace TRICEPS_NS {

TableType::TableType(Onceref<RowType> rt) :
	Type(false, TT_TABLE),
	root_(new RootIndexType),
	rowType_(rt),
	initialized_(false)
{ }

TableType::~TableType()
{ }

TableType *TableType::copy() const
{
	TableType *cpt = new TableType(rowType_);
	// replace the root index type with a copy
	cpt->root_ = (RootIndexType *)root_->copy();
	return cpt;
}

TableType *TableType::deepCopy(HoldRowTypes *holder) const
{
	TableType *cpt = new TableType(holder->copy(rowType_));
	// replace the root index type with a copy
	cpt->root_ = (RootIndexType *)root_->deepCopy(holder);
	return cpt;
}

TableType *TableType::addSubIndex(const string &name, IndexType *index)
{
	if (initialized_) {
		Autoref<TableType> cleaner = this;
		throw Exception::fTrace("Attempted to add a sub-index '%s' to an initialized table type", name.c_str());
	}
	root_->addSubIndex(name, index);
	return this;
}

Erref TableType::getErrors() const
{
	return errors_;
}

bool TableType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t))
		return false;
	
	const TableType *tt = static_cast<const TableType *>(t);

	if (!rowType_->equals(tt->rowType_))
		return false;
	return root_->equals(tt->root_);
}

bool TableType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t))
		return false;
	
	const TableType *tt = static_cast<const TableType *>(t);

	if (!rowType_->match(tt->rowType_))
		return false;
	return root_->match(tt->root_);
}

void TableType::printTo(string &res, const string &indent, const string &subindent) const
{
	string bufindent;
	const string &passni = nextindent(indent, subindent, bufindent);

	res.append("table (");
	if (rowType_) {
		newlineTo(res, passni);
		rowType_->printTo(res, passni, subindent);
	}

	newlineTo(res, indent);
	res.append(")");
	root_->printTo(res, indent, subindent);
}

void TableType::initialize()
{
	if (initialized_)
		return; // nothing to do
	initialized_ = true;

	errors_ = new Errors;

	if (rowType_.isNull()) {
		errors_->appendMsg(true, "the row type is not set");
		return;
	}
	if (root_->isLeaf()) {
		errors_->appendMsg(true, "no indexes are defined");
		return;
	}

	errors_->append("row type error:", rowType_->getErrors());

	rhType_ = new RowHandleType;

	// collect the aggregators
	root_->collectAggregators(aggs_);

	// set the aggregator positions and check for duplicate gadget names
	set<string> gnames;
	gnames.insert("in");
	gnames.insert("out");

	size_t n = aggs_.size();
	for (size_t i = 0; i < n; i++) {
		aggs_[i].agg_->setPos((int)i);
		string name = aggs_[i].agg_->getName();
		// XXX improve the error message, print on which indexes
		if (gnames.find(name) != gnames.end())
			errors_->appendMsg(true, "duplicate aggregator/label name '" + name + "'");
		gnames.insert(name);
	}

	// XXX should it check that there is at least one index?
	root_->setNestPos(this, NULL, 0);
	root_->initialize();
	root_->initializeNested();
	errors_->append("index error:", root_->getErrors());

	if (!errors_->hasError() && errors_->isEmpty())
		errors_ = NULL;
}

Onceref<Table> TableType::makeTable(Unit *unit, const string &name) const
{
	if (!initialized_ || errors_->hasError())
		return NULL;

	return new Table(unit, name, this, rowType_, rhType_);
}

IndexType *TableType::findSubIndex(const string &name) const
{
	return root_->findSubIndex(name);
}

IndexType *TableType::findSubIndexById(IndexType::IndexId it) const
{
	return root_->findSubIndexById(it);
}

const IndexTypeVec &TableType::getSubIndexes() const
{
	return root_->getSubIndexes();
}

IndexType *TableType::getFirstLeaf() const
{
	if (root_->isLeaf())
		return NULL;
	return root_->getFirstLeaf();
}

}; // TRICEPS_NS
