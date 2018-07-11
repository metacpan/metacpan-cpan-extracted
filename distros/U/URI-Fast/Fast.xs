#include "fast.h"
#include "strnspn.c"
#include "query.c"
#include "urlencode.c"

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
  uri_is_iri_t is_iri;
  uri_scheme_t scheme;
  uri_query_t  query;
  uri_path_t   path;
  uri_host_t   host;
  uri_port_t   port;
  uri_frag_t   frag;
  uri_usr_t    usr;
  uri_pwd_t    pwd;
} uri_t;

/*
 * Clearers
 */
static void clear_scheme(pTHX_ SV* uri_obj) { Zero(&((URI(uri_obj))->scheme), 1, uri_scheme_t); }
static void clear_path(pTHX_ SV* uri_obj)   { Zero(&((URI(uri_obj))->path),   1, uri_path_t);   }
static void clear_query(pTHX_ SV* uri_obj)  { Zero(&((URI(uri_obj))->query),  1, uri_query_t);  }
static void clear_frag(pTHX_ SV* uri_obj)   { Zero(&((URI(uri_obj))->frag),   1, uri_frag_t);   }
static void clear_usr(pTHX_ SV* uri_obj)    { Zero(&((URI(uri_obj))->usr),    1, uri_usr_t);    }
static void clear_pwd(pTHX_ SV* uri_obj)    { Zero(&((URI(uri_obj))->pwd),    1, uri_pwd_t);    }
static void clear_host(pTHX_ SV* uri_obj)   { Zero(&((URI(uri_obj))->host),   1, uri_host_t);   }
static void clear_port(pTHX_ SV* uri_obj)   { Zero(&((URI(uri_obj))->port),   1, uri_port_t);   }

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
int uri_scan_auth(pTHX_ uri_t* uri, const char* auth, const size_t len) {
  size_t idx  = 0;
  size_t brk1 = 0;
  size_t brk2 = 0;
  size_t i;
  unsigned char flag;
  int truncated = 0;

  if (len > 0) {
    // Credentials
    brk1 = strncspn(&auth[idx], len - idx, "@");

    if (brk1 > 0 && brk1 != (len - idx)) {
      brk2 = strncspn(&auth[idx], len - idx, ":");

      if (brk2 > 0 && brk2 < brk1) {
        // user
        if (brk2 > URI_SIZE_usr) truncated = 1;
        set_str(uri->usr, &auth[idx], minnum(URI_SIZE_usr, brk2));
        idx += brk2 + 1;

        // password
        if (brk1 - brk2 - 1 > URI_SIZE_pwd) truncated = 1;
        set_str(uri->pwd, &auth[idx], minnum(URI_SIZE_pwd, brk1 - brk2 - 1));
        idx += brk1 - brk2;
      }
      else {
        // user only
        if (brk1 > URI_SIZE_usr) truncated = 1;
        set_str(uri->usr, &auth[idx], minnum(URI_SIZE_usr, brk1));
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
        if (brk1 + 1 > URI_SIZE_host) truncated = 1;
        set_str(uri->host, &auth[idx], minnum(URI_SIZE_host, brk1 + 1));
        idx += brk1 + 1;
        flag = 1;
      }

      if (auth[idx] == ':') {
        ++idx;
      }
    }

    if (flag == 0) {
      brk1 = strncspn(&auth[idx], len - idx, ":");

      if (brk1 > 0 && brk1 != (len - idx)) {
        if (brk1 > URI_SIZE_host) truncated = 1;
        set_str(uri->host, &auth[idx], minnum(URI_SIZE_host, brk1));
        idx += brk1 + 1;
      }
    }

    if (uri->host[0] != '\0') {
      if (len - idx > URI_SIZE_port) truncated = 1;
      for (i = 0; i < (len - idx) && i < URI_SIZE_port; ++i) {
        if (!isdigit(auth[i + idx])) {
          Zero(&uri->port, 1, uri_port_t);
          break;
        }
        else {
          uri->port[i] = auth[i + idx];
        }
      }
    }
    else {
      if (len - idx > URI_SIZE_host) truncated = 1;
      set_str(uri->host, &auth[idx], minnum(URI_SIZE_host, len - idx));
    }
  }

  return truncated;
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
int uri_scan(pTHX_ uri_t *uri, const char *src, size_t len) {
  size_t idx = 0;
  size_t brk;
  size_t i;
  int truncated = 0;

  while (my_isspace(src[idx]) == 1)     ++idx; // Trim leading whitespace
  while (my_isspace(src[len - 1]) == 1) --len; // Trim trailing whitespace

  // Scheme
  brk = strncspn(&src[idx], len - idx, ":/@?#");

  if (brk > 0 && src[idx + brk] == ':') {
    if (brk > URI_SIZE_scheme) truncated = 1;
    set_str(uri->scheme, &src[idx], minnum(URI_SIZE_scheme, brk));
    idx += brk + 1;

    // Authority section following scheme must be separated by //
    if (src[idx] == '/' && src[idx + 1] == '/') {
      idx += 2;
    }
  }

  // Authority
  brk = strncspn(&src[idx], len - idx, "/?#");
  if (brk > 0) {
    if (uri_scan_auth(aTHX_ uri, &src[idx], brk)) truncated = 1;
    idx += brk;
  }

  // path
  brk = strncspn(&src[idx], len - idx, "?#");
  if (brk > 0) {
    if (brk > URI_SIZE_path) truncated = 1;
    set_str(uri->path, &src[idx], minnum(URI_SIZE_path, brk));
    idx += brk;
  }

  // query
  if (src[idx] == '?') {
    ++idx; // skip past ?
    brk = strncspn(&src[idx], len - idx, "#");
    if (brk > 0) {
      if (brk > URI_SIZE_query) truncated = 1;
      set_str(uri->query, &src[idx], minnum(URI_SIZE_query, brk));
      idx += brk;
    }
  }

  // fragment
  if (src[idx] == '#') {
    ++idx; // skip past #
    brk = len - idx;
    if (brk > 0) {
      if (brk > URI_SIZE_frag) truncated = 1;
      set_str(uri->frag, &src[idx], minnum(URI_SIZE_frag, brk));
    }
  }

  return truncated;
}

/*
 * Perl API
 */

/*
 * Getters
 */
static const char* get_scheme(pTHX_ SV* uri_obj) { return URI_MEMBER(uri_obj, scheme); }
static const char* get_query(pTHX_ SV* uri_obj)  { return URI_MEMBER(uri_obj, query);  }
static const char* get_frag(pTHX_ SV* uri_obj)   { return URI_MEMBER(uri_obj, frag);   }
static const char* get_usr(pTHX_ SV* uri_obj)    { return URI_MEMBER(uri_obj, usr);    }
static const char* get_pwd(pTHX_ SV* uri_obj)    { return URI_MEMBER(uri_obj, pwd);    }
static const char* get_host(pTHX_ SV* uri_obj)   { return URI_MEMBER(uri_obj, host);   }
static const char* get_port(pTHX_ SV* uri_obj)   { return URI_MEMBER(uri_obj, port);   }

static
SV* get_path(pTHX_ SV *uri_obj) {
  const char *in = URI_MEMBER(uri_obj, path);
  size_t ilen = strlen(in);

  char buf[ilen + 1];
  size_t len = uri_decode(in, ilen, buf, "/");

  SV* out = newSVpvn(buf, len);
  sv_utf8_decode(out);

  return out;
}

static
SV* get_auth(pTHX_ SV* uri_obj) {
  uri_t* uri = URI(uri_obj);
  SV* out = newSVpvn("", 0);

  if (uri->is_iri) {
    SvUTF8_on(out);
  }

  if (uri->usr[0] != '\0') {
    if (uri->pwd[0] != '\0') {
      sv_catpv(out, uri->usr);
      sv_catpvn(out, ":", 1);
      sv_catpv(out, uri->pwd);
      sv_catpvn(out, "@", 1);
    } else {
      sv_catpv(out, uri->usr);
      sv_catpvn(out, "@", 1);
    }
  }

  if (uri->host[0] != '\0') {
    if (uri->port[0] != '\0') {
      sv_catpv(out, uri->host);
      sv_catpvn(out, ":", 1);
      sv_catpv(out, uri->port);
    } else {
      sv_catpv(out, uri->host);
    }
  }

  return out;
}

static
SV* split_path(pTHX_ SV* uri) {
  size_t len, segment_len, brk, idx = 0;
  AV* arr = newAV();
  SV* tmp;

  const char *str = URI_MEMBER(uri, path);
  len = strlen(str);

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

  return newRV_noinc((SV*) arr);
}

static
SV* get_query_keys(pTHX_ SV* uri) {
  char* query = URI_MEMBER(uri, query);
  size_t klen, qlen = strlen(query);
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
  char* query = URI_MEMBER(uri, query);
  size_t qlen = strlen(query), klen, vlen;
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
  char* query = URI_MEMBER(uri, query);
  const char *key;
  size_t qlen = strlen(query), klen, vlen, elen;
  uri_query_scanner_t scanner;
  uri_query_token_t token;
  AV* out = newAV();
  SV* value;

  // Read key to search
  SvGETMAGIC(sv_key);

  if (!SvOK(sv_key)) {
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

/*
 * Setters
 */
URI_SIMPLE_SETTER(scheme, "");
URI_SIMPLE_SETTER(path,   URI_CHARS_PATH);
URI_SIMPLE_SETTER(query,  URI_CHARS_QUERY);
URI_SIMPLE_SETTER(frag,   URI_CHARS_FRAG);
URI_SIMPLE_SETTER(usr,    URI_CHARS_USER);
URI_SIMPLE_SETTER(pwd,    URI_CHARS_USER);
URI_SIMPLE_SETTER(host,   URI_CHARS_HOST);

static
void set_port(pTHX_ SV* uri_obj, const char* value) {
  size_t i, len = strlen(value);
  int truncated = len > URI_SIZE_port ? 1 : 0;

  for (i = 0; i < minnum(URI_SIZE_port, len); ++i) {
    if (isdigit(value[i])) {
      URI_MEMBER(uri_obj, port)[i] = value[i];
    }
    else {
      clear_port(aTHX_ uri_obj);
      break;
    }
  }

  if (truncated)
    croak("set_port: input string is larger than supported by URI::Fast");
}

static
void set_auth(pTHX_ SV *uri_obj, const char *value) {
  Zero(URI_MEMBER(uri_obj, usr),  URI_SIZE_usr, char);
  Zero(URI_MEMBER(uri_obj, pwd),  URI_SIZE_pwd, char);
  Zero(URI_MEMBER(uri_obj, host), URI_SIZE_host, char);
  Zero(URI_MEMBER(uri_obj, port), URI_SIZE_port, char);

  // auth isn't stored as an individual field, so encode to local array and rescan
  char auth[URI_SIZE_auth];
  size_t len = uri_encode(value, strlen(value), (char*) &auth, URI_CHARS_AUTH, URI_MEMBER(uri_obj, is_iri));

  if (uri_scan_auth(aTHX_ URI(uri_obj), auth, len)) {
    croak("set_auth: one or more authority section inputs is larger than supported by URI::Fast");
  }
}

static
void set_path_array(pTHX_ SV *uri_obj, SV *sv_path) {
  SV **refval, *tmp;
  AV *av_path;
  size_t i, av_idx, seg_len, wrote, idx;
  const char *seg;
  char out[URI_SIZE_path];

  // Inspect input array
  av_path = (AV*) SvRV(sv_path);
  av_idx  = av_top_index(av_path);

  idx = 0;

  // Build the new path
  for (i = 0; i <= av_idx; ++i) {
    // Add separator. If the next value fetched from the array is invalid, it
    // just gets an empty segment.
    out[idx++] = '/';

    // Fetch next segment
    refval = av_fetch(av_path, (SSize_t) i, 0);
    if (refval == NULL) continue;
    if (!SvOK(*refval)) continue;

    // Copy value over
    SvGETMAGIC(*refval);

    if (SvOK(*refval)) {
      seg = SvPV_nomg_const(*refval, seg_len);

      // Convert octets to utf8 if necessary
      if (!DO_UTF8(*refval)) {
        tmp = sv_2mortal(newSVpvn(seg, seg_len));
        sv_utf8_encode(tmp);
        seg = SvPV_const(tmp, seg_len);
      }

      idx += uri_encode(seg, seg_len, &out[idx], URI_CHARS_PATH_SEGMENT, URI_MEMBER(uri_obj, is_iri));
    }
  }

  out[idx++] = '\0';
  Copy(out, URI_MEMBER(uri_obj, path), minnum(URI_SIZE_path, idx), char);

  if (idx > URI_SIZE_path) {
    croak("set_path_array: input is larger than supported by URI::Fast");
  }
}

static
void update_query_keyset(pTHX_ SV *uri, SV *sv_key_set, char separator) {
  HE     *ent;
  HV     *keys, *enc_keys;
  I32    iterlen, i, klen;
  SV     *val, **refval;
  bool   copy;
  char   *key, *query = URI_MEMBER(uri, query);
  char   dest[URI_SIZE_query];
  int    is_iri = URI_MEMBER(uri, is_iri);
  size_t off = 0, qlen = strlen(query);

  uri_query_scanner_t scanner;
  uri_query_token_t   token;

  // Validate reference parameters
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
  query_scanner_init(&scanner, query, qlen);

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
        dest[off++] = separator;
      }

      set_str(&dest[off], token.key, token.key_length);
      off += token.key_length;

      if (token.type == PARAM) {
        dest[off++] = '=';
        set_str(&dest[off], token.value, token.value_length);
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
        dest[off++] = separator;
      }

      set_str(&dest[off], key, klen);
      off += klen;
    }
  }

  dest[off++] = '\0';

  clear_query(aTHX_ uri);
  set_str(URI_MEMBER(uri, query), dest, minnum(URI_SIZE_query, off));

  if (off > URI_SIZE_query) {
    croak("update_query_keyset: input is larger than supported by URI::Fast");
  }
}

static
void set_param(pTHX_ SV* uri, SV* sv_key, SV* sv_values, char separator) {
  int    is_iri = URI_MEMBER(uri, is_iri);
  char   *key, *strval, *query = URI_MEMBER(uri, query);
  size_t qlen = strlen(query), klen, vlen, slen, av_idx, i = 0, off = 0;
  char   dest[URI_SIZE_query];
  AV     *av_values;
  SV     **refval;
  uri_query_scanner_t scanner;
  uri_query_token_t token;

  // Build encoded key string
  SvGETMAGIC(sv_key);
  key = SvPV_nomg(sv_key, klen);
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
  query_scanner_init(&scanner, query, qlen);

  while (!query_scanner_done(&scanner)) {
    query_scanner_next(&scanner, &token);
    if (token.type == DONE) continue;

    // The key does not match the key being set
    if (strncmp(enc_key, token.key, maxnum(klen, token.key_length)) != 0) {
      // Add separator if this is not the first key being written
      if (off > 0) {
        dest[off++] = separator;
      }

      // Write the key to the buffer
      set_str(&dest[off], token.key, token.key_length);
      off += token.key_length;

      // The key has a value
      if (token.type == PARAM) {
        dest[off++] = '=';

        // If the value's length is 0, it was parsed from "key=", so the value
        // is not written after the '=' is added above.
        if (token.value_length > 0) {
          // Otherwise, write the value to the buffer
          set_str(&dest[off], token.value, token.value_length);
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
    if (!SvOK(*refval)) break;

    // Break out after hitting the limit of the query slot
    if (off == URI_SIZE_query) break;

    // Add separator if needed to separate pairs
    if (off > 0) dest[off++] = separator;

    // Break out early if this key would overflow the struct member
    if (off + klen + 1 > URI_SIZE_query) break;

    // Copy key over
    set_str(&dest[off], enc_key, klen);
    off += klen;

    dest[off++] = '=';

    // Copy value over
    SvGETMAGIC(*refval);
    strval = SvPV_nomg(*refval, slen);

    vlen = uri_encode(strval, slen, &dest[off], ":@?/", is_iri);
    off += vlen;
  }

  clear_query(aTHX_ uri);
  set_str(URI_MEMBER(uri, query), dest, minnum(URI_SIZE_query, off));

  if (off > URI_SIZE_query) {
    croak("set_param: input is larger than supported by URI::Fast");
  }
}

/*
 * Other stuff
 */

static
SV* to_string(pTHX_ SV* uri_obj) {
  uri_t *uri = URI(uri_obj);
  SV *out = newSVpvn("", 0);
  SV *auth = get_auth(aTHX_ uri_obj);

  if (uri->is_iri) {
    SvUTF8_on(out);
  }

  if (uri->scheme[0] != '\0') {
    sv_catpv(out, uri->scheme);
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
    if (uri->path[0] != '\0' && uri->path[0] != '/') {
      sv_catpvn(out, "/", 1);
    }
  }

  sv_catpv(out, uri->path);

  if (uri->query[0] != '\0') {
    sv_catpvn(out, "?", 1);
    sv_catpv(out, uri->query);
  }

  if (uri->frag[0] != '\0') {
    sv_catpvn(out, "#", 1);
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
void debug(pTHX_ SV* uri_obj) {
  warn("scheme: %s\n",  URI_MEMBER(uri_obj, scheme));
  warn("auth:\n");
  warn("  -usr: %s\n",  URI_MEMBER(uri_obj, usr));
  warn("  -pwd: %s\n",  URI_MEMBER(uri_obj, pwd));
  warn("  -host: %s\n", URI_MEMBER(uri_obj, host));
  warn("  -port: %s\n", URI_MEMBER(uri_obj, port));
  warn("path: %s\n",    URI_MEMBER(uri_obj, path));
  warn("query: %s\n",   URI_MEMBER(uri_obj, query));
  warn("frag: %s\n",    URI_MEMBER(uri_obj, frag));
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
  //Zero(uri, 1, uri_t);
  memset(uri, '\0', sizeof(uri_t));
  uri->is_iri = is_iri;

  // Build the blessed instance
  obj = newSViv((IV) uri);
  obj_ref = newRV_noinc(obj);
  sv_bless(obj_ref, gv_stashpv(class, GV_ADD));
  SvREADONLY_on(obj);

  // Scan the input string to fill the struct
  SvGETMAGIC(uri_str);

  if (!SvOK(uri_str)) {
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

  if (uri_scan(aTHX_ uri, src, len)) {
    croak("uri: one or more sections of the URI input string were larger than supported by URI::Fast");
  }

  return obj_ref;
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
# Simple getters
#-------------------------------------------------------------------------------
const char* get_scheme(uri_obj)
  SV* uri_obj
  CODE:
    RETVAL = get_scheme(aTHX_ uri_obj);
  OUTPUT:
    RETVAL

SV* get_path(uri_obj)
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
  SV *uri_obj
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
  const char *value
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
  const char *value
  CODE:
    set_port(aTHX_ uri_obj, value);

void set_param(uri, sv_key, sv_values, separator)
  SV* uri
  SV* sv_key
  SV* sv_values
  char separator
  CODE:
    set_param(aTHX_ uri, sv_key, sv_values, separator);

void update_query_keyset(uri, sv_key_set, separator)
  SV* uri
  SV* sv_key_set
  char separator
  CODE:
    update_query_keyset(aTHX_ uri, sv_key_set, separator);

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
