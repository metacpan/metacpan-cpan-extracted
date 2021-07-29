#include "unievent.h"
#include "unievent/Listener.h"
#include <typeinfo>
#include <cxxabi.h>

using namespace panda::unievent;
using panda::string;
using panda::string_view;

namespace xs { namespace unievent {

Sv::payload_marker_t event_listener_marker;

static bool _init () {
    event_listener_marker.svt_free = [](pTHX_ SV*, MAGIC* mg) -> int {
        delete (XSListener*)mg->mg_ptr;
        return 0;
    };
    return true;
}
static bool __init = _init();

IoInfo sv_io_info (const Sv& sv) {
    IoInfo ret;
    ret.is_sock = false;

    if (sv.is_ref() || sv.type() > SVt_PVMG) { // if we have a perl IO, get its type for free
        Io io(sv);
        ret.is_sock = io.iotype() == IoTYPE_SOCKET;
        ret.fd      = io.fileno();
    }
    else if (!SvOK(sv)) throw std::invalid_argument("fd must be defined");
    else { // otherwise we have to check the type
        ret.fd      = SvIV(sv);
        ret.is_sock = Fs::stat(ret.fd).value().type() == Fs::FileType::SOCKET;
    }

    if (ret.is_sock) ret.sock = fd2sock(ret.fd);
    return ret;
}

string sv2buf (const Sv& sv) {
    string buf;
    if (sv.is_array_ref()) { // [$str1, $str2, ...]
        Array wlist(sv);
        STRLEN sum = 0;
        for (auto it = wlist.cbegin(); it != wlist.cend(); ++it) {
            STRLEN len;
            SvPV(*it, len);
            sum += len;
        }
        if (!sum) return string();

        char* ptr = buf.reserve(sum);
        for (auto it = wlist.cbegin(); it != wlist.cend(); ++it) {
            STRLEN len;
            const char* data = SvPV(*it, len);
            memcpy(ptr, data, len);
            ptr += len;
        }
        buf.length(sum);
    } else { // $str
        STRLEN len;
        const char* data = SvPV(sv, len);
        if (!len) return string();
        buf.assign(data, len);
    }
    return buf;
}

void XSListener::_throw_noobj (const Simple& evname) {
    auto err = std::string("Handle needs event listener for event '") + evname.c_str() + "' but listener was weak and went out of scope";
    throw std::logic_error(err);
}

}}

namespace xs {

static inline void throw_bad_hints () { throw "argument is not a valid AddrInfoHints"; }

AddrInfoHints Typemap<AddrInfoHints>::in (SV* arg) {
    if (!SvOK(arg)) return AddrInfoHints();

    if (SvPOK(arg)) {
        if (SvCUR(arg) < sizeof(AddrInfoHints)) throw_bad_hints();
        return *reinterpret_cast<AddrInfoHints*>(SvPVX(arg));
    }

    if (!Sv(arg).is_hash_ref()) throw_bad_hints();
    AddrInfoHints ret;
    Hash h = arg;
    for (auto& row : h) {
        auto k = row.key();
        auto val = row.value().number();
        if      (k == "family"  ) ret.family   = val;
        else if (k == "socktype") ret.socktype = val;
        else if (k == "protocol") ret.protocol = val;
        else if (k == "flags"   ) ret.flags    = val;
    }
    return ret;
}

Sv Typemap<Fs::FStat>::out (const Fs::FStat& s, const Sv&) {
    return Ref::create(Array::create({
        Simple(s.dev),
        Simple(s.ino),
        Simple(s.mode),
        Simple(s.nlink),
        Simple(s.uid),
        Simple(s.gid),
        Simple(s.rdev),
        Simple(s.size),
        Simple(s.atime.get()),
        Simple(s.mtime.get()),
        Simple(s.ctime.get()),
        Simple(s.blksize),
        Simple(s.blocks),
        Simple(s.flags),
        Simple(s.gen),
        Simple(s.birthtime.get()),
        Simple((int)s.type()),
        Simple(s.perms()),
    }));
}

Fs::FStat Typemap<Fs::FStat>::in (const Array& a) {
    Fs::FStat ret;
    ret.dev       = a.fetch(0).number();
    ret.ino       = a.fetch(1).number();
    ret.mode      = a.fetch(2).number();
    ret.nlink     = a.fetch(3).number();
    ret.uid       = a.fetch(4).number();
    ret.gid       = a.fetch(5).number();
    ret.rdev      = a.fetch(6).number();
    ret.size      = a.fetch(7).number();
    ret.atime     = a.fetch(8).number();
    ret.mtime     = a.fetch(9).number();
    ret.ctime     = a.fetch(10).number();
    ret.blksize   = a.fetch(11).number();
    ret.blocks    = a.fetch(12).number();
    ret.flags     = a.fetch(13).number();
    ret.gen       = a.fetch(14).number();
    ret.birthtime = a.fetch(15).number();
    return ret;
}

uint64_t type;
uint64_t bsize;
uint64_t blocks;
uint64_t bfree;
uint64_t bavail;
uint64_t files;
uint64_t ffree;
uint64_t spare[4];

Sv Typemap<Fs::FsInfo>::out (const Fs::FsInfo& i, const Sv&) {
    return Ref::create(Array::create({
        Simple(i.type),
        Simple(i.bsize),
        Simple(i.blocks),
        Simple(i.bfree),
        Simple(i.bavail),
        Simple(i.files),
        Simple(i.ffree),
        Ref::create(Array::create({
            Simple(i.spare[0]),
            Simple(i.spare[1]),
            Simple(i.spare[2]),
            Simple(i.spare[3]),
        })),
    }));
}

Fs::FsInfo Typemap<Fs::FsInfo>::in (const Array& a) {
    Fs::FsInfo ret;
    ret.type   = a.fetch(0).number();
    ret.bsize  = a.fetch(1).number();
    ret.blocks = a.fetch(2).number();
    ret.bfree  = a.fetch(3).number();
    ret.bavail = a.fetch(4).number();
    ret.files  = a.fetch(5).number();
    ret.ffree  = a.fetch(6).number();
    Array spare = a.fetch(7);
    ret.spare[0] = spare.fetch(0).number();
    ret.spare[1] = spare.fetch(1).number();
    ret.spare[2] = spare.fetch(2).number();
    ret.spare[3] = spare.fetch(3).number();
    return ret;
}

Sv Typemap<Fs::DirEntry>::out (const Fs::DirEntry& de, const Sv&) {
    return Ref::create(Array::create({
        Simple(de.name()),
        Simple((int)de.type())
    }));
}

Fs::DirEntry Typemap<Fs::DirEntry>::in (const Array& a) {
    return Fs::DirEntry(a[0].as_string(), (Fs::FileType)a[1].as_number<int>());
}

Sv Typemap<Fs::path_fd_t>::out (const Fs::path_fd_t& val, const Sv&) {
    return Ref::create(Array::create({
        Simple(val.path),
        Simple(val.fd)
    }));
}

Fs::path_fd_t Typemap<Fs::path_fd_t>::in (const Array& a) {
    return Fs::path_fd_t{ a[0].as_string(), (fd_t)a[1].as_number<int>() };
}

}
