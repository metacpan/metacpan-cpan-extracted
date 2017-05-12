#include <math.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

const STRLEN INIT_SIZE = 32;

enum tn_type {
	tn_type_array      = ']',
	tn_type_bool       = '!',
	tn_type_bytestring = ',',
	tn_type_float      = '^',
	tn_type_hash       = '}',
	tn_type_integer    = '#',
	tn_type_null       = '~',
};

struct tn_buffer {
	SV *sv;
	size_t size;
	char *start;
	char *cursor;
};

static SV *tn_decode(char *const encoded, STRLEN length, char **rest);
static SV *tn_decode_payload(char *const encoded, STRLEN length, enum tn_type type);
static SV *tn_decode_array(char *const encoded, STRLEN length);
static SV *tn_decode_hash(char *const encoded, STRLEN length);
static void tn_encode(SV *data, struct tn_buffer *buf);
static void tn_encode_array(SV *data, struct tn_buffer *buf);
static void tn_encode_hash(SV *data, struct tn_buffer *buf);
/* Initialize structure */
static int tn_buffer_init(struct tn_buffer *buf, size_t size);
/* Prepend character at the beginning of the buffer */
static int tn_buffer_putc(struct tn_buffer *buf, char);
/* Prepend string at the beginning of the buffer */
static int tn_buffer_puts(struct tn_buffer *buf, char *str, STRLEN len);
/* Prepend number at the beginning of the buffer */
static int tn_buffer_puti(struct tn_buffer *buf, size_t i);
/* Allocate enough memory to accomodate an additional n bytes */
static int tn_buffer_expand(struct tn_buffer *buf, size_t n);
/* Return the length of the buffer */
static STRLEN tn_buffer_length(struct tn_buffer *buf);
/* Finalize the buffer and return the resulting scalar. This will move
 * the string from the end of the buffer to the beginning, resulting in
 * a "normal" string.
 *
 * If len is not null it will be set to the length of the resulting
 * string.
 *
 * The buffer becomes invalid.
 */
static SV *tn_buffer_finalize(struct tn_buffer *buf, STRLEN *len);
/* Free the structure */
static void tn_buffer_free(struct tn_buffer *buf);

static void
tn_encode(SV *data, struct tn_buffer *buf)
{
	size_t init_length = tn_buffer_length(buf) + 1;

	/* Null */
	if(!SvOK(data)) {
		tn_buffer_puts(buf, "0:~", 3);
		return;
	}
	/* Boolean */
	else if(sv_isobject(data) && sv_derived_from(data, "boolean")) {
		tn_buffer_putc(buf, tn_type_bool);
		if(SvTRUE(data)) {
			tn_buffer_puts(buf, "4:true", 6);
		} else {
			tn_buffer_puts(buf, "5:false", 7);
		}
		return;
	}
	/* Integer */
	else if(SvIOK(data)) {
		/* The evaluatioin order of arguments isn't defined, so
		 * stringify before calling tn_buffer_puts(). */
		SvPV_nolen(data);
		tn_buffer_putc(buf, tn_type_integer);
		tn_buffer_puts(buf, SvPVX(data), SvCUR(data));
	}
	/* Floating point */
	else if(SvNOK(data)) {
		/* The evaluatioin order of arguments isn't defined, so
		 * stringify before calling tn_buffer_puts(). */
		SvPV_nolen(data);
		tn_buffer_putc(buf, tn_type_float);
		tn_buffer_puts(buf, SvPVX(data), SvCUR(data));
	}
	/* String */
	else if(SvPOK(data)) {
		tn_buffer_putc(buf, tn_type_bytestring);
		tn_buffer_puts(buf, SvPVX(data), SvCUR(data));
	}
	/* Reference (Hash/Array) */
	else if(SvROK(data)) {
		data = SvRV(data);
		switch(SvTYPE(data)) {
			case SVt_PVAV:
				tn_buffer_putc(buf, tn_type_array);
				tn_encode_array(data, buf);
				break;
			case SVt_PVHV:
				tn_buffer_putc(buf, tn_type_hash);
				tn_encode_hash(data, buf);
				break;
			default:
				croak("encountered %s (%s), but TNetstrings can only represent references to arrays or hashes",
					SvPV_nolen(data), sv_reftype(data, 0));
		}
	} else {
		croak("support for type (%s, %s) not implemented, please file a bug",
			sv_reftype(data, 0), SvPV_nolen(data));
	}
	tn_buffer_putc(buf, ':');
	tn_buffer_puti(buf, tn_buffer_length(buf) - init_length - 1);
}

static void
tn_encode_array(SV *data, struct tn_buffer *buf)
{
	AV *array = (AV *)data;
	I32 len = av_len(array) + 1;
	I32 i;

	for(i = len - 1; i >= 0; --i) {
		tn_encode(*av_fetch(array, i, 0), buf);
	}
}

static void
tn_encode_hash(SV *data, struct tn_buffer *buf)
{
	HV *hash = (HV *)data;
	HE *entry;
	SV *key;

	hv_iterinit(hash);
	while(entry = hv_iternext(hash)) {
		key = hv_iterkeysv(entry);
		SvPOK_on(key);
		tn_encode(hv_iterval(hash, entry), buf);
		tn_encode(key, buf);
	}
}

static char *
tn_lex(char *const encoded, STRLEN length, STRLEN *plength, enum tn_type *type, char **rest)
{
	char *payload;
	assert(plength);
	assert(type);

	/* Parse the size prefix */
	errno = 0;
	*plength = strtol(encoded, &payload, 10);
	if(errno == ERANGE) {
		croak("absurdly large size prefix");
	} else if(*plength == 0 && encoded == payload) {
		croak("expected size prefix but got \"%s\"", payload);
	} else if(*payload != ':') {
		croak("expected ':' but got \"%s\"", payload);
	}
	payload++;
	/* Check if string is truncated */
	if(payload + *plength >= encoded + length) {
		croak("expected at least %d bytes", *plength);
	}

	*type = payload[*plength];

	if(rest != NULL) {
		if(encoded + length > payload + *plength + 1) {
			*rest = payload + *plength + 1;
		} else {
			*rest = NULL;
		}
	}

	return payload;
}

static SV *
tn_decode(char *const encoded, STRLEN length, char **rest)
{
	char *payload;
	STRLEN payload_length;
	enum tn_type type;

	payload = tn_lex(encoded, length, &payload_length, &type, rest);
	return tn_decode_payload(payload, payload_length, type);
}

static SV *
tn_decode_payload(char *const encoded, STRLEN length, enum tn_type type)
{
	SV *decoded = NULL;

	/* Everything in between is the body */
	switch(type) {
		case tn_type_array:
			decoded = tn_decode_array(encoded, length);
			break;
		case tn_type_bool:
			if(strncmp(encoded, "true", 4) == 0) {
				decoded = &PL_sv_yes;
			} else if(strncmp(encoded, "false", 5) == 0) {
				decoded = &PL_sv_no;
			} else {
				croak("expected \"true\" or \"false\" but got \"%s\"", encoded);
			}
			break;
		case tn_type_float:
			decoded = newSVnv(atof(encoded));
			break;
		case tn_type_hash:
			decoded = tn_decode_hash(encoded, length);
			break;
		case tn_type_null:
			decoded = &PL_sv_undef;
			break;
		case tn_type_integer:
			decoded = newSViv(atoi(encoded));
			break;
		case tn_type_bytestring:
			decoded = newSVpvn(encoded, length);
			break;
		default:
			croak("invalid date type '%c'", type);
	}
	return decoded;
}

static char *
tn_decode_string(char *const encoded, STRLEN length, STRLEN *strlength, char **rest)
{
	char *payload;
	STRLEN payload_length;
	enum tn_type type;

	payload = tn_lex(encoded, length, strlength, &type, rest);
	if(type != tn_type_bytestring) {
		croak("expected string");
	}
	return payload;
}

static SV *
tn_decode_array(char *const encoded, STRLEN length)
{
	char *cursor = encoded;
	char *end = encoded + length;
	char *rest = NULL;
	SV *decoded = newRV_noinc((SV *)newAV());
	AV *array = (AV *)SvRV(decoded);
	SV *elem = NULL;

	while(cursor <= end) {
		elem = tn_decode(cursor, length, &rest);
		if(elem != NULL) {
			av_push(array, elem);
		} else {
			croak("expected array element but got \"%s\"", cursor);
		}
		if(rest != NULL) {
			length = length - (rest - cursor);
			cursor = rest;
		} else {
			break;
		}

		elem = NULL;
	}

	return decoded;
}

static SV *
tn_decode_hash(char *const encoded, STRLEN length)
{
	char *cursor = encoded;
	char *end = encoded + length;
	char *rest = NULL;
	char *key = NULL;
	STRLEN key_length = 0;
	SV *decoded = newRV_noinc((SV *)newHV());
	HV *hash = (HV *)SvRV(decoded);
	SV *value = NULL;

	while(cursor <= end) {
		key = tn_decode_string(cursor, length, &key_length, &rest);
		if(key == NULL) {
			croak("expected hash key but got \"%s\"", cursor);
		}

		if(rest != NULL) {
			length = length - (rest - cursor);
			cursor = rest;
		} else {
			croak("odd number of elements in hash");
		}

		value = tn_decode(cursor, length, &rest);
		if(value == NULL) {
			croak("expected hash value but got \"%s\"", cursor);
		}
		/* The value refcount must be decremented if storing fails. */
		if(!hv_store(hash, key, (I32)key_length, value, 0)) {
			SvREFCNT_dec(value);
		}
		if(rest != NULL) {
			length = length - (rest - cursor);
			cursor = rest;
		} else {
			break;
		}

		key = NULL;
		value = NULL;
		key_length = 0;
	}

	return decoded;
}

static int
tn_buffer_init(struct tn_buffer *buf, size_t size)
{
	assert(buf);
	buf->sv = newSV(size);
	if(!buf->sv) {
		return 0;
	}
	SvPOK_only(buf->sv);
	buf->start = SvPVX(buf->sv);
	buf->cursor = buf->start + size;
	*buf->cursor = '\0';
	buf->size = size;
	return 1;
}

static int
tn_buffer_expand(struct tn_buffer *buf, size_t n)
{
	struct tn_buffer old;
	STRLEN length;
	assert(buf);
	assert(buf->cursor <= buf->start && "buffer overflow");
	if(buf->cursor - buf->start < n) {
		Move(buf, &old, 1, old);
		length = tn_buffer_length(buf);

		buf->size = old.size * 2;
		while(buf->size < old.size + n) {
			buf->size *= 2;
		}

		tn_buffer_init(buf, buf->size);
		buf->cursor = buf->start + buf->size - length;
		Move(old.cursor, buf->cursor, length, *buf->cursor);
		sv_free(old.sv);
	}
}

static STRLEN
tn_buffer_length(struct tn_buffer *buf)
{
	return buf->size - (buf->cursor - buf->start);
}

static int
tn_buffer_putc(struct tn_buffer *buf, char ch)
{
	assert(buf);
	tn_buffer_expand(buf, 1);
	buf->cursor--;
	*buf->cursor = ch;
	return 1;
}

static int
tn_buffer_puti(struct tn_buffer *buf, size_t i)
{
	assert(buf);
	do {
		tn_buffer_putc(buf, (i % 10) + '0');
		i = i / 10;
	} while(i > 0);
	return 1;
}

static int
tn_buffer_puts(struct tn_buffer *buf, char *str, STRLEN len)
{
	assert(buf);
	if(len <= 0) {
		len = strlen(str);
	}
	tn_buffer_expand(buf, len);
	buf->cursor -= len;
	Move(str, buf->cursor, len, *str);
	return len;
}

static SV *
tn_buffer_finalize(struct tn_buffer *buf, STRLEN *len)
{
	size_t length = tn_buffer_length(buf);
	Move(buf->cursor, buf->start, length, *buf->start);
	buf->start[length] = '\0';
	if(len != NULL) {
		*len = length;
	}
	return newSVpvn(buf->start, length);
}

static void
tn_buffer_free(struct tn_buffer *buf)
{
	assert(buf);
	sv_free(buf->sv);
	buf->sv = NULL;
}

/* XSUBS */
MODULE = Text::TNetstrings::XS PACKAGE = Text::TNetstrings::XS PREFIX=TN_

SV *
TN_encode_tnetstrings(data)
	SV *data
	PREINIT:
		struct tn_buffer buffer;
		SV *encoded;
	CODE:
	{
		tn_buffer_init(&buffer, INIT_SIZE);
		tn_encode(data, &buffer);
		encoded = tn_buffer_finalize(&buffer, NULL);
		tn_buffer_free(&buffer);
		RETVAL = encoded;
	}
	OUTPUT:
		RETVAL

SV *
TN_decode_tnetstrings(encoded)
	SV *encoded
	PREINIT:
		char *rest = NULL;
	PPCODE:
	{
		XPUSHs(sv_2mortal(tn_decode(SvPV_nolen(encoded), SvCUR(encoded), &rest)));
		if(rest != NULL) {
			XPUSHs(sv_2mortal(newSVpvn(rest, SvCUR(encoded) - (rest - SvPV_nolen(encoded)))));
		}
	}
