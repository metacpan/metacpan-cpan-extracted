#pragma once
#include <panda/time/timezone.h>

namespace panda { namespace time {

bool tzparse      (const string_view&, Timezone*);
bool tzparse_rule (const string_view&, Timezone::Rule*);

}}
