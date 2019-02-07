/* This code is derived from that of File::Map.
 * It exposes a C buffer to perl-space in a safe-ish manner by applying scalar magic
 * that intercepts reads and writes, to ensure that the buffer doesn't change size.
 */

#define BUFFER_SCALAR_READONLY 1
#define BUFFER_SCALAR_UTF8 2
typedef intptr_t buffer_scalar_callback_data_t[8];
typedef void (*buffer_scalar_free_fn)(SV *var, void *address, size_t length, buffer_scalar_callback_data_t callback_data);

#ifndef SvPV_free
#	define SvPV_free(arg) sv_setpvn_mg(arg, NULL, 0);
#endif

#ifndef SV_CHECK_THINKFIRST_COW_DROP
#define SV_CHECK_THINKFIRST_COW_DROP(sv) SV_CHECK_THINKFIRST(sv)
#endif

struct buffer_scalar_info {
	char* address;
	size_t length;
	int flags;
	buffer_scalar_callback_data_t callback_data;
	buffer_scalar_free_fn destructor;
};

static int buffer_scalar_mg_write(pTHX_ SV *sv, MAGIC* mg);
static int buffer_scalar_mg_clear(pTHX_ SV *sv, MAGIC *mg);
static int buffer_scalar_mg_free(pTHX_ SV *sv, MAGIC *mg);

#ifdef MGf_LOCAL
static int buffer_scalar_mg_local(pTHX_ SV* var, MAGIC* mg) {
	croak("Can't localize view of foreign buffer");
	return 0;
}
#endif
#ifdef USE_ITHREADS
static int buffer_scalar_mg_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* param) {
	croak("Can't share foreign buffer between iThreads");
	return 0;
}
#else
#define buffer_scalar_mg_dup 0
#endif

/* Defined in perl/mg.h */
static const MGVTBL buffer_scalar_vtable = {
	0, /* get */
	buffer_scalar_mg_write,
	0, /* length */
	buffer_scalar_mg_clear,
	buffer_scalar_mg_free,
	0, /* copy */
	buffer_scalar_mg_dup
#ifdef MGf_LOCAL
	, buffer_scalar_mg_local
#endif
};

static void reset_var(SV* var, struct buffer_scalar_info* info) {
	SvPVX(var) = info->address;
	SvLEN(var) = 0;
	SvCUR(var) = info->length;
	SvPOK_only_UTF8(var);
}

static void buffer_scalar_fixup(pTHX_ SV* var, struct buffer_scalar_info* info, const char* string, STRLEN len) {
	if (ckWARN(WARN_SUBSTR))
		Perl_warn(aTHX_ "Writing directly to a foreign buffer is not recommended");
	if (SvCUR(var) > info->length)
		Perl_warn(aTHX_ "Truncating new value to size of foreign buffer");
 
	if (string && len)
		Copy(string, info->address, (len < info->length? len : info->length), char);
	SV_CHECK_THINKFIRST_COW_DROP(var);
	if (SvROK(var))
		sv_unref_flags(var, SV_IMMEDIATE_UNREF);
	if (SvPOK(var))
		SvPV_free(var);
	reset_var(var, info);
}

static int buffer_scalar_mg_write(pTHX_ SV* var, MAGIC* magic) {
	struct buffer_scalar_info* info = (struct buffer_scalar_info*) magic->mg_ptr;
	if (!SvOK(var))
		buffer_scalar_fixup(aTHX_ var, info, NULL, 0);
	else if (!SvPOK(var)) {
		STRLEN len;
		const char* string = SvPV(var, len);
		buffer_scalar_fixup(aTHX_ var, info, string, len);
	}
	else if (SvPVX(var) != info->address)
		buffer_scalar_fixup(aTHX_ var, info, SvPVX(var), SvCUR(var));
	else {
		if (ckWARN(WARN_SUBSTR) && SvCUR(var) != info->length) {
			Perl_warn(aTHX_ "Writing directly to a foreign buffer");
			SvCUR(var) = info->length;
		}
		SvPOK_only_UTF8(var);
	}
	return 0;
}
 
static int buffer_scalar_mg_clear(pTHX_ SV* var, MAGIC* magic) {
	Perl_die(aTHX_ "Can't clear a foreign buffer");
	return 0;
}
 
static int buffer_scalar_mg_free(pTHX_ SV* var, MAGIC* magic) {
	struct buffer_scalar_info* info = (struct buffer_scalar_info*) magic->mg_ptr;
	if (info->destructor)
		info->destructor(var, info->address, info->length, info->callback_data);
	PerlMemShared_free(info);
	SvREADONLY_off(var);
	SvPVX(var) = NULL;
	SvCUR(var) = 0;
	return 0;
}

static void check_new_variable(pTHX_ SV* var) {
	if (SvTYPE(var) > SVt_PVMG && SvTYPE(var) != SVt_PVLV)
		Perl_croak(aTHX_ "Can't wrap a non-scalar!\n");
	SV_CHECK_THINKFIRST_COW_DROP(var);
	if (SvREADONLY(var))
		Perl_croak(aTHX_ "%s", PL_no_modify);
	if (SvMAGICAL(var) && mg_find(var, PERL_MAGIC_uvar))
		sv_unmagic(var, PERL_MAGIC_uvar);
	if (SvROK(var))
		sv_unref_flags(var, SV_IMMEDIATE_UNREF);
	if (SvNIOK(var))
		SvNIOK_off(var);
	if (SvPOK(var)) 
		SvPV_free(var);
	SvUPGRADE(var, SVt_PVMG);
}

static struct buffer_scalar_info* add_sv_magic(pTHX_ SV *var) {
	struct buffer_scalar_info* info;
	MAGIC* magic;
	check_new_variable(var);
	info= PerlMemShared_malloc(sizeof *info);
	magic= sv_magicext(var, NULL, PERL_MAGIC_uvar, &buffer_scalar_vtable, (const char*) info, 0);
#ifdef MGf_LOCAL
	magic->mg_flags |= MGf_LOCAL;
#endif
#ifdef USE_ITHREADS
	magic->mg_flags |= MGf_DUP;
#endif
	SvTAINTED_on(var);
	return info;
}

static struct buffer_scalar_info* get_sv_magic(pTHX_ SV* var) {
	MAGIC* magic;
	if (!SvMAGICAL(var)) return NULL;
	for (magic= SvMAGIC(var); magic; magic = magic->mg_moremagic)
		if (magic->mg_type == PERL_MAGIC_uvar && magic->mg_virtual == &buffer_scalar_vtable)
			return (struct buffer_scalar_info*) magic->mg_ptr;
	return NULL;
}

/* Public API
 *
 * Functions are stil static (not extern) because right now this code isn't actually a library
 * and needs to be #include'd directly into other XS modules, else multiple XS modules using
 * it might have symbol clashes.
 */

static SV* buffer_scalar_wrap(
	SV *target, void *address, size_t length, int flags,
	buffer_scalar_callback_data_t cbdata,
	buffer_scalar_free_fn destructor
) {
	struct buffer_scalar_info *info;
	if (SvMAGICAL(target) && mg_find(target, PERL_MAGIC_uvar))
		croak("Scalar already has scalar magic applied");
	info= add_sv_magic(target);
	info->address= address;
	info->length= length;
	info->flags= flags;
	if (cbdata)
		memcpy(info->callback_data, cbdata, sizeof(buffer_scalar_callback_data_t));
	info->destructor= destructor;
	reset_var(target, info);
	return target;
}

static SV* buffer_scalar_unwrap(SV *target) {
	if (!get_sv_magic(target))
		croak("Scalar is not bound to a buffer");
	sv_unmagic(target, PERL_MAGIC_uvar);
	return target;
}

static int buffer_scalar_iswrapped(SV *target) {
	return get_sv_magic(target) != NULL;
}

