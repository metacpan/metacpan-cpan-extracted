#pragma once
#include <xs.h>
#include "Work.h"
#include <panda/unievent/Fs.h>

namespace xs {

template <> struct Typemap<panda::unievent::Fs::FStat> : TypemapBase<panda::unievent::Fs::FStat> {
    static Sv out (const panda::unievent::Fs::FStat&, const Sv& = Sv());
    static panda::unievent::Fs::FStat in (const Array&);
};

template <> struct Typemap<panda::unievent::Fs::FsInfo> : TypemapBase<panda::unievent::Fs::FsInfo> {
    static Sv out (const panda::unievent::Fs::FsInfo&, const Sv& = Sv());
    static panda::unievent::Fs::FsInfo in (const Array&);
};

template <> struct Typemap<panda::unievent::Fs::DirEntry> : TypemapBase<panda::unievent::Fs::DirEntry> {
    static Sv out (const panda::unievent::Fs::DirEntry&, const Sv& = Sv());
    static panda::unievent::Fs::DirEntry in (const Array&);
};

template <> struct Typemap<panda::unievent::Fs::path_fd_t> : TypemapBase<panda::unievent::Fs::path_fd_t> {
    static Sv out (const panda::unievent::Fs::path_fd_t& val, const Sv& = {});
    static panda::unievent::Fs::path_fd_t in (const Array&);
};

template <class TYPE> struct Typemap<panda::unievent::Fs::Request*, TYPE> : Typemap<panda::unievent::Work*, TYPE> {
    static panda::string package () { return "UniEvent::Request::Fs"; }
};

}
