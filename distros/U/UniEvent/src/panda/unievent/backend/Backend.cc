#include "LoopImpl.h"
#include "HandleImpl.h"

namespace panda { namespace unievent { namespace backend {

log::Module uebacklog("UniEvent::Backend");

uint64_t HandleImpl::last_id;

void LoopImpl::capture_exception () {
    _exception = std::current_exception();
    assert(_exception);
    stop();
}

void LoopImpl::throw_exception () {
    auto exc = std::move(_exception);
    _exception = nullptr;
    std::rethrow_exception(exc);
}

}}}
