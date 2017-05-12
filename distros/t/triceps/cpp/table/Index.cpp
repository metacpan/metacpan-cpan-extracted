//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The common interface for indexes.

#include <table/Index.h>
#include <type/TableType.h>

namespace TRICEPS_NS {

////////////////////////// Index ///////////////////////////////////

Index::Index(const TableType *tabtype, Table *table) :
	tabType_(tabtype),
	table_(table)
{ }

Index::~Index()
{ }

}; // TRICEPS_NS

