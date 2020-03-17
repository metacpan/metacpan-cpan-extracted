#include "Handle.h"
#include <ostream>

namespace panda { namespace unievent {

const HandleType Handle::UNKNOWN_TYPE("unknown");

std::ostream& operator<< (std::ostream& out, const HandleType& type) {
    return out << type.name;
}

}}
