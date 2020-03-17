#pragma once
#include <xs.h>
#include <panda/unievent/Fs.h>

namespace xs {

template <> struct Typemap<panda::unievent::Fs::FStat> : TypemapBase<panda::unievent::Fs::FStat> {
    static Sv out (const panda::unievent::Fs::FStat&, const Sv& = Sv());
    static panda::unievent::Fs::FStat in (const Array&);
};

template <> struct Typemap<panda::unievent::Fs::DirEntry> : TypemapBase<panda::unievent::Fs::DirEntry> {
    static Sv out (const panda::unievent::Fs::DirEntry&, const Sv& = Sv());
    static panda::unievent::Fs::DirEntry in (const Array&);
};

template <class TYPE> struct Typemap<panda::unievent::Fs::Request*, TYPE> : TypemapObject<panda::unievent::Fs::Request*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Fs::Request"; }
};

}
