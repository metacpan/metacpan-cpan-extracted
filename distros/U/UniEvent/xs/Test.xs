#include <xs/unievent/Loop.h>
#include <panda/unievent/test/AsyncTest.h>

using namespace xs;
using namespace panda::unievent;
using namespace panda::unievent::test;

namespace xs {
    template <> struct Typemap<AsyncTest*> : TypemapObject<AsyncTest*, AsyncTest*, ObjectTypePtr, ObjectStorageMG> {
        static panda::string_view package () { return "UniEvent::Test::Async"; }
    };
}

MODULE = UniEvent::Test                PACKAGE = UniEvent::Test::Async
PROTOTYPES: DISABLE

BOOT {
}

AsyncTest* AsyncTest::new (Sv events = {}, double timeout = 1, LoopSP loop = {}) {
    if (events.is_array_ref()) RETVAL = new AsyncTest(timeout * 1000, xs::in<std::vector<string>>(events), loop);
    else                       RETVAL = new AsyncTest(timeout * 1000, (int)Simple(events), loop);
}

LoopSP AsyncTest::loop () {
    RETVAL = THIS->loop;
}

void AsyncTest::run ()

void AsyncTest::run_once ()

void AsyncTest::run_nowait ()
    
void AsyncTest::happens (Simple arg = {}) {
    if (arg) THIS->happens(arg.as_string());
    else     THIS->happens();
}
