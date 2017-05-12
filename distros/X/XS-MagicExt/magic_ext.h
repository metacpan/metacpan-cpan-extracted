/*

=head1 NAME

magic_ext.h - Provides MAGIC manipulators for XS modules

=head1 SEE ALSO

L<XS::MagicExt> for details.

=cut

*/

#ifndef XS_MAGIC_EXT_H
#define XS_MAGIC_EXT_H

#ifdef USE_PPPORT
#include "ppport.h"
#endif

#define mgx_attach_with_ptr(sv, vtbl, obj, ptr, len) magic_ext_mgx_attach(aTHX_ sv, vtbl, obj, ptr, len)
#define mgx_attach_with_sv(sv, vtbl, obj, data)      magic_ext_mgx_attach(aTHX_ sv, vtbl, obj, data, HEf_SVKEY)
#define mgx_attach(sv, vtbl, obj)                    magic_ext_mgx_attach(aTHX_ sv, vtbl, obj, (void*)NULL, 0)

#define mgx_find(sv, vtbl) magic_ext_mgx_find(aTHX_ sv, vtbl, MGXf_DEFAULT)
#define mgx_get(sv, vtbl)  magic_ext_mgx_find(aTHX_ sv, vtbl, MGXf_CROAK_IF_NOT_FOUND)
#define MGX_FIND(sv, vtbl) (SvMAGICAL(sv) ? mgx_find(sv, vtbl) : NULL)

#define mgx_detach(sv, vtbl) magic_ext_mgx_detach(aTHX_ sv, vtbl)

#define MG_obj_refcounted_on(mg)  ((mg)->mg_flags |=  MGf_REFCOUNTED)
#define MG_obj_refcounted_off(mg) ((mg)->mg_flags &= ~MGf_REFCOUNTED)
#define MG_sv_refcounted_on(mg)   ((mg)->mg_len    = HEf_SVKEY)
#define MG_sv_refcounted_off(mg)  ((mg)->mg_len    = 0)

#define MG_obj(mg)       ((mg)->mg_obj)
#define MG_private(mg)   ((mg)->mg_private)
#define MG_ptr(mg)       ((mg)->mg_ptr)
#define MG_len(mg)       ((mg)->mg_len)

#define MG_vptr(mg)      ((void*)MG_ptr(mg))
#define MG_sv(mg)        ((SV*)MG_ptr(mg))
#define MG_sv_set(mg, sv) STMT_START{    \
		SV* const _sv = (sv);    \
		assert(mg);              \
		assert(_sv)  ;           \
		MG_ptr(mg) = (char*)_sv; \
		MG_sv_refcounted_on(mg); \
	} STMT_END

#define MG_ptr_is_sv(mg) (MG_len(mg) == HEf_SVKEY)

#define MGXf_DEFAULT            0x00
#define MGXf_CROAK_IF_NOT_FOUND 0x01


MAGIC* magic_ext_mgx_attach(pTHX_ SV* const sv,       MGVTBL* const vtbl, SV* const obj, void* const ptr, I32 const len);
MAGIC* magic_ext_mgx_find  (pTHX_ SV* const sv, const MGVTBL* const vtbl, I32 const flags);
void   magic_ext_mgx_detach(pTHX_ SV* const sv, const MGVTBL* const vtbl);


#endif /* !defined(XS_MAGIC_EXT_H) */
