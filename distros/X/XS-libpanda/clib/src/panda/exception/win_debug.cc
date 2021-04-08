// adopted from https://github.com/boostorg/stacktrace/tree/develop/include/boost/stacktrace/detail
#ifdef _WIN32

#include "win_debug.h"
#include <windows.h>
#include <dbgeng.h>


__CRT_UUID_DECL(IDebugClient,0x27fe5639,0x8407,0x4f47,0x83,0x64,0xee,0x11,0x8f,0xb0,0x8a,0xc8)
__CRT_UUID_DECL(IDebugControl,0x5182e668,0x105e,0x416e,0xad,0x92,0x24,0xef,0x80,0x04,0x24,0xba)
__CRT_UUID_DECL(IDebugSymbols,0x8c31e98c,0x983a,0x48a5,0x90,0x16,0x6f,0xe5,0xd6,0x67,0xa9,0x50)


using namespace panda;

com_global_initer::com_global_initer() noexcept : _ok{false} {
    // COINIT_MULTITHREADED means that we must serialize access to the objects manually.
    // This is the fastest way to work. If user calls CoInitializeEx before us - we
    // can end up with other mode (which is OK for us).
    //
    // If we call CoInitializeEx befire user - user may end up with different mode, which is a problem.
    // So we need to call that initialization function as late as possible.
    auto res = ::CoInitializeEx(0, COINIT_MULTITHREADED);
    _ok = (res == S_OK || res == S_FALSE);
}

com_global_initer::~com_global_initer() noexcept {
    if (_ok) { ::CoUninitialize(); }
}

void debugging_symbols::try_init_com(com_holder< ::IDebugSymbols>& idebug, const com_global_initer& com) noexcept {
    com_holder< ::IDebugClient> iclient(com);
    if (S_OK != ::DebugCreate(__uuidof(IDebugClient), iclient.to_void_ptr_ptr())) {
        return;
    }

    com_holder< ::IDebugControl> icontrol(com);
    const bool res0 = (S_OK == iclient->QueryInterface(
        __uuidof(IDebugControl),
        icontrol.to_void_ptr_ptr()
    ));
    if (!res0) {
        return;
    }

    const bool res1 = (S_OK == iclient->AttachProcess(
        0,
        ::GetCurrentProcessId(),
        DEBUG_ATTACH_NONINVASIVE | DEBUG_ATTACH_NONINVASIVE_NO_SUSPEND
    ));
    if (!res1) {
        return;
    }

    if (S_OK != icontrol->WaitForEvent(DEBUG_WAIT_DEFAULT, INFINITE)) {
        return;
    }

    // No cheking: QueryInterface sets the output parameter to NULL in case of error.
    iclient->QueryInterface(__uuidof(IDebugSymbols), idebug.to_void_ptr_ptr());
}


com_holder< ::IDebugSymbols>& debugging_symbols::get_thread_local_debug_inst() noexcept {
    // [class.mfct]: A static local variable or local type in a member function always refers to the same entity, whether
    // or not the member function is inline.
    static thread_local com_global_initer com;
    static thread_local com_holder< ::IDebugSymbols> idebug(com);

    if (!idebug.is_inited()) {
        try_init_com(idebug, com);
    }

    return idebug;
}

debugging_symbols::debugging_symbols() noexcept : idebug_( get_thread_local_debug_inst() ) {}

bool debugging_symbols::is_inited() const noexcept { return idebug_.is_inited();  }


#endif
