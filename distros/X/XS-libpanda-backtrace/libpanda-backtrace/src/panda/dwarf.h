#pragma once

#include "SharedObjectInfo.h"
#include <libdwarf.h>
#include <dwarf.h>
#include <memory>
#include <unordered_map>
#include <list>
#include <functional>
#include <panda/exception.h>
#include <panda/optional.h>

namespace panda { namespace backtrace {

namespace dwarf {

const constexpr std::size_t max_inline = 10;

struct HighLow {
    Dwarf_Addr high;
    Dwarf_Addr low;
};

enum class Scan  { found, not_found, dead_end };

struct DieHolder;
struct LookupResult;
struct DieRC;
using DieSP = panda::iptr<DieRC>;
struct CU;
using CUSP = panda::iptr<CU>;
using DieCollection = std::list<DieSP>;

struct FunctionDetails {
    panda::string name;
    DieSP name_die = nullptr;
    std::uint64_t line_no = 0;
    panda::string source;
    std::uint32_t mask = 0;
};

struct DieRC: panda::Refcnt {
    Dwarf_Die die;
    Dwarf_Debug debug;
    DieSP parent;
    DieCollection context;

    struct FQN {
        string full_name;
        DieSP source_die;
    };

    DieRC(Dwarf_Die die_, Dwarf_Debug debug_, DieSP parent_);
    ~DieRC();

    panda::optional<HighLow> get_addr() noexcept;
    Scan contains(std::uint64_t offset) noexcept;
    DieSP resolve_ref(DieSP source, Dwarf_Half attribute) noexcept;
    DieSP discover(DieSP target) noexcept;
    DieSP discover(Dwarf_Off target_offset, DieSP node) noexcept;
    FQN gather_fqn() noexcept;
    DieSP refine_location(std::uint64_t offset) noexcept;
    FunctionDetails refine_fn(LookupResult& lr) noexcept;
    void refine_fn_ao(DieSP abstract_origin, FunctionDetails& details) noexcept;
    void refine_fn_name(DieSP it, FunctionDetails& details) noexcept;
    void refine_fn_line(DieSP die, std::uint64_t offset, FunctionDetails& details) noexcept;
    void refine_fn_line_fallback(DieSP it, FunctionDetails& details) noexcept;
    void refine_fn_source(DieSP it, FunctionDetails& details, CU& cu) noexcept;
    void refine_fn_spec(DieSP specification, FunctionDetails& details) noexcept;
};

struct LookupResult {
    LookupResult(CU& root_) noexcept: root{CUSP{&root_}} {}
    LookupResult(const LookupResult&) = delete;
    LookupResult(LookupResult&&);

    bool is_complete() noexcept;
    bool get_frames(std::uint64_t ip, const SharedObjectInfo& so, StackFrames& frames) noexcept;

    CUSP root;
    DieSP cu;
    DieSP subprogram;
    std::uint64_t offset{0};
};

struct CU: panda::Refcnt {
    Dwarf_Debug debug;
    int number;

    Dwarf_Unsigned header_length = 0;
    Dwarf_Unsigned abbrev_offset = 0;
    Dwarf_Half     address_size = 0;
    Dwarf_Half     version_stamp = 0;
    Dwarf_Half     offset_size = 0;
    Dwarf_Half     extension_size = 0;
    Dwarf_Unsigned typeoffset = 0;
    Dwarf_Half     header_type = DW_UT_compile;
    Dwarf_Sig8     signature;
    Dwarf_Off      cu_offset = 0;
    DieSP cu_die;

    char **sources = nullptr;
    Dwarf_Signed sources_count = 0;

    CU(Dwarf_Debug debug, int number_);
    ~CU();

    LookupResult resolve(std::uint64_t offset) noexcept;
    void resolve(std::uint64_t offset, DieSP& root, LookupResult& lr) noexcept;

    string get_source(size_t index) noexcept;
};
}


struct DwarfInfo;

struct DwarfInfo {
    using file_guard_t = std::unique_ptr<FILE, std::function<void(FILE*)>>;

    SharedObjectInfo so_info;
    Dwarf_Ptr err_arg = nullptr;
    Dwarf_Debug debug = nullptr;
    std::list<dwarf::CUSP> CUs;
    file_guard_t guard;

    DwarfInfo(const SharedObjectInfo& info_):so_info{info_}{}
    ~DwarfInfo();

    bool load(file_guard_t&& guard) noexcept;
    bool resolve(std::uint64_t ip, StackFrames& frames) noexcept;
};
using DwarfInfoMap = std::map<panda::string, std::unique_ptr<DwarfInfo>>;


struct DwarfBackend: BacktraceBackend {
    const Backtrace& raw_traces;
    DwarfInfoMap info_map;

    DwarfBackend(const Backtrace& raw_traces_) noexcept;

    bool produce_frame(StackFrames& frames, size_t i);
};

}}
