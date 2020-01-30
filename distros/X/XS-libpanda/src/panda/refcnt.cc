#include "refcnt.h"

namespace panda {

iptr<weak_storage> panda::Refcnt::get_weak() const {
    if (!_weak) _weak = new weak_storage();
    return _weak;
}

Refcnt::~Refcnt() {
    if (_weak) _weak->valid = false;
}

}
