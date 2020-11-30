#pragma once

namespace panda { namespace backtrace {

extern "C" {

extern volatile int fn_val;

int fn01();
int fn02();
int fn03();
}

}}
