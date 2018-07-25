#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/*------------------------------------------------------------------------------
 *
 * Macros and definitions
 *
 -----------------------------------------------------------------------------*/

// permitted characters
#define URI_CHARS_AUTH          "!$&'()*+,;:=@"
#define URI_CHARS_PATH          "!$&'()*+,;:=@/"
#define URI_CHARS_PATH_SEGMENT  "!$&'()*+,;:=@"
#define URI_CHARS_HOST          "!$&'()[]*+,.;=@/"
#define URI_CHARS_QUERY         ":@?/&=;"
#define URI_CHARS_FRAG          ":@?/"
#define URI_CHARS_USER          "!$&'()*+,;="

// return uri_t* from blessed pointer ref
#define URI(obj) ((uri_t*) SvIV(SvRV( (obj) )))

// expands to member reference
#define URI_MEMBER(obj, member) (URI(obj)->member)

// size constants
#define URI_SIZE_scheme 32UL
#define URI_SIZE_usr    32UL
#define URI_SIZE_pwd    32UL
#define URI_SIZE_host   64UL
#define URI_SIZE_port    8UL
#define URI_SIZE_path   64UL
#define URI_SIZE_query  64UL
#define URI_SIZE_frag   32UL

// enough to fit all pieces + 3 chars for separators (2 colons + @)
#define URI_SIZE_auth (3 + URI_SIZE_usr + URI_SIZE_pwd + URI_SIZE_host + URI_SIZE_port)

// returns the size of the member in bytes
#define URI_SIZE(member) (URI_SIZE_##member)

// defines a clearer method
#define URI_SIMPLE_CLEARER(member) \
static void clear_##member(pTHX_ SV *uri) { \
  str_clear(aTHX_ URI_MEMBER(uri, member)); \
}

// Defines a setter method that accepts an unencoded value, encodes it,
// ignoring characters in string 'allowed', and copies the encoded value into
// slot 'member'.
#define URI_SIMPLE_SETTER(member, allowed) \
static void set_##member(pTHX_ SV *uri, SV *sv_value) { \
  SvGETMAGIC(sv_value); \
  if (SvOK(sv_value)) { \
    size_t len_value, len_enc; \
    const char *value = SvPV_const(sv_value, len_value); \
    char enc[len_value * 3 + 1]; \
    len_enc = uri_encode(value, len_value, enc, allowed, URI_MEMBER(uri, is_iri)); \
    str_set(aTHX_ URI_MEMBER(uri, member), enc, len_enc); \
  } \
  else { \
    str_clear(aTHX_ URI_MEMBER(uri, member)); \
  } \
}

// Defines a getter method that returns the raw, encoded value of the member slot.
#define URI_RAW_GETTER(member) \
static SV* get_raw_##member(pTHX_ SV *uri) { \
  uri_str_t *str = URI_MEMBER(uri, member); \
  return newSVpvn(str->length == 0 ? "" : str->string, str->length); \
}

// Defines a getter method that returns the decoded value of the member slot.
#define URI_SIMPLE_GETTER(member) \
static SV* get_##member(pTHX_ SV *uri) { \
  uri_str_t *str = URI_MEMBER(uri, member); \
  if (str->length == 0) return newSVpvn("", 0); \
  char decoded[ str->length + 1 ]; \
  size_t len = uri_decode(str->string, str->length, decoded, ""); \
  SV *out = newSVpvn(decoded, len); \
  sv_utf8_decode(out); \
  return out; \
}

// Defines a getter method for a structured field that returns the value of the
// member slot with non-ASCII character decoded, while leaving reserved
// characters encoded.
#define URI_COMPOUND_GETTER(member) \
static SV* get_##member(pTHX_ SV *uri) { \
  uri_str_t *str = URI_MEMBER(uri, member); \
  if (str->length == 0) return newSVpvn("", 0); \
  char decoded[ str->length + 1 ]; \
  size_t len = uri_decode_utf8(str->string, str->length, decoded); \
  SV *out = newSVpvn(decoded, len); \
  sv_utf8_decode(out); \
  return out; \
}

/*
 * Allocate memory with Newx if it's
 * available - if it's an older perl
 * that doesn't have Newx then we
 * resort to using New.
 */
#ifndef Newx
#define Newx(v,n,t) New(0,v,n,t)
#endif

// av_top_index not available on Perls < 5.18
#ifndef av_top_index
#define av_top_index(av) av_len(av)
#endif

/*------------------------------------------------------------------------------
 *
 * Internal API
 *
 -----------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
 * Utilities
 -----------------------------------------------------------------------------*/

static
size_t strnspn(const char *s, size_t s_len, const char *c)
{
  size_t res = strspn(s, c);
  return s_len < res ? s_len : res;
}

static
size_t strncspn(const char *s, size_t s_len, const char *c)
{
  size_t res = strcspn(s, c);
  return s_len < res ? s_len : res;
}

static inline
bool char_in_str(const char c, const char *set) {
  size_t i;

  for (i = 0; set[i] != '\0'; ++i) {
    if (set[i] == c) {
      return 1;
    }
  }

  return 0;
}

// returns true for an ASCII whitespace char
static inline
bool my_isspace(const char c) {
  switch (c) {
    case ' ':  case '\t':
    case '\r': case '\n':
    case '\f': case '\v':
      return 1;
    default:
      return 0;
  }
}

// min of two numbers
static inline
size_t minnum(size_t x, size_t y) {
  return x <= y ? x : y;
}

// max of two numbers
static inline
size_t maxnum(size_t x, size_t y) {
  return x >= y ? x : y;
}


/*------------------------------------------------------------------------------
 * Resizable strings
 -----------------------------------------------------------------------------*/
typedef struct {
  size_t chunk;     // bytes to allocate at a time
  size_t allocated; // number of currently allocated bytes
  size_t length;    // length of the string within the allocated buffer
  char *string;     // pointer to the allocated string
} uri_str_t;

#define str_len(str) ((str)->length)
#define str_get(str) (str_len(str) == 0 ? "" : (const char*)str->string)

static
void str_set(pTHX_ uri_str_t *str, const char *value, size_t len) {
  size_t allocate = str->chunk * (((len + 1) / str->chunk) + 1);

  if (str->string == NULL) {
    Newx(str->string, allocate, char);
    str->allocated = allocate;
  }
  else if (len > str->allocated) {
    Renew(str->string, allocate, char);
    str->allocated = allocate;
  }

  if (value == NULL) {
    Zero(str->string, len + 1, char);
    str->length = 0;
  }
  else {
    Copy(value, str->string, len, char);
    str->string[len] = '\0';
    str->length = len;
  }
}

static
void str_append(pTHX_ uri_str_t *str, const char *value, size_t len) {
  if (str->string == NULL) {
    str_set(aTHX_ str, value, len);
    return;
  }

  if (value != NULL) {
    size_t allocate = str->chunk * (((str->length + len + 1) / str->chunk) + 1);

    if (allocate != str->allocated) {
      Renew(str->string, allocate, char);
      str->allocated = allocate;
    }

    Copy(value, &str->string[str->length], len, char);
    str->string[str->length + len] = '\0';
    str->length += len;
  }
}

static
void str_clear(pTHX_ uri_str_t *str) {
  str_set(aTHX_ str, NULL, 0);
}

static
uri_str_t* str_new(pTHX_ size_t alloc_size) {
  uri_str_t *str;
  Newx(str, 1, uri_str_t);
  str->chunk = alloc_size;
  str->allocated = 0;
  str->length = 0;
  str->string = NULL;
  return str;
}

static
void str_free(pTHX_ uri_str_t *str) {
  if (str->string != NULL) {
    Safefree(str->string);
  }

  Safefree(str);
}


/*-------------------------------------------------------------------------------
 * Percent encoding
 -----------------------------------------------------------------------------*/

// Taken with respect from URI::Escape::XS. Adapted to accept a configurable
// string of permissible characters.
#define _______ "\0\0\0\0"
static const char uri_encode_tbl[ sizeof(U32) * 0x100 ] = {
/*  0       1       2       3       4       5       6       7       8       9       a       b       c       d       e       f                        */
    "%00\0" "%01\0" "%02\0" "%03\0" "%04\0" "%05\0" "%06\0" "%07\0" "%08\0" "%09\0" "%0A\0" "%0B\0" "%0C\0" "%0D\0" "%0E\0" "%0F\0"  /* 0:   0 ~  15 */
    "%10\0" "%11\0" "%12\0" "%13\0" "%14\0" "%15\0" "%16\0" "%17\0" "%18\0" "%19\0" "%1A\0" "%1B\0" "%1C\0" "%1D\0" "%1E\0" "%1F\0"  /* 1:  16 ~  31 */
    "%20\0" "%21\0" "%22\0" "%23\0" "%24\0" "%25\0" "%26\0" "%27\0" "%28\0" "%29\0" "%2A\0" "%2B\0" "%2C\0" _______ _______ "%2F\0"  /* 2:  32 ~  47 */
    _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ "%3A\0" "%3B\0" "%3C\0" "%3D\0" "%3E\0" "%3F\0"  /* 3:  48 ~  63 */
    "%40\0" _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______  /* 4:  64 ~  79 */
    _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ "%5B\0" "%5C\0" "%5D\0" "%5E\0" _______  /* 5:  80 ~  95 */
    "%60\0" _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______  /* 6:  96 ~ 111 */
    _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ "%7B\0" "%7C\0" "%7D\0" _______ "%7F\0"  /* 7: 112 ~ 127 */
    "%80\0" "%81\0" "%82\0" "%83\0" "%84\0" "%85\0" "%86\0" "%87\0" "%88\0" "%89\0" "%8A\0" "%8B\0" "%8C\0" "%8D\0" "%8E\0" "%8F\0"  /* 8: 128 ~ 143 */
    "%90\0" "%91\0" "%92\0" "%93\0" "%94\0" "%95\0" "%96\0" "%97\0" "%98\0" "%99\0" "%9A\0" "%9B\0" "%9C\0" "%9D\0" "%9E\0" "%9F\0"  /* 9: 144 ~ 159 */
    "%A0\0" "%A1\0" "%A2\0" "%A3\0" "%A4\0" "%A5\0" "%A6\0" "%A7\0" "%A8\0" "%A9\0" "%AA\0" "%AB\0" "%AC\0" "%AD\0" "%AE\0" "%AF\0"  /* A: 160 ~ 175 */
    "%B0\0" "%B1\0" "%B2\0" "%B3\0" "%B4\0" "%B5\0" "%B6\0" "%B7\0" "%B8\0" "%B9\0" "%BA\0" "%BB\0" "%BC\0" "%BD\0" "%BE\0" "%BF\0"  /* B: 176 ~ 191 */
    "%C0\0" "%C1\0" "%C2\0" "%C3\0" "%C4\0" "%C5\0" "%C6\0" "%C7\0" "%C8\0" "%C9\0" "%CA\0" "%CB\0" "%CC\0" "%CD\0" "%CE\0" "%CF\0"  /* C: 192 ~ 207 */
    "%D0\0" "%D1\0" "%D2\0" "%D3\0" "%D4\0" "%D5\0" "%D6\0" "%D7\0" "%D8\0" "%D9\0" "%DA\0" "%DB\0" "%DC\0" "%DD\0" "%DE\0" "%DF\0"  /* D: 208 ~ 223 */
    "%E0\0" "%E1\0" "%E2\0" "%E3\0" "%E4\0" "%E5\0" "%E6\0" "%E7\0" "%E8\0" "%E9\0" "%EA\0" "%EB\0" "%EC\0" "%ED\0" "%EE\0" "%EF\0"  /* E: 224 ~ 239 */
    "%F0\0" "%F1\0" "%F2\0" "%F3\0" "%F4\0" "%F5\0" "%F6\0" "%F7\0" "%F8\0" "%F9\0" "%FA\0" "%FB\0" "%FC\0" "%FD\0" "%FE\0" "%FF"    /* F: 240 ~ 255 */
};
#undef _______

static
size_t uri_encode(const char* in, size_t len, char* out, const char* allow, int allow_utf8) {
  size_t i = 0;
  size_t j = 0;
  size_t k, skip;
  U8 octet;
  U32 code;

  while (i < len) {
    octet = in[i];

    if (allow_utf8 && octet & 0xc0) {
      skip = UTF8SKIP(&in[i]);

      if (skip > 0) {
        for (k = 0; k < skip; ++k) {
          out[j++] = in[i++];
        }

        continue;
      }
    }

    if (char_in_str(octet, allow)) {
      out[j++] = octet;
      ++i;
    }
    else {
      code = ((U32*) uri_encode_tbl)[(unsigned char) octet];

      if (code) {
        *((U32*) &out[j]) = code;
        j += 3;
      }
      else {
        out[j++] = octet;
      }

      ++i;
    }
  }

  out[j] = '\0';

  return j;
}

/*-------------------------------------------------------------------------------
 * Percent decoding
 -----------------------------------------------------------------------------*/

#define __ 0xFF
static const unsigned char hex[0x100] = {
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 00-0F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 10-1F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 20-2F */
   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,__,__,__,__,__,__, /* 30-3F */
  __,10,11,12,13,14,15,__,__,__,__,__,__,__,__,__, /* 40-4F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 50-5F */
  __,10,11,12,13,14,15,__,__,__,__,__,__,__,__,__, /* 60-6F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 70-7F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 80-8F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 90-9F */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* A0-AF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* B0-BF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* C0-CF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* D0-DF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* E0-EF */
  __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* F0-FF */
};
#undef __

static inline
char unhex(const char *in) {
  unsigned char v1 = hex[ (unsigned char) in[0] ];
  unsigned char v2 = hex[ (unsigned char) in[1] ];

  /* skip invalid hex sequences */
  if ((v1 | v2) != 0xFF) {
    return (v1 << 4) | v2;
  }

  return '\0';
}

static
size_t uri_decode(const char *in, size_t len, char *out, const char *ignore) {
  size_t i = 0, j = 0;
  char decoded;

  while (i < len) {
    decoded = '\0';

    switch (in[i]) {
      case '+':
        decoded = ' ';
        if (!char_in_str(decoded, ignore)) {
          ++i;
          break;
        }
      case '%':
        if (i + 2 < len) {
          decoded = unhex( &in[i + 1] );
          if (decoded != '\0' && !char_in_str(decoded, ignore)) {
            i += 3;
            break;
          }
        }
      default:
        decoded = in[i++];
    }

    if (decoded != '\0') {
      out[j++] = decoded;
    }
  }

  out[j] = '\0';

  return j;
}

static
size_t uri_decode_utf8(const char *in, size_t len, char *out) {
  size_t i = 0, j = 0;
  char decoded;

  while (i < len) {
    decoded = '\0';

    switch (in[i]) {
      case '%':
        if (i + 2 < len) {
          decoded = unhex( &in[i + 1] );
          if (decoded != '\0' && (U32)decoded > 127) {
            i += 3;
            break;
          }
        }
      default:
        decoded = in[i++];
    }

    if (decoded != '\0') {
      out[j++] = decoded;
    }
  }

  out[j] = '\0';

  return j;
}

// EOT (end of theft)

static
SV* encode(pTHX_ SV *in, SV *sv_allowed) {
  size_t ilen, olen, alen;
  const char *allowed;
  SV* out;

  SvGETMAGIC(in);

  if (!SvOK(in)) {
    return newSVpvn("", 0);
  }

  const char *src = SvPV_nomg_const(in, ilen);
  char dest[(ilen * 3) + 1];

  if (sv_allowed == NULL) {
    allowed = "";
  } else {
    allowed = SvPV_nomg_const(sv_allowed, alen);
  }

  olen = uri_encode(src, ilen, dest, allowed, 0);
  out  = newSVpvn(dest, olen);
  sv_utf8_downgrade(out, FALSE);

  return out;
}

static
SV* decode(pTHX_ SV *in) {
  size_t ilen, olen;
  const char *src;
  SV *out;

  SvGETMAGIC(in);

  if (!SvOK(in)) {
    return newSVpvn("", 0);
  }

  if (DO_UTF8(in)) {
    in = sv_mortalcopy(in);
    SvUTF8_on(in);

    if (!sv_utf8_downgrade(in, TRUE)) {
      croak("decode: wide character in input octet string");
    }

    src = SvPV_nomg_const(in, ilen);
  }
  else {
    src = SvPV_nomg_const(in, ilen);
  }

  char dest[ilen + 1];
  olen = uri_decode(src, ilen, dest, "");
  out = newSVpvn(dest, olen);
  sv_utf8_decode(out);

  return out;
}


/*------------------------------------------------------------------------------
 * Query string parsing
 -----------------------------------------------------------------------------*/

typedef enum {
  KEY   = 1,
  PARAM = 2,
  DONE  = 3,
} uri_query_token_type_t;

typedef struct {
  uri_query_token_type_t type;
  const char *key;   size_t key_length;
  const char *value; size_t value_length; // only present when type=PARAM
} uri_query_token_t;

typedef struct {
  size_t length;
  size_t cursor;
  const char *source;
} uri_query_scanner_t;

void query_scanner_init(
    uri_query_scanner_t *scanner,
    const char *source,
    size_t length
  )
{
  scanner->source = source;
  scanner->length = length;
  scanner->cursor = 0;
}

static
int query_scanner_done(uri_query_scanner_t *scanner) {
  return scanner->cursor >= scanner->length;
}

/*
 * Fills the token struct with the next token information. Does not decode
 * any values.
 */
static
void query_scanner_next(uri_query_scanner_t *scanner, uri_query_token_t *token) {
  size_t brk;
  const char sep[4] = {'&', ';', '=', '\0'};

SCAN_KEY:
  if (scanner->cursor >= scanner->length) {
    token->key   = NULL; token->key_length   = 0;
    token->value = NULL; token->value_length = 0;
    token->type  = DONE;
    return;
  }

  // Scan to end of token
  brk = strncspn(
    &scanner->source[ scanner->cursor ],
    scanner->length - scanner->cursor,
    sep
  );

  // Set key members in token struct
  token->key = &scanner->source[ scanner->cursor ];
  token->key_length = brk;

  // Move cursor to end of token
  scanner->cursor += brk;

  // If there is an associate value, add it to the token
  if (scanner->source[ scanner->cursor ] == '=') {
    // Advance past '='
    ++scanner->cursor;

    // Find the end of the value
    brk = strncspn(&scanner->source[ scanner->cursor ], scanner->length - scanner->cursor, sep);

    // Set the value and token type
    token->value = &scanner->source[ scanner->cursor ];
    token->value_length = brk;
    token->type = PARAM;

    // Move cursor to the end of the value, eating the separator terminating it
    scanner->cursor += brk + 1;
  }
  // No value assigned to this key
  else {
    token->type = KEY;
    ++scanner->cursor; // advance past terminating separator
  }

  // No key was found; try again
  if (token->key_length == 0) {
    goto SCAN_KEY;
  }

  return;
}


/*------------------------------------------------------------------------------
 * URI parsing
 -----------------------------------------------------------------------------*/

typedef struct {
  U8         is_iri;
  uri_str_t *scheme;
  uri_str_t *query;
  uri_str_t *path;
  uri_str_t *host;
  uri_str_t *port;
  uri_str_t *frag;
  uri_str_t *usr;
  uri_str_t *pwd;
} uri_t;

/*
 * Scans the authorization portion of the URI string
 */
static
void uri_scan_auth(pTHX_ uri_t* uri, const char* auth, const size_t len) {
  size_t idx  = 0;
  size_t brk1 = 0;
  size_t brk2 = 0;
  size_t i;
  unsigned char flag;

  if (len > 0) {
    // Credentials
    brk1 = strncspn(&auth[idx], len - idx, "@");

    if (brk1 > 0 && brk1 != (len - idx)) {
      brk2 = strncspn(&auth[idx], len - idx, ":");

      if (brk2 > 0 && brk2 < brk1) {
        // user
        str_set(aTHX_ uri->usr, &auth[idx], brk2);
        idx += brk2 + 1;

        // password
        str_set(aTHX_ uri->pwd, &auth[idx], brk1 - brk2 - 1);
        idx += brk1 - brk2;
      }
      else {
        // user only
        str_set(aTHX_ uri->usr, &auth[idx], brk1);
        idx += brk1 + 1;
      }
    }

    // Location

    // Maybe an IPV6 address
    flag = 0;
    if (auth[idx] == '[') {
      brk1 = strncspn(&auth[idx], len - idx, "]");

      if (auth[idx + brk1] == ']') {
        // Copy, including the square brackets
        str_set(aTHX_ uri->host, &auth[idx], brk1 + 1);
        idx += brk1 + 1;
        flag = 1;
      }
    }

    if (flag == 0) {
      brk1 = strncspn(&auth[idx], len - idx, ":");

      if (brk1 > 0) {
        str_set(aTHX_ uri->host, &auth[idx], brk1);
        idx += brk1;
      }
    }

    if (auth[idx] == ':') {
      ++idx;
      str_set(aTHX_ uri->port, &auth[idx], len - idx);
    }
  }
}

/*
 * Scans a URI string and populates the uri_t struct.
 *
 * Correct:
 *   scheme:[//[usr[:pwd]@]host[:port]]path[?query][#fragment]
 *
 * Incorrect but supported:
 *   /path[?query][#fragment]
 *
 */
static
void uri_scan(pTHX_ uri_t *uri, const char *src, size_t len) {
  size_t idx = 0;
  size_t brk;
  size_t i;

  while (my_isspace(src[idx]) == 1)     ++idx; // Trim leading whitespace
  while (my_isspace(src[len - 1]) == 1) --len; // Trim trailing whitespace

  // Scheme
  brk = strncspn(&src[idx], len - idx, ":/@?#");

  if (brk > 0 && src[idx + brk] == ':') {
    str_set(aTHX_ uri->scheme, &src[idx], brk);
    idx += brk + 1;

    // Authority section following scheme must be separated by //
    if (idx + 1 < len && src[idx] == '/' && src[idx + 1] == '/') {
      idx += 2;
    }
  }

  // Authority
  brk = strncspn(&src[idx], len - idx, "/?#");
  uri_scan_auth(aTHX_ uri, &src[idx], brk);

  if (brk > 0) {
    idx += brk;
  }

  // path
  brk = strncspn(&src[idx], len - idx, "?#");
  if (brk > 0) {
    str_set(aTHX_ uri->path, &src[idx], brk);
    idx += brk;
  }

  // query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = strncspn(&src[idx], len - idx, "#");
    if (brk > 0) {
      str_set(aTHX_ uri->query, &src[idx], brk);
      idx += brk;
    }
  }

  // fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      str_set(aTHX_ uri->frag, &src[idx], brk);
    }
  }
}

/*------------------------------------------------------------------------------
 *
 * Perl API
 *
 -----------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
 * Clearers
 -----------------------------------------------------------------------------*/

URI_SIMPLE_CLEARER(scheme);
URI_SIMPLE_CLEARER(path);
URI_SIMPLE_CLEARER(query);
URI_SIMPLE_CLEARER(frag);
URI_SIMPLE_CLEARER(usr);
URI_SIMPLE_CLEARER(pwd);
URI_SIMPLE_CLEARER(host);
URI_SIMPLE_CLEARER(port);

static
void clear_auth(pTHX_ SV *uri_obj) {
  clear_usr(aTHX_ uri_obj);
  clear_pwd(aTHX_ uri_obj);
  clear_host(aTHX_ uri_obj);
  clear_port(aTHX_ uri_obj);
}

/*------------------------------------------------------------------------------
 * Raw getters
 -----------------------------------------------------------------------------*/

// Raw getters
URI_RAW_GETTER(scheme);
URI_RAW_GETTER(usr);
URI_RAW_GETTER(pwd);
URI_RAW_GETTER(host);
URI_RAW_GETTER(port);
URI_RAW_GETTER(path);
URI_RAW_GETTER(query);
URI_RAW_GETTER(frag);

static
SV* get_raw_auth(pTHX_ SV *uri_obj) {
  uri_t *uri = URI(uri_obj);
  SV *out = newSVpvn("", 0);

  if (uri->is_iri) {
    SvUTF8_on(out);
  }

  if (str_len(uri->usr) > 0) {
    if (str_len(uri->pwd) > 0) {
      sv_catpvn(out, str_get(uri->usr), str_len(uri->usr));
      sv_catpvn(out, ":", 1);
      sv_catpvn(out, str_get(uri->pwd), str_len(uri->pwd));
      sv_catpvn(out, "@", 1);
    } else {
      sv_catpvn(out, str_get(uri->usr), str_len(uri->usr));
      sv_catpvn(out, "@", 1);
    }
  }

  if (str_len(uri->host) > 0) {
    if (str_len(uri->port) > 0) {
      sv_catpvn(out, str_get(uri->host), str_len(uri->host));
      sv_catpvn(out, ":", 1);
      sv_catpvn(out, str_get(uri->port), str_len(uri->port));
    } else {
      sv_catpvn(out, str_get(uri->host), str_len(uri->host));
    }
  }

  return out;
}

/*------------------------------------------------------------------------------
 * Decoding getters
 -----------------------------------------------------------------------------*/

URI_SIMPLE_GETTER(scheme);
URI_SIMPLE_GETTER(usr);
URI_SIMPLE_GETTER(pwd);
URI_SIMPLE_GETTER(host);
URI_SIMPLE_GETTER(port);
URI_SIMPLE_GETTER(frag);

URI_COMPOUND_GETTER(path);
URI_COMPOUND_GETTER(query);

static
SV* get_auth(pTHX_ SV *uri_obj) {
  uri_t *uri = URI(uri_obj);
  SV *out = newSVpvn("", 0);

  if (uri->is_iri) {
    SvUTF8_on(out);
  }

  if (str_len(uri->usr) > 0) {
    if (str_len(uri->pwd) > 0) {
      sv_catsv(out, sv_2mortal(get_usr(aTHX_ uri_obj)));
      sv_catpvn(out, ":", 1);
      sv_catsv(out, sv_2mortal(get_pwd(aTHX_ uri_obj)));
      sv_catpvn(out, "@", 1);
    } else {
      sv_catsv(out, sv_2mortal(get_usr(aTHX_ uri_obj)));
      sv_catpvn(out, "@", 1);
    }
  }

  if (str_len(uri->host) > 0) {
    if (str_len(uri->port) > 0) {
      sv_catsv(out, sv_2mortal(get_host(aTHX_ uri_obj)));
      sv_catpvn(out, ":", 1);
      sv_catsv(out, sv_2mortal(get_port(aTHX_ uri_obj)));
    } else {
      sv_catsv(out, sv_2mortal(get_host(aTHX_ uri_obj)));
    }
  }

  return out;
}

static
SV* split_path(pTHX_ SV* uri) {
  size_t len, segment_len, brk, idx = 0;
  AV* arr = newAV();
  SV* tmp;

  const char *str = str_get(URI_MEMBER(uri, path));
  len = str_len(URI_MEMBER(uri, path));

  if (len > 0) {
    if (str[0] == '/') {
      ++idx; // skip past leading /
    }

    while (idx < len) {
      // Find the next separator
      brk = strcspn(&str[idx], "/");

      // Decode the segment
      char segment[brk + 1];
      segment_len = uri_decode(&str[idx], brk, segment, "");

      // Push new SV to AV
      tmp = newSVpvn(segment, segment_len);
      sv_utf8_decode(tmp);
      av_push(arr, tmp);

      idx += brk + 1;
    }
  }

  return newRV_noinc((SV*) arr);
}

static
SV* get_query_keys(pTHX_ SV* uri) {
  const char *query = str_get(URI_MEMBER(uri, query));
  size_t klen, qlen = str_len(URI_MEMBER(uri, query));
  HV* out = newHV();
  uri_query_scanner_t scanner;
  uri_query_token_t token;

  query_scanner_init(&scanner, query, qlen);

  while (!query_scanner_done(&scanner)) {
    query_scanner_next(&scanner, &token);
    if (token.type == DONE) continue;
    char key[token.key_length];
    klen = uri_decode(token.key, token.key_length, key, "");
    hv_store(out, key, -klen, &PL_sv_undef, 0);
  }

  return newRV_noinc((SV*) out);
}

static
SV* query_hash(pTHX_ SV* uri) {
  SV *tmp, **refval;
  AV *arr;
  HV *out = newHV();
  const char *query = str_get(URI_MEMBER(uri, query));
  size_t qlen = str_len(URI_MEMBER(uri, query)), klen, vlen;
  uri_query_scanner_t scanner;
  uri_query_token_t token;

  query_scanner_init(&scanner, query, qlen);

  while (!query_scanner_done(&scanner)) {
    query_scanner_next(&scanner, &token);
    if (token.type == DONE) continue;

    // Get decoded key
    char key[token.key_length + 1];
    klen = uri_decode(token.key, token.key_length, key, "");

    // Values are stored in an array; this block is the rough equivalent of:
    //   $out{$key} = [] unless exists $out{$key};
    if (!hv_exists(out, key, klen)) {
      arr = newAV();
      hv_store(out, key, -klen, newRV_noinc((SV*) arr), 0);
    }
    else {
      refval = hv_fetch(out, key, -klen, 0);
      if (refval == NULL) croak("query_hash: something went wrong");
      arr = (AV*) SvRV(*refval);
    }

    // Get decoded value if there is one
    if (token.type == PARAM) {
      char val[token.value_length + 1];
      vlen = uri_decode(token.value, token.value_length, val, "");
      tmp = newSVpvn(val, vlen);
      sv_utf8_decode(tmp);
      av_push(arr, tmp);
    }
  }

  return newRV_noinc((SV*) out);
}

static
SV* get_param(pTHX_ SV* uri, SV* sv_key) {
  int is_iri = URI_MEMBER(uri, is_iri);
  const char *query = str_get(URI_MEMBER(uri, query));
  const char *key;
  size_t qlen = str_len(URI_MEMBER(uri, query)), klen, vlen, elen;
  uri_query_scanner_t scanner;
  uri_query_token_t token;
  AV* out = newAV();
  SV* value;

  // Read key to search
  if (!SvTRUE(sv_key)) {
    croak("get_param: expected key to search");
  }
  else {
    // Copy input string *before* calling DO_UTF8() in case the SV is an object
    // with string overloading, which may trigger the utf8 flag.
    key = SvPV_const(sv_key, klen);

    if (!DO_UTF8(sv_key)) {
      sv_key = sv_2mortal(newSVpvn(key, klen));
      sv_utf8_encode(sv_key);
      key = SvPV_const(sv_key, klen);
    }
  }

  char enc_key[(klen * 3) + 2];
  elen = uri_encode(key, klen, enc_key, ":@?/", is_iri);

  query_scanner_init(&scanner, query, qlen);

  while (!query_scanner_done(&scanner)) {
    query_scanner_next(&scanner, &token);
    if (token.type == DONE) continue;

    if (strncmp(enc_key, token.key, maxnum(elen, token.key_length)) == 0) {
      if (token.type == PARAM) {
        char val[token.value_length + 1];
        vlen = uri_decode(token.value, token.value_length, val, "");
        value = newSVpvn(val, vlen);
        sv_utf8_decode(value);
        av_push(out, value);
      }
      else {
        av_push(out, newSV(0));
      }
    }
  }

  return newRV_noinc((SV*) out);
}

/*------------------------------------------------------------------------------
 * Setters
 -----------------------------------------------------------------------------*/

URI_SIMPLE_SETTER(scheme, "");
URI_SIMPLE_SETTER(path,   URI_CHARS_PATH);
URI_SIMPLE_SETTER(query,  URI_CHARS_QUERY);
URI_SIMPLE_SETTER(frag,   URI_CHARS_FRAG);
URI_SIMPLE_SETTER(usr,    URI_CHARS_USER);
URI_SIMPLE_SETTER(pwd,    URI_CHARS_USER);
URI_SIMPLE_SETTER(host,   URI_CHARS_HOST);

static
void set_port(pTHX_ SV *uri_obj, SV *sv_value) {
  if (!SvTRUE(sv_value)) {
    str_clear(aTHX_ URI_MEMBER(uri_obj, port));
    return;
  }

  size_t vlen, i;
  const char *value = SvPV_const(sv_value, vlen);
  str_set(aTHX_ URI_MEMBER(uri_obj, port), value, vlen);
}

static
void set_auth(pTHX_ SV *uri_obj, SV *sv_value) {
  str_clear(aTHX_ URI_MEMBER(uri_obj, usr));
  str_clear(aTHX_ URI_MEMBER(uri_obj, pwd));
  str_clear(aTHX_ URI_MEMBER(uri_obj, host));
  str_clear(aTHX_ URI_MEMBER(uri_obj, port));

  if (SvTRUE(sv_value)) {
    size_t vlen;
    const char *value = SvPV_const(sv_value, vlen);

    // auth isn't stored as an individual field, so encode to local array and rescan
    char auth[URI_SIZE_auth];
    size_t len = uri_encode(value, vlen, (char*) &auth, URI_CHARS_AUTH, URI_MEMBER(uri_obj, is_iri));

    uri_scan_auth(aTHX_ URI(uri_obj), auth, len);
  }
}

static
void set_path_array(pTHX_ SV *uri_obj, SV *sv_path) {
  SV **refval, *tmp;
  AV *av_path;
  size_t i, av_idx, seg_len;
  const char *seg;
  uri_str_t *path = URI_MEMBER(uri_obj, path);

  str_clear(aTHX_ path);

  if (!SvTRUE(sv_path)) {
    return;
  }

  // Inspect input array
  av_path = (AV*) SvRV(sv_path);
  av_idx  = av_top_index(av_path);

  // Build the new path
  for (i = 0; i <= av_idx; ++i) {
    // Add separator. If the next value fetched from the array is invalid, it
    // just gets an empty segment.
    str_append(aTHX_ path, "/", 1);

    // Fetch next segment
    refval = av_fetch(av_path, (SSize_t) i, 0);
    if (refval == NULL) continue;
    if (!SvTRUE(*refval)) continue;

    // Copy value over
    if (SvTRUE(*refval)) {
      seg = SvPV_nomg_const(*refval, seg_len);

      // Convert octets to utf8 if necessary
      if (!DO_UTF8(*refval)) {
        tmp = sv_2mortal(newSVpvn(seg, seg_len));
        sv_utf8_encode(tmp);
        seg = SvPV_const(tmp, seg_len);
      }

      char out[seg_len * 3];
      size_t out_len = uri_encode(seg, seg_len, out, URI_CHARS_PATH_SEGMENT, URI_MEMBER(uri_obj, is_iri));

      str_append(aTHX_ path, out, out_len);
    }
  }
}

static
void update_query_keyset(pTHX_ SV *uri, SV *sv_key_set, SV *sv_separator) {
  int    is_iri = URI_MEMBER(uri, is_iri);
  HE     *ent;
  HV     *keys, *enc_keys;
  I32    iterlen, i, klen;
  SV     *val, **refval;
  bool   copy;
  char   *key;
  size_t off = 0;
  uri_str_t *query = URI_MEMBER(uri, query);
  uri_str_t *dest  = str_new(aTHX_ URI_SIZE_query);

  size_t slen = 1;
  const char *separator = SvTRUE(sv_separator) ? SvPV_const(sv_separator, slen) : "&";

  uri_query_scanner_t scanner;
  uri_query_token_t   token;

  // Validate reference parameters
  SvGETMAGIC(sv_key_set);

  if (!SvROK(sv_key_set) || SvTYPE(SvRV(sv_key_set)) != SVt_PVHV) {
    croak("set_query_keys: expected hash ref");
  }

  // Dereference key set hash
  keys = (HV*) SvRV(sv_key_set);

  // Create new HV with all keys uri-encoded
  enc_keys = newHV();
  iterlen = hv_iterinit(keys);

  for (i = 0; i < iterlen; ++i) {
    ent = hv_iternext(keys);
    key = hv_iterkey(ent, &klen);
    val = hv_iterval(keys, ent);

    SvGETMAGIC(val);

    char enc_key[(3 * klen) + 1];
    klen = uri_encode(key, klen, enc_key, ":@?/", is_iri);

    hv_store(enc_keys, enc_key, klen * (is_iri ? -1 : 1), val, 0);
  }

  // Begin building the new query string from the existing one. As each key is
  // encountered in the query string, exclude ones with a falsish value in the
  // hash and keep the ones with a truish value. Any not present in the hash
  // are kept unchanged.
  query_scanner_init(&scanner, str_get(query), str_len(query));

  while (!query_scanner_done(&scanner)) {
    query_scanner_next(&scanner, &token);
    if (token.type == DONE) continue;

    // Use the encrypted keys hash to decide whether to copy this key (and
    // value if present) over to dest. If the key exists, skip. It will be
    // added to the filtered query string last.
    copy = 1;
    if (hv_exists(enc_keys, token.key, token.key_length * (is_iri ? -1 : 1))) {
      refval = hv_fetch(enc_keys, token.key, token.key_length * (is_iri ? -1 : 1), 0);
      // NULL shouldn't be possible since this is guarded with hv_exists, but
      // perlguts, amirite?
      copy = refval == NULL || SvTRUE(*refval);
    }

    if (copy) {
      if (off > 0) {
        str_append(aTHX_ dest, separator, slen);
        off += slen;
      }

      str_append(aTHX_ dest, token.key, token.key_length);
      off += token.key_length;

      if (token.type == PARAM) {
        str_append(aTHX_ dest, "=", 1);
        str_append(aTHX_ dest, token.value, token.value_length);
        off += token.value_length;
      }
    }
  }

  // Walk through the encoded-key hash, adding remaining keys.
  iterlen = hv_iterinit(enc_keys);

  for (i = 0; i < iterlen; ++i) {
    ent = hv_iternext(enc_keys);
    key = hv_iterkey(ent, &klen);
    val = hv_iterval(enc_keys, ent);

    if (SvTRUE(val)) {
      // Add separator if the new query string is not empty
      if (off > 0) {
        str_append(aTHX_ dest, separator, slen);
        off += slen;
      }

      str_append(aTHX_ dest, key, klen);
      off += klen;
    }
  }

  str_free(aTHX_ query);
  URI_MEMBER(uri, query) = dest;
}

static
void set_param(pTHX_ SV *uri, SV *sv_key, SV *sv_values, SV *sv_separator) {
  int is_iri = URI_MEMBER(uri, is_iri);
  const char *strval;
  size_t vlen, reflen, av_idx, i = 0, off = 0;
  AV *av_values;
  SV **refval;
  uri_str_t *query = URI_MEMBER(uri, query);
  uri_str_t *dest = str_new(aTHX_ URI_SIZE_query);
  uri_query_scanner_t scanner;
  uri_query_token_t token;

  size_t slen = 1;
  const char *separator = SvTRUE(sv_separator) ? SvPV_const(sv_separator, slen) : "&";

  // Build encoded key string
  if (!SvTRUE(sv_key)) {
    croak("set_param: expected key");
  }

  size_t klen;
  const char *key = SvPV_const(sv_key, klen);
  char enc_key[(3 * klen) + 1];
  klen = uri_encode(key, strlen(key), enc_key, ":@?/", is_iri);

  // Get array of values to set
  SvGETMAGIC(sv_values);

  if (!SvROK(sv_values) || SvTYPE(SvRV(sv_values)) != SVt_PVAV) {
    croak("set_param: expected array of values");
  }

  av_values = (AV*) SvRV(sv_values);
  av_idx = av_top_index(av_values);

  // Begin building the new query string from the existing one, skipping
  // keys (and their values, if any) matching sv_key.
  query_scanner_init(&scanner, str_get(query), str_len(query));

  while (!query_scanner_done(&scanner)) {
    query_scanner_next(&scanner, &token);
    if (token.type == DONE) continue;

    // The key does not match the key being set
    if (strncmp(enc_key, token.key, maxnum(klen, token.key_length)) != 0) {
      // Add separator if this is not the first key being written
      if (off > 0) {
        str_append(aTHX_ dest, separator, slen);
        off += slen;
      }

      // Write the key to the buffer
      str_append(aTHX_ dest, token.key, token.key_length);
      off += token.key_length;

      // The key has a value
      if (token.type == PARAM) {
        str_append(aTHX_ dest, "=", 1);

        // If the value's length is 0, it was parsed from "key=", so the value
        // is not written after the '=' is added above.
        if (token.value_length > 0) {
          // Otherwise, write the value to the buffer
          str_append(aTHX_ dest, token.value, token.value_length);
          off += token.value_length;
        }
      }
    }
  }

  // Add the new values to the query
  for (i = 0; i <= av_idx; ++i) {
    // Fetch next value from the array
    refval = av_fetch(av_values, (SSize_t) i, 0);
    if (refval == NULL) break;
    if (!SvTRUE(*refval)) break;

    // Add separator if needed to separate pairs
    if (off > 0) {
      str_append(aTHX_ dest, separator, slen);
      off += slen;
    }

    // Copy key over
    str_append(aTHX_ dest, enc_key, klen);
    off += klen;

    str_append(aTHX_ dest, "=", 1);

    // Copy value over
    SvGETMAGIC(*refval);
    strval = SvPV_const(*refval, reflen);

    char tmp[reflen * 3];
    vlen = uri_encode(strval, reflen, tmp, ":@?/", is_iri);
    str_append(aTHX_ dest, tmp, vlen);
    off += vlen;
  }

  str_free(aTHX_ query);
  URI_MEMBER(uri, query) = dest;
}

/*------------------------------------------------------------------------------
 * Other stuff
 -----------------------------------------------------------------------------*/

static
SV* to_string(pTHX_ SV* uri_obj) {
  uri_t *uri = URI(uri_obj);
  SV *out = newSVpvn("", 0);
  SV *auth = get_auth(aTHX_ uri_obj);

  if (uri->is_iri) {
    SvUTF8_on(out);
  }

  if (str_len(uri->scheme) > 0) {
    sv_catpvn(out, str_get(uri->scheme), str_len(uri->scheme));
    sv_catpvn(out, ":", 1);

    if (SvTRUE(auth)) {
      // When the authority section is present, the scheme must be followed by
      // two forward slashes
      sv_catpvn(out, "//", 2);
    }
  }

  if (SvTRUE(auth)) {
    sv_catsv(out, sv_2mortal(auth));

    // When the authority section is present, any path must be separated from
    // the authority section by a forward slash
    if (str_len(uri->path) > 0 && (str_get(uri->path))[0] != '/') {
      sv_catpvn(out, "/", 1);
    }
  }

  sv_catpvn(out, str_get(uri->path), str_len(uri->path));

  if (str_len(uri->query) > 0) {
    sv_catpvn(out, "?", 1);
    sv_catpvn(out, str_get(uri->query), str_len(uri->query));
  }

  if (str_len(uri->frag) > 0) {
    sv_catpvn(out, "#", 1);
    sv_catpvn(out, str_get(uri->frag), str_len(uri->frag));
  }

  return out;
}

static
void explain(pTHX_ SV* uri_obj) {
  printf("scheme: %s\n",  str_get(URI_MEMBER(uri_obj, scheme)));
  printf("auth:\n");
  printf("  -usr: %s\n",  str_get(URI_MEMBER(uri_obj, usr)));
  printf("  -pwd: %s\n",  str_get(URI_MEMBER(uri_obj, pwd)));
  printf("  -host: %s\n", str_get(URI_MEMBER(uri_obj, host)));
  printf("  -port: %s\n", str_get(URI_MEMBER(uri_obj, port)));
  printf("path: %s\n",    str_get(URI_MEMBER(uri_obj, path)));
  printf("query: %s\n",   str_get(URI_MEMBER(uri_obj, query)));
  printf("frag: %s\n",    str_get(URI_MEMBER(uri_obj, frag)));
}

static
void debug(pTHX_ SV* uri_obj) {
  warn("scheme: %s\n",  str_get(URI_MEMBER(uri_obj, scheme)));
  warn("auth:\n");
  warn("  -usr: %s\n",  str_get(URI_MEMBER(uri_obj, usr)));
  warn("  -pwd: %s\n",  str_get(URI_MEMBER(uri_obj, pwd)));
  warn("  -host: %s\n", str_get(URI_MEMBER(uri_obj, host)));
  warn("  -port: %s\n", str_get(URI_MEMBER(uri_obj, port)));
  warn("path: %s\n",    str_get(URI_MEMBER(uri_obj, path)));
  warn("query: %s\n",   str_get(URI_MEMBER(uri_obj, query)));
  warn("frag: %s\n",    str_get(URI_MEMBER(uri_obj, frag)));
}

static
SV* new(pTHX_ const char* class, SV* uri_str, int is_iri) {
  const char* src;
  size_t len;
  uri_t* uri;
  SV*    obj;
  SV*    obj_ref;

  // Initialize the struct
  Newx(uri, 1, uri_t);
  Zero(uri, 1, uri_t);

  uri->is_iri = is_iri;
  uri->scheme = str_new(aTHX_ URI_SIZE_scheme);
  uri->usr    = str_new(aTHX_ URI_SIZE_usr);
  uri->pwd    = str_new(aTHX_ URI_SIZE_pwd);
  uri->host   = str_new(aTHX_ URI_SIZE_host);
  uri->port   = str_new(aTHX_ URI_SIZE_port);
  uri->path   = str_new(aTHX_ URI_SIZE_path);
  uri->query  = str_new(aTHX_ URI_SIZE_query);
  uri->frag   = str_new(aTHX_ URI_SIZE_frag);

  // Build the blessed instance
  obj = newSViv((IV) uri);
  obj_ref = newRV_noinc(obj);
  sv_bless(obj_ref, gv_stashpv(class, GV_ADD));
  SvREADONLY_on(obj);

  // Scan the input string to fill the struct
  if (!SvTRUE(uri_str)) {
    src = "";
    len = 0;
  }
  else {
    // Copy input string *before* calling DO_UTF8() in case the SV is an object
    // with string overloading, which may trigger the utf8 flag.
    src = SvPV_nomg_const(uri_str, len);

    // Ensure the pv bytes are utf8-encoded
    if (!DO_UTF8(uri_str)) {
      uri_str = sv_2mortal(newSVpvn(src, len));
      sv_utf8_encode(uri_str);
      src = SvPV_const(uri_str, len);
    }
  }

  uri_scan(aTHX_ uri, src, len);

  return obj_ref;
}

static
void DESTROY(pTHX_ SV *uri_obj) {
  uri_t *uri = (uri_t*) SvIV(SvRV(uri_obj));
  str_free(aTHX_ uri->scheme);
  str_free(aTHX_ uri->usr);
  str_free(aTHX_ uri->pwd);
  str_free(aTHX_ uri->host);
  str_free(aTHX_ uri->port);
  str_free(aTHX_ uri->path);
  str_free(aTHX_ uri->query);
  str_free(aTHX_ uri->frag);
  Safefree(uri);
}

/*
 * Extras
 */
static
void uri_split(pTHX_ SV* uri) {
  const char* src;
  size_t idx = 0;
  size_t brk = 0;
  size_t len;

  if (!SvTRUE(uri)) {
    src = "";
    len = 0;
  }
  else {
    src = SvPV_nomg_const(uri, len);

    if (!DO_UTF8(uri)) {
      uri = sv_2mortal(newSVpvn(src, len));
      sv_utf8_encode(uri);
      src = SvPV_const(uri, len);
    }
  }

  dXSARGS;
  sp = mark;

  // Scheme
  brk = strcspn(&src[idx], ":/@?#");
  if (brk > 0 && strncmp(&src[idx + brk], "://", 3) == 0) {
    XPUSHs(sv_2mortal(newSVpvn(&src[idx], brk)));
    idx += brk + 3;

    // Authority
    brk = strcspn(&src[idx], "/?#");
    if (brk > 0) {
      XPUSHs(sv_2mortal(newSVpvn(&src[idx], brk)));
      idx += brk;
    } else {
      XPUSHs(sv_2mortal(newSVpvn("",0)));
    }
  }
  else {
    XPUSHs(&PL_sv_undef);
    XPUSHs(&PL_sv_undef);
  }

  // path
  brk = strcspn(&src[idx], "?#");
  if (brk > 0) {
    XPUSHs(sv_2mortal(newSVpvn(&src[idx], brk)));
    idx += brk;
  } else {
    XPUSHs(sv_2mortal(newSVpvn("", 0)));
  }

  // query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = strcspn(&src[idx], "#");
    if (brk > 0) {
      XPUSHs(sv_2mortal(newSVpvn(&src[idx], brk)));
      idx += brk;
    } else {
      XPUSHs(&PL_sv_undef);
    }
  } else {
    XPUSHs(&PL_sv_undef);
  }

  // fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      XPUSHs(sv_2mortal(newSVpvn(&src[idx], brk)));
    } else {
      XPUSHs(&PL_sv_undef);
    }
  } else {
    XPUSHs(&PL_sv_undef);
  }

  PUTBACK;
}


MODULE = URI::Fast  PACKAGE = URI::Fast

PROTOTYPES: DISABLE

VERSIONCHECK: ENABLE

#-------------------------------------------------------------------------------
# URL-encoding
#-------------------------------------------------------------------------------
SV* encode(in, ...)
  SV *in
    PREINIT:
      SV *temp = NULL;
    CODE:
      if (items > 1) {
        temp = ST(1);
      }
      RETVAL = encode(aTHX_ in, temp);
    OUTPUT:
      RETVAL

SV* decode(in)
  SV* in
    CODE:
      RETVAL = decode(aTHX_ in);
    OUTPUT:
      RETVAL

#-------------------------------------------------------------------------------
# Constructors and destructors
#-------------------------------------------------------------------------------
SV* new(class, uri_str)
  const char* class
  SV* uri_str
  CODE:
    RETVAL = new(aTHX_ class, uri_str, 0);
  OUTPUT:
    RETVAL

SV* new_iri(class, uri_str)
  const char* class;
  SV* uri_str
  CODE:
    RETVAL = new(aTHX_ "URI::Fast::IRI", uri_str, 1);
  OUTPUT:
    RETVAL

void DESTROY(uri_obj)
  SV* uri_obj
  CODE:
    DESTROY(aTHX_ uri_obj);


#-------------------------------------------------------------------------------
# Clearers
#-------------------------------------------------------------------------------
void clear_scheme(uri_obj)
  SV* uri_obj
  CODE:
    clear_scheme(aTHX_ uri_obj);

void clear_path(uri_obj)
  SV* uri_obj
  CODE:
    clear_path(aTHX_ uri_obj);

void clear_query (uri_obj)
  SV* uri_obj
  CODE:
    clear_query(aTHX_ uri_obj);

void clear_frag(uri_obj)
  SV* uri_obj
  CODE:
    clear_frag(aTHX_ uri_obj);

void clear_usr(uri_obj)
  SV* uri_obj
  CODE:
    clear_usr(aTHX_ uri_obj);

void clear_pwd(uri_obj)
  SV* uri_obj
  CODE:
    clear_pwd(aTHX_ uri_obj);

void clear_host(uri_obj)
  SV* uri_obj
  CODE:
    clear_host(aTHX_ uri_obj);

void clear_port(uri_obj)
  SV* uri_obj
  CODE:
    clear_port(aTHX_ uri_obj);

void clear_auth(uri_obj)
  SV* uri_obj
  CODE:
    clear_auth(aTHX_ uri_obj);

#-------------------------------------------------------------------------------
# Raw getters
#-------------------------------------------------------------------------------
SV* raw_scheme(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_scheme(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_auth(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_auth(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_path(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_path(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_query(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_query(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_frag(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_frag(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_usr(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_usr(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_pwd(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_pwd(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_host(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_host(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* raw_port(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_raw_port(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

#-------------------------------------------------------------------------------
# Decoding getters
#-------------------------------------------------------------------------------
SV* get_scheme(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_scheme(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_path(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_path(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_query(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_query(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_frag(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_frag(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_usr(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_usr(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_pwd(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_pwd(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_host(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_host(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_port(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_port(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_auth(uri_obj)
  SV *uri_obj
  CODE:
    RETVAL = get_auth(aTHX_ uri_obj);
  OUTPUT:
    RETVAL


#-------------------------------------------------------------------------------
# Compound getters
#-------------------------------------------------------------------------------
SV* split_path(uri)
  SV* uri
  CODE:
    RETVAL = split_path(aTHX_ uri);
  OUTPUT:
    RETVAL

SV* get_query_keys(uri)
  SV* uri
  CODE:
    RETVAL = get_query_keys(aTHX_ uri);
  OUTPUT:
    RETVAL

SV* get_query_hash(uri)
  SV* uri
  CODE:
    RETVAL = query_hash(aTHX_ uri);
  OUTPUT:
    RETVAL

SV* get_param(uri, sv_key)
  SV* uri
  SV* sv_key
  CODE:
    RETVAL = get_param(aTHX_ uri, sv_key);
  OUTPUT:
    RETVAL


#-------------------------------------------------------------------------------
# Setters
#-------------------------------------------------------------------------------
void set_scheme(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_scheme(aTHX_ uri_obj, value);

void set_auth(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_auth(aTHX_ uri_obj, value);

void set_path(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_path(aTHX_ uri_obj, value);

void set_path_array(uri_obj, segments)
  SV *uri_obj
  SV *segments
  CODE:
    set_path_array(aTHX_ uri_obj, segments);

void set_query(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_query(aTHX_ uri_obj, value);

void set_frag(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_frag(aTHX_ uri_obj, value);

void set_usr(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_usr(aTHX_ uri_obj, value);

void set_pwd(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_pwd(aTHX_ uri_obj, value);

void set_host(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_host(aTHX_ uri_obj, value);

void set_port(uri_obj, value)
  SV *uri_obj
  SV *value
  CODE:
    set_port(aTHX_ uri_obj, value);

void set_param(uri, sv_key, sv_values, sv_separator)
  SV *uri
  SV *sv_key
  SV *sv_values
  SV *sv_separator
  CODE:
    set_param(aTHX_ uri, sv_key, sv_values, sv_separator);

void update_query_keyset(uri, sv_key_set, sv_separator)
  SV *uri
  SV *sv_key_set
  SV *sv_separator
  CODE:
    update_query_keyset(aTHX_ uri, sv_key_set, sv_separator);

#-------------------------------------------------------------------------------
# Extras
#-------------------------------------------------------------------------------
SV* to_string(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = to_string(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

void explain(uri_obj)
  SV* uri_obj
  CODE:
    explain(aTHX_ uri_obj);

void debug(uri_obj)
  SV* uri_obj
  CODE:
    debug(aTHX_ uri_obj);

void uri_split(uri)
  SV* uri
  PREINIT:
    I32* temp;
  PPCODE:
    temp = PL_markstack_ptr++;
    uri_split(aTHX_ uri);

    if (PL_markstack_ptr != temp) {
      PL_markstack_ptr = temp;
      XSRETURN_EMPTY;
    }

    return;
