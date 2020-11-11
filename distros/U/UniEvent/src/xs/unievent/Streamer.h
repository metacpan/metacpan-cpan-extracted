#pragma once
#include "Loop.h"
#include "Stream.h"
#include <panda/unievent/Streamer.h>
#include <panda/unievent/streamer/File.h>
#include <panda/unievent/streamer/Stream.h>

namespace xs {

template <class TYPE> struct Typemap<panda::unievent::Streamer*, TYPE> : TypemapObject<panda::unievent::Streamer*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Streamer"; }
};


template <class TYPE> struct Typemap<panda::unievent::Streamer::IInput*, TYPE> : TypemapObject<panda::unievent::Streamer::IInput*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Streamer::IInput"; }
};

template <class TYPE> struct Typemap<panda::unievent::Streamer::IOutput*, TYPE> : TypemapObject<panda::unievent::Streamer::IOutput*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string package () { return "UniEvent::Streamer::IOutput"; }
};


template <class TYPE> struct Typemap<panda::unievent::streamer::FileInput*, TYPE> : Typemap<panda::unievent::Streamer::IInput*, TYPE> {
    static panda::string package () { return "UniEvent::Streamer::FileInput"; }
};

template <class TYPE> struct Typemap<panda::unievent::streamer::FileOutput*, TYPE> : Typemap<panda::unievent::Streamer::IOutput*, TYPE> {
    static panda::string package () { return "UniEvent::Streamer::FileOutput"; }
};


template <class TYPE> struct Typemap<panda::unievent::streamer::StreamInput*, TYPE> : Typemap<panda::unievent::Streamer::IInput*, TYPE> {
    static panda::string package () { return "UniEvent::Streamer::StreamInput"; }
};

template <class TYPE> struct Typemap<panda::unievent::streamer::StreamOutput*, TYPE> : Typemap<panda::unievent::Streamer::IOutput*, TYPE> {
    static panda::string package () { return "UniEvent::Streamer::StreamOutput"; }
};

}
