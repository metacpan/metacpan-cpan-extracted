#pragma once
#include "log.h"

namespace panda { namespace log {

/*
 * SYNTAX OF TOKEN: %X or %xX or %.yX or %x.yX
 * where x and y are optional digits (default is 0), and X is one of the following letters:
 * %L - level
 * %M - module
 *      if module has no name (root), removes x chars on the left and y chars on the right.
 * %F - function
 * %f - file
 *      x=0: only file name
 *      x=1: full path as it appeared during compilation
 * %l - line
 * %m - message
 * %t - current time
 *      x=0: YYYY/MM/DD HH:MM:SS
 *      x=1: YY/MM/DD HH:MM:SS
 *      x=2: HH:MM:SS
 *      x=3: UNIX TIMESTAMP
 *      y>0: high resolution time, adds fractional part after seconds with "y" digits precision
 * %T - current thread id
 * %p - current process id
 * %P - current process title
 * %c - start color
 * %C - end color
 */

extern string_view default_format;

struct PatternFormatter : IFormatter {
    PatternFormatter (string_view fmt) : _fmt(fmt) {}
    string format (std::string&, const Info&) const override;
private:
    string_view _fmt;
};

void set_format (string_view pattern);

}}
