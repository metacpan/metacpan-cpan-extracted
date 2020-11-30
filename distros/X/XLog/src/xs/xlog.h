#pragma once
#include <xs.h>
#include <panda/log.h>
#include <panda/exception.h>

// typemaps
namespace xs {
    template <> struct Typemap<panda::log::Level> : TypemapBase<panda::log::Level> {
        static inline panda::log::Level in (SV* sv) {
            int l = SvIV(sv);
            if (l < (int)panda::log::Level::VerboseDebug || l > (int)panda::log::Level::Emergency) throw panda::exception("invalid log level");
            return (panda::log::Level)l;
        }
        static inline Sv out (panda::log::Level l, const Sv& = {}) {
            return Simple((int)l);
        }
    };

    template <class TYPE> struct Typemap<panda::log::ILogger*, TYPE> : TypemapObject<panda::log::ILogger*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
        static panda::string package () { return "XLog::ILogger"; }
    };

    template <> struct Typemap<panda::log::ILoggerSP> : Typemap<panda::log::ILogger*> {
        static panda::log::ILoggerSP in (Sv arg);
    };

    template <class TYPE> struct Typemap<panda::log::IFormatter*, TYPE> : TypemapObject<panda::log::IFormatter*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
        static panda::string package () { return "XLog::IFormatter"; }
    };

    template <> struct Typemap<panda::log::IFormatterSP> : Typemap<panda::log::IFormatter*> {
        static panda::log::IFormatterSP in (Sv arg);
    };

    template <class TYPE> struct Typemap<panda::log::Module*, TYPE> : TypemapObject<panda::log::Module*, TYPE, ObjectTypeForeignPtr, ObjectStorageMG> {
        static panda::string package () { return "XLog::Module"; }
    };
}
