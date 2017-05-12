//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The base class for aggregators.

#include <common/Common.h>
#include <table/Aggregator.h>
#include <sched/AggregatorGadget.h>
#include <common/StringUtil.h>

namespace TRICEPS_NS {

Aggregator::~Aggregator()
{ }

Valname aggOpCodes[] = {
	{ Aggregator::AO_BEFORE_MOD, "AO_BEFORE_MOD" },
	{ Aggregator::AO_AFTER_DELETE, "AO_AFTER_DELETE" },
	{ Aggregator::AO_AFTER_INSERT, "AO_AFTER_INSERT" },
	{ Aggregator::AO_COLLAPSE, "AO_COLLAPSE" },
	{ -1, NULL }
};

const char *Aggregator::aggOpString(int code, const char *def)
{
	return enum2string(aggOpCodes, code, def);
}

int Aggregator::stringAggOp(const char *code)
{
	return string2enum(aggOpCodes, code);
}

}; // TRICEPS_NS

