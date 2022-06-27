#include "util.h"
#include "xs/Glob.h"
#include "xs/Stash.h"
#include <xs/xlog.h>
#include <panda/optional.h>

using namespace panda;
using namespace panda::log;
using panda::log::Level;

namespace xs { namespace xlog {

#define OP_NA (OP_max + 1)

using backend_t = std::add_pointer<OP*(pTHX)>::type;

using Args = std::vector<int>;
using Optimizer = std::function<backend_t(const Args& args)>;

static Sv::payload_marker_t module_cache_marker;

bool has_module (SV* ref) {
    if (SvOBJECT(ref)) {
        auto stash = SvSTASH(ref);
        return string_view(HvNAME(stash), HvNAMELEN(stash)) == "XLog::Module";
    }
    return false;
}

Module* get_module_by_namespace (Stash stash) {
    auto module = (Module*)stash.payload(&module_cache_marker).ptr; // try to get module from cache
    if (module) return module;

    Object module_obj;
    auto name = stash.name();

    while (1) {
        auto pkg = Stash(name);
        if (pkg) {
            auto val = pkg.fetch("xlog_module").scalar();
            if (val && val.is_object_ref()) {
                Object o = val;
                if (o.stash().name() == "XLog::Module") {
                    module = xs::in<Module*>(o);
                    module_obj = o;
                    break;
                }
            }
        }
        if (!name.length()) break; // stop after main::
        auto pos = name.rfind("::");
        if (pos == string_view::npos) { // look in main::
            name = "";
            continue;
        }
        name = name.substr(0, pos);
    }

    if (!module) module = &::panda_log_module;
    stash.payload_attach((void*)module, module_obj, &module_cache_marker);

    return module;
}

Module* resolve_module(size_t depth) {
    Stash stash;
    if (depth == 0) {
        stash = CopSTASH(PL_curcop);
    }
    else {
        const PERL_CONTEXT *dbcx = nullptr;
        const PERL_CONTEXT *cx = caller_cx(depth, &dbcx);
        if (cx) {
            if ((CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT)) {
                #ifdef CvHASGV
                    bool has_gv = CvHASGV(dbcx->blk_sub.cv);
                #else
                    GV * const cvgv = CvGV(dbcx->blk_sub.cv);
                    /* So is ccstack[dbcxix]. */
                    bool has_gv = (cvgv && isGV(cvgv));
                #endif
                if (has_gv) {
                    xs::Sub sub(dbcx->blk_sub.cv);
                    stash = sub.glob().effective_stash();
                }
            }
            else stash =  CopSTASH(cx->blk_oldcop);
        }
    }
    // fallback
    if (!stash) return &::panda_log_module;

    return get_module_by_namespace(stash);
}


template<typename SkipPredicate>
inline static OP* pp_maybe_skip(SkipPredicate&& p) {
    bool skip = true;
    try {
        skip = p();
    } catch (panda::string& ex) {
        croak_sv(newSVpvn_flags(ex.c_str(), ex.length(), SVf_UTF8 | SVs_TEMP));
    }
    if (skip) {
        OP* cur_op = PL_op;
        while (OpHAS_SIBLING(cur_op))          { cur_op = OpSIBLING(cur_op); }
        while (cur_op->op_type != OP_ENTERSUB) { cur_op = cur_op->op_next; }
        return cur_op->op_next;
    } else {
        return PL_ppaddr[PL_op->op_type](aTHX);
    }
}

static bool final_check(Level level, SV* mod_sv) {
    const Module* module = nullptr;
    if (mod_sv) {
        if (mod_sv && SvROK(mod_sv)) {
            auto ref = SvRV(mod_sv);
            bool ok = has_module(ref);
            if (ok) {
                module = xs::in<Module*>(ref);
            }
        }
    }
    if (!module) module = resolve_module(0);
    return module->level() > level;
}

namespace access {

SV* constsv(const OP* op)  {
    if (op->op_type == OP_CONST) return cSVOPx_sv(op);
    return nullptr;
}

SV* padsv(const OP* op)  {
    if (op->op_type == OP_PADSV) return PAD_SVl(op->op_targ);
    return nullptr;
}

SV* rv2sv(const OP* op)  {
    if (OP_TYPE_IS_OR_WAS(op, OP_RV2SV)) {
        auto gvop = cUNOPx(op)->op_first;
        if (gvop->op_type == OP_GVSV) {
            auto gv = cGVOPx_gv(gvop);
            if (SvTYPE(gv) == SVt_PVGV) {
                return GvSV(gv);
            }
        }
    }
    return nullptr;
}


}

namespace with_level {

template<Level level> struct AutoModule {
    static OP* pp(pTHX)  {
        auto check = [&]() { return final_check(level, nullptr); };
        return pp_maybe_skip(check);
    }
};

template<Level level> struct PADSV {
    static OP* pp(pTHX)  {
        auto check = [&]() {
            auto sv = access::padsv(OpSIBLING(PL_op));
            return final_check(level, sv);
        };
        return pp_maybe_skip(check);
    }
};

template<Level level> struct RV2SV {
    static OP* pp(pTHX)  {
        auto check = [&]() {
            bool skip = false;
            auto sv = access::rv2sv(OpSIBLING(PL_op));
            if (sv) skip = final_check(level, sv);
            return skip;
        };
        return pp_maybe_skip(check);
    }
};


template<template <Level> class Backend>
backend_t apply(Level level)  {
    switch (level) {
    case Level::VerboseDebug : return &Backend<Level::VerboseDebug>::pp;
    case Level::Debug        : return &Backend<Level::Debug>::pp;
    case Level::Info         : return &Backend<Level::Info>::pp;
    case Level::Notice       : return &Backend<Level::Notice>::pp;
    case Level::Warning      : return &Backend<Level::Warning>::pp;
    case Level::Error        : return &Backend<Level::Error>::pp;
    case Level::Critical     : return &Backend<Level::Critical>::pp;
    case Level::Alert        : return &Backend<Level::Alert>::pp;
    case Level::Emergency    : return &Backend<Level::Emergency>::pp;
    }
    std::abort();
}

}

namespace fetch_level {

enum class LevelAccess  { op_const, op_padsv, op_rv2sv };
enum class ModuleAccess { op_const, op_padsv, op_rv2sv, deduce };
using LevelOption = panda::optional<Level>;

static inline LevelOption sv2level (SV* sv)  {
    using namespace panda::log;
    if (sv) {
        int l = SvIV(sv);
        if (l >= (int)Level::VerboseDebug && l <= (int)Level::Emergency) return LevelOption((Level)l);
    }
    return LevelOption{};
}

template<LevelAccess> struct GetLevel;

template<> struct GetLevel<LevelAccess::op_const> {
    static LevelOption get (OP* op)  {
        return sv2level(access::constsv(op));
    }
};

template<> struct GetLevel<LevelAccess::op_padsv> {
    static LevelOption get (OP* op)  {
        return sv2level(access::padsv(op));
    }
};

template<> struct GetLevel<LevelAccess::op_rv2sv> {
    static LevelOption get (OP* op)  {
        return sv2level(access::rv2sv(op));
    }
};

template<ModuleAccess> struct GetModule;
template<> struct GetModule<ModuleAccess::op_const> {
    static SV* get (OP* op_prev)  { return access::constsv(OpSIBLING(op_prev)); }
};
template<> struct GetModule<ModuleAccess::op_padsv> {
    static SV* get (OP* op_prev)  { return access::padsv(OpSIBLING(op_prev)); }
};
template<> struct GetModule<ModuleAccess::op_rv2sv> {
    static SV* get (OP* op_prev)  { return access::rv2sv(OpSIBLING(op_prev)); }
};
template<> struct GetModule<ModuleAccess::deduce> {
    static SV* get (OP*)  { return nullptr; }
};


template<LevelAccess L, ModuleAccess M>
struct OpAccessor {
    static OP* pp (pTHX) {
        auto check = [&]() {
            auto op = OpSIBLING(PL_op);
            bool skip = false;
            auto level_option = GetLevel<L>::get(op);
            if (level_option) {
                auto sv_module = GetModule<M>::get(op);
                skip = final_check(level_option.value(), sv_module);
            }
            return skip;
        };
        return pp_maybe_skip(check);
    }
};

backend_t compose (LevelAccess level_access, ModuleAccess module_access) {
    switch (module_access) {
    case ModuleAccess::op_const: {
        switch (level_access) {
            case LevelAccess::op_const: return &OpAccessor<LevelAccess::op_const, ModuleAccess::op_const>::pp;
            case LevelAccess::op_padsv: return &OpAccessor<LevelAccess::op_padsv, ModuleAccess::op_const>::pp;
            case LevelAccess::op_rv2sv: return &OpAccessor<LevelAccess::op_rv2sv, ModuleAccess::op_const>::pp;
        } break; }
    case ModuleAccess::op_padsv: {
        switch (level_access) {
            case LevelAccess::op_const: return &OpAccessor<LevelAccess::op_const, ModuleAccess::op_padsv>::pp;
            case LevelAccess::op_padsv: return &OpAccessor<LevelAccess::op_padsv, ModuleAccess::op_padsv>::pp;
            case LevelAccess::op_rv2sv: return &OpAccessor<LevelAccess::op_rv2sv, ModuleAccess::op_padsv>::pp;
        } break; }
    case ModuleAccess::op_rv2sv: {
        switch (level_access) {
            case LevelAccess::op_const: return &OpAccessor<LevelAccess::op_const, ModuleAccess::op_rv2sv>::pp;
            case LevelAccess::op_padsv: return &OpAccessor<LevelAccess::op_padsv, ModuleAccess::op_rv2sv>::pp;
            case LevelAccess::op_rv2sv: return &OpAccessor<LevelAccess::op_rv2sv, ModuleAccess::op_rv2sv>::pp;
        } break; }
    case ModuleAccess::deduce: {
        switch (level_access) {
            case LevelAccess::op_const: return &OpAccessor<LevelAccess::op_const, ModuleAccess::deduce>::pp;
            case LevelAccess::op_padsv: return &OpAccessor<LevelAccess::op_padsv, ModuleAccess::deduce>::pp;
            case LevelAccess::op_rv2sv: return &OpAccessor<LevelAccess::op_rv2sv, ModuleAccess::deduce>::pp;
        } break; }
    }
    assert(0 && "should not happen");
    return nullptr;
}

}

static inline bool is_under_debugger() {
    return (bool)PL_DBsub;
}

static void optimize (size_t module_pos, Optimizer&& optimizer) {
    static bool is_dbg = is_under_debugger();
    if (is_dbg) return; // do not optimize under debugger as it OP structure may differ and may lead to corruption
    
    OP* op = PL_op;
    bool already_optimized = op->op_spare & 1;
    if (already_optimized) return;
    /* it does not matter whether successful optimization was applied or not.
     * in any case it will not be attempted to be applied again */
    op->op_spare |= 1;

    /* can be goto, no optimization */
    if (op->op_type != OP_ENTERSUB) return;

    OP* args_op = cUNOPx(op)->op_first;
    bool ok = true;
    while(ok && args_op->op_type == OP_NULL) {
        auto klass = PL_opargs[(args_op->op_targ)] & OA_CLASS_MASK;
        switch (klass) {
        case OA_UNOP:   args_op = cUNOPx(args_op)->op_first;   break;
        case OA_LISTOP: args_op = cLISTOPx(args_op)->op_first; break;
        default: ok = false;
        }
    }

    auto type = args_op->op_type;
    /* we don't know what it is, no optimization is possible */
    if ((type != OP_PUSHMARK) && (type != OP_PADRANGE)) return;

    /* somebody already optimized arg op, skip */
    if ((args_op->op_ppaddr != PL_ppaddr[type]) || (args_op->op_spare & 1)) return;

    /* no idea how this can be */
    if (!OpHAS_SIBLING(args_op)) return;

    Args args;
    OP *cur_op = OpSIBLING(args_op);
    while(OpHAS_SIBLING(cur_op) && (args.size() < module_pos) && !OP_TYPE_IS_OR_WAS(cur_op,OP_RV2CV)){
        args.push_back(cur_op->op_type == OP_NULL ? cur_op->op_targ : cur_op->op_type);
        cur_op = OpSIBLING(cur_op);
    }

    while((args.size() < module_pos)) args.push_back(OP_NA);
    backend_t backend = optimizer(args);
    if (backend != nullptr) {
        args_op->op_ppaddr = backend;
    }
}

void optimize () {
    auto optimizer = [] (const Args& args) -> backend_t {
        using namespace fetch_level;
        LevelAccess level_access;
        switch (args[0]) {
            case OP_CONST: level_access = LevelAccess::op_const; break;
            case OP_PADSV: level_access = LevelAccess::op_padsv; break;
            case OP_RV2SV: level_access = LevelAccess::op_rv2sv; break;
            default:       return nullptr;
        }

        ModuleAccess module_access;
        switch (args[1]) {
            case OP_CONST: module_access = ModuleAccess::op_const; break;
            case OP_PADSV: module_access = ModuleAccess::op_padsv; break;
            case OP_RV2SV: module_access = ModuleAccess::op_rv2sv; break;
            default:       module_access = ModuleAccess::deduce; break;
        }

        return compose(level_access, module_access);
    };
    optimize(2, optimizer);
}


void optimize (panda::log::Level level) {
    auto optimizer = [level] (const Args& args) -> backend_t {
        using namespace with_level;
        switch (args.front()) {
            case OP_NA :   return apply<AutoModule>(level);
            case OP_CONST: return apply<AutoModule>(level);
            case OP_PADSV: return apply<PADSV>(level);
            case OP_RV2SV: return apply<RV2SV>(level);
        }
        return nullptr;
    };
    optimize(1, optimizer);
}

}}
