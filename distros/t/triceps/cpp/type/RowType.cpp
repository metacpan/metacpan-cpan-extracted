//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The row type definition.

#include <type/RowType.h>
#include <map>
#include <string.h>

namespace TRICEPS_NS {


////////////////////// RowType ////////////////////////

RowType::RowType(const vector<Field> &fields) :
	Type(false, TT_ROW),
	fields_(fields)
{ 
	errors_ = parse();
}

const RowType::Field *RowType::find(const string &fname) const
{
	IdMap::const_iterator it = idmap_.find(fname);
	if (it == idmap_.end())
		return NULL;
	else
		return &fields_[it->second];
}

int RowType::findIdx(const string &fname) const
{
	IdMap::const_iterator it = idmap_.find(fname);
	if (it == idmap_.end())
		return -1;
	else
		return it->second;
}

int RowType::fieldCount() const
{
	return (int)fields_.size();
}

Erref RowType::getErrors() const
{
	return errors_;
}

bool RowType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t))
		return false;

	const RowType *rt = static_cast<const RowType *>(t);

	if (fields_.size() != rt->fields_.size())
		return false;

	size_t i, n = fields_.size();
	for (i = 0; i < n; i++) {
		if ( fields_[i].name_ != rt->fields_[i].name_
		|| !fields_[i].type_->equals(rt->fields_[i].type_) 
		|| fields_[i].arsz_ != rt->fields_[i].arsz_ )
			return false;
	}
	return true;
}

bool RowType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!Type::equals(t))
		return false;

	const RowType *rt = static_cast<const RowType *>(t);

	if (fields_.size() != rt->fields_.size())
		return false;

	size_t i, n = fields_.size();
	for (i = 0; i < n; i++) {
		if ( !fields_[i].type_->match(rt->fields_[i].type_) 
		|| fields_[i].arsz_ != rt->fields_[i].arsz_ )
			return false;
	}
	return true;
}

void RowType::printTo(string &res, const string &indent, const string &subindent) const
{
	string nextindent;
	const string *passni;
	if (&indent != &NOINDENT) {
		nextindent = indent + subindent;
		passni = &nextindent;
	} else {
		passni = &NOINDENT;
	}

	res.append("row {");

	size_t i, n = fields_.size();
	for (i = 0; i < n; i++) {
		if (&indent != &NOINDENT) {
			res.append("\n");
			res.append(nextindent);
		} else {
			res.append(" ");
		}
		fields_[i].type_->printTo(res, *passni, subindent);

		int arsz = fields_[i].arsz_;
		if (arsz == 0) {
			res.append("[]");
		} else if (arsz > 0) {
			res.append(strprintf("[%d]", arsz));
		}
		
		res.append(" ");
		res.append(fields_[i].name_);
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

Erref RowType::parse()
{
	Erref err;

	size_t i, n = fields_.size();

	idmap_.clear();
	for (i = 0; i < n; i++) {
		const string &name = fields_[i].name_;

		if (name.empty()) {
			err.f("field %d name must not be empty", (int)i+1);
			continue;
		}

		if (idmap_.find(name) != idmap_.end())  {
			err.f("duplicate field name '%s' for fields %d and %d",
				name.c_str(), (int)i+1, (int)(idmap_[name])+1);
		} else {
			idmap_[name] = i;
		}

		const Type *t = fields_[i].type_;
		if (!t->isSimple()) {
			err.f("field '%s' type must be a simple type", name.c_str());
		} else if(t->getTypeId() == TT_VOID) {
			err.f("field '%s' type must not be void", name.c_str());
		}
	}

	return err;
}

void RowType::splitInto(const Row *row, FdataVec &data) const
{
	int n = (int)fields_.size();
	data.resize(n);
	for (int i = 0; i < n; i++) {
		data[i].setFrom(this, row, i);
	}
}

Row *RowType::copyRow(const RowType *rtype, const Row *row) const
{
	FdataVec v;
	rtype->splitInto(row, v);
	if (v.size() > fields_.size())
		v.resize(fields_.size()); // truncate if too long
	return makeRow(v);
}

void RowType::fillFdata(FdataVec &v, int nf)
{
	int oldsz = (int) v.size();
	if (oldsz < nf) {
		v.resize(nf);
		for (int i = oldsz; i < nf; i++)
			v[i].notNull_ = false;
	}
}

uint8_t RowType::getUint8(const Row *row, int nf, int pos) const
{
	uint8_t val;

	const char *ptr;
	intptr_t len;
	bool notNull = getField(row, nf, ptr, len);
	if (notNull  && len >= sizeof(val)*(pos+1)) {
		memcpy(&val, ptr + sizeof(val)*pos, sizeof(val));
		return val;
	} else {
		return 0;
	}
}

int32_t RowType::getInt32(const Row *row, int nf, int pos) const
{
	int32_t val;

	const char *ptr;
	intptr_t len;
	bool notNull = getField(row, nf, ptr, len);
	if (notNull  && len >= sizeof(val)*(pos+1)) {
		memcpy(&val, ptr + sizeof(val)*pos, sizeof(val));
		return val;
	} else {
		return 0;
	}
}

int64_t RowType::getInt64(const Row *row, int nf, int pos) const
{
	int64_t val;

	const char *ptr;
	intptr_t len;
	bool notNull = getField(row, nf, ptr, len);
	if (notNull  && len >= sizeof(val)*(pos+1)) {
		memcpy(&val, ptr + sizeof(val)*pos, sizeof(val));
		return val;
	} else {
		return 0;
	}
}

double RowType::getFloat64(const Row *row, int nf, int pos) const
{
	double val;

	const char *ptr;
	intptr_t len;
	bool notNull = getField(row, nf, ptr, len);
	if (notNull  && len >= sizeof(val)*(pos+1)) {
		memcpy(&val, ptr + sizeof(val)*pos, sizeof(val));
		return val;
	} else {
		return 0;
	}
}

const char *RowType::getString(const Row *row, int nf) const
{
	const char *ptr;
	intptr_t len;
	bool notNull = getField(row, nf, ptr, len);
	if (notNull) {
		return ptr;
	} else {
		return "";
	}
}

}; // TRICEPS_NS
