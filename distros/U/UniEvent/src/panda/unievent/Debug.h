#pragma once
#include <panda/log.h>

namespace panda { namespace unievent {
    extern panda::log::Module& uelog; // for fast use from logs, defenition is in Loop.cc
    panda::log::Module& uelog_init();
}}

#define _ECTOR() do { panda_mlog_verbose_debug(uelog, __func__ << " [ctor]" ) } while(0)
#define _EDTOR() do { panda_mlog_verbose_debug(uelog, __func__ << " [dtor]" ) } while(0)
