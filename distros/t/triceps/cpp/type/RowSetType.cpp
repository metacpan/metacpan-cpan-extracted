//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Representation of an ordered set of row types. 

#include <type/RowSetType.h>
#include <type/HoldRowTypes.h>
#include <common/Exception.h>

namespace TRICEPS_NS {

RowSetType::RowSetType() :
	Type(false, TT_ROWSET),
	errors_(NULL),
	initialized_(false)
{ }

RowSetType *RowSetType::deepCopy(HoldRowTypes *holder) const
{
	RowSetType *cp = new RowSetType;
	int sz = types_.size();
	for (int i = 0; i < sz; i++) {
		cp->addRow(names_[i], holder->copy(types_[i]));
	}
	return cp;
}

RowSetType *RowSetType::addRow(const string &rname, const_Autoref<RowType>rtype)
{
	if (initialized_) {
		Autoref<RowSetType> cleaner = this;
		throw Exception("Triceps API violation: attempt to add row '" + rname + "' to an initialized row set type.", true);
	}

	int idx = names_.size();
	if (rname.empty()) {
		addError(strprintf("row name at position %d must not be empty", idx+1));
	} else if (nameMap_.find(rname) != nameMap_.end()) {
		addError("duplicate row name '" + rname + "'");
	} else if (rtype.isNull()) {
		addError("null row type with name '" + rname + "'");
	} else {
		names_.push_back(rname);
		types_.push_back(const_cast<RowType *>(rtype.get()));
		nameMap_[rname] = idx;
	}
	return this;
}

int RowSetType::findName(const string &name) const
{
	NameMap::const_iterator it = nameMap_.find(name);
	if (it != nameMap_.end())
		return it->second;
	else
		return -1;
}

RowType *RowSetType::getRowType(const string &name) const
{
	int idx = findName(name);
	if (idx < 0)
		return NULL;
	else
		return types_[idx];
}

RowType *RowSetType::getRowType(int idx) const
{
	if (idx >= 0 && idx < types_.size())
		return types_[idx];
	else
		return NULL;
}

const string *RowSetType::getRowTypeName(int idx) const
{
	if (idx >= 0 && idx < names_.size())
		return &names_[idx];
	else
		return NULL;
}

void RowSetType::addError(const string &msg)
{
	appendErrors()->appendMsg(true, msg);
}

Erref RowSetType::appendErrors()
{
	if (initialized_) {
		Autoref<RowSetType> cleaner = this;
		throw Exception("Triceps API violation: attempt to add an error to an initialized row set type.", true);
	}
	if (errors_.isNull())
		errors_ = new Errors;
	return errors_;
}

Erref RowSetType::getErrors() const
{
	return errors_;
}

bool RowSetType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t))
		return false;

	const RowSetType *rst = static_cast<const RowSetType *>(t);

	if (names_.size() != rst->names_.size())
		return false;

	size_t i, n = names_.size();
	for (i = 0; i < n; i++) {
		if ( names_[i] != rst->names_[i]
		|| !types_[i]->equals(rst->types_[i]) )
			return false;
	}
	return true;
}

bool RowSetType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t))
		return false;

	const RowSetType *rst = static_cast<const RowSetType *>(t);

	if (names_.size() != rst->names_.size())
		return false;

	size_t i, n = names_.size();
	for (i = 0; i < n; i++) {
		if ( !types_[i]->match(rst->types_[i]) )
			return false;
	}
	return true;
}

void RowSetType::printTo(string &res, const string &indent, const string &subindent) const
{
	string nextindent;
	const string *passni;
	if (&indent != &NOINDENT) {
		nextindent = indent + subindent;
		passni = &nextindent;
	} else {
		passni = &NOINDENT;
	}

	res.append("rowset {");

	size_t i, n = names_.size();
	for (i = 0; i < n; i++) {
		if (&indent != &NOINDENT) {
			res.append("\n");
			res.append(nextindent);
		} else {
			res.append(" ");
		}
		types_[i]->printTo(res, *passni, subindent);

		res.append(" ");
		res.append(names_[i]);
		res.append(",");
	}
	if (&indent != &NOINDENT) {
		res.append("\n");
		res.append(indent);
	} else {
		res.append(" ");
	}
	res.append("}");
}

}; // TRICEPS_NS
