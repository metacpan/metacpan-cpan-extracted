#include <panda/backtrace.h>
#include <panda/exception.h>
#include "dwarf.h"

namespace panda { namespace backtrace {

static BacktraceBackendSP dl_produce(const Backtrace& raw_traces);
static BacktraceProducer dl_producer(dl_produce);

BacktraceBackendSP dl_produce(const Backtrace& raw_traces) {
    return new DwarfBackend(raw_traces);
}

void install() {
    panda::Backtrace::install_producer(dl_producer);
}

void uninstall() {
    panda::Backtrace::uninstall_producer(dl_producer);
}


}}

