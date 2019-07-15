#include <xs/Sub.h>
#include <xs/Stash.h>
#include <xs/Object.h>
#include <xs/HashEntry.h>

#ifndef PERL_VERSION_DECIMAL
#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#endif

using std::string_view;
using panda::string;

namespace xs {

Stash::op_proxy& Stash::op_proxy::operator= (SV* val) {
    _assert();

    if (!val) {
        slot(Scalar());
        return *this;
    }

    if (SvROK(val)) val = SvRV(val);
    if (SvTYPE(val) == SVt_PVGV) return operator=((GV*)val);
    slot(val);
    return *this;
}

Stash::op_proxy& Stash::op_proxy::operator= (GV* val) {
    _assert();
    if (val) {
        SvREFCNT_inc_simple_void_NN(val);
        SvREFCNT_dec_NN(*ptr);
        *ptr = (SV*)val;
        Glob::operator=(val);
    } else { // it is not allowed to set NULL to hash element, so nullify all slots
        slot(Scalar());
        slot(Array());
        slot(Hash());
        slot(Sub());
    }
    return *this;
}

void Stash::_promote (GV* gv, const std::string_view& key) const {
    if (!gv || SvTYPE(gv) == SVt_PVGV) return;
#if PERL_DECIMAL_VERSION < PERL_VERSION_DECIMAL(5,26,1) && PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(5,22,0)
    if (SvROK(gv)) {
        SV* val = SvRV(gv);
        if (SvTYPE(val) == SVt_PVCV && !CvNAMED((CV*)val)) { // core-dump in gv_init_pvn with non-named CV
            U32 hash;
            PERL_HASH(hash, key.data(), key.length());
            HEK* hek = share_hek(key.data(), key.length(), hash);
            CvNAME_HEK_set((CV*)val, hek);
        }
    }
#endif
    gv_init_pvn(gv, (HV*)sv, key.data(), key.length(), 0);
}

string Stash::path () const {
    auto pkg = name();
    int len = pkg.length();
    string ret(len+3);
    char* dst = ret.buf();
    const char* src = pkg.data();
    for (int i = 0; i < len; ++i) {
        if (*src == ':') {
            *dst = '/';
            ++src;
            ++i;
        }
        else *dst = *src;
        ++dst;
        ++src;
    }
    *dst++ = '.';
    *dst++ = 'p';
    *dst++ = 'm';
    ret.length(dst-ret.buf());
    return ret;
}

void Stash::mark_as_loaded (const Stash& source) const {
    if (!source) throw std::invalid_argument(string("can't register module '") + name() + "': source module doesn't exist");
    auto inc = Stash::root().hash("INC");
    auto realpath = inc.fetch(source.path());
    if (!realpath) throw std::invalid_argument(string("can't register module '") + name() + "': source module '" + source.name() + "' hasn't been registered");
    inc.store(path(), realpath);
}

void Stash::inherit (const Stash& parent) {
    auto ISA = array("ISA");
    if (!ISA) { // we must create @ISA via gv_fetchpvn_flags, because perl is written like a monkey's shit
        auto fqn = string(name()) + "::ISA";
        ISA = GvAV(gv_fetchpvn_flags(fqn.data(), fqn.length(), GV_ADD, SVt_PVAV));
    }
    av_push(ISA, Simple::shared(parent.name())); // can't use ISA.push() syntax, because @ISA is a magical array, otherwise MRO cache won't be cleared
}

void Stash::_throw_nomethod (const std::string_view& name) const {
    throw std::invalid_argument(panda::string("can't locate method '") + name + "' via package '" + this->name() + "'");
}

bool Stash::isa (const std::string_view& parent, U32 hash, int flags) const {
    if (name() == parent) return TRUE;

    const struct mro_meta*const meta = HvMROMETA((HV*)sv);
    HV *isa = meta->isa;

    if (!isa) {
        (void)mro_get_linear_isa((HV*)sv);
        isa = meta->isa;
    }

    if (hv_common(isa, NULL, parent.data(), parent.length(), flags, HV_FETCH_ISEXISTS, NULL, hash)) return TRUE;
    return FALSE;

}

Object Stash::bless () const {
    return Object(sv_bless(newRV_noinc(newSV_type(SVt_PVMG)), (HV*)sv), NONE);
}

Object Stash::bless (const Sv& what) const {
    if (SvROK(what)) return sv_bless(what, (HV*)sv);
    else return Object(sv_bless(newRV(what), (HV*)sv), NONE);
}

void Stash::add_const_sub (const std::string_view& name, const Sv& _val) {
    auto val = _val;
    val.readonly(true);
    newCONSTSUB_flags((HV*)sv, name.data(), name.length(), 0, val.detach()); // detach because newCONSTSUB doesn't increment refcnt
}

}
