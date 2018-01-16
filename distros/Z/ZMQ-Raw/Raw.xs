#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <zmq.h>
#include <libzmqraw/eventmap.h>
#include <libzmqraw/mutex.h>
#include <libzmqraw/timers.h>

#ifndef MUTABLE_GV
#define MUTABLE_GV(p) ((GV *)MUTABLE_PTR(p))
#endif

#define FEATURE_IPC      1
#define FEATURE_PGM      2
#define FEATURE_TIPC     3
#define FEATURE_NORM     4
#define FEATURE_CURVE    5
#define FEATURE_GSSAPI   6
#define FEATURE_DRAFT    7

#include "const-c-constant.inc"
#include "const-c-error.inc"
#include "const-c-message_options.inc"
#include "const-c-message_properties.inc"
#include "const-c-socket_options.inc"

typedef struct
{
	void *context;
	void *counter;
} zmq_raw_context;

typedef struct
{
	int code;
	SV *message;
	const char *file;
	unsigned int line;
} zmq_raw_error;

typedef struct
{
	void *socket;
	void *context;
	int type;
} zmq_raw_socket;

typedef struct
{
	void *poller;
	zmq_raw_event_map *interested;
	zmq_raw_event_map *events;
	zmq_poller_event_t *poller_events;
	int allocated;
	int size;
} zmq_raw_poller;

typedef struct
{
	int dummy;
} zmq_raw_proxy;

typedef struct my_cxt_t
{
	zmq_raw_context *contexts;
} my_cxt_t;

STATIC PerlIO *zmq_get_socket_io (SV *sv)
{
	if (SvROK (sv))
		sv = SvRV (sv);

	if (SvTYPE (sv) == SVt_PVGV)
	{
		if (isGV_with_GP (sv))
		{
			GV *gv = MUTABLE_GV (sv);
			IO *io = GvIO (gv);
			if (io)
				return IoIFP (io);
		}
	}

	return NULL;
}

#ifdef _WIN32
STATIC SOCKET zmq_get_native_socket (PerlIO *io)
{
	return _get_osfhandle (PerlIO_fileno (io));
}
#else
STATIC int zmq_get_native_socket (PerlIO *io)
{
	return PerlIO_fileno (io);
}
#endif

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

STATIC void xs_object_magic_attach_struct(pTHX_ SV *sv, void *ptr)
{
	sv_magicext(sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, (const char *)ptr, 0);
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

#define ZMQ_NEW_OBJ(rv, package, sv)				\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), package, sv);	\
	} STMT_END

#define ZMQ_NEW_OBJ_WITH_MAGIC(rv, package, sv, magic)		\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), package, sv);	\
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

	if (!(sv_isobject (sv) && sv_derived_from (sv, SvPV_nolen (full_type))))
	croak_usage ("Argument is not of type %s @ (%s:%d)\n",
		SvPV_nolen (full_type), file, line);

	return INT2PTR (void *, SvIV ((SV *) SvRV (sv)));
}

#define ZMQ_SV_TO_PTR(type, sv) \
	zmq_sv_to_ptr(#type, sv, __FILE__, __LINE__)

#define zmq_raw_check_error(error) \
    STMT_START {					                                              \
		if (error < 0)                                                            \
		{                                                                         \
			zmq_raw_error *e;                                                     \
                                                                                  \
			if (zmq_errno() == EINTR || zmq_errno() == EAGAIN)                    \
			{                                                                     \
				int ctx = GIMME_V;                                                \
				if (ctx == G_ARRAY)                                               \
				{                                                                 \
					XSRETURN_EMPTY;                                               \
				}                                                                 \
                                                                                  \
				XSRETURN_UNDEF;                                                   \
			}                                                                     \
                                                                                  \
			e = create_error_obj (zmq_errno(), NULL);                             \
			if (SvTRUE(ERRSV))                                                    \
				e->message = newSVpv (SvPVbyte_nolen (ERRSV), 0);                 \
			else                                                                  \
				e->message = newSVpvf ("%s (errno: %d) @ (%s:%d)\n",              \
					zmq_strerror (zmq_errno()), zmq_errno(), __FILE__, __LINE__); \
                                                                                  \
			croak_error_obj (e);                                                  \
		}                                                                         \
    } STMT_END

static zmq_raw_timers *timers;
static zmq_raw_mutex *timers_mutex;
STATIC void zmq_raw_timers_cleanup (void)
{
	#ifndef _WIN32
	zmq_raw_timers_destroy (timers);
	#endif

	zmq_raw_mutex_destroy (timers_mutex);
}

#define MY_CXT_KEY "ZMQ::Raw::_guts"
#define MAX_CONTEXT_COUNT 64
static zmq_raw_context contexts[MAX_CONTEXT_COUNT];

START_MY_CXT

MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.contexts = contexts;

	timers_mutex = zmq_raw_mutex_create();
	assert (timers_mutex);
}

INCLUDE: const-xs-constant.inc

void
has (package, option)
	SV *package
	int option

	PREINIT:
		const char *f = NULL;

	CODE:
		switch (option)
		{
			case FEATURE_IPC:
				f = "ipc";
				break;
			case FEATURE_PGM:
				f = "pgm";
				break;
			case FEATURE_TIPC:
				f = "tipc";
				break;
			case FEATURE_NORM:
				f = "norm";
				break;
			case FEATURE_CURVE:
				f = "curve";
				break;
			case FEATURE_GSSAPI:
				f = "gssapi";
				break;
			case FEATURE_DRAFT:
				f = "draft";
				break;
			default:
				croak_usage ("unknown option %d", option);
		}

		if (zmq_has (f))
			XSRETURN_YES;

		XSRETURN_NO;

INCLUDE: xs/Context.xs
INCLUDE: xs/Curve.xs
INCLUDE: xs/Error.xs
INCLUDE: xs/Message.xs
INCLUDE: xs/Poller.xs
INCLUDE: xs/Proxy.xs
INCLUDE: xs/Socket.xs
INCLUDE: xs/Timer.xs
INCLUDE: xs/Z85.xs

