#include <xs/Sub.h>
#include <xs/Stash.h>
#include <xs/Object.h>
#include <panda/string.h>

namespace xs {

Stash Sub::stash () const { return CvSTASH((CV*)sv); }

Glob Sub::glob () const { return CvGV((CV*)sv); }

void Sub::_throw_super () const {
    throw std::invalid_argument(panda::string("can't locate super method '") + name() + "' via package '" + stash().name() + "'");
}

}
