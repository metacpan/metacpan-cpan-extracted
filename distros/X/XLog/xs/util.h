#pragma once
#include <xs.h>
#include <panda/log.h>

namespace xs { namespace xlog {

const panda::log::Module* get_module_by_namespace ();
bool has_module (SV* ref);
void optimize ();
void optimize (panda::log::Level level);

}}
