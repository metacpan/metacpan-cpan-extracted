#ifndef __TEXT_DIFF_IO_HELPER_HPP__
#define __TEXT_DIFF_IO_HELPER_HPP__

#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <perlio.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"
#undef do_open
#undef do_close

#include <vector>
#include <sstream>

void split_lines(
        const char *s,
        std::vector<std::string> &lines
        );

void read_lines(
    pTHX_
    const char *fname,
    std::vector<std::string> &lines
    );

#endif
