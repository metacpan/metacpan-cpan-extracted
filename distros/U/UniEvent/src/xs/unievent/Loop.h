#pragma once
#include "Backend.h"
#include <panda/unievent/Loop.h>

namespace xs { namespace unievent {

struct DLoopSP : xs::nn<panda::unievent::LoopSP> {
    using LoopSP = panda::unievent::LoopSP;
    using Loop   = panda::unievent::Loop;
    using Super  = typename xs::nn<LoopSP>;
    using Super::Super;

    LoopSP& operator-> () {
        if (!val) val = Loop::default_loop();
        return val;
    }

    Loop& operator* () { return *operator->(); }
    operator LoopSP () { return operator->(); }
    operator Loop*  () { return operator->(); }
};

}}

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Loop*, TYPE> : TypemapObject<panda::unievent::Loop*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref, DynamicCast> {
    static panda::string package () { return "UniEvent::Loop"; }
};

template <> struct Typemap<xs::unievent::DLoopSP> : TypemapBase<xs::unievent::DLoopSP> {
    static xs::unievent::DLoopSP in (const Sv& arg) {
        auto val = xs::in<panda::unievent::LoopSP>(arg);
        return xs::unievent::DLoopSP(val ? val : panda::unievent::Loop::default_loop());
    }
};

}
