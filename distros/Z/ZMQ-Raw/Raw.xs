#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <zmq.h>

#include "const-c-constant.inc"
#include "const-c-error.inc"
#include "const-c-message_options.inc"
#include "const-c-socket_options.inc"

typedef struct
{
	int code;
	SV *message;
	const char *file;
	unsigned int line;
} zmq_raw_error;

STATIC MGVTBL null_mg_vtbl =
{
	NULL, /* get */
	NULL, /* set */
	NULL, /* len */
	NULL, /* clear */
	NULL, /* free */
#if MGf_COPY
	NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
	NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
	NULL, /* local */
#endif /* MGf_LOCAL */
};

STATIC void xs_object_magic_attach_struct(pTHX_ SV *sv, void *ptr) {
	sv_magicext(sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, ptr, 0);
}

STATIC void *xs_object_magic_get_struct(pTHX_ SV *sv) {
	MAGIC *mg = NULL;

	if (SvTYPE(sv) >= SVt_PVMG) {
		MAGIC *tmp;

		for (tmp = SvMAGIC(sv); tmp;
			tmp = tmp -> mg_moremagic) {
			if ((tmp -> mg_type == PERL_MAGIC_ext) &&
				(tmp -> mg_virtual == &null_mg_vtbl))
				mg = tmp;
		}
	}

	return (mg) ? mg -> mg_ptr : NULL;
}

#define ZMQ_SV_TO_MAGIC(SV) \
	xs_object_magic_get_struct(aTHX_ SvRV(SV))

#define ZMQ_NEW_OBJ(rv, class, sv)				\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), class, sv);	\
	} STMT_END

#define ZMQ_NEW_OBJ_WITH_MAGIC(rv, class, sv, magic)		\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), class, sv);	\
								\
		xs_object_magic_attach_struct(			\
			aTHX_ SvRV(rv), SvREFCNT_inc_NN(magic)	\
		);						\
	} STMT_END

#define ZMQ_OBJ_SET_MAGIC(sv, magic) \
	STMT_START {						\
		xs_object_magic_attach_struct(			\
			aTHX_ SvRV(sv), SvREFCNT_inc_NN(magic)	\
		);						\
	} STMT_END


STATIC const COP* zmq_closest_cop(pTHX_ const COP *cop, const OP *o, const OP *curop, bool opnext)
{
	dVAR;

	if (!o || !curop || (
	opnext ? o->op_next == curop && o->op_type != OP_SCOPE : o == curop
	))
		return cop;

	if (o->op_flags & OPf_KIDS)
	{
		const OP *kid;

		for (kid = cUNOPo->op_first; kid; kid = OpSIBLING (kid))
		{
			const COP *new_cop;

			if (kid->op_type == OP_NULL && kid->op_targ == OP_NEXTSTATE)
				cop = (const COP *)kid;

			/* Keep searching, and return when we've found something. */
			new_cop = zmq_closest_cop (aTHX_ cop, kid, curop, opnext);
			if (new_cop)
				return new_cop;
		}
    }

    return NULL;
}

STATIC zmq_raw_error *create_error_obj (int code, SV *message)
{
	zmq_raw_error *e;
	const COP *cop;

	Newxz (e, 1, zmq_raw_error);
	e -> code = code;
	e -> message = message;

	cop = zmq_closest_cop (aTHX_ PL_curcop, OpSIBLING(PL_curcop), PL_op, FALSE);
	if (cop == NULL)
		cop = PL_curcop;

	if (CopLINE (cop))
	{
		e -> file = CopFILE (cop);
		e -> line = CopLINE (cop);
	} else
		e -> file = "unknown";

	return e;
}

STATIC zmq_raw_error *create_error_obj_fmt (int code, const char *prefix, const char *pat, va_list *list)
{
	zmq_raw_error *e;

	e = create_error_obj (code, newSVpv (prefix, 0));
	sv_vcatpvf(e -> message, pat, list);

	return e;
}

STATIC void __attribute__noreturn__ croak_error_obj (zmq_raw_error *e)
{
	SV *res = NULL;
	ZMQ_NEW_OBJ (res, "ZMQ::Raw::Error", e);
	SvREFCNT_inc (e -> message);
	croak_sv (res);
}

STATIC void croak_usage (const char *pat, ...)
{
	zmq_raw_error *e;
	va_list list;

	va_start (list, pat);
	e = create_error_obj_fmt (-1, "", pat, &list);
	va_end (list);

	croak_error_obj (e);
}

STATIC void *zmq_sv_to_ptr (const char *type, SV *sv, const char *file, int line)
{
	SV *full_type = sv_2mortal (newSVpvf ("ZMQ::Raw::%s", type));

	if (sv_isobject (sv) && sv_derived_from (sv, SvPV_nolen(full_type)))
		return INT2PTR (void *, SvIV ((SV *) SvRV (sv)));

	croak_usage ("Argument is not of type %s @ (%s:%d)",
		SvPV_nolen (full_type), file, line);

	return NULL;
}

#define ZMQ_SV_TO_PTR(type, sv) \
	zmq_sv_to_ptr(#type, sv, __FILE__, __LINE__)

STATIC void S_zmq_raw_check_error (int error, const char *file, int line)
{
	if (error < 0)
	{
		zmq_raw_error *e = create_error_obj (zmq_errno(), NULL);
		if (SvTRUE(ERRSV))
			e->message = newSVpv (SvPVbyte_nolen (ERRSV), 0);
		else
			e->message = newSVpvf ("%s (errno: %d) @ (%s:%d)", zmq_strerror (zmq_errno()), zmq_errno(), file, line);

		croak_error_obj (e);
	}
}

#define zmq_raw_check_error(e) S_zmq_raw_check_error(e, __FILE__, __LINE__)


MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw

INCLUDE: const-xs-constant.inc

INCLUDE: xs/Context.xs
INCLUDE: xs/Error.xs
INCLUDE: xs/Message.xs
INCLUDE: xs/Socket.xs

