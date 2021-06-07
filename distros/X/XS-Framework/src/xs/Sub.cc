#include <xs/Sub.h>
#include <xs/Stash.h>
#include <xs/Object.h>
#include <panda/string.h>

namespace xs {

Sub Sub::create (panda::string_view sub_code) {
    auto code = panda::string("sub { ") + sub_code + " }";
    return eval(code);
}

Sub Sub::create (XSUBADDR_t xsfunc) {
    return newXS(nullptr, xsfunc, "<C++>");
}

Stash Sub::stash () const { return CvSTASH((CV*)sv); }

Glob Sub::glob () const { return CvGV((CV*)sv); }

void Sub::_throw_super () const {
    throw std::invalid_argument(panda::string("can't locate super method '") + name() + "' via package '" + stash().name() + "'");
}

size_t Sub::_call (CV* cv, I32 flags, const CallArgs& args, SV** ret, size_t maxret, AV** avr) {
    dTHX; dSP; ENTER; SAVETMPS;
    PUSHMARK(SP);

    if (args.self) XPUSHs(args.self);
    if (args.scalars) for (size_t i = 0; i < args.items; ++i) XPUSHs(args.scalars[i] ? args.scalars[i].get() : &PL_sv_undef);
    else              for (size_t i = 0; i < args.items; ++i) XPUSHs(args.list[i]    ? args.list[i]          : &PL_sv_undef);
    PUTBACK;

    if (!maxret && !avr) flags |= G_DISCARD;
    size_t count = call_sv((SV*)cv, flags|G_EVAL);
    SPAGAIN;

    auto errsv = GvSV(PL_errgv);
    if (SvTRUE(errsv)) {
        while (count > 0) { POPs; --count; }
        PUTBACK; FREETMPS; LEAVE;
        auto exc = Sv::noinc(errsv);
        GvSV(PL_errgv) = newSVpvs("");
        throw PerlRuntimeException(exc);
    }

    auto nret = count > maxret ? maxret : count;

    if (!avr) {
        while (count > maxret) { POPs; --count; }
        while (count > 0) ret[--count] = SvREFCNT_inc_NN(POPs);
    }
    else if (count) {
        nret = count;
        AV* av = *avr = newAV();
        av_extend(av, count-1);
        AvFILLp(av) = count-1;
        SV** svlist = AvARRAY(av);
        while (count--) svlist[count] = SvREFCNT_inc_NN(POPs);
    }
    else *avr = NULL;

    PUTBACK; FREETMPS; LEAVE;

    return nret;
}

Sub Sub::clone_anon_xsub (const Sub& proto) {
    dTHX;
    CV* cv = MUTABLE_CV(newSV_type(SvTYPE(proto)));
    CvFLAGS(cv) = CvFLAGS(proto) & ~(CVf_CLONE|CVf_WEAKOUTSIDE|CVf_CVGV_RC);
    CvCLONED_on(cv);
    CvFILE(cv) = CvFILE(proto);
    CvGV_set(cv,CvGV(proto));
    CvSTASH_set(cv, CvSTASH(proto));
    CvISXSUB_on(cv);
    CvXSUB(cv) = CvXSUB(proto);
    #if PERL_VERSION >= 22
        #ifndef PERL_IMPLICIT_CONTEXT
            CvHSCXT(cv) = &PL_stack_sp;
        #else
            PoisonPADLIST(cv);
        #endif
    #endif
    CvANON_on(cv);
    return Sub::noinc(cv);
}


static inline OP* want_get_op_assign (OP* entersub) {
    // for perls < 5.26, we don't have op_parent feature
  #ifndef op_parent
    auto cx = caller_cx(0, NULL);
    auto cv = cx->blk_sub.cv;
    OP* path[30];
    size_t path_max = sizeof(path) / sizeof(path[0]);
    size_t cur = 0;
    for (size_t i = 0; i < path_max; ++i) path[i] = nullptr;

    auto op = CvSTART(cv);
    while (1) {
        if (op == entersub) break;
        if (op->op_flags & OPf_KIDS) {
            if (cur >= path_max) return nullptr;
            path[cur++] = op;
            op = cUNOPx(op)->op_first;
            continue;
        }
        // get next sibling or parent's next sibling
        while (!(op = OpSIBLING(op))) {
            if (cur == 0) return nullptr; // we've searched the whole tree
            op = path[--cur];
        }
    }

    if (op != entersub) return nullptr;

    while (cur--) {
        OP* op = path[cur];
  #else
    for (OP* op = op_parent(entersub); op; op = op_parent(op)) {
  #endif
        switch (op->op_type) {
            case OP_AASSIGN: return op;
            case OP_SASSIGN:
            case OP_ANONHASH:
            case OP_ANONLIST:
            case OP_ENTERSUB: return nullptr;
        }
    }
    return nullptr;
}

static inline OP* want_unwrap (OP* op) {
    if (op->op_type == OP_LIST) return cUNOPx(op)->op_first;
    if (op->op_type == OP_NULL) {
        if (op->op_targ == OP_LIST || (PL_opargs[op->op_targ] & OA_CLASS_MASK) & (OA_UNOP|OA_BINOP|OA_LISTOP)) {
            return cUNOPx(op)->op_first;
        }
    }
    return nullptr;
}

static double want_count_slice (OP* op_slice);

static inline double want_count_list (OP* op) {
    double count = 0;
    OP* unwrapped;
    for (; op; op = OpSIBLING(op)) {
        if ((unwrapped = want_unwrap(op))) {
            //warn("UNWRAP");
            count += want_count_list(unwrapped);
            continue;
        }
        //warn("INSPECT =============================="); op_dump(op);
        switch (op->op_type) {
            case OP_CONST:
            case OP_PADSV:
            case OP_GVSV:
            case OP_UNDEF:
                ++count;
                break;
            case OP_PADAV:
            case OP_PADHV:
            case OP_ENTERSUB:
                return std::numeric_limits<double>::infinity();
            case OP_ASLICE:
            case OP_HSLICE:
                count += want_count_slice(op);
                break;
            case OP_AELEM:
            case OP_AELEMFAST:
            case OP_AELEMFAST_LEX:
            case OP_HELEM:
            case OP_MULTIDEREF:
                ++count;
                break;
            case OP_PADRANGE: // there should be optimized-out op_padsv/av/hv representing this padrange, so we skip it
            case OP_PUSHMARK:
            case OP_NULL:     // non-list
                break;
            default:
                return std::numeric_limits<double>::infinity();
        }
    }
    return count;
}

static double want_count_slice (OP* op_slice) {
    auto op = cLISTOPx(op_slice)->op_first;
    op = OpSIBLING(op);
    assert(op);

    auto inner = want_unwrap(op);
    if (inner) return want_count_list(inner); // @arr[1,2,3]

    switch (op->op_type) {
        case OP_RV2AV: {
            auto opf = cUNOPx(op)->op_first;
            if (opf->op_type == OP_CONST && SvTYPE(cSVOPx_sv(opf)) == SVt_PVAV) { // @arr[1..3]
                return AvFILLp((AV*)cSVOPx_sv(opf)) + 1;
            }
            return std::numeric_limits<double>::infinity();
        }
    }

    return std::numeric_limits<double>::infinity();
}

int Sub::want_count () {
    auto type = want();
    if      (type == Want::Void) return 0;
    else if (type == Want::Scalar) return 1;

    auto entersub = PL_op;
    if (entersub->op_type != OP_ENTERSUB) throw "want_count() must be called from XS sub";
    OP* op_assign = want_get_op_assign(entersub);
    if (!op_assign) return -1;
    //op_dump(op_assign);

    OP* lhs_root = cBINOPx(op_assign)->op_last;
    auto ret = want_count_list(lhs_root);
    return ret == std::numeric_limits<double>::infinity() ? -1 : (int)ret;
}

}
