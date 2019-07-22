#include <xs/Sub.h>
#include <xs/Stash.h>
#include <xs/Object.h>
#include <panda/string.h>

namespace xs {

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
        throw exc;
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

}
