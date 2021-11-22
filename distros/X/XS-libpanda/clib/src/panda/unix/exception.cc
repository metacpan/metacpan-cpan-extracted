#include "../exception.h"
#include <regex>
#include <functional>
#include <cxxabi.h>
#include <memory>

#if PANDA_HAS_LIBUNWIND
    #define UNW_LOCAL_ONLY
    #include <libunwind.h>
#endif

#if PANDA_HAS_EXECINFO
    #include <execinfo.h>
#endif

namespace panda {

RawTraceProducer get_default_raw_producer() noexcept {
    /* prefer libunwind, otherwise there are annoying warnings on FreeBSD x86 (seems bug in it) */
    #if PANDA_HAS_LIBUNWIND
        return [](void **dst, int sz) -> int {
            unw_cursor_t cursor;
            unw_context_t uc;
            unw_word_t ip;

            unw_getcontext(&uc);
            unw_init_local(&cursor, &uc);
            int count = 0;
            while ((unw_step(&cursor) > 0) && count < sz) {
                unw_get_reg(&cursor, UNW_REG_IP, &ip);
                dst[count++] = (void*)ip;
            }
            return count;
        };
    #else
        #if defined (__linux__)
            return ::backtrace;
        #else
            return [](void **dst, int sz) -> int {
                auto r = ::backtrace(dst, sz);
                return (int)r;
            };
        #endif
    #endif
}

#if PANDA_HAS_EXECINFO
static StackframeSP as_frame (const char* symbol) {
    StackframeSP r;
    std::cmatch what;
    #if defined (__linux__)
        static std::regex re("(.+)\\((.*)\\+(0x)?([0-9a-f]+)\\) \\[0x([0-9a-f]+)\\]");
        if (!regex_match(symbol, what, re)) return r;
        panda::string dll           (what[1].first, what[1].length());
        panda::string mangled_name  (what[2].first, what[2].length());
        panda::string base_off      (what[3].first, what[3].length());
        panda::string symbol_offset (what[4].first, what[4].length());
        panda::string address       (what[5].first, what[5].length());
    #elif !defined(__APPLE__)
        static std::regex re("0x([0-9a-f]+) <([^+]+)\\+(0x)?([0-9a-f]+)> at (.+)");
        if (!regex_match(symbol, what, re)) return r;
        panda::string dll           (what[5].first, what[5].length());
        panda::string mangled_name  (what[2].first, what[2].length());
        panda::string base_off      (what[3].first, what[3].length());
        panda::string symbol_offset (what[4].first, what[4].length());
        panda::string address       (what[1].first, what[1].length());
    #else
        static std::regex re("\\d+\\s+(\\S+).bundle\\s+0x([0-9a-f]+) (.+) \\+ (\\d+)");
        if (!regex_match(symbol, what, re)) return r;
        panda::string dll           (what[1].first, what[1].length());
        panda::string mangled_name  (what[3].first, what[3].length());
        panda::string base_off;
        panda::string symbol_offset (what[4].first, what[4].length());
        panda::string address       (what[2].first, what[2].length());
    #endif

    r = new Stackframe();
    int status;
    string demangled_name = mangled_name;
    // https://en.wikipedia.org/wiki/Name_mangling, check it starts with '_Z'. The
    // abi::__cxa_demangle() on FreeBSD "demangles" even non-mangled names
    if (mangled_name.size() > 2 && (mangled_name[0] == '_') && (mangled_name[1] == 'Z')) {
        char* demangled = abi::__cxa_demangle(mangled_name.c_str(), nullptr, nullptr, &status);
        if (demangled) {
            demangled_name = demangled;
            free(demangled);
        }
    }
    // printf("symbol = %s, d = %s, o=%s\n", symbol, demangled_name.c_str(), mangled_name.c_str());
    r->name = demangled_name;
    r->mangled_name = mangled_name;
    r->library = dll;
    r->line_no = 0;

    std::uint64_t addr = 0;
    int base = base_off ? 16 : 10;
    auto addr_r = from_chars(address.data(), address.data() + address.length(), addr, base);
    if (!addr_r.ec) { r->address = addr; }
    else            { r->address = 0; }

    std::uint64_t offset = 0;
    // +2 to skip 0x prefix
    auto offset_r = from_chars(symbol_offset.data(), symbol_offset.data() + symbol_offset.size(), offset, 16);
    if (!offset_r.ec) { r->offset = offset; }
    else              { r->offset = 0; }
    //printf("symbol = %s\n", symbol);

    return r;
}
#endif

struct GlibcBacktrace : BacktraceBackend {
    char** symbols = nullptr;
    std::size_t size = 0;
    const Backtrace& raw_traces;
    bool gathered = false;

    GlibcBacktrace(const Backtrace& raw_traces) noexcept : raw_traces(raw_traces) {}

    ~GlibcBacktrace() {
        if (symbols) free(symbols);
    }

    void gather() noexcept {
        #if PANDA_HAS_EXECINFO
            auto& buffer = raw_traces.buffer;
            symbols = ::backtrace_symbols((void**)buffer.data(), buffer.size());
            if (symbols) { size = buffer.size(); }
            gathered  = true;
        #else
            size = raw_traces.buffer.size();
        #endif
    }

    bool produce_frame(StackFrames& frames, size_t i) override {
        if (!gathered) gather();
        #if PANDA_HAS_EXECINFO
                if (i >= size) throw std::out_of_range("invalid frame index");
                auto frame = as_frame(symbols[i]);
                if (frame) frames.emplace_back(std::move(frame));
                return (bool) frame;
        #else
                if (i >= size) throw std::out_of_range("invalid frame index");
                StackframeSP frame = new Stackframe();
                frame->address = (std::uint64_t)raw_traces.buffer.at(i);
                frames.emplace_back(std::move(frame));
                return (bool) frame;
        #endif
    }
};

BacktraceProducer get_default_bt_producer() noexcept {
    return [](const Backtrace& raw_traces) -> BacktraceBackendSP {
        return new GlibcBacktrace(raw_traces);
    };
}

}
