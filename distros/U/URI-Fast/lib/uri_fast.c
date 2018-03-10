#include "perl.h"
#include <stdlib.h>
#include <string.h>

/*
 * Allocate memory with Newx if it's
 * available - if it's an older perl
 * that doesn't have Newx then we
 * resort to using New.
 * */
#ifndef Newx
#define Newx(v,n,t) New(0,v,n,t)
#endif

// av_top_index not available on Perls < 5.18
#ifndef av_top_index
#define av_top_index(av) av_len(av)
#endif

#ifndef Uri
#define Uri(obj) ((uri_t*) SvIV(SvRV(obj)))
#endif

#ifndef Uri_Mem
#define Uri_Mem(obj, member) (Uri(obj)->member)
#endif

/*
 * Percent encoding
 */

inline
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

size_t uri_encode(const char* in, size_t len, char* out, const char* allow, size_t allow_len) {
  size_t i = 0;
  size_t j = 0;
  char   octet;
  U32    code;

  if (len == 0) {
    len = strlen((char*) in);
  }

  while (i < len) {
    octet = in[i++];

    if (is_allowed(octet, allow, allow_len)) {
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

size_t uri_decode(const char *in, size_t len, char *out) {
  size_t i = 0, j = 0;
  unsigned char v1, v2;
  int copy_char;

  if (len == 0) {
    len = strlen((char*) in);
  }

  while (i < len) {
    copy_char = 1;

    if (in[i] == '+') {
      out[j] = ' ';
      ++i;
      ++j;
      copy_char = 0;
    }
    else if (in[i] == '%' && i + 2 < len) {
      v1 = hex[ (unsigned char)in[i+1] ];
      v2 = hex[ (unsigned char)in[i+2] ];

      /* skip invalid hex sequences */
      if ((v1 | v2) != 0xFF) {
        out[j] = (v1 << 4) | v2;
        ++j;
        i += 3;
        copy_char = 0;
      }
    }
    if (copy_char) {
      out[j] = in[i];
      ++i;
      ++j;
    }
  }

  out[j] = '\0';

  return j;
}

// EOT (end of theft)

SV* encode(SV* in, ...) {
  size_t ilen, olen, alen;
  const char *allowed;
  const char *src = SvPV_const(in, ilen);
  char dest[(ilen * 3) + 1];
  SV* out;

  Inline_Stack_Vars;

  if (Inline_Stack_Items > 1) {
    allowed = SvPV(Inline_Stack_Item(1), alen);
  } else {
    allowed = "";
    alen = 0;
  }

  Inline_Stack_Done;

  olen = uri_encode(src, ilen, dest, allowed, alen);
  out  = newSVpv(dest, olen);
  sv_utf8_downgrade(out, FALSE);

  return out;
}

SV* decode(SV* in) {
  size_t ilen, olen;
  const char* src;
  SV*   out;

  if (SvUTF8(in)) {
    in = sv_mortalcopy(in);

    SvUTF8_on(in);

    if (!sv_utf8_downgrade(in, TRUE)) {
      croak("decode: wide character in octet string");
    }

    src = SvPV_const(in, ilen);
  }
  else {
    src = SvPV_const(in, ilen);
  }

  char dest[ilen + 1];

  olen = uri_decode(src, ilen, dest);
  out  = newSVpv(dest, olen);
  SvUTF8_on(out);

  return out;
}

/*
 * Internal API
 */

typedef struct {
  char scheme[16];
  char auth[264];
  char path[256];
  char query[1024];
  char frag[32];

  char usr[64];
  char pwd[64];
  char host[128];
  char port[8];
} uri_t;

/*
 * Clearers
 *   -note that these do not do other related cleanup (e.g. clearing auth triggering
 *    the clearing of usr/pwd/host/port)
 */
void clear_scheme(SV* uri_obj) { memset(&((Uri(uri_obj))->scheme), '\0', 16);   }
void clear_auth(SV* uri_obj)   { memset(&((Uri(uri_obj))->auth),   '\0', 264);  }
void clear_path(SV* uri_obj)   { memset(&((Uri(uri_obj))->path),   '\0', 256);  }
void clear_query(SV* uri_obj)  { memset(&((Uri(uri_obj))->query),  '\0', 1024); }
void clear_frag(SV* uri_obj)   { memset(&((Uri(uri_obj))->frag),   '\0', 32);   }
void clear_usr(SV* uri_obj)    { memset(&((Uri(uri_obj))->usr),    '\0', 64);   }
void clear_pwd(SV* uri_obj)    { memset(&((Uri(uri_obj))->pwd),    '\0', 64);   }
void clear_host(SV* uri_obj)   { memset(&((Uri(uri_obj))->host),   '\0', 128);  }
void clear_port(SV* uri_obj)   { memset(&((Uri(uri_obj))->port),   '\0', 8);    }

/*
 * Scans the authorization portion of the Uri string. This must only be called
 * *after* the 'auth' member has been populated (eg, by uri_scan).
 */
void uri_scan_auth (uri_t* uri) {
  size_t len  = strlen((char*) uri->auth);
  size_t idx  = 0;
  size_t brk1 = 0;
  size_t brk2 = 0;

  memset(&uri->usr,  '\0', 64);
  memset(&uri->pwd,  '\0', 64);
  memset(&uri->host, '\0', 128);
  memset(&uri->port, '\0', 8);

  if (len > 0) {
    // Credentials
    brk1 = strcspn(&uri->auth[idx], "@");

    if (brk1 > 0 && brk1 != len) {
      brk2 = strcspn(&uri->auth[idx], ":");

      if (brk2 > 0 && brk2 < brk1) {
        strncpy(uri->usr, &uri->auth[idx], brk2);
        idx += brk2 + 1;

        strncpy(uri->pwd, &uri->auth[idx], brk1 - brk2 - 1);
        idx += brk1 - brk2;
      }
      else {
        strncpy(uri->usr, &uri->auth[idx], brk1);
        idx += brk1 + 1;
      }
    }

    // Location
    brk1 = strcspn(&uri->auth[idx], ":");

    if (brk1 > 0 && brk1 != (len - idx)) {
      strncpy(uri->host, &uri->auth[idx], brk1);
      idx += brk1 + 1;
      strncpy(uri->port, &uri->auth[idx], len - idx);
    }
    else {
      strncpy(uri->host, &uri->auth[idx], len - idx);
    }
  }
}

/*
 * Scans a Uri string and populates the uri_t struct.
 */
void uri_scan(uri_t* uri, const char* src, size_t len) {
  size_t idx = 0;
  size_t brk = 0;

  // Scheme
  brk = strcspn(&src[idx], ":/@?#");
  if (brk > 0 && strncmp(&src[idx + brk], "://", 3) == 0) {
    strncpy(uri->scheme, &src[idx], brk);
    uri->scheme[brk] = '\0';
    idx += brk + 3;

    // Authority
    brk = strcspn(&src[idx], "/?#");
    if (brk > 0) {
      strncpy(uri->auth, &src[idx], brk);
      uri->auth[brk] = '\0';
      idx += brk;
    }
  }

  // Path
  brk = strcspn(&src[idx], "?#");
  if (brk > 0) {
    strncpy(uri->path, &src[idx], brk);
    uri->path[brk] = '\0';
    idx += brk;
  }

  // Query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = strcspn(&src[idx], "#");
    if (brk > 0) {
      strncpy(uri->query, &src[idx], brk);
      uri->query[brk] = '\0';
      idx += brk;
    }
  }

  // Fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      strncpy(uri->frag, &src[idx], brk);
      uri->frag[brk] = '\0';
    }
  }
}

/*
 * Rebuilds the authority string: username:password@hostname:portnumber
 */
void uri_build_auth(uri_t* uri) {
  size_t len = 0;
  int idx = 0;

  memset(&uri->auth, '\0', 264);

  if (uri->usr[0] != '\0') {
    len = strlen((char*) &uri->usr);
    strncpy(&uri->auth[idx], (char*) &uri->usr, len);
    idx += len;

    if (uri->pwd[0] != '\0') {
      len = strlen((char*) &uri->pwd);
      uri->auth[idx++] = ':';
      strncpy(&uri->auth[idx], (char*) &uri->pwd, len);
      idx += len;
    }

    uri->auth[idx++] = '@';
  }

  if (uri->host[0] != '\0') {
    len = strlen((char*) &uri->host);
    strncpy(&uri->auth[idx], (char*) &uri->host, len);
    idx += len;

    if (uri->port[0] != '\0') {
      len = strlen((char*) &uri->port);
      uri->auth[idx++] = ':';
      strncpy(&uri->auth[idx], (char*) &uri->port, len);
      idx += len;
    }
  }

  uri->auth[idx++] = '\0';
}

/*
 * Perl API
 */

/*
 * Getters
 */
const char* get_scheme(SV* uri_obj) { return Uri_Mem(uri_obj, scheme); }
const char* get_auth(SV* uri_obj)   { return Uri_Mem(uri_obj, auth); }
const char* get_path(SV* uri_obj)   { return Uri_Mem(uri_obj, path); }
const char* get_query(SV* uri_obj)  { return Uri_Mem(uri_obj, query); }
const char* get_frag(SV* uri_obj)   { return Uri_Mem(uri_obj, frag); }
const char* get_usr(SV* uri_obj)    { return Uri_Mem(uri_obj, usr); }
const char* get_pwd(SV* uri_obj)    { return Uri_Mem(uri_obj, pwd); }
const char* get_host(SV* uri_obj)   { return Uri_Mem(uri_obj, host); }
const char* get_port(SV* uri_obj)   { return Uri_Mem(uri_obj, port); }

SV* query_hash(SV* uri) {
  const char* src = Uri_Mem(uri, query);
  size_t klen, vlen, idx;
  HV*  out = newHV();
  AV*  arr;
  SV** ref;
  SV*  tmp;

  while (src != NULL && src[0] != '\0') {
    idx = strcspn(src, "=");
    char key[idx + 1];
    klen = uri_decode(src, idx, key);

    src = strstr(src, "=");
    src += 1;

    idx = strcspn(src, "&");
    char val[idx + 1];
    vlen = uri_decode(src, idx, val);

    tmp = newSVpv(val, vlen);
    SvUTF8_on(tmp);

    if (!hv_exists(out, key, klen)) {
      arr = newAV();
      hv_store(out, key, klen, newRV_noinc((SV*) arr), 0);
    }
    else {
      ref = hv_fetch(out, key, klen, 0);
      if (ref == NULL) croak("query_form: something went wrong");
      arr = (AV*) SvRV(*ref);
    }

    av_push(arr, tmp);

    src = strstr(src, "&");
    if (src == NULL) break;
    ++src;
  }

  return newRV_noinc((SV*) out);
}

SV* split_path(SV* uri) {
  size_t brk, idx = 0;
  AV* arr = newAV();
  SV* tmp;

  size_t path_len = strlen(Uri_Mem(uri, path));
  char str[path_len + 1];
  size_t len = uri_decode(Uri_Mem(uri, path), path_len, str);

  if (str[0] == '/') {
    ++idx; // skip past leading /
  }

  while (idx < len) {
    brk = strcspn(&str[idx], "/");
    tmp = newSVpv(&str[idx], brk);
    SvUTF8_on(tmp);
    av_push(arr, tmp);
    idx += brk + 1;
  }

  return newRV_noinc((SV*) arr);
}

SV* get_query_keys(SV* uri) {
  const char* src;
  size_t vlen, idx;
  HV* out = newHV();

  for (src = Uri_Mem(uri, query); src != NULL && src[0] != '\0'; src = strstr(src, "&")) {
    if (src[0] == '&') {
      ++src;
    }

    idx = strcspn(src, "=");
    char tmp[idx + 1];
    vlen = uri_decode(src, idx, tmp);
    hv_store(out, tmp, vlen, &PL_sv_undef, 0);
  }

  return newRV_noinc((SV*) out);
}

SV* get_param(SV* uri, const char* key) {
  const char *tmp, *src = Uri_Mem(uri, query);
  char haystack[1024], needle[32];
  size_t klen, vlen, idx;
  char* ptr;
  AV* out = newAV();
  SV* val;

  needle[0] = '&';
  klen = 1 + uri_encode(key, 0, &needle[1], "", 0);
  needle[klen++] = '=';
  needle[klen] = '\0';

  memset(haystack, '\0', 1024);
  sprintf(haystack, "&%s", Uri_Mem(uri, query));

  for (ptr = strstr(haystack, needle); ptr != NULL; ptr = strstr(ptr, needle)) {
    ptr += klen;
    idx = strcspn(ptr, "&");

    char tmp[idx + 1];
    vlen = uri_decode(ptr, idx, tmp);
    val = newSVpv(tmp, vlen);
    SvUTF8_on(val);
    av_push(out, val);
  }

  return newRV_noinc((SV*) out);
}

/*
 * Setters
 */

const char* set_scheme(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, scheme), "", 0);
  return Uri_Mem(uri_obj, scheme);
}

const char* set_auth(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, auth), ":@", 2);
  if (!no_triggers) uri_scan_auth(Uri(uri_obj));
  return Uri_Mem(uri_obj, auth);
}

const char* set_path(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, path), "/", 1);
  return Uri_Mem(uri_obj, path);
}

const char* set_query(SV* uri_obj, const char* value, int no_triggers) {
  strncpy(Uri_Mem(uri_obj, query), value, strlen(value) + 1);
  return value;
}

const char* set_frag(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, frag), "", 0);
  return Uri_Mem(uri_obj, frag);
}

const char* set_usr(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, usr), "", 0);
  if (!no_triggers) uri_build_auth(Uri(uri_obj));
  return Uri_Mem(uri_obj, usr);
}

const char* set_pwd(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, pwd), "", 0);
  if (!no_triggers) uri_build_auth(Uri(uri_obj));
  return Uri_Mem(uri_obj, pwd);
}

const char* set_host(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, host), "", 0);
  if (!no_triggers) uri_build_auth(Uri(uri_obj));
  return Uri_Mem(uri_obj, host);
}

const char* set_port(SV* uri_obj, const char* value, int no_triggers) {
  uri_encode(value, 0, Uri_Mem(uri_obj, port), "", 0);
  if (!no_triggers) uri_build_auth(Uri(uri_obj));
  return Uri_Mem(uri_obj, port);
}

void set_param(SV* uri, const char* key, SV* sv_values) {
  char   dest[1024];
  const  char *src = Uri_Mem(uri, query), *strval;
  size_t klen, vlen, slen, qlen = strlen(src), avlen, i = 0, j = 0, brk = 0;
  AV*    av_values;
  SV**   ref;

  char enckey[(3 * strlen(key)) + 1];
  klen = uri_encode(key, 0, enckey, "", 0);

  av_values = (AV*) SvRV(sv_values);
  avlen = av_top_index(av_values);

  // Copy the old query, skipping the key to be updated
  while (i < qlen) {
    // If the string does not begin with the key, advance until it does,
    // copying into dest as idx advances.
    while (strncmp(&src[i], enckey, klen) != 0) {
      // Find the end of this key=value section
      brk = strcspn(&src[i], "&");

      // If this is not the first key=value section written to dest, add an
      // ampersand to separate the pairs.
      if (j > 0) dest[j++] = '&';

      // Copy up to our break point
      strncpy(&dest[j], &src[i], brk);
      j += brk;
      i += brk;

      if (i >= qlen) break;
      if (src[i] == '&') ++i;
    }

    // The key was found; skip past to the next key=value pair
    i += strcspn(&src[i], "&");

    // Skip the '&', too, since it will already be there
    if (src[i] == '&') ++i;
  }

  for (i = 0; i <= avlen; ++i) {
    // Fetch next value from the array
    ref = av_fetch(av_values, (SSize_t) i, 0);
    if (ref == NULL) break;
    if (!SvOK(*ref)) break;

    // Add ampersand if needed to separate pairs
    if (j > 0) dest[j++] = '&';

    // Copy key over
    strncpy(&dest[j], enckey, klen);
    j += klen;

    dest[j++] = '=';

    // Copy value over
    strval = SvPV(*ref, slen);
    vlen = uri_encode(strval, slen, &dest[j], "", 0);
    j += vlen;
  }

  clear_query(uri);
  strncpy(Uri_Mem(uri, query), dest, j);
}

/*
 * Other stuff
 */

SV* to_string(SV* uri_obj) {
  uri_t* uri = Uri(uri_obj);
  SV*    out = newSVpv("", 0);

  sv_catpv(out, uri->scheme);
  sv_catpv(out, "://");
  sv_catpv(out, uri->auth);
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

void explain(SV* uri_obj) {
  printf("scheme: %s\n",  Uri_Mem(uri_obj, scheme));
  printf("auth: %s\n",    Uri_Mem(uri_obj, auth));
  printf("  -usr: %s\n",  Uri_Mem(uri_obj, usr));
  printf("  -pwd: %s\n",  Uri_Mem(uri_obj, pwd));
  printf("  -host: %s\n", Uri_Mem(uri_obj, host));
  printf("  -port: %s\n", Uri_Mem(uri_obj, port));
  printf("path: %s\n",    Uri_Mem(uri_obj, path));
  printf("query: %s\n",   Uri_Mem(uri_obj, query));
  printf("frag: %s\n",    Uri_Mem(uri_obj, frag));
}

SV* new(const char* class, SV* uri_str) {
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

  src = SvPV_const(uri_str, len);
  uri_scan(uri, src, len);
  uri_scan_auth(uri);

  return obj_ref;
}

void DESTROY(SV* uri_obj) {
  uri_t* uri = (uri_t*) SvIV(SvRV(uri_obj));
  Safefree(uri);
}

/*
 * Extras
 */
void uri_split(SV* uri) {
  size_t idx = 0;
  size_t brk = 0;
  size_t len;
  const char* src = SvPV_const(uri, len);

  Inline_Stack_Vars;
  Inline_Stack_Reset;

  // Scheme
  brk = strcspn(&src[idx], ":/@?#");
  if (brk > 0 && strncmp(&src[idx + brk], "://", 3) == 0) {
    Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
    idx += brk + 3;

    // Authority
    brk = strcspn(&src[idx], "/?#");
    if (brk > 0) {
      Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
      idx += brk;
    } else {
      Inline_Stack_Push(sv_2mortal(newSVpv("",0)));
    }
  }
  else {
    Inline_Stack_Push(&PL_sv_undef);
    Inline_Stack_Push(&PL_sv_undef);
  }

  // Path
  brk = strcspn(&src[idx], "?#");
  if (brk > 0) {
    Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
    idx += brk;
  } else {
    Inline_Stack_Push(sv_2mortal(newSVpv("",0)));
  }

  // Query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = strcspn(&src[idx], "#");
    if (brk > 0) {
      Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
      idx += brk;
    } else {
      Inline_Stack_Push(&PL_sv_undef);
    }
  } else {
    Inline_Stack_Push(&PL_sv_undef);
  }

  // Fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      Inline_Stack_Push(sv_2mortal(newSVpv(&src[idx], brk)));
    } else {
      Inline_Stack_Push(&PL_sv_undef);
    }
  } else {
    Inline_Stack_Push(&PL_sv_undef);
  }

  Inline_Stack_Done;
}

