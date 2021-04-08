#include <xs/xlog.h>
#include <panda/log/file.h>

using namespace xs;
using namespace panda;
using namespace panda::log;

namespace xs {
    template <> struct Typemap<FileLogger::Config> : TypemapBase<FileLogger::Config> {
        static FileLogger::Config in (const Hash& h) {
            FileLogger::Config cfg;
            Sv val;
            
            if (val = h.fetch("file")) {
                cfg.file = xs::in<string>(val);
                if ((val = h.fetch("autoflush")))  cfg.autoflush = val.is_true();
                if ((val = h.fetch("check_freq"))) cfg.check_freq = Simple(val);
            }
            
            return cfg;
        }
    };

    template <> struct Typemap<FileLogger*> : Typemap<ILogger*, FileLogger*> {
        static string package () { return "XLog::File"; }
    };
}

MODULE = XLog::File                PACKAGE = XLog::File
PROTOTYPES: DISABLE

BOOT {
    Stash(__PACKAGE__).inherit("XLog::ILogger");
}

FileLogger* FileLogger::new (FileLogger::Config cfg) {
    RETVAL = new FileLogger(cfg);
}
