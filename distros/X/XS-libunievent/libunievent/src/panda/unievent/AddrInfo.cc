#include "AddrInfo.h"
#include <sstream>
#include <ostream>

namespace panda { namespace unievent {

bool AddrInfo::operator== (const AddrInfo& oth) const {
    if (cur == oth.cur) return true;
    return cur && oth.cur &&
           family()   == oth.family()   &&
           socktype() == oth.socktype() &&
           protocol() == oth.protocol() &&
           flags()    == oth.flags()    &&
           addr()     == oth.addr();
}

std::string AddrInfo::to_string () {
    std::stringstream ss;
    ss << *this;
    return ss.str();
}

std::ostream& operator<< (std::ostream& os, const AddrInfo& ai) {
    auto cur = ai;
    while (cur) {
        os << cur.addr();
        cur = cur.next();
        if (cur) os << " ";
    }
    return os;
}

std::ostream& operator<< (std::ostream& os, const AddrInfoHints& hints) {
    os << "family=" << hints.family << ", socktype=" << hints.socktype << ", protocol=" << hints.protocol << ", flags=" << hints.flags;
    return os;
}

}}
