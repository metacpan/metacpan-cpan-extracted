#include <xs/CallProxy.h>
#include <xs/Array.h>
#include <xs/Scalar.h>
#include <xs/Object.h>

namespace xs {

Sv CallProxy::sv () const {
    SV* ret = NULL;
    _call(G_SCALAR, &ret, 1, NULL);
    return Sv(ret, Sv::NONE);
}

Scalar CallProxy::scalar () const {
    SV* ret = NULL;
    _call(G_SCALAR, &ret, 1, NULL);
    return Scalar(ret, Sv::NONE);
}

Array CallProxy::list () const {
    AV* av = NULL;
    _call(G_ARRAY, NULL, 0, &av);
    return Array(av, Sv::NONE);
}

size_t CallProxy::_call (I32 flags, SV** ret, size_t maxret, AV** avr) const {
    if (called) throw std::logic_error("[Sub.call]: double call with proxy, don't use 'auto' on call's return value");
    called = true;
    if (!cv) return 0; // no sub - empty return. used for next/super maybe methods.

    dTHX; dSP; ENTER; SAVETMPS;
    PUSHMARK(SP);

    if (arg) XPUSHs(arg);
    if (args) for (size_t i = 0; i < items; ++i) XPUSHs(args[i] ? args[i].get() : &PL_sv_undef);
    else      for (size_t i = 0; i < items; ++i) XPUSHs(sv_args[i] ? sv_args[i] : &PL_sv_undef);
    PUTBACK;

    if (!maxret && !avr) { flags |= G_DISCARD; maxret = 0; }
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

static inline Object _object_for_call (SV* v) {
    if (v) sv_2mortal(v);
    Object o(v);
    if (!o) throw std::invalid_argument("call result is not a blessed object reference");
    return o;
}

CallProxy CallProxy::call (const std::string_view& name) {
    SV* ret = NULL;
    _call(G_SCALAR, &ret, 1, NULL);
    return _object_for_call(ret).call(name);
}

CallProxy CallProxy::call (const std::string_view& name, const Scalar& arg) {
    SV* ret = NULL;
    _call(G_SCALAR, &ret, 1, NULL);
    return _object_for_call(ret).call(name, arg);
}

CallProxy CallProxy::call (const std::string_view& name, SV*const* args, size_t items) {
    SV* ret = NULL;
    _call(G_SCALAR, &ret, 1, NULL);
    return _object_for_call(ret).call(name, args, items);
}

CallProxy CallProxy::call (const std::string_view& name, std::initializer_list<Scalar> l) {
    SV* ret = NULL;
    _call(G_SCALAR, &ret, 1, NULL);
    return _object_for_call(ret).call(name, l);
}

}

