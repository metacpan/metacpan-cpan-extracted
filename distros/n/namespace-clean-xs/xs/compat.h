#ifndef __NAMESPACE_CLEAN_COMPAT_H_
#define __NAMESPACE_CLEAN_COMPAT_H_

#if (PERL_VERSION == 10 || PERL_VERSION == 14)
#define DEBUGGER_NEEDS_CV_RENAME
#endif

#ifndef hv_deletehek
#define hv_deletehek(hv, hek, flags) \
    hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), (flags)|HV_DELETE, NULL, HEK_HASH(hek))
#endif

#ifndef hv_storehek
#define hv_storehek(hv, hek, val) \
    hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), HV_FETCH_ISSTORE|HV_FETCH_JUST_SV, (val), HEK_HASH(hek))
#endif

#ifndef hv_fetchhek_flags
#define hv_fetchhek_flags(hv, hek, flags) \
    ((SV**)hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), flags, NULL, HEK_HASH(hek)))
#endif

#define hv_fetch_sv_flags(hv, keysv, flags) \
        ((SV**)hv_common((hv),(keysv), NULL, 0, 0, flags, NULL, 0))

#ifndef SvREFCNT_dec_NN
#define SvREFCNT_dec_NN SvREFCNT_dec
#endif

#ifndef GvCV_set
#define GvCV_set(gv, cv) (GvCV(gv) = cv)
#endif

#ifndef gv_init_sv
#define gv_init_sv(gv, stash, sv, flags) \
    {   STRLEN len;    \
        const char* buf = SvPV_const(sv, len);    \
        gv_init_pvn(gv, stash, buf, len, flags | SvUTF8(sv)); }
#endif

#ifndef gv_init_pvn
#define gv_init_pvn(gv,stash,name,len,flags) gv_init(gv,stash,name,len,flags & GV_ADDMULTI)
#endif

#ifndef HV_FETCH_EMPTY_HE
#define NO_HV_FETCH_EMPTY_HE
#define HV_FETCH_EMPTY_HE 0
#endif

#ifndef sv_dup_inc
#define sv_dup_inc(s,t) SvREFCNT_inc_NN(sv_dup(s,t))
#endif

#endif /* __NAMESPACE_CLEAN_COMPAT_H_ */

