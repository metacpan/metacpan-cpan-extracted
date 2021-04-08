#pragma once
#include <xs.h>
#include <panda/log.h>

namespace xs { namespace xlog {

panda::log::Module* resolve_module(size_t depth);
bool has_module (SV* ref);
void optimize ();
void optimize (panda::log::Level level);

}}
