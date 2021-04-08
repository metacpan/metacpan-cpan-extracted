#include "refcnt.h"

namespace panda {

iptr<weak_storage> Refcnt::get_weak () const {
    if (!_weak) _weak = new weak_storage();
    return _weak;
}

Refcnt::~Refcnt () {
    if (_weak) _weak->valid = false;
}

iptr<atomic_weak_storage> AtomicRefcnt::get_weak () const {
    if (!_weak) _weak = new atomic_weak_storage();
    return _weak;
}

AtomicRefcnt::~AtomicRefcnt () {
    if (_weak) _weak->valid = false;
}

}
