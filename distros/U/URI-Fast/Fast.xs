#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef URI

// return uri_t* from blessed pointer ref
#define URI(obj) ((uri_t*) SvIV(SvRV(obj)))

// expands to member reference
#define URI_MEMBER(obj, member) (URI(obj)->member)

// quick sugar for calling uri_encode
#define URI_ENCODE_MEMBER(uri, mem, val, allow, alen) uri_encode(val, min(strlen(val), URI_SIZE(mem)), URI_MEMBER(uri, mem), allow, alen, URI_MEMBER(uri, is_iri))

// size constats
#define URI_SIZE_scheme 32
#define URI_SIZE_path   1024
#define URI_SIZE_query  2048
#define URI_SIZE_frag   64
#define URI_SIZE_usr    64
#define URI_SIZE_pwd    64
#define URI_SIZE_host   256
#define URI_SIZE_port   8

// enough to fit all pieces + 3 chars for separators (2 colons + @)
#define URI_SIZE_auth (3 + URI_SIZE_usr + URI_SIZE_pwd + URI_SIZE_host + URI_SIZE_port)
#define URI_SIZE(member) (URI_SIZE_##member)

#endif

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

// min of two numbers
#ifndef min
#define min(a, b) (a <= b ? a : b)
#endif

/*
 * Percent encoding
 */
static inline
char is_allowed(char c, const char* allowed, size_t len) {
  size_t i;
  for (i = 0; i < len; ++i) {
    if (c == allowed[i]) {
      return 1;
    }
  }

  return 0;
}

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

size_t uri_encode(const char* in, size_t len, char* out, const char* allow, size_t allow_len, int allow_utf8) {
  size_t i = 0;
  size_t j = 0;
  char octet;
  U32 code;

  while (i < len) {
    octet = in[i++];

    if (is_allowed(octet, allow, allow_len) || (allow_utf8 && octet & 0X8000)) {
      out[j++] = octet;
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
    }
  }

  out[j] = '\0';

  return j;
}

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
size_t uri_decode(const char *in, size_t len, char *out) {
  size_t i = 0, j = 0;
  unsigned char v1, v2;
  char decoded;

  while (i < len) {
    decoded = '\0';

    switch (in[i]) {
      case '+':
        decoded = ' ';
        ++i;
        break;
      case '%':
        if (i + 2 < len) {
          decoded = unhex( &in[i + 1] );
          if (decoded != '\0') {
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
SV* encode(pTHX_ SV* in, ...) {
  size_t ilen, olen, alen;
  const char *allowed;
  SV* out;

  SvGETMAGIC(in);
  const char *src = SvPV_nomg_const(in, ilen);
  char dest[(ilen * 3) + 1];

  dXSARGS;

  if (items > 1) {
    allowed = SvPV_nomg_const(ST(1), alen);
  } else {
    allowed = "";
    alen = 0;
  }

  PUTBACK;

  olen = uri_encode(src, ilen, dest, allowed, alen, 0);
  out  = newSVpv(dest, olen);
  sv_utf8_downgrade(out, FALSE);

  return out;
}

static
SV* decode(pTHX_ SV* in) {
  size_t ilen, olen;
  const char* src;
  SV* out;

  SvGETMAGIC(in);

  if (SvUTF8(in)) {
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

  olen = uri_decode(src, ilen, dest);
  out  = newSVpv(dest, olen);
  sv_utf8_decode(out);

  return out;
}

/*
 * Internal API
 */
typedef char uri_scheme_t [URI_SIZE_scheme + 1];
typedef char uri_path_t   [URI_SIZE_path + 1];
typedef char uri_query_t  [URI_SIZE_query + 1];
typedef char uri_frag_t   [URI_SIZE_frag + 1];
typedef char uri_usr_t    [URI_SIZE_usr + 1];
typedef char uri_pwd_t    [URI_SIZE_pwd + 1];
typedef char uri_host_t   [URI_SIZE_host + 1];
typedef char uri_port_t   [URI_SIZE_port + 1];
typedef int  uri_is_iri_t;

typedef struct {
  uri_scheme_t scheme;
  uri_path_t   path;
  uri_query_t  query;
  uri_frag_t   frag;
  uri_usr_t    usr;
  uri_pwd_t    pwd;
  uri_host_t   host;
  uri_port_t   port;
  uri_is_iri_t is_iri;
} uri_t;

/*
 * Clearers
 */
static void clear_scheme(pTHX_ SV* uri_obj) { memset(&((URI(uri_obj))->scheme), '\0', sizeof(uri_scheme_t)); }
static void clear_path(pTHX_ SV* uri_obj)   { memset(&((URI(uri_obj))->path),   '\0', sizeof(uri_path_t));   }
static void clear_query(pTHX_ SV* uri_obj)  { memset(&((URI(uri_obj))->query),  '\0', sizeof(uri_query_t));  }
static void clear_frag(pTHX_ SV* uri_obj)   { memset(&((URI(uri_obj))->frag),   '\0', sizeof(uri_frag_t));   }
static void clear_usr(pTHX_ SV* uri_obj)    { memset(&((URI(uri_obj))->usr),    '\0', sizeof(uri_usr_t));    }
static void clear_pwd(pTHX_ SV* uri_obj)    { memset(&((URI(uri_obj))->pwd),    '\0', sizeof(uri_pwd_t));    }
static void clear_host(pTHX_ SV* uri_obj)   { memset(&((URI(uri_obj))->host),   '\0', sizeof(uri_host_t));   }
static void clear_port(pTHX_ SV* uri_obj)   { memset(&((URI(uri_obj))->port),   '\0', sizeof(uri_port_t));   }

static
void clear_auth(pTHX_ SV* uri_obj) {
  clear_usr(aTHX_ uri_obj);
  clear_pwd(aTHX_ uri_obj);
  clear_host(aTHX_ uri_obj);
  clear_port(aTHX_ uri_obj);
}

/*
 * Scans the authorization portion of the URI string
 */
static
void uri_scan_auth(uri_t* uri, const char* auth, const size_t len) {
  size_t idx  = 0;
  size_t brk1 = 0;
  size_t brk2 = 0;
  size_t i;

  memset(&uri->usr,  '\0', sizeof(uri_usr_t));
  memset(&uri->pwd,  '\0', sizeof(uri_pwd_t));
  memset(&uri->host, '\0', sizeof(uri_host_t));
  memset(&uri->port, '\0', sizeof(uri_port_t));

  if (len > 0) {
    // Credentials
    brk1 = min(len, strcspn(&auth[idx], "@"));

    if (brk1 > 0 && brk1 != len) {
      brk2 = min(len - idx, strcspn(&auth[idx], ":"));

      if (brk2 > 0 && brk2 < brk1) {
        strncpy(uri->usr, &auth[idx], min(brk2, URI_SIZE_usr));
        idx += brk2 + 1;

        strncpy(uri->pwd, &auth[idx], min(brk1 - brk2 - 1, URI_SIZE_pwd));
        idx += brk1 - brk2;
      }
      else {
        strncpy(uri->usr, &auth[idx], min(brk1, URI_SIZE_usr));
        idx += brk1 + 1;
      }
    }

    // Location
    brk1 = min(len - idx, strcspn(&auth[idx], ":"));

    if (brk1 > 0 && brk1 != (len - idx)) {
      strncpy(uri->host, &auth[idx], min(brk1, URI_SIZE_host));
      idx += brk1 + 1;

      for (i = 0; i < (len - idx) && i < URI_SIZE_port; ++i) {
        if (!isdigit(auth[i + idx])) {
          memset(&uri->port, '\0', URI_SIZE_port + 1);
          break;
        }
        else {
          uri->port[i] = auth[i + idx];
        }
      }
    }
    else {
      strncpy(uri->host, &auth[idx], min(len - idx, URI_SIZE_host));
    }
  }
}

/*
 * Scans a URI string and populates the uri_t struct.
 */
static
void uri_scan(uri_t* uri, const char* src, size_t len) {
  size_t idx = 0;
  size_t brk = 0;

  // Scheme
  brk = min(len, strcspn(&src[idx], ":/@?#"));
  if (brk > 0 && strncmp(&src[idx + brk], "://", 3) == 0) {
    strncpy(uri->scheme, &src[idx], min(brk, URI_SIZE_scheme));
    uri->scheme[brk] = '\0';
    idx += brk + 3;

    // Authority
    brk = min(len - idx, strcspn(&src[idx], "/?#"));
    if (brk > 0) {
      uri_scan_auth(uri, &src[idx], brk);
      idx += brk;
    }
  }

  // path
  brk = min(len - idx, strcspn(&src[idx], "?#"));
  if (brk > 0) {
    strncpy(uri->path, &src[idx], min(brk, URI_SIZE_path));
    uri->path[brk] = '\0';
    idx += brk;
  }

  // query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = min(len - idx, strcspn(&src[idx], "#"));
    if (brk > 0) {
      strncpy(uri->query, &src[idx], min(brk, URI_SIZE_query));
      uri->query[brk] = '\0';
      idx += brk;
    }
  }

  // fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      strncpy(uri->frag, &src[idx], min(brk, URI_SIZE_frag));
      uri->frag[brk] = '\0';
    }
  }
}

/*
 * Perl API
 */

/*
 * Getters
 */
static const char* get_scheme(pTHX_ SV* uri_obj) { return URI_MEMBER(uri_obj, scheme); }
static const char* get_path(pTHX_ SV* uri_obj)   { return URI_MEMBER(uri_obj, path);   }
static const char* get_query(pTHX_ SV* uri_obj)  { return URI_MEMBER(uri_obj, query);  }
static const char* get_frag(pTHX_ SV* uri_obj)   { return URI_MEMBER(uri_obj, frag);   }
static const char* get_usr(pTHX_ SV* uri_obj)    { return URI_MEMBER(uri_obj, usr);    }
static const char* get_pwd(pTHX_ SV* uri_obj)    { return URI_MEMBER(uri_obj, pwd);    }
static const char* get_host(pTHX_ SV* uri_obj)   { return URI_MEMBER(uri_obj, host);   }
static const char* get_port(pTHX_ SV* uri_obj)   { return URI_MEMBER(uri_obj, port);   }

static
SV* get_auth(pTHX_ SV* uri_obj) {
  uri_t* uri = URI(uri_obj);
  SV* out = newSVpv("", 0);

  if (uri->usr[0] != '\0') {
    if (uri->pwd[0] != '\0') {
      sv_catpvf(out, "%s:%s@", uri->usr, uri->pwd);
    } else {
      sv_catpvf(out, "%s@", uri->usr);
    }
  }

  if (uri->host[0] != '\0') {
    if (uri->port[0] != '\0') {
      sv_catpvf(out, "%s:%s", uri->host, uri->port);
    } else {
      sv_catpv(out, uri->host);
    }
  }

  return out;
}

static
SV* split_path(pTHX_ SV* uri) {
  size_t brk, idx = 0;
  AV* arr = newAV();
  SV* tmp;

  size_t path_len = strlen(URI_MEMBER(uri, path));
  char str[path_len + 1];
  size_t len = uri_decode(URI_MEMBER(uri, path), path_len, str);

  if (str[0] == '/') {
    ++idx; // skip past leading /
  }

  while (idx < len) {
    brk = strcspn(&str[idx], "/");
    tmp = newSVpvn(&str[idx], brk);
    sv_utf8_decode(tmp);
    av_push(arr, tmp);
    idx += brk + 1;
  }

  return newRV_noinc((SV*) arr);
}

static
SV* get_query_keys(pTHX_ SV* uri) {
  const char* src;
  size_t vlen, idx;
  HV* out = newHV();

  for (src = URI_MEMBER(uri, query); src != NULL && src[0] != '\0'; src = strstr(src, "&")) {
    if (src[0] == '&' || src[0] == ';') {
      ++src;
    }

    idx = strcspn(src, "=");
    char tmp[idx + 1];
    vlen = uri_decode(src, idx, tmp);
    hv_store(out, tmp, -vlen, &PL_sv_undef, 0);
  }

  return newRV_noinc((SV*) out);
}

static
SV* query_hash(pTHX_ SV* uri) {
  const char* src = URI_MEMBER(uri, query);
  size_t idx = 0, brk, klen, vlen, slen = min(URI_SIZE_query, strlen(src));
  SV** ref;
  SV* tmp;
  AV* arr;
  HV* out = newHV();

  while (idx < slen) {
    tmp = NULL;

    // Scan key
    brk = strcspn(&src[idx], "=");

    // Missing key (e.g. query is "?=foo")
    if (brk == 0) {
      // Skip past value since there is no key to store it
      idx += strcspn(&src[idx], "&;") + 1;
      continue;
    }

    // Decode key
    char key[brk + 1];
    klen = uri_decode(&src[idx], brk, key);
    idx += brk + 1;

    // Scan value
    brk = strcspn(&src[idx], "&;");

    // Create SV of value
    if (brk > 0) {
      char val[brk + 1];
      vlen = uri_decode(&src[idx], brk, val);

      // Create new sv to store value
      tmp = newSVpv(val, vlen);
      sv_utf8_decode(tmp);
    }

    // Move to next key
    idx += brk + 1;

    if (!hv_exists(out, key, klen)) {
      arr = newAV();
      hv_store(out, key, -klen, newRV_noinc((SV*) arr), 0);
    }
    else {
      ref = hv_fetch(out, key, klen, 0);
      if (ref == NULL) {
        croak("query_form: something went wrong");
      }
      arr = (AV*) SvRV(*ref);
    }

    if (tmp != NULL) {
      av_push(arr, tmp);
    }
  }

  return newRV_noinc((SV*) out);
}

static
SV* get_param(pTHX_ SV* uri, SV* sv_key) {
  int is_iri = URI_MEMBER(uri, is_iri);
  const char* src = URI_MEMBER(uri, query);
  size_t idx = 0, brk = 0, klen, elen, vlen, len = min(URI_SIZE_query, strlen(src));
  AV* out = newAV();
  SV* value;

  SvGETMAGIC(sv_key);
  const char* key = SvPV_nomg_const(sv_key, klen);

  char enc_key[(klen * 3) + 2];
  elen = uri_encode(key, klen, enc_key, "", 0, is_iri);
  enc_key[elen] = '=';
  enc_key[++elen] = '\0';

  while (idx < len) {
    if (strncmp(&src[idx], enc_key, elen) == 0) {
      idx += elen;
      brk = strcspn(&src[idx], "&;");

      char val[brk + 1];
      vlen = uri_decode(&src[idx], brk, val);
      idx += brk + 1;
      value = newSVpv(val, vlen);
      sv_utf8_decode(value);
      av_push(out, value);
    }
    else {
      idx += strcspn(&src[idx], "&;") + 1;
    }
  }

  return newRV_noinc((SV*) out);
}

/*
 * Setters
 */
static
const char* set_scheme(pTHX_ SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, scheme, value, "", 0);
  return URI_MEMBER(uri_obj, scheme);
}

static
SV* set_auth(pTHX_ SV* uri_obj, const char* value) {
  char auth[URI_SIZE_auth];
  size_t len = uri_encode(value, strlen(value), (char*) &auth, ":@", 2, URI_MEMBER(uri_obj, is_iri));
  uri_scan_auth(URI(uri_obj), auth, len);
  return newSVpv(auth, len);
}

static
const char* set_path(pTHX_ SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, path, value, "/", 1);
  return URI_MEMBER(uri_obj, path);
}

static
const char* set_query(pTHX_ SV* uri_obj, const char* value) {
  strncpy(URI_MEMBER(uri_obj, query), value, min(strlen(value) + 1, URI_SIZE_query));
  return value;
}

static
const char* set_frag(pTHX_ SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, frag, value, "", 0);
  return URI_MEMBER(uri_obj, frag);
}

static
const char* set_usr(pTHX_ SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, usr, value, "", 0);
  return URI_MEMBER(uri_obj, usr);
}

static
const char* set_pwd(pTHX_ SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, pwd, value, "", 0);
  return URI_MEMBER(uri_obj, pwd);
}

static
const char* set_host(pTHX_ SV* uri_obj, const char* value) {
  URI_ENCODE_MEMBER(uri_obj, host, value, "", 0);
  return URI_MEMBER(uri_obj, host);
}

static
const char* set_port(pTHX_ SV* uri_obj, const char* value) {
  size_t len = min(strlen(value), URI_SIZE_port);
  size_t i;

  for (i = 0; i < len; ++i) {
    if (isdigit(value[i])) {
      URI_MEMBER(uri_obj, port)[i] = value[i];
    }
    else {
      clear_port(aTHX_ uri_obj);
      break;
    }
  }

  return URI_MEMBER(uri_obj, port);
}

static
void set_param(pTHX_ SV* uri, SV* sv_key, SV* sv_values, const char* separator) {
  int    is_iri = URI_MEMBER(uri, is_iri);
  char   dest[1024];
  const  char *key, *src = URI_MEMBER(uri, query), *strval;
  const  char sep = separator[0];
  size_t klen, vlen, slen, qlen = strlen(src), avlen, i = 0, j = 0, brk = 0;
  AV*    av_values;
  SV**   ref;

  SvGETMAGIC(sv_key);
  key = SvPV_nomg_const(sv_key, klen);
  char enckey[(3 * klen) + 1];
  klen = uri_encode(key, strlen(key), enckey, "", 0, is_iri);

  SvGETMAGIC(sv_values);
  if (!SvROK(sv_values) || SvTYPE(SvRV(sv_values)) != SVt_PVAV) {
    croak("set_param: expected array of values");
  }

  av_values = (AV*) SvRV(sv_values);
  avlen = av_top_index(av_values);

  // Copy the old query, skipping the key to be updated
  while (i < qlen) {
    // If the string does not begin with the key, advance until it does,
    // copying into dest as idx advances.
    while (strncmp(&src[i], enckey, klen) != 0) {
      // Find the end of this key=value section
      brk = strcspn(&src[i], separator);

      // If this is not the first key=value section written to dest, add an
      // ampersand to separate the pairs.
      if (j > 0) dest[j++] = src[i + brk];

      // Copy up to our break point
      strncpy(&dest[j], &src[i], brk);
      j += brk;
      i += brk;

      if (i >= qlen) break;
      if (strcspn(&src[i], separator) == 0) ++i;
    }

    // The key was found; skip past to the next key=value pair
    i += strcspn(&src[i], separator);

    // Skip the '&', too, since it will already be there
    if (strcspn(&src[i], separator) == 0) ++i;
  }

  // Add the new values to the query
  for (i = 0; i <= avlen; ++i) {
    // Fetch next value from the array
    ref = av_fetch(av_values, (SSize_t) i, 0);
    if (ref == NULL) break;
    if (!SvOK(*ref)) break;

    // Add ampersand if needed to separate pairs
    if (j > 0) dest[j++] = sep;

    // Copy key over
    strncpy(&dest[j], enckey, klen);
    j += klen;

    dest[j++] = '=';

    // Copy value over
    SvGETMAGIC(*ref);
    strval = SvPV_nomg_const(*ref, slen);

    vlen = uri_encode(strval, slen, &dest[j], "", 0, is_iri);
    j += vlen;
  }

  clear_query(aTHX_ uri);
  strncpy(URI_MEMBER(uri, query), dest, j);
}

/*
 * Other stuff
 */

static
SV* to_string(pTHX_ SV* uri_obj) {
  uri_t* uri = URI(uri_obj);
  SV*    out = newSVpv("", 0);

  if (uri->scheme[0] != '\0') {
    sv_catpv(out, uri->scheme);
    sv_catpv(out, "://");
  }

  sv_catsv(out, sv_2mortal(get_auth(aTHX_ uri_obj)));
  sv_catpv(out, uri->path);

  if (uri->query[0] != '\0') {
    sv_catpv(out, "?");
    sv_catpv(out, uri->query);
  }

  if (uri->frag[0] != '\0') {
    sv_catpv(out, "#");
    sv_catpv(out, uri->frag);
  }

  return out;
}

static
void explain(pTHX_ SV* uri_obj) {
  printf("scheme: %s\n",  URI_MEMBER(uri_obj, scheme));
  printf("auth:\n");
  printf("  -usr: %s\n",  URI_MEMBER(uri_obj, usr));
  printf("  -pwd: %s\n",  URI_MEMBER(uri_obj, pwd));
  printf("  -host: %s\n", URI_MEMBER(uri_obj, host));
  printf("  -port: %s\n", URI_MEMBER(uri_obj, port));
  printf("path: %s\n",    URI_MEMBER(uri_obj, path));
  printf("query: %s\n",   URI_MEMBER(uri_obj, query));
  printf("frag: %s\n",    URI_MEMBER(uri_obj, frag));
}

static
SV* new(pTHX_ const char* class, SV* uri_str) {
  const char* src;
  size_t len;
  uri_t* uri;
  SV*    obj;
  SV*    obj_ref;

  Newx(uri, 1, uri_t);
  memset(uri, '\0', sizeof(uri_t));

  obj = newSViv((IV) uri);
  obj_ref = newRV_noinc(obj);
  sv_bless(obj_ref, gv_stashpv(class, GV_ADD));
  SvREADONLY_on(obj);

  SvGETMAGIC(uri_str);

  if (!SvOK(uri_str)) {
    src = "";
    len = 0;
  }
  else {
    src = SvPV_nomg_const(uri_str, len);
  }

  uri_scan(uri, src, len);

  return obj_ref;
}

static
SV* new_iri(pTHX_ const char* class, SV* uri_str) {
  SV* obj = new(aTHX_ "URI::Fast::IRI", uri_str);
  URI_MEMBER(obj, is_iri) = 1;
  return obj;
}

static
void DESTROY(pTHX_ SV* uri_obj) {
  uri_t* uri = (uri_t*) SvIV(SvRV(uri_obj));
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

  SvGETMAGIC(uri);

  if (!SvOK(uri)) {
    src = "";
    len = 0;
  }
  else {
    src = SvPV_nomg_const(uri, len);
  }

  dXSARGS;
  sp = mark;

  // Scheme
  brk = strcspn(&src[idx], ":/@?#");
  if (brk > 0 && strncmp(&src[idx + brk], "://", 3) == 0) {
    XPUSHs(sv_2mortal(newSVpv(&src[idx], brk)));
    idx += brk + 3;

    // Authority
    brk = strcspn(&src[idx], "/?#");
    if (brk > 0) {
      XPUSHs(sv_2mortal(newSVpv(&src[idx], brk)));
      idx += brk;
    } else {
      XPUSHs(sv_2mortal(newSVpv("",0)));
    }
  }
  else {
    XPUSHs(&PL_sv_undef);
    XPUSHs(&PL_sv_undef);
  }

  // path
  brk = strcspn(&src[idx], "?#");
  if (brk > 0) {
    XPUSHs(sv_2mortal(newSVpv(&src[idx], brk)));
    idx += brk;
  } else {
    XPUSHs(sv_2mortal(newSVpv("",0)));
  }

  // query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = strcspn(&src[idx], "#");
    if (brk > 0) {
      XPUSHs(sv_2mortal(newSVpv(&src[idx], brk)));
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
      XPUSHs(sv_2mortal(newSVpv(&src[idx], brk)));
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

#-------------------------------------------------------------------------------
# URL-encoding
#-------------------------------------------------------------------------------
SV* encode(in, ...)
  SV* in
    PREINIT:
      I32* temp;
    CODE:
      temp = PL_markstack_ptr++;
      RETVAL = encode(aTHX_ in);
      PL_markstack_ptr = temp;
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
    RETVAL = new(aTHX_ class, uri_str);
  OUTPUT:
    RETVAL

SV* new_iri(class, uri_str)
  const char* class;
  SV* uri_str
  CODE:
    RETVAL = new_iri(aTHX_ class, uri_str);
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
# Simple getters
#-------------------------------------------------------------------------------
const char* get_scheme(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_scheme(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

const char* get_path(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_path(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

const char* get_query(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_query(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

const char* get_frag(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_frag(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

const char* get_usr(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_usr(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

const char* get_pwd(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_pwd(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

const char* get_host(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_host(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

const char* get_port(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_port(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_auth(uri_obj)
  SV* uri_obj
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

SV* query_hash(uri)
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
const char* set_scheme(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_scheme(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

SV* set_auth(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_auth(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

const char* set_path(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_path(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

const char* set_query(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_query(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

const char* set_frag(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_frag(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

const char* set_usr(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_usr(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

const char* set_pwd(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_pwd(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

const char* set_host(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_host(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

const char* set_port(uri_obj, value)
  SV* uri_obj
  const char* value
  CODE:
    RETVAL = set_port(aTHX_ uri_obj, value);
  OUTPUT:
    RETVAL

void set_param(uri, sv_key, sv_values, separator)
  SV* uri
  SV* sv_key
  SV* sv_values
  const char* separator
  CODE:
    set_param(aTHX_ uri, sv_key, sv_values, separator);


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
