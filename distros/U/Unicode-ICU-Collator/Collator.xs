#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "unicode/ucol.h"

#include "const-c.inc"

typedef UCollator *Unicode__ICU__Collator;

/* iterators require all of these, but most aren't called for our
 * use-cases */


static int32_t
byte_getIndex(UCharIterator *i, UCharIteratorOrigin origin) {
  switch(origin) {
  case UITER_START:
    return 0;
  case UITER_CURRENT:
    return i->index;
  case UITER_LIMIT:
    return i->length;
  case UITER_ZERO:
    return 0;
  case UITER_LENGTH:
    return i->length;
  }
}

static int32_t
byte_move(UCharIterator *i, int32_t delta, UCharIteratorOrigin origin) {
  int32_t index = 0;
  switch(origin) {
  case UITER_START:
    index = delta;
    break;
  case UITER_CURRENT:
    index = i->index + delta;
    break;
  case UITER_LIMIT:
    index = i->length + delta;
    break;
  case UITER_ZERO:
    index = delta;
    break;
  case UITER_LENGTH:
    index = i->length + delta;
    break;
  }

  if (index >= 0 && index <= i->length)
    i->index = index;
}

static UBool
byte_hasNext(UCharIterator *i) {
  return i->index < i->length;
}

static UBool
byte_hasPrevious(UCharIterator *i) {
  return i->index > 0;
}

UChar32
byte_current(UCharIterator *i) {
  if(i->index < i->length) {
    unsigned const char *p = i->context;
    return p[i->index];
  }
  return U_SENTINEL;
}

UChar32
byte_next(UCharIterator *i) {
  if(i->index < i->length) {
    unsigned const char *p = i->context;
    return p[i->index++];
  }
  return U_SENTINEL;
}

UChar32
byte_previous(UCharIterator *i) {
  if (i->index > 0) {
    unsigned const char *p = i->context;
    return p[--(i->index)];
  }
  return U_SENTINEL;
}

uint32_t
byte_getState(const UCharIterator *i) {
  return i->index;
}

void
byte_setState(UCharIterator *i, uint32_t state, UErrorCode *status) {
  if (state > i->length) {
    *status = U_INDEX_OUTOFBOUNDS_ERROR;
  }
  else {
    i->index = state;
  }
}

/* Character iterator for byte strings */
static void
uiter_setByteString(UCharIterator *c, char const *src, size_t len) {
  c->context = src;
  c->length = len;
  c->start = 0;
  c->index = 0;
  c->limit = len;
  c->getIndex = byte_getIndex;
  c->move = byte_move;
  c->hasNext = byte_hasNext;
  c->hasPrevious = byte_hasPrevious;
  c->current = byte_current;
  c->next = byte_next;
  c->previous = byte_previous;
  c->getState = byte_getState;
  c->setState = byte_setState;
}

static void *
malloc_temp(pTHX_ size_t size) {
  SV *sv = sv_2mortal(newSV(size));

  return SvPVX(sv);
}

static UChar *
make_uchar(pTHX_ SV *sv, STRLEN *lenp) {
  STRLEN len;
  /* SvPV early to process any GMAGIC */
  char const *pv = SvPV(sv, len);

  if (SvUTF8(sv)) {
    /* room for the characters and a bit for UTF-16 */
    STRLEN src_chars = sv_len_utf8(sv);
    int32_t cap = src_chars * 5 / 4 + 10;
    size_t size = sizeof(UChar) * cap;
    SV *result_sv = sv_2mortal(newSV(size));
    UChar *result = (UChar *)SvPVX(result_sv);
    int32_t result_len;
    UErrorCode status = U_ZERO_ERROR;

    u_strFromUTF8(result, cap, &result_len, pv, len, &status);

    if (status == U_BUFFER_OVERFLOW_ERROR
	|| result_len >= cap) {
      /* need more room, repeat */
      /* ideally this doesn't happen much */
      cap = result_len + 10;
      SvGROW(result_sv, sizeof(UChar) * cap);
      result = (UChar *)SvPVX(result_sv);
      status = U_ZERO_ERROR;
      u_strFromUTF8(result, cap, &result_len, pv, len, &status);
    }

    if (U_SUCCESS(status)) {
      *lenp = result_len;

      return result;
    }
    else {
      croak("Error converting utf8 to utf16: %d", status);
    }
  }
  else {
    UChar *result = malloc_temp(aTHX_ sizeof(UChar) * (len + 1));
    ssize_t i;
    for (i = 0; i < len; ++i)
      result[i] = (unsigned char)pv[i];
    result[len] = 0;
    *lenp = len;

    return result;
  }
}

/*

Convert a UChar * native ICU string into an SV.

Currently this always returns a string with UTF8 on, but that may change.

*/

static SV *
from_uchar(pTHX_ const UChar *src, int32_t len) {
  /* rough guess */
  STRLEN bytes = len * 2;
  SV *result = newSV(bytes);
  UErrorCode status = U_ZERO_ERROR;
  int32_t result_len = 0;

  u_strToUTF8(SvPVX(result), SvLEN(result), &result_len, src, len, &status);
  if (status == U_BUFFER_OVERFLOW_ERROR
      || result_len >= SvLEN(result)) {
    /* overflow of some sort, expand it */
    SvGROW(result, result_len + 10);
    status = U_ZERO_ERROR;
    u_strToUTF8(SvPVX(result), SvLEN(result), &result_len, src, len, &status);
  }

  SvCUR_set(result, result_len);
  SvPOK_only(result);
  *SvEND(result) = '\0';
  SvUTF8_on(result);

  return result;
}

static UCollationResult
ucol_cmp(pTHX_ UCollator *col, SV *sv1, SV *sv2) {
  UCollationResult result;
#if U_ICU_VERSION_MAJOR_NUM >= 50 && !defined(USE_ITERATORS)
  const char *s1, *s2;
  STRLEN len1, len2;
  UErrorCode status = U_ZERO_ERROR;

  s1 = SvPVutf8(sv1, len1);
  s2 = SvPVutf8(sv2, len2);

  result = ucol_strcollUTF8(col, s1, len1, s2, len2, &status);
#else
  UCharIterator c1, c2;
  const char *s1, *s2;
  STRLEN len1, len2;
  UErrorCode status = U_ZERO_ERROR;

  s1 = SvPV(sv1, len1);
  s2 = SvPV(sv2, len2);
  if (SvUTF8(sv1))
    uiter_setUTF8(&c1, s1, len1);
  else
    uiter_setByteString(&c1, s1, len1);
  if (SvUTF8(sv2))
    uiter_setUTF8(&c2, s2, len2);
  else
    uiter_setByteString(&c2, s2, len2);
  result = ucol_strcollIter(col, &c1, &c2, &status);
#endif

  if (!U_SUCCESS(status)) {
    croak("Error comparing: %d", (int)status);
  }

  return result;
}

MODULE = Unicode::ICU::Collator  PACKAGE = Unicode::ICU::Collator PREFIX = ucol_

PROTOTYPES: DISABLE

Unicode::ICU::Collator
ucol_new(class, loc)
	const char *loc
    PREINIT:
	UErrorCode status = U_ZERO_ERROR;
    CODE:
	RETVAL = ucol_open(loc, &status);
	if (!U_SUCCESS(status)) {
	    croak("Could not create collation for %s: %d", loc, (int)status);
	}
    OUTPUT:
        RETVAL

void
ucol_DESTROY(col)
	Unicode::ICU::Collator col
    CODE:
	ucol_close(col);

int
ucol_cmp(col, sv1, sv2)
	Unicode::ICU::Collator col
	SV *sv1
	SV *sv2
    CODE:
        RETVAL = ucol_cmp(aTHX_ col, sv1, sv2);
    OUTPUT:
	RETVAL

bool
ucol_eq(col, sv1, sv2)
	Unicode::ICU::Collator col
	SV *sv1
	SV *sv2
    CODE:
        RETVAL = ucol_cmp(aTHX_ col, sv1, sv2) == UCOL_EQUAL;
    OUTPUT:
	RETVAL

bool
ucol_ne(col, sv1, sv2)
	Unicode::ICU::Collator col
	SV *sv1
	SV *sv2
    CODE:
        RETVAL = ucol_cmp(aTHX_ col, sv1, sv2) != UCOL_EQUAL;
    OUTPUT:
	RETVAL

bool
ucol_gt(col, sv1, sv2)
	Unicode::ICU::Collator col
	SV *sv1
	SV *sv2
    CODE:
        RETVAL = ucol_cmp(aTHX_ col, sv1, sv2) == UCOL_GREATER;
    OUTPUT:
	RETVAL

bool
ucol_lt(col, sv1, sv2)
	Unicode::ICU::Collator col
	SV *sv1
	SV *sv2
    CODE:
        RETVAL = ucol_cmp(aTHX_ col, sv1, sv2) == UCOL_LESS;
    OUTPUT:
	RETVAL

bool
ucol_ge(col, sv1, sv2)
	Unicode::ICU::Collator col
	SV *sv1
	SV *sv2
    CODE:
        RETVAL = ucol_cmp(aTHX_ col, sv1, sv2) != UCOL_LESS;
    OUTPUT:
	RETVAL

bool
ucol_le(col, sv1, sv2)
	Unicode::ICU::Collator col
	SV *sv1
	SV *sv2
    CODE:
        RETVAL = ucol_cmp(aTHX_ col, sv1, sv2) != UCOL_GREATER;
    OUTPUT:
	RETVAL

SV *
ucol_getSortKey(col, sv)
	Unicode::ICU::Collator col
	SV *sv
    PREINIT:
	/* freed by FREETMPS */
        UChar *u16text;
	STRLEN len;
        size_t alloc;
	SV *result_sv;
	uint8_t *result;
	int32_t rlen;
    CODE:
	u16text = make_uchar(aTHX_ sv, &len);
	alloc = len * 3 + 2;
	result_sv = newSV(alloc);
	result = (uint8_t*)SvPVX(result_sv);
	/* sometimes it allocates a bit more */
	alloc = SvLEN(result_sv);
	rlen = ucol_getSortKey(col, u16text, len, result, alloc);
	if (rlen == 0)
  	    croak("Internal error in ucol_getSortKey");

	if (rlen > SvLEN(result_sv)) {
	  /* ideally we don't execute this often */
	  int32_t new_len = rlen + 10;
	  /* expand the buffer and try again */
	  SvGROW(result_sv, new_len);
	  result = (uint8_t*)SvPVX(result_sv);
	  new_len = SvLEN(result_sv);
	  rlen = ucol_getSortKey(col, u16text, len, result, new_len);
	}
	/* the result length includes the trailing NUL */
        SvCUR_set(result_sv, rlen-1);
	/* which means this probably isn't needed, but I'm paranoid */
	*SvEND(result_sv) = '\0';
	SvPOK_only(result_sv);
	RETVAL = result_sv;
    OUTPUT:
	RETVAL

void
ucol_getLocale(col, type = ULOC_ACTUAL_LOCALE)
	Unicode::ICU::Collator col
	int type
    PREINIT:
       const char *name;
       UErrorCode status = U_ZERO_ERROR;
    PPCODE:
       name = ucol_getLocaleByType(col, type, &status);
       if (!U_SUCCESS(status)) {
         croak("Error getting locale type: %d", (int)status);
       }
       if (name) {
         EXTEND(SP, 1);
	 PUSHs(sv_2mortal(newSVpv(name, 0)));
       }

void
ucol_setAttribute(col, attr, value)
	Unicode::ICU::Collator col
	int attr
	int value
    PREINIT:
	UErrorCode status = U_ZERO_ERROR;
    CODE:
	ucol_setAttribute(col, attr, value, &status);
	if (!U_SUCCESS(status))
	    croak("Error setting attribute: %d", (int)status);

int
ucol_getAttribute(col, attr)
	Unicode::ICU::Collator col
	int attr
    PREINIT:
	UErrorCode status = U_ZERO_ERROR;
    CODE:
	RETVAL = ucol_getAttribute(col, attr, &status);
	if (!U_SUCCESS(status))
	    croak("Error setting attribute: %d", (int)status);
    OUTPUT:
	RETVAL


SV *
ucol_getRules(col, rule_option = UCOL_FULL_RULES)
	Unicode::ICU::Collator col
        int rule_option;
    PREINIT:
        SV *work_sv;
	UChar *work;
        int32_t len;
    CODE:
        /* preflight to get the size */
	len = ucol_getRulesEx(col, rule_option, NULL, 0);
        if (len) {
	  work_sv = sv_2mortal(newSV((len + 1) * sizeof(UChar)));
	  work = (UChar *)SvPVX(work_sv);
	  ucol_getRulesEx(col, rule_option, work, len+1);
	  RETVAL = from_uchar(aTHX_ work, len);
	}
	else {
	  /* no rules */
	  RETVAL = newSVpvn("", 0);
	}
    OUTPUT:
        RETVAL

const char *
ucol_getVersion(col)
	Unicode::ICU::Collator col
    ALIAS:
        getVersion = 1
        getUCAVersion = 2
    PREINIT:
        char ver_str[U_MAX_VERSION_STRING_LENGTH];
        UVersionInfo ver;
    CODE:
	if (ix == 1)
	  ucol_getVersion(col, ver);
 	else
	  ucol_getUCAVersion(col, ver);
	u_versionToString(ver, ver_str);
        RETVAL = ver_str;
    OUTPUT:
	RETVAL

SV *
ucol_getDisplayName(class, locale, disp_loc)
	const char *locale;
	const char *disp_loc;
    PREINIT:
        SV *work_sv;
	UChar *work;
        int32_t len;
	UErrorCode status = U_ZERO_ERROR;
	char temp[1];
    CODE:
        /* preflight to get the size */
	len = ucol_getDisplayName(locale, disp_loc, NULL, 0, &status);
	if(status != U_BUFFER_OVERFLOW_ERROR){
	  croak("Unexpected getDisplayName result: %d", (int)status);
	}
	work_sv = sv_2mortal(newSV((len + 1) * sizeof(UChar)));
	work = (UChar *)SvPVX(work_sv);
	status = U_ZERO_ERROR;
	ucol_getDisplayName(locale, disp_loc, work, len+1, &status);
	RETVAL = from_uchar(aTHX_ work, len);
    OUTPUT:
        RETVAL

void
ucol_available(...)
    PREINIT:
	int32_t count;
        int32_t i;
    PPCODE:
        count = ucol_countAvailable();
       	EXTEND(SP, count);
        for (i = 0; i < count; ++i) {
          const char *name = ucol_getAvailable(i);
	  PUSHs(sv_2mortal(newSVpv(name, 0)));
        }

INCLUDE: const-xs.inc
