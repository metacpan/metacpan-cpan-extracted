// adopted from https://github.com/boostorg/stacktrace/tree/develop/include/boost/stacktrace/detail
#include "../exception.h"
#include <cxxabi.h>
#include "exception_debug.h"
#include <windows.h>
#include <dbgeng.h>

namespace panda {

class SimpleDebuggingSymbols: public debugging_symbols {
    using debugging_symbols::debugging_symbols;
public:
    void gather(const void* addr, Stackframe& f) const noexcept {
        if (!is_inited()) { return; }
        const ULONG64 offset = reinterpret_cast<ULONG64>(addr);

        // get name and dll
        string fqn;
        char buff[256] = {0};
        buff[0] = '\0';
        ULONG size = 0;
        bool res = (S_OK == idebug_->GetNameByOffset(offset, buff, sizeof(buff), &size, 0 ));

        if (!res && size != 0) {
            fqn.resize(size);
            res = (S_OK == idebug_->GetNameByOffset(offset, fqn.buf(), size,  &size, 0));
            if (res) { fqn.length(size - 1); }
        } else if (res) {
            fqn.assign(buff, size - 1);
        }
        if (res) {
            //std::cout << "fqn: " << buff << "\n";

            auto delimiter = fqn.find_first_of('!');
            if (delimiter == string::npos) { f.library = fqn; } // can't get name
            else {
                auto dll     = fqn.substr(0, delimiter);
                auto mangled = fqn.substr(delimiter + 1);

                auto demangled = mangled;
                if (mangled.size() > 2 && (mangled[0] == '_') && (mangled[1] == 'Z')) {
                    int status;
                    char* d = abi::__cxa_demangle(mangled.c_str(), nullptr, nullptr, &status);
                    if (d) {
                        demangled = d;
                        free(d);
                    }
                }
                f.mangled_name = mangled;
                f.name = demangled;
                f.library = dll;
            }
        }

        // get source file & line_no ; actually does not work on mingw
        buff[0] = '\0';
        ULONG line_no = 0;
        string file;
        res = (S_OK == idebug_->GetLineByOffset(reinterpret_cast<ULONG64>(addr), &line_no, buff, sizeof(buff), &size, 0));
        //std::cout << "l =" << line_no << "\n";
        if (!res && size != 0) {
            file.resize(size);
            res = (S_OK == idebug_->GetLineByOffset(reinterpret_cast<ULONG64>(addr), &line_no, file.buf(), size, &size, 0));
        } else if (res) {
            file = buff;
        }
        if (res) {
            file.length(size - 1);
            f.line_no = line_no;
            f.file = file;
        }

        f.address = reinterpret_cast<uint64_t>(addr);
    }
};

RawTraceProducer get_default_raw_producer () noexcept {
    return [](void** ptr, int sz) -> int {
        auto r = ::CaptureStackBackTrace(1, static_cast<unsigned long>(sz), ptr, nullptr);
        return r;
    };
}

struct WinBacktrace: BacktraceBackend {
    const Backtrace& raw_traces;
    SimpleDebuggingSymbols idebug;

    WinBacktrace(const Backtrace& raw_traces_) noexcept: raw_traces{raw_traces_} {}

    bool produce_frame(StackFrames& frames, size_t i) override {
        StackframeSP frame;
        if (!idebug.is_inited()) return false;
        auto raw_frame = raw_traces.buffer.at(i);
        frame = StackframeSP(new Stackframe());
        idebug.gather(raw_frame, *frame);
        frames.emplace_back(std::move(frame));
        return true;
    }
};

BacktraceProducer get_default_bt_producer () noexcept {
    return [](const Backtrace& raw_traces) -> BacktraceBackendSP {
        return new WinBacktrace(raw_traces);
    };
}

}
