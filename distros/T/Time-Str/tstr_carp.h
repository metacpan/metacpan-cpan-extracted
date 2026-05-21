#ifndef TSTR_CARP_H
#define TSTR_CARP_H

#include <stdarg.h>

static inline void tstr_carp_croak(pTHX_ const char *msg) {
  dSP;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(msg, 0)));
  PUTBACK;
  call_pv("Carp::croak", G_DISCARD);
  croak("Time::Str panic: unexpected return from Carp::croak");
}

static inline void tstr_carp_croakf(pTHX_ const char *fmt, ...) {
  dSP;
  va_list ap;
  SV *msg;

  va_start(ap, fmt);
  msg = vnewSVpvf(fmt, &ap);
  va_end(ap);

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(msg));
  PUTBACK;
  call_pv("Carp::croak", G_DISCARD);
  croak("Time::Str panic: unexpected return from Carp::croak");
}

static inline void tstr_carp_function_croakf(pTHX_ const char *fn, const char *fmt, ...) {
  dSP;
  va_list ap;
  SV *msg;

  va_start(ap, fmt);
  msg = vnewSVpvf(fmt, &ap);
  va_end(ap);

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(msg));
  PUTBACK;
  call_pv(fn, G_DISCARD);
  croak("Time::Str panic: unexpected return from Carp::croak");
}
#define tstr_croak(msg)       tstr_carp_function_croakf(aTHX_ "Time::Str::_croak", msg)
#define tstr_croakf(fmt, ...) tstr_carp_function_croakf(aTHX_ "Time::Str::_croak", fmt, __VA_ARGS__)
#define tstr_token_croakf(...) tstr_carp_function_croakf(aTHX_ "Time::Str::Token::_croak", __VA_ARGS__)

#endif /* TSTR_CARP_H */
