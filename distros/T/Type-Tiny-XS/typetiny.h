#ifndef TYPETINY_H
#define TYPETINY_H

#define PERL_EUPXS_ALWAYS_EXPORT

#include "xshelper.h"

#ifndef mro_get_linear_isa
#define no_mro_get_linear_isa
#define mro_get_linear_isa(stash) typetiny_mro_get_linear_isa(aTHX_ stash)
AV* typetiny_mro_get_linear_isa(pTHX_ HV* const stash);
#define mro_method_changed_in(stash) ((void)++PL_sub_generation)
#endif /* !mro_get_linear_isa */

#ifndef mro_get_pkg_gen
#ifdef no_mro_get_linear_isa
#define mro_get_pkg_gen(stash) ((void)stash, PL_sub_generation)
#else
#define mro_get_pkg_gen(stash) (HvAUX(stash)->xhv_mro_meta ? HvAUX(stash)->xhv_mro_meta->pkg_gen : (U32)0)
#endif /* !no_mro_get_linear_isa */
#endif /* mro_get_package_gen */

#ifndef GvCV_set
#define GvCV_set(gv, cv) (GvCV(gv) = (cv))
#endif

extern SV* typetiny_package;
extern SV* typetiny_methods;
extern SV* typetiny_name;
extern SV* typetiny_coerce;

void
typetiny_throw_error(SV* const metaobject, SV* const data /* not used */, const char* const fmt, ...)
    __attribute__format__(__printf__, 3, 4);

#if (PERL_BCDVERSION < 0x5014000)
/* workaround RT #69939 */
I32
typetiny_call_sv_safe(pTHX_ SV*, I32);
#else
#define typetiny_call_sv_safe Perl_call_sv
#endif

#define call_sv_safe(sv, flags)     typetiny_call_sv_safe(aTHX_ sv, flags)
#define call_method_safe(m, flags)  typetiny_call_sv_safe(aTHX_ newSVpvn_flags(m, strlen(m), SVs_TEMP), flags | G_METHOD)
#define call_method_safes(m, flags) typetiny_call_sv_safe(aTHX_ newSVpvs_flags(m, SVs_TEMP),            flags | G_METHOD)

#define is_class_loaded(sv) typetiny_is_class_loaded(aTHX_ sv)
bool typetiny_is_class_loaded(pTHX_ SV*);

#define is_an_instance_of(klass, sv) typetiny_is_an_instance_of(aTHX_ gv_stashpvs(klass, GV_ADD), (sv))

#define IsObject(sv)   (SvROK(sv) && SvOBJECT(SvRV(sv)))
#define IsArrayRef(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVAV)
#define IsHashRef(sv)  (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVHV)
#define IsCodeRef(sv)  (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVCV)

#define mcall0(invocant, m)          typetiny_call0(aTHX_ (invocant), (m))
#define mcall1(invocant, m, arg1)    typetiny_call1(aTHX_ (invocant), (m), (arg1))
#define predicate_call(invocant, m)  typetiny_predicate_call(aTHX_ (invocant), (m))

#define mcall0s(invocant, m)          mcall0((invocant), sv_2mortal(newSVpvs_share(m)))
#define mcall1s(invocant, m, arg1)    mcall1((invocant), sv_2mortal(newSVpvs_share(m)), (arg1))
#define predicate_calls(invocant, m)  predicate_call((invocant), sv_2mortal(newSVpvs_share(m)))

SV* typetiny_call0(pTHX_ SV *const self, SV *const method);
SV* typetiny_call1(pTHX_ SV *const self, SV *const method, SV* const arg1);
int typetiny_predicate_call(pTHX_ SV* const self, SV* const method);

SV* typetiny_get_metaclass(pTHX_ SV* metaclass_name);

GV* typetiny_stash_fetch(pTHX_ HV* const stash, const char* const name, I32 const namelen, I32 const create);
#define stash_fetch(s, n, l, c) typetiny_stash_fetch(aTHX_ (s), (n), (l), (c))
#define stash_fetchs(s, n, c)   typetiny_stash_fetch(aTHX_ (s), STR_WITH_LEN(n), (c))

void typetiny_install_sub(pTHX_ GV* const gv, SV* const code_ref);

void typetiny_must_defined(pTHX_ SV* const value, const char* const name);
void typetiny_must_ref(pTHX_ SV* const value, const char* const name, svtype const t);

#define must_defined(sv, name)   typetiny_must_defined(aTHX_ sv, name)
#define must_ref(sv, name, svt)  typetiny_must_ref(aTHX_ sv, name, svt)

#define TYPETINYf_DIE_ON_FAIL 0x01
MAGIC* typetiny_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl, I32 const flags);

/* TYPETINY_av_at(av, ix) is the safer version of AvARRAY(av)[ix] if perl is compiled with -DDEBUGGING */
#ifdef DEBUGGING
#define TYPETINY_av_at(av, ix)  typetiny_av_at_safe(aTHX_ (av) , (ix))
SV* typetiny_av_at_safe(pTHX_ AV* const mi, I32 const ix);
#else
#define TYPETINY_av_at(av, ix) \
    (AvARRAY(av)[ix] ? AvARRAY(av)[ix] : &PL_sv_undef)
#endif

#define TYPETINY_mg_obj(mg)     ((mg)->mg_obj)
#define TYPETINY_mg_ptr(mg)     ((mg)->mg_ptr)
#define TYPETINY_mg_len(mg)     ((mg)->mg_len)
#define TYPETINY_mg_flags(mg)   ((mg)->mg_private)
#define TYPETINY_mg_virtual(mg) ((mg)->mg_virtual)

#define TYPETINY_mg_slot(mg)   TYPETINY_mg_obj(mg)
#define TYPETINY_mg_xa(mg)    ((AV*)TYPETINY_mg_ptr(mg))

/* type constraints */

int typetiny_tc_check(pTHX_ SV* const tc, SV* const sv);

int typetiny_tc_Any       (pTHX_ SV*, SV* const sv);
int typetiny_tc_Bool      (pTHX_ SV*, SV* const sv);
int typetiny_tc_Undef     (pTHX_ SV*, SV* const sv);
int typetiny_tc_Defined   (pTHX_ SV*, SV* const sv);
int typetiny_tc_Value     (pTHX_ SV*, SV* const sv);
int typetiny_tc_Num       (pTHX_ SV*, SV* const sv);
int typetiny_tc_Int       (pTHX_ SV*, SV* const sv);
int typetiny_tc_Str       (pTHX_ SV*, SV* const sv);
int typetiny_tc_ClassName (pTHX_ SV*, SV* const sv);
int typetiny_tc_RoleName  (pTHX_ SV*, SV* const sv);
int typetiny_tc_Ref       (pTHX_ SV*, SV* const sv);
int typetiny_tc_ScalarRef (pTHX_ SV*, SV* const sv);
int typetiny_tc_ArrayRef  (pTHX_ SV*, SV* const sv);
int typetiny_tc_HashRef   (pTHX_ SV*, SV* const sv);
int typetiny_tc_CodeRef   (pTHX_ SV*, SV* const sv);
int typetiny_tc_RegexpRef (pTHX_ SV*, SV* const sv);
int typetiny_tc_GlobRef   (pTHX_ SV*, SV* const sv);
int typetiny_tc_FileHandle(pTHX_ SV*, SV* const sv);
int typetiny_tc_Object    (pTHX_ SV*, SV* const sv);

CV* typetiny_generate_isa_predicate_for(pTHX_ SV* const klass, const char* const predicate_name);
CV* typetiny_generate_can_predicate_for(pTHX_ SV* const klass, const char* const predicate_name);

int typetiny_is_an_instance_of(pTHX_ HV* const stash, SV* const instance);

#endif /* !TYPETINY_H */

