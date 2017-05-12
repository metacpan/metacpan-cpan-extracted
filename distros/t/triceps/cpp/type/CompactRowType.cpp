//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Row type that operates on CompactRow internal representation.

#include <string.h>
#include <type/CompactRowType.h>
#include <common/StringUtil.h>

namespace TRICEPS_NS {

CompactRowType::CompactRowType(const FieldVec &fields) :
	RowType(fields)
{ }

CompactRowType::CompactRowType(const RowType &proto) :
	RowType(proto)
{ }

CompactRowType::CompactRowType(const RowType *proto) :
	RowType(*proto)
{ }

CompactRowType::~CompactRowType()
{ }

RowType *CompactRowType::newSameFormat(const FieldVec &fields) const
{
	return new CompactRowType(fields);
}

bool CompactRowType::isFieldNull(const Row *row, int nf) const
{
	return static_cast<const CompactRow *>(row)->isFieldNull(nf);
}

bool CompactRowType::getField(const Row *row, int nf, const char *&ptr, intptr_t &len) const
{
	const CompactRow *cr = static_cast<const CompactRow *>(row);
	ptr = cr->getFieldPtr(nf);
	len = cr->getFieldLen(nf);
	return cr->isFieldNotNull(nf);
}

Row *CompactRowType::makeRow(FdataVec &data) const
{
	int i;
	int n = (int)fields_.size();

	if ((int)data.size() < n)
		fillFdata(data, n);
	
	// calculate the length
	intptr_t paylen = 0;
	for (i = 0; i < n; i++) {
		if (data[i].notNull_)
			paylen += data[i].len_;
	}
	CompactRow *row = new (CompactRow::variableLen(n, paylen)) CompactRow;
	
	// copy in the data from the main data entries
	intptr_t off = CompactRow::payloadOffset(n);
	char *to = row->payloadPtrW(n);
	for (i = 0; i < n; i++) {
		if (data[i].notNull_) {
			row->off_[i] = off;
			intptr_t len = data[i].len_;
			const char *d = data[i].data_;
			if (d == NULL) {
				memset(to, 0, len);
			} else {
				memcpy(to, d, len);
			}
			off += len;
			to += len;
		} else {
			row->off_[i] = (off | CompactRow::NULLMASK);
		}
	}
	row->off_[i] = off; // past last field

	// fill the overrides
	int nd = (int)data.size();
	for (i = n; i < nd; i++) {
		int f = data[i].nf_;
		if (f >= n)
			continue; // wrong field?
		off = data[i].off_;
		intptr_t len = data[i].len_;
		const char *d = data[i].data_;
		// NULL field will have a length of 0
		if (off < 0 || len <= 0 || d == NULL || off + len > row->getFieldLen(f))
			continue;
		memcpy(row->getFieldPtrW(f) + off, d, len);
	}

	return row;
}

void CompactRowType::destroyRow(Row *row) const
{
	delete static_cast<CompactRow *>(row);
}

void CompactRowType::hexdumpRow(string &dest, const Row *row, const string &indent) const
{
	const CompactRow *cr = static_cast<const CompactRow *>(row);
	intptr_t len = cr->off_[fields_.size()];
	hexdump(dest, cr->off_, len, indent.c_str());
}
	
bool CompactRowType::equalRows(const Row *row1, const Row *row2) const
{
	if (row1 == row2)
		return true; // short-circuit
		
	size_t nf = fields_.size();
	const CompactRow *cr1 = static_cast<const CompactRow *>(row1);
	intptr_t len1 = cr1->off_[nf];
	const CompactRow *cr2 = static_cast<const CompactRow *>(row2);
	if (len1 != cr2->off_[nf])
		return false;
	return memcmp(cr1->off_, cr2->off_, len1) == 0;
}

bool CompactRowType::isRowEmpty(const Row *row) const
{
	const CompactRow *cr = static_cast<const CompactRow *>(row);
	return cr->isRowEmpty((int)fields_.size());
}

}; // TRICEPS_NS
