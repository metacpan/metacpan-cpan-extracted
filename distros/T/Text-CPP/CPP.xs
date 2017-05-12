#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <patchlevel.h>	/* Include explicitly */
#include "config.h"
#include "system.h"
#include "cpplib.h"
#include "cpphash.h"

#if (PATCHLEVEL < 6)
/* This makes it compile on 5.5.2! Perhaps I can also get it to run. */
#define SvPV_nolen(s) SvPV((s), PL_na)
#define get_av(n, c) perl_get_av((n), (c))
#endif

#define ST_INIT		0
#define ST_READ		1
#define ST_FINAL	2
#define ST_FAIL		99

#define ASSERT_INIT(s) do { if ((s)->state != ST_INIT) \
	croak("Text::CPP reader is not ready to read a file"); } while(0)
#define ASSERT_READ(s) do { if ((s)->state != ST_READ) \
	croak("Text::CPP reader has not yet read a file"); } while(0)

typedef
struct _text_cpp {
	struct cpp_reader	*reader;
	unsigned int		 state;
	SV					*user_data;
	HV					*builtins;
	AV					*errors;
	SV					*buffer;

	SV					*cb_line_change;
	SV					*cb_file_change;
	SV					*cb_include;
	SV					*cb_define;
	SV					*cb_undef;
	SV					*cb_ident;
	SV					*cb_def_pragma;
	SV					*cb_register_builtins;
} *Text__CPP;

#define TEXT_CPP(x) ((Text__CPP)((x)->userdata))

static Text__CPP instance = NULL;

#define EXPORT_INT_AS(n, v) do { \
				newCONSTSUB(stash, n, newSViv(v)); \
				av_push(export, newSVpv(n, strlen(n))); \
					} while(0)

#define EXPORT_INT(x) EXPORT_INT_AS(#x, x)

static void
cb_line_change(struct cpp_reader *reader,
				const cpp_token *token,
				int passing_args)
{
	Text__CPP	 self;
	dSP;

	self = TEXT_CPP(reader);
	if (!self->cb_line_change)
		return;
	PUSHMARK(SP);
	// XPUSHs(self);	/* Keep a pointer to 'self' around. */
	call_sv(self->cb_line_change, G_DISCARD);
}

static void
cb_define(struct cpp_reader *reader,
		unsigned int line,
		cpp_hashnode *node)
{
	Text__CPP	 self;

	self = TEXT_CPP(reader);
	if (!self->cb_define)
		return;
}

static void
cb_undef(struct cpp_reader *reader,
		unsigned int line,
		cpp_hashnode *node)
{
	Text__CPP	 self;

	self = TEXT_CPP(reader);
	if (!self->cb_undef)
		return;
}

static void
cb_ident(struct cpp_reader *reader,
		unsigned int line,
		const cpp_string * str)
{
	Text__CPP	 self;

	self = TEXT_CPP(reader);
	if (!self->cb_ident)
		return;
}

static void
setup_callbacks(struct cpp_reader *reader, HV *hv)
{
	Text__CPP		  self;
	cpp_callbacks	 *cb;
	SV				**svp;

#define LOOKUP_CALLBACK(k) (svp = hv_fetch(hv, k, strlen(k), FALSE))
#define VALID_CALLBACK (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV)
#define DO_CALLBACK(k, n) \
		cb->n = cb_ ## n; /* Set this unconditionally */ \
		if (LOOKUP_CALLBACK(k)) { \
			if (!(VALID_CALLBACK)) \
				croak("Callback " k " not subref"); \
			else { \
				self->cb_ ## n = *svp; \
			} \
		}

	self = TEXT_CPP(reader);
	cb = cpp_get_callbacks(reader);

	DO_CALLBACK("LineChange", line_change);
	DO_CALLBACK("Define", define);
	DO_CALLBACK("Undef", undef);
	DO_CALLBACK("Ident", ident);
}

/* Would this lot be better if preprocessed in pure Perl to build a
 * standard set of option names? */
static void
parse_options(struct cpp_reader *reader, HV *hv)
{
	struct cpp_options	*opts;
	SV					**svp;
	char				 *str;
	STRLEN				  slen;
	AV					 *av;
	int					  alen;
	int					  i;

	if (!hv)
		return;

	opts = cpp_get_options(reader);

#define TEST_OPTION(k) (svp = hv_fetch(hv, k, strlen(k), FALSE))
#define SET_OPTION(o, v) opts->o = (v)
#define DO_OPTION(k, o, v) if (TEST_OPTION(k)) SET_OPTION(o, v)

#define FOREACH_VALUE(name) \
		if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) \
			av = (AV *)SvRV(*svp); \
		else \
			croak("Argument to " name " must be an array"); \
		alen = av_len(av) +1; \
		for (i = 0; i < alen; i++) \
			if (!(svp = av_fetch(av, i, FALSE))) \
				continue; \
			else


	/* Output related features */

	DO_OPTION("DiscardComments", discard_comments, !!SvTRUE(*svp));
		else
	DO_OPTION("-C", discard_comments, !!SvTRUE(*svp));

	DO_OPTION("DiscardCommentsInMacroExp",
					discard_comments_in_macro_exp, !!SvTRUE(*svp));
		else
	DO_OPTION("-CC", discard_comments_in_macro_exp, !!SvTRUE(*svp));

	DO_OPTION("PrintIncludeNames", print_include_names, !!SvTRUE(*svp));
		else
	DO_OPTION("-H", print_include_names, !!SvTRUE(*svp));

	/* Handle deps: -M -MM -MD -MMD -MG -MP -MQ -MT */
	DO_OPTION("NoLineCommands", no_line_commands, !!SvTRUE(*svp));
		else
	DO_OPTION("-P", no_line_commands, !!SvTRUE(*svp));

	/* Other features */

	DO_OPTION("Remap", remap, !!SvTRUE(*svp));
		else
	DO_OPTION("-remap", remap, !!SvTRUE(*svp));

	DO_OPTION("Trigraphs", trigraphs, !!SvTRUE(*svp));
		else
	DO_OPTION("-trigraphs", trigraphs, !!SvTRUE(*svp));

	DO_OPTION("Traditional", traditional, !!SvTRUE(*svp));
		else
	DO_OPTION("-traditional", traditional, !!SvTRUE(*svp));

	DO_OPTION("NoWarnings", inhibit_warnings, !!SvTRUE(*svp));
		else
	DO_OPTION("-w", inhibit_warnings, !!SvTRUE(*svp));

	DO_OPTION("Verbose", inhibit_warnings, !!SvTRUE(*svp));
		else
	DO_OPTION("-v", inhibit_warnings, !!SvTRUE(*svp));

	/* Warnings */
	/* Handle: WarnAll WarnEndifLabels */

	DO_OPTION("WarnComments", warn_comments, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wcomment", warn_comments, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wcomments", warn_comments, !!SvTRUE(*svp));

	DO_OPTION("WarnDeprecated", warn_deprecated, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wdeprecated", warn_deprecated, !!SvTRUE(*svp));

	DO_OPTION("WarningsAreErrors", warnings_are_errors, !!SvTRUE(*svp));
		else
	DO_OPTION("-Werror", warnings_are_errors, !!SvTRUE(*svp));

	DO_OPTION("WarnImport", warn_import, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wimport", warn_import, !!SvTRUE(*svp));

	DO_OPTION("WarnMultichar", warn_multichar, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wmultichar", warn_multichar, !!SvTRUE(*svp));

	DO_OPTION("WarnSystemHeaders", warn_system_headers, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wsystem-headers", warn_system_headers, !!SvTRUE(*svp));

	DO_OPTION("WarnTraditional", warn_traditional, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wtraditional", warn_traditional, !!SvTRUE(*svp));

	DO_OPTION("WarnTrigraphs", warn_trigraphs, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wtrigraphs", warn_trigraphs, !!SvTRUE(*svp));

	DO_OPTION("WarnUndef", warn_undef, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wundef", warn_undef, !!SvTRUE(*svp));

	DO_OPTION("WarnUnusedMacros", warn_unused_macros, !!SvTRUE(*svp));
		else
	DO_OPTION("-Wunused-macros", warn_unused_macros, !!SvTRUE(*svp));

	/* Error handling */

	if (TEST_OPTION("PedanticErrors")||TEST_OPTION("-pedantic-errors")){
		SET_OPTION(pedantic_errors, !!SvTRUE(*svp));
		SET_OPTION(pedantic, !!SvTRUE(*svp));
		SET_OPTION(warn_endif_labels, !!SvTRUE(*svp));
	}
	else if (TEST_OPTION("Pedantic") || TEST_OPTION("-pedantic")) {
		SET_OPTION(pedantic, !!SvTRUE(*svp));
		SET_OPTION(warn_endif_labels, !!SvTRUE(*svp));
	}

	/* Including and include path */
	/* Do not handle: -iwithprefix-iwithprefixbefore */

	DO_OPTION("NoStandardIncludes",
					no_standard_includes, !!SvTRUE(*svp));
		else
	DO_OPTION("-nostdinc", no_standard_includes, !!SvTRUE(*svp));

	DO_OPTION("NoStandardIncludes++",
					no_standard_cplusplus_includes, !!SvTRUE(*svp));
		else
	DO_OPTION("-nostdincplusplus",
					no_standard_cplusplus_includes, !!SvTRUE(*svp));

	if (TEST_OPTION("IncludePrefix") || TEST_OPTION("-iprefix")) {
		str = SvPV(*svp, slen);
		SET_OPTION(include_prefix, str);
		SET_OPTION(include_prefix_len, slen);
	}

	if (TEST_OPTION("SystemRoot") || TEST_OPTION("-isysroot")) {
		SET_OPTION(sysroot, SvPV_nolen(*svp));
	}

	if (TEST_OPTION("IncludePath") || TEST_OPTION("-I")) {
		FOREACH_VALUE("IncludePath/-I") {
			cpp_append_include_chain(reader, xstrdup(SvPV_nolen(*svp)),
					0);
		}
	}

	if (TEST_OPTION("SystemIncludePath") || TEST_OPTION("-isystem")) {
		FOREACH_VALUE("SystemIncludePath/-isystem") {
			cpp_append_include_chain(reader, xstrdup(SvPV_nolen(*svp)),
					1);
		}
	}

	if (TEST_OPTION("AfterIncludePath") || TEST_OPTION("-idirafter")) {
		FOREACH_VALUE("AfterIncludePath/-idirafter") {
			cpp_append_include_chain(reader, xstrdup(SvPV_nolen(*svp)),
					2);
		}
	}

	if (TEST_OPTION("Include") || TEST_OPTION("-include")) {
		FOREACH_VALUE("Include/-include") {
			cpp_append_include_file(reader, SvPV_nolen(*svp));
		}
	}

	if (TEST_OPTION("IncludeMacros") || TEST_OPTION("-imacros")) {
		FOREACH_VALUE("IncludeMacros/-imacros") {
			cpp_append_imacros_file(reader, SvPV_nolen(*svp));
		}
	}

	/* Macro definitions an undefinitions */
	/* Do not handle: -A */

	if (TEST_OPTION("Define") || TEST_OPTION("-D")) {
		FOREACH_VALUE("Define/-D") {
			cpp_append_pending_directive(reader, SvPV_nolen(*svp),
							cpp_define);
		}
	}

	if (TEST_OPTION("Undef") || TEST_OPTION("-U")) {
		FOREACH_VALUE("Undef/-U") {
			cpp_append_pending_directive(reader, SvPV_nolen(*svp),
							cpp_undef);
		}
	}

	/* Everything else */
	/* Handle: -foperator-names -fpreprocessed -fshow-column
	 * -ftabstop -lang-objc -x -std -ansi -I- */
}

static void
cb_register_builtins(struct cpp_reader *reader)
{
	HV		*hv;
	char	*key;
	I32		 klen;
	char	*val;
	STRLEN	 vlen;
	SV		*sv;
	char	*buf;

	hv = TEXT_CPP(reader)->builtins;
	if (!hv)
		return;

	hv_iterinit(hv);
	while ((sv = hv_iternextsv(hv, &key, &klen))) {
		if (!SvPOK(sv) && !SvIOK(sv))
			croak("cb_register_builtins: builtin macro "
							"value not string or integer");
		val = SvPV(sv, vlen);
		buf = alloca(klen + 1 + vlen + 1);
		memcpy(buf, key, klen);
		buf[klen] =  '=';
		memcpy(&(buf[klen + 1]), val, vlen);
		buf[klen + 1 + vlen] = '\0';
		cpp_define(reader, buf);
	}
}


void
cb_error(cpp_reader *reader, SV *sv, const char *msgid, va_list ap)
{
	char	*buf;
	char	 tmpbuf[1];
	int		 bufsiz;
	va_list	 aplocal;

	/* This will not work in glibc up to 2.0.6 */
	va_copy(aplocal, ap);
	bufsiz = vsnprintf(tmpbuf, 1, msgid, aplocal);
	va_end(aplocal);

	buf = alloca(bufsiz + 1);

	va_copy(aplocal, ap);
	vsprintf(buf, msgid, aplocal);
	va_end(aplocal);

	sv_catpvn(sv, buf, bufsiz);
	av_push(TEXT_CPP(reader)->errors, sv);
}

/* Copied from do_diagnostic() in cpplib.c */
void
cb_diagnostic(struct cpp_reader *reader, int code, const char *dir)
{
	const cpp_token	*token;
	SV				*sv;
	int				 len;
	char			*buf;
	char			*end;

	if ((sv = _sv_cpp_begin_message(reader, code,
					reader->cur_token[-1].line,
					reader->cur_token[-1].col))) {
		if (dir)
			sv_catpvf(sv, "#%s ", dir);
		reader->state.prevent_expansion++;
		token = cpp_get_token(reader);
		while (token->type != CPP_EOF) {
			len = cpp_token_len(token);
			buf = alloca(len);
			end = cpp_spell_token(reader, token, buf);
			end[0] = '\0';
			sv_catpvn(sv, buf, (end - buf));
			token = cpp_get_token(reader);
			if (token->flags & PREV_WHITE)
				sv_catpvn(sv, " ", 1);
		}
		reader->state.prevent_expansion--;
	}

	av_push(TEXT_CPP(reader)->errors, sv);
}

MODULE = Text::CPP PACKAGE = Text::CPP

PROTOTYPES: ENABLE

BOOT:
{
	HV	*stash;
	AV	*export;

	stash = gv_stashpv("Text::CPP", TRUE);
	export = get_av("Text::CPP::EXPORT_OK", TRUE);

	EXPORT_INT(CLK_GNUC89);
	EXPORT_INT(CLK_GNUC99);
	EXPORT_INT(CLK_STDC89);
	EXPORT_INT(CLK_STDC94);
	EXPORT_INT(CLK_STDC99);
	EXPORT_INT(CLK_GNUCXX);
	EXPORT_INT(CLK_CXX98);
	EXPORT_INT(CLK_ASM);

	EXPORT_INT(CPP_EQ);
	EXPORT_INT(CPP_NOT);
	EXPORT_INT(CPP_GREATER);
	EXPORT_INT(CPP_LESS);
	EXPORT_INT(CPP_PLUS);
	EXPORT_INT(CPP_MINUS);
	EXPORT_INT(CPP_MULT);
	EXPORT_INT(CPP_DIV);
	EXPORT_INT(CPP_MOD);
	EXPORT_INT(CPP_AND);
	EXPORT_INT(CPP_OR);
	EXPORT_INT(CPP_XOR);
	EXPORT_INT(CPP_RSHIFT);
	EXPORT_INT(CPP_LSHIFT);
	EXPORT_INT(CPP_MIN);
	EXPORT_INT(CPP_MAX);
	EXPORT_INT(CPP_COMPL);
	EXPORT_INT(CPP_AND_AND);
	EXPORT_INT(CPP_OR_OR);
	EXPORT_INT(CPP_QUERY);
	EXPORT_INT(CPP_COLON);
	EXPORT_INT(CPP_COMMA);
	EXPORT_INT(CPP_OPEN_PAREN);
	EXPORT_INT(CPP_CLOSE_PAREN);
	EXPORT_INT(CPP_EOF);
	EXPORT_INT(CPP_EQ_EQ);
	EXPORT_INT(CPP_NOT_EQ);
	EXPORT_INT(CPP_GREATER_EQ);
	EXPORT_INT(CPP_LESS_EQ);
	EXPORT_INT(CPP_PLUS_EQ);
	EXPORT_INT(CPP_MINUS_EQ);
	EXPORT_INT(CPP_MULT_EQ);
	EXPORT_INT(CPP_DIV_EQ);
	EXPORT_INT(CPP_MOD_EQ);
	EXPORT_INT(CPP_AND_EQ);
	EXPORT_INT(CPP_OR_EQ);
	EXPORT_INT(CPP_XOR_EQ);
	EXPORT_INT(CPP_RSHIFT_EQ);
	EXPORT_INT(CPP_LSHIFT_EQ);
	EXPORT_INT(CPP_MIN_EQ);
	EXPORT_INT(CPP_MAX_EQ);
	EXPORT_INT(CPP_HASH);
	EXPORT_INT(CPP_PASTE);
	EXPORT_INT(CPP_OPEN_SQUARE);
	EXPORT_INT(CPP_CLOSE_SQUARE);
	EXPORT_INT(CPP_OPEN_BRACE);
	EXPORT_INT(CPP_CLOSE_BRACE);
	EXPORT_INT(CPP_SEMICOLON);
	EXPORT_INT(CPP_ELLIPSIS);
	EXPORT_INT(CPP_PLUS_PLUS);
	EXPORT_INT(CPP_MINUS_MINUS);
	EXPORT_INT(CPP_DEREF);
	EXPORT_INT(CPP_DOT);
	EXPORT_INT(CPP_SCOPE);
	EXPORT_INT(CPP_DEREF_STAR);
	EXPORT_INT(CPP_DOT_STAR);
	EXPORT_INT(CPP_ATSIGN);
	EXPORT_INT(CPP_NAME);
	EXPORT_INT(CPP_NUMBER);
	EXPORT_INT(CPP_CHAR);
	EXPORT_INT(CPP_WCHAR);
	EXPORT_INT(CPP_OTHER);
	EXPORT_INT(CPP_STRING);
	EXPORT_INT(CPP_WSTRING);
	EXPORT_INT(CPP_HEADER_NAME);
	EXPORT_INT(CPP_COMMENT);
	EXPORT_INT(CPP_MACRO_ARG);
	EXPORT_INT(CPP_PADDING);

	EXPORT_INT(CPP_N_CATEGORY);
	EXPORT_INT(CPP_N_INVALID);
	EXPORT_INT(CPP_N_INTEGER);
	EXPORT_INT(CPP_N_FLOATING);
	EXPORT_INT(CPP_N_WIDTH);
	EXPORT_INT(CPP_N_SMALL);
	EXPORT_INT(CPP_N_MEDIUM);
	EXPORT_INT(CPP_N_LARGE);
	EXPORT_INT(CPP_N_RADIX);
	EXPORT_INT(CPP_N_DECIMAL);
	EXPORT_INT(CPP_N_HEX);
	EXPORT_INT(CPP_N_OCTAL);
	EXPORT_INT(CPP_N_UNSIGNED);
	EXPORT_INT(CPP_N_IMAGINARY);

	EXPORT_INT_AS("TF_PREV_WHITE", PREV_WHITE);
	EXPORT_INT_AS("TF_DIGRAPH", DIGRAPH);
	EXPORT_INT_AS("TF_STRINGIFY_ARG", STRINGIFY_ARG);
	EXPORT_INT_AS("TF_PASTE_LEFT", PASTE_LEFT);
	EXPORT_INT_AS("TF_NAMED_OP", NAMED_OP);
	EXPORT_INT_AS("TF_NO_EXPAND", NO_EXPAND);
	EXPORT_INT_AS("TF_BOL", BOL);

	/*
	EXPORT_INT(ST_INIT);
	EXPORT_INT(ST_READ);
	EXPORT_INT(ST_FINAL);
	EXPORT_INT(ST_FAIL);
	*/
}

SV *
_create(class, lang, builtins, options, callbacks)
	const char *class
	int			lang
	HV *		builtins
	HV *		options
	HV *		callbacks
	PREINIT:
		Text__CPP				 self;
		struct cpp_callbacks	*cb;
	CODE:
		if (instance)
			croak("Please create only one Text::CPP at a time");
		Newz(0, self, 1, struct _text_cpp);
		self->reader = cpp_create_reader(lang);
		self->reader->userdata = self;
		self->state = ST_INIT;
		self->user_data = newRV_noinc((SV *)newHV());
		self->builtins = (HV *)SvREFCNT_inc((SV *)builtins);
		self->errors = newAV();
		cb = cpp_get_callbacks(self->reader);
		cb->register_builtins = cb_register_builtins;
		parse_options(self->reader, options);
		setup_callbacks(self->reader, callbacks);	/* Change the NULL! */
		/* This is slightly uglier than just returning self as a
		 * Text::CPP but does allow proper subclassing. */
		RETVAL = newSV(0);
		sv_setref_pv(RETVAL, class, (void *)self);
		instance = self;
	OUTPUT:
		RETVAL

SV *
data(self)
	Text::CPP	self
	CODE:
		/* Re-mortalised by XS */
		RETVAL = SvREFCNT_inc(self->user_data);
	OUTPUT:
		RETVAL

SV *
read(self, file)
	Text::CPP	self
	const char *file
	CODE:
		ASSERT_INIT(self);
		if (!cpp_read_main_file(self->reader, file, NULL)) {
			self->state = ST_FAIL;
			XSRETURN_UNDEF;
		}
		self->state = ST_READ;
		cpp_finish_options(self->reader);
		RETVAL = &PL_sv_yes;
	OUTPUT:
		RETVAL

void
token(self)
	Text::CPP	self
	PREINIT:
		const cpp_token	*token;
		SV				*sv;
		char			*text;
	PPCODE:
		ASSERT_READ(self);
		token = cpp_get_token(self->reader);
		if (token->type == CPP_EOF) {
			self->state = ST_FINAL;
			if (GIMME_V == G_SCALAR)
				XSRETURN_UNDEF;
			else
				XSRETURN_EMPTY;
		}
		/* This is ugly, but works for now. XXX I should split this
		 * out into my own function for using in 'type'. */
		switch(token->type) {
			case CPP_EOF:
				/* NOTREACHED */
				text = "<EOF>";
				break;
			case CPP_MACRO_ARG:
				text = "<MACRO_ARG>";
				break;
			case CPP_PADDING:
				text = "<PADDING>";
				break;
			default:
				/* I should use cpp_spell_token into an allocated SV. */
				text = cpp_token_as_text(self->reader, token);
				break;
		}
		sv = newSVpv(text, 0);
		XPUSHs(sv_2mortal(sv));
		if (GIMME_V == G_SCALAR)
			XSRETURN(1);
		XPUSHs(sv_2mortal(newSViv(token->type)));
		XPUSHs(sv_2mortal(newSViv(token->flags)));
		// XSRETURN(3);	/* Do I need this? */

const char *
type(self, type)
	Text::CPP	self
	int			type
	CODE:
		RETVAL = cpp_type2name(type);
	OUTPUT:
		RETVAL

void
tokens(self)
	Text::CPP	self
	PREINIT:
		const cpp_token	*token;
		int				 wa;
		AV				*av;
		SV				*sv;
	PPCODE:
		ASSERT_READ(self);
		wa = GIMME_V;
		if (wa == G_SCALAR)
			av = newAV();
		else
			av = NULL;	/* Avoid warning */
		for (;;) {
			token = cpp_get_token(self->reader);
			if (token->type == CPP_EOF)
				break;
			if (wa == G_VOID)
				continue;
			sv = newSVpv(cpp_token_as_text(self->reader, token), 0);
			if (wa == G_SCALAR)
				av_push(av, sv);
			else
				XPUSHs(sv_2mortal(sv));
		}
		if (wa == G_SCALAR)
			XPUSHs(sv_2mortal(newRV_noinc((SV *)av)));
		self->state = ST_FINAL;

void
preprocess_to_stream(self, file, stream)
	Text::CPP	self
	const char *file
	FILE*		stream
	CODE:
		/* We get this method for free. */
		ASSERT_INIT(self);
		cpp_preprocess_file(self->reader, file, stream);
		self->state = ST_FINAL;

void
errors(self)
	Text::CPP	self
	PREINIT:
		SV **svp;
		int	 count;
		int	 len;
		int	 i;
		// dSP;
	PPCODE:
		if (GIMME_V != G_ARRAY) {
			XPUSHs(sv_2mortal(newSViv(cpp_errors(self->reader))));
			// XPUSHi(cpp_errors(self->reader));
			XSRETURN(1);
		}
		count = 0;
		len = av_len(self->errors) + 1;
		for (i = 0; i < len; i++) {
			if ((svp = av_fetch(self->errors, i, FALSE))) {
				XPUSHs(sv_2mortal(SvREFCNT_inc(*svp)));
				count++;
			}
		}
		XSRETURN(count);	/* Do I need this? */

void
DESTROY(self)
	Text::CPP  self
	CODE:
		cpp_finish(self->reader, stderr);
		cpp_destroy(self->reader);
		SvREFCNT_dec(self->user_data);
		SvREFCNT_dec(self->builtins);
		SvREFCNT_dec(self->errors);
		Safefree(self);
		instance = NULL;
