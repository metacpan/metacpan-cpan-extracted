#include "mruby_pm_bridge.h"

#include "mruby/array.h"
#include "mruby/hash.h"
#include "mruby/string.h"
#include "mruby/error.h"

#define hv_foreach(hv, entry, block) {  \
  HV* hash = hv;                        \
  hv_iterinit(hash);                    \
  HE* entry;                            \
  while ((entry = hv_iternext(hash))) { \
    block;                              \
  }                                     \
}


SV * mruby_pm_bridge_value2sv(pTHX_ mrb_state *mrb, const mrb_value v) {
    switch (mrb_type(v)) {
    case MRB_TT_UNDEF:
      return &PL_sv_undef;
    case MRB_TT_FALSE: {
      if (mrb_fixnum(v)) {
        return sv_bless(newRV_inc(sv_2mortal(newSVsv(&PL_sv_undef))), gv_stashpv("mRuby::Bool::False", TRUE));
      }
      else {
        return &PL_sv_undef;
      }
    }
    case MRB_TT_TRUE:
      return sv_bless(newRV_inc(sv_2mortal(newSViv(1))), gv_stashpv("mRuby::Bool::True", TRUE));
    case MRB_TT_FIXNUM:
      return newSViv(mrb_fixnum(v));
    case MRB_TT_FLOAT:
      return newSVnv(mrb_float(v));
    case MRB_TT_STRING:
      return newSVpvn((char*)RSTRING_PTR(v), (STRLEN)RSTRING_LEN(v));
    case MRB_TT_SYMBOL: {
      mrb_int len;
      const char *name = mrb_sym2name_len(mrb, mrb_symbol(v), &len);
      return sv_bless(newRV_inc(sv_2mortal(newSVpvn((char*)name, (STRLEN)len))), gv_stashpv("mRuby::Symbol", TRUE));
    }
    case MRB_TT_HASH: {
      const mrb_value  keys = mrb_hash_keys(mrb, v);
      const mrb_value *ptr  = RARRAY_PTR(keys);
      const int        len  = RARRAY_LEN(keys);

      HV * ret = newHV_mortal();

      int i;
      for (i=0; LIKELY(i<len); i++) {
        const mrb_value kk = ptr[i];
        const mrb_value vv = mrb_hash_get(mrb, v, kk);

        SV * key_sv = sv_2mortal(mruby_pm_bridge_value2sv(aTHX_ mrb, kk));
        SV * val_sv = mruby_pm_bridge_value2sv(aTHX_ mrb, vv);
        hv_store_ent(ret, key_sv, SvROK(val_sv) ? SvREFCNT_inc(sv_2mortal(val_sv)) : val_sv, 0);
      }

      return newRV_inc((SV*)ret);
    }
    case MRB_TT_ARRAY: {
      const mrb_value *ptr = RARRAY_PTR(v);
      const int        len = RARRAY_LEN(v);

      AV * ret = newAV_mortal();

      int i;
      for (i=0; LIKELY(i<len); i++) {
        SV * val_sv = mruby_pm_bridge_value2sv(aTHX_ mrb, ptr[i]);
        av_push(ret, SvROK(val_sv) ? SvREFCNT_inc(sv_2mortal(val_sv)) : val_sv);
      }

      return newRV_inc((SV*)ret);
    }
    case MRB_TT_EXCEPTION: {
      mrb_value bt = mrb_exc_backtrace(mrb, v);
      return sv_bless(SvREFCNT_inc(sv_2mortal(mruby_pm_bridge_value2sv(aTHX_ mrb, bt))), gv_stashpv("mRuby::Exception", TRUE));
    }
    default:
      croak("This type of ruby value is not supported yet: %d", mrb_type(v));
    }
    abort();
}

static mrb_value mruby_pm_bridge_av2value(pTHX_ mrb_state *mrb, AV *av) {
  const I32 size = av_len(av) + 1;
  mrb_value ary = mrb_ary_new_capa(mrb, (mrb_int)size);

  I32 i;
  for (i=0; LIKELY(i<size); i++) {
    SV** v = av_fetch(av, i, 0);
    mrb_ary_set(mrb, ary, i, mruby_pm_bridge_sv2value(aTHX_ mrb, *v));
  }

  return ary;
}

static mrb_value mruby_pm_bridge_hv2value(pTHX_ mrb_state *mrb, HV *hv) {
  static const int BUF_SIZE = 32;

  int bufsize = BUF_SIZE;
  int keysize = 0;
  SV **keys_buf; Newxc(keys_buf, bufsize, SV*, SV*);
  SV **vals_buf; Newxc(vals_buf, bufsize, SV*, SV*);
  hv_foreach(hv, ent, {
    keys_buf[keysize] = hv_iterkeysv(ent);
    vals_buf[keysize] = HeVAL(ent);
    if (++keysize == bufsize) {
      bufsize *= 2;
      Renewc(keys_buf, bufsize, SV*, SV*);
      Renewc(vals_buf, bufsize, SV*, SV*);
    }
  });

  mrb_value hash = mrb_hash_new_capa(mrb, (mrb_int)keysize);

  int i;
  for (i=0; LIKELY(i<keysize); i++) {
    const mrb_value key = mruby_pm_bridge_sv2value(aTHX_ mrb, keys_buf[i]);
    const mrb_value val = mruby_pm_bridge_sv2value(aTHX_ mrb, vals_buf[i]);
    mrb_hash_set(mrb, hash, key, val);
  }

  Safefree(keys_buf);
  Safefree(vals_buf);
  return hash;
}

mrb_value mruby_pm_bridge_sv2value(pTHX_ mrb_state *mrb, SV *sv) {
  if (!SvOK(sv)) {
    return mrb_nil_value();
  }
  else if (sv_isobject(sv)) {
    if (sv_derived_from(sv, "mRuby::Symbol")) {
      STRLEN len;
      const char* sym = SvPV(SvRV(sv), len);
      return mrb_symbol_value(mrb_intern(mrb, sym, (size_t)len));
    }
    else if (sv_isobject(sv) && sv_derived_from(sv, "mRuby::Bool::True")) {
      return mrb_true_value();
    }
    else if (sv_isobject(sv) && sv_derived_from(sv, "mRuby::Bool::False")) {
      return mrb_false_value();
    }
    return mrb_nil_value();
  }
  else if (SvROK(sv)) {
    switch (SvTYPE(SvRV(sv))) {
      case SVt_PVAV:
        return mruby_pm_bridge_av2value(aTHX_ mrb, (AV*)SvRV(sv));
      case SVt_PVHV:
        return mruby_pm_bridge_hv2value(aTHX_ mrb, (HV*)SvRV(sv));
      default:
        return mruby_pm_bridge_sv2value(aTHX_ mrb, (SV*)SvRV(sv));
    }
  }
  else if (SvIOK(sv)) {
    return mrb_fixnum_value((mrb_int)SvIV(sv));
  }
  else if (SvNOK(sv)) {
    return mrb_float_value(mrb, (mrb_float)SvNV(sv));
  }
  else {
    STRLEN len;
    const char *p = SvPV(sv, len);
    return mrb_str_new(mrb, p, (size_t)len);
  }
}

