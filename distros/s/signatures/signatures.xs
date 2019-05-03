#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_parser
#include "ppport.h"

/* this should go into ppport */
#if PERL_BCDVERSION >= 0x5009005
#define PL_oldbufptr D_PPP_my_PL_parser_var(oldbufptr)
#endif

#if PERL_REVISION == 5 && PERL_VERSION >= 10
#define HAS_HINTS_HASH
#endif

#include "hook_op_check.h"
#include "hook_op_ppaddr.h"
#include "hook_parser.h"

typedef struct userdata_St {
	char *f_class;
	SV *class;
	hook_op_check_id eval_hook;
	hook_op_check_id parser_id;
} userdata_t;

STATIC void
call_to_perl (SV *class, UV offset, char *proto) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);
	EXTEND (SP, 3);
	PUSHs (class);
	mPUSHu (offset);
	mPUSHp (proto, strlen (proto));
	PUTBACK;

	call_method ("callback", G_VOID|G_DISCARD);

	FREETMPS;
	LEAVE;
}

STATIC SV *
qualify_func_name (const char *s) {
	SV *ret = newSVpvs ("");

	if (strstr (s, ":") == NULL) {
		sv_catpv (ret, SvPVX (PL_curstname));
		sv_catpvs (ret, "::");
	}

	sv_catpv (ret, s);

	return ret;
}

STATIC int
enabled (SV *class) {
	STRLEN len;
	char *key;
	HV *hints = GvHV (PL_hintgv);
	SV **sv, *tmp = newSVsv (class);

	sv_catpv (tmp, "::enabled");
	key = SvPV (tmp, len);

	if (!hints) {
		return 0;
	}

	sv = hv_fetch (hints, key, len, 0);
	SvREFCNT_dec (tmp);

	if (!sv || !*sv) {
		return 0;
	}

	return SvOK (*sv);
}

STATIC OP *
handle_proto (pTHX_ OP *op, void *user_data) {
	OP *ret;
	SV *op_sv, *name;
	char *s, *tmp, *tmp2;
	char tmpbuf[sizeof (PL_tokenbuf)], proto[sizeof (PL_tokenbuf)];
	STRLEN retlen = 0;
	userdata_t *ud = (userdata_t *)user_data;

	if (strNE (ud->f_class, SvPVX (PL_curstname))) {
		return op;
	}

	if (!enabled (ud->class)) {
		return op;
	}

	if (!PL_parser) {
		return op;
	}

	if (!PL_lex_stuff) {
		return op;
	}

	op_sv = cSVOPx (op)->op_sv;

	if (!SvPOK (op_sv)) {
		return op;
	}

	/* sub $name */
	s = PL_oldbufptr;
	s = hook_toke_skipspace (aTHX_ s);

	if (strnNE (s, "sub", 3)) {
		return op;
	}

	if (!isSPACE (s[3])) {
		return op;
	}

	s = hook_toke_skipspace (aTHX_ s + 4);

	if (strNE (SvPVX (PL_subname), "?")) {
		(void)hook_toke_scan_word (aTHX_ (s - SvPVX (PL_linestr)), 1, tmpbuf, sizeof (tmpbuf), &retlen);

		if (retlen < 1) {
			return op;
		}

		name = qualify_func_name (tmpbuf);

		if (!sv_eq (PL_subname, name)) {
			SvREFCNT_dec (name);
			return op;
		}

		SvREFCNT_dec (name);
	}

	/* ($proto) */
	s = hook_toke_skipspace (aTHX_ s + retlen);
	if (s[0] != '(') {
		return op;
	}

	assert(PL_lex_stuff == op_sv);
	PL_lex_stuff = NULL;

	tmp = hook_toke_scan_str (aTHX_ s);
	tmp2 = hook_parser_get_lex_stuff (aTHX);
	hook_parser_clear_lex_stuff (aTHX);

	if (s == tmp || !tmp2) {
		return op;
	}

	strncpy (proto, s + 1, tmp - s - 2);
	proto[tmp - s - 2] = '\0';

	s++;

	while (tmp > s + 1) {
		if (isSPACE (s[0])) {
			s++;
			continue;
		}

		if (isSPACE (tmp2[0])) {
			tmp2++;
			continue;
		}

		if (*tmp2 != *s) {
			return op;
		}

		tmp2++;
		s++;
	}

	ret = NULL;

	s = hook_toke_skipspace (aTHX_ s + 1);
	if (s[0] == ':') {
		s++;
		while (s[0] != '{') {
			char *attr_start;
			s = hook_toke_skipspace (aTHX_ s);
			attr_start = s;
			(void)hook_toke_scan_word (aTHX_ (s - SvPVX (PL_linestr)), 0, tmpbuf, sizeof (tmpbuf), &retlen);

			if (retlen < 1) {
				return op;
			}

			s += retlen;
			if (s[0] == '(') {
				tmp = hook_toke_scan_str (aTHX_ s);
				tmp2 = hook_parser_get_lex_stuff (aTHX);
				hook_parser_clear_lex_stuff (aTHX);

				if (s == tmp) {
					return op;
				}

				s = tmp;

				if (strEQ (tmpbuf, "proto")) {
					while (attr_start < tmp) {
						*attr_start = ' ';
						attr_start++;
					}

					ret = newSVOP (OP_CONST, 0, newSVpvn (tmp2, strlen (tmp2)));
					op_free (op);
					op = ret;
				}
			}
			else if (strEQ (tmpbuf, "proto")) {
				croak ("proto attribute requires argument");
			}

			s = hook_toke_skipspace (aTHX_ s);

            if (s[0] == ':') {
                s++;
            }
		}
	}

	if (s[0] != '{') {
		/* croak as we already messed with op when :proto is given? */
		return op;
	}

	call_to_perl (ud->class, s - hook_parser_get_linestr (aTHX), proto);

	if (!ret) {
		op_free (op);
	}

	return ret;
}

/* block_start conflicts with the perl API function exposed in 5.21.6.  */
#undef block_start
#if PERL_BCDVERSION >= 0x5013006
STATIC void
block_start (pTHX_ int full) {
	PERL_UNUSED_VAR (full);

	if (SvLEN (PL_linestr) < 16384)
		lex_grow_linestr (16384);
}
#endif

STATIC OP *
before_eval (pTHX_ OP *op, void *user_data) {
	dSP;
	SV *sv, **stack;
	SV *class = (SV *)user_data;

#ifdef HAS_HINTS_HASH
	if (PL_op->op_private & OPpEVAL_HAS_HH) {
		stack = &SP[-1];
	}
	else {
		stack = &SP[0];
	}
#else
	stack = &SP[0];
#endif

	sv = *stack;

	if (SvPOK (sv)) {
		/* FIXME: this leaks the new scalar */
		SV *new = newSVpvs ("use ");
		sv_catsv (new, class);
		sv_catpvs (new, ";");
		sv_catsv (new, sv);
		*stack = new;
	}

	return op;
}

STATIC OP *
handle_eval (pTHX_ OP *op, void *user_data) {
	userdata_t *ud = (userdata_t *)user_data;

	if (enabled (ud->class)) {
		hook_op_ppaddr_around (op, before_eval, NULL, newSVsv (ud->class));
	}

	return op;
}

MODULE = signatures  PACKAGE = signatures

PROTOTYPES: DISABLE

UV
setup (class, f_class)
		SV *class
		char *f_class
	PREINIT:
		userdata_t *ud;
#if PERL_BCDVERSION >= 0x5013006
		static BHK bhk;
#endif
	INIT:
		Newx (ud, 1, userdata_t);
		ud->class = newSVsv (class);
		ud->f_class = f_class;
	CODE:
		ud->parser_id = hook_parser_setup ();
#if PERL_BCDVERSION >= 0x5013006
		BhkENTRY_set (&bhk, bhk_start, block_start);
		Perl_blockhook_register (aTHX_ &bhk);
#endif
		ud->eval_hook = hook_op_check (OP_ENTEREVAL, handle_eval, ud);
		RETVAL = (UV)hook_op_check (OP_CONST, handle_proto, ud);
	OUTPUT:
		RETVAL

void
teardown (class, id)
		UV id
	PREINIT:
		userdata_t *ud;
	CODE:
		ud = (userdata_t *)hook_op_check_remove (OP_CONST, id);

		if (ud) {
			hook_op_check_remove (OP_ENTEREVAL, ud->eval_hook);
			hook_parser_teardown (ud->parser_id);
			SvREFCNT_dec (ud->class);
			Safefree (ud);
		}
# # vim: ts=4 sts=4 sw=4 noet :
