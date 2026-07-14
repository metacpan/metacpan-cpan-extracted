#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

#if !defined(__cplusplus) && defined(_MSC_VER) && _MSC_VER < 1900
#  define inline __inline
#endif

#define UTF8_VALID_STREAM_PROBE_WINDOW_SIZE 1024

#include "utf8_dfa32.h"
#include "utf8_valid.h"
#include "utf8_valid_stream.h"
#include "utf8_distance_unsafe.h"
#include "utf8_advance_forward_unsafe.h"

#ifndef WARN_NON_UNICODE
# define WARN_NON_UNICODE WARN_UTF8
# define WARN_NONCHAR WARN_UTF8
# define WARN_SURROGATE WARN_UTF8
#endif

#ifndef SvPVCLEAR  
# define SvPVCLEAR(sv) sv_setpvs((sv), "")
#endif

#ifndef O_BINARY
# define O_BINARY 0
#endif

static inline STRLEN
xs_utf8_check(const U8 *src, STRLEN len) {
  STRLEN off;
  utf8_check_ascii((const char *)src, len, &off);
  return off;
};

static void
xs_report_unmappable(pTHX_ const UV cp, const STRLEN pos) {
  const char *fmt;
  U32 cat;

  if (cp > 0x10FFFF) {
    fmt = "Can't represent super code point \\x{%"UVXf"} in position %"UVuf;
    cat = WARN_NON_UNICODE;
  }
  else if ((cp & 0xF800) == 0xD800) {
    fmt = "Can't represent surrogate code point U+%"UVXf" in position %"UVuf;
    cat = WARN_SURROGATE;
  }
  else {
    fmt = "Can't represent code point U+%04"UVXf" in position %"UVuf;
    cat = WARN_UTF8;
  }

#if PERL_REVISION == 5 && PERL_VERSION >= 14
  Perl_ck_warner_d(aTHX_ packWARN(cat), fmt, cp, (UV)pos);
#else
  Perl_warner(aTHX_ packWARN(cat), fmt, cp, (UV)pos);
#endif
}

static void
xs_report_illformed(pTHX_ const U8 *s, STRLEN len, const char *enc, STRLEN pos, const bool fatal) {
  static const char *fmt = "Can't decode ill-formed %s octet sequence <%s> in position %"UVuf;
  static const char *hex = "0123456789ABCDEF";
  char seq[20 * 3 + 4];
  char *d = seq, *dstop = d + sizeof(seq) - 4;

  while (len-- > 0) {
    const U8 c = *s++;
    *d++ = hex[c >> 4];
    *d++ = hex[c & 15];
    if (len) {
      *d++ = ' ';
      if (d == dstop) {
        *d++ = '.', *d++ = '.', *d++ = '.';
        break;
      }
    }
  }
  *d = 0;

  if (fatal)
    Perl_croak(aTHX_ fmt, enc, seq, (UV)pos);
  else
    Perl_warner(aTHX_ packWARN(WARN_UTF8), fmt, enc, seq, (UV)pos);
}

static void
xs_report_illformed_read(pTHX_ const char* cur, STRLEN len, bool eof) {
  static const char hex[] = "0123456789ABCDEF";
  char seq[4 * 3];
  char* d = seq;
  STRLEN n = len;
  const char* fmt =
      eof ? "Can't decode ill-formed UTF-8 octet sequence <%s> at end of file"
          : "Can't decode ill-formed UTF-8 octet sequence <%s>";

  while (n-- > 0) {
    const U8 c = (U8)*cur++;
    *d++ = hex[c >> 4];
    *d++ = hex[c & 0xF];
    if (n)
      *d++ = ' ';
  }
  *d = '\0';
  Perl_warner(aTHX_ packWARN(WARN_UTF8), fmt, seq);
}

static void
xs_utf8_encode_native(pTHX_ SV *, const U8 *, STRLEN, const bool);

static void
xs_handle_fallback(pTHX_ SV *dsv, CV *fallback, SV *val, UV usv, STRLEN pos) {
  dSP;
  SV *str;
  const char *src;
  STRLEN len;
  int count;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHs(val);
  mPUSHu(usv);
  mPUSHu((UV)pos);
  PUTBACK;

  count = call_sv((SV *)fallback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("expected 1 return value from fallback sub, got %d\n", count);

  str = POPs;
  src = SvPV_const(str, len);
  if (SvUTF8(str))
    sv_catpvn_nomg(dsv, src, len); /* XXX validate? */
  else
    xs_utf8_encode_native(aTHX_ dsv, (const U8 *)src, len, TRUE);

  PUTBACK;
  FREETMPS;
  LEAVE;
}

static void
xs_utf8_decode_replace(pTHX_ SV *dsv, const U8 *src, STRLEN len, STRLEN off, CV *fallback) {
  const bool do_warn = ckWARN_d(WARN_UTF8);

  STRLEN pos = 0;
  STRLEN skip;

  (void)SvUPGRADE(dsv, SVt_PV);
  (void)SvGROW(dsv, off + 1);
  SvCUR_set(dsv, 0);
  SvPOK_only(dsv);

  do {
    src += off;
    len -= off;
    pos += off;

    skip = utf8_maximal_subpart((const char *)src, len);

    if (do_warn) {
      xs_report_illformed(aTHX_ src, skip, "UTF-8", pos, FALSE);
    }

    sv_catpvn_nomg(dsv, (const char *)src - off, off);

    if (fallback) {
      SV *octets = newSVpvn((const char *)src, skip);
      xs_handle_fallback(aTHX_ dsv, fallback, octets, 0, pos);
    }
    else
      sv_catpvn_nomg(dsv, "\xEF\xBF\xBD", 3);

    src += skip;
    len -= skip;
    pos += skip;

    off = xs_utf8_check(src, len);
    if (off == len) {
      sv_catpvn_nomg(dsv, (const char *)src, off);
      break;
    }
  } while (len);
}

static void
xs_utf8_encode_replace(pTHX_ SV *dsv, const U8 *src, STRLEN len, STRLEN off, CV *fallback) {
#if PERL_REVISION == 5 && PERL_VERSION >= 14
  const bool do_warn = ckWARN4_d(WARN_UTF8, WARN_NONCHAR, WARN_SURROGATE, WARN_NON_UNICODE);
#else
  const bool do_warn = ckWARN_d(WARN_UTF8);
#endif
  STRLEN pos = 0;
  STRLEN skip;
  UV v;

  (void)SvUPGRADE(dsv, SVt_PV);
  (void)SvGROW(dsv, off + 1);
  SvCUR_set(dsv, 0);
  SvPOK_only(dsv);

  do {
    src += off;
    len -= off;
    pos += utf8_length(src - off, src);

    v = utf8n_to_uvchr(src, len, &skip, (UTF8_ALLOW_ANYUV|UTF8_CHECK_ONLY) & ~UTF8_ALLOW_LONG);
    if (skip == (STRLEN) -1) {
      skip = 1;
      if (UTF8_IS_START(*src)) {
        STRLEN n = UTF8SKIP(src);
        if (n > len)
          n = len;
        while (skip < n && UTF8_IS_CONTINUATION(src[skip]))
          skip++;
      }
      xs_report_illformed(aTHX_ src, skip, "UTF-X", pos, TRUE);
    }
    if (do_warn)
      xs_report_unmappable(aTHX_ v, pos);

    sv_catpvn_nomg(dsv, (const char *)src - off, off);

    if (fallback) {
      SV *codepoint = newSVuv(v);
      UV usv = (v <= 0x10FFFF && (v & 0xF800) != 0xD800) ? v : 0;
      xs_handle_fallback(aTHX_ dsv, fallback, codepoint, usv, pos);
    }
    else
      sv_catpvn_nomg(dsv, "\xEF\xBF\xBD", 3);

    src += skip;
    len -= skip;
    pos += 1;

    off = xs_utf8_check(src, len);
    if (off == len) {
      sv_catpvn_nomg(dsv, (const char *)src, off);
      break;
    }
  } while (len);
}

static void
xs_utf8_encode_native(pTHX_ SV *dsv, const U8 *src, STRLEN len, const bool append) {
  const U8 *end = src + len;
  U8 *d;
  STRLEN off = 0;

  if (append)
    off = SvCUR(dsv);

  (void)SvUPGRADE(dsv, SVt_PV);
  (void)SvGROW(dsv, off + len * 2 + 1);
  d = (U8 *)SvPVX(dsv) + off;

  for (; src < end; src++) {
    const U8 c = *src;
    if (c < 0x80)
      *d++ = c;
    else {
      *d++ = (U8)(0xC0 | ((c >> 6) & 0x1F));
      *d++ = (U8)(0x80 | ((c   ) & 0x3F));
    }
  }
  *d = 0;
  SvCUR_set(dsv, d - (U8 *)SvPVX(dsv));
  SvPOK_only(dsv);
}

static void
xs_utf8_encode_native_inplace(pTHX_ SV *sv, const U8 *s, STRLEN len) {
  const U8 *p = s;
  const U8 *e = s + len;

  while (p < e && *p < 0x80)
    p++;

  if (p != e) {
    STRLEN size, off;
    U8 *d;

    off = p - s;
    size = len;
    while (p < e)
      size += (*p++ > 0x7F);

    if (SvLEN(sv) < size + 1) {
      (void)sv_grow(sv, size + 1);
      s = (const U8 *)SvPVX(sv);
      e = s + len;
    }
    d = (U8 *)SvPVX(sv) + size;
    *d = 0;
    for (s += off, e--; e >= s; e--) {
      const U8 c = *e;
      if (c < 0x80)
        *--d = c;
      else {
        *--d = (U8)(0x80 | ((c   ) & 0x3F));
        *--d = (U8)(0xC0 | ((c >> 6) & 0x1F));
      }
    }
    SvCUR_set(sv, size);
  }
  SvPOK_only(sv);
}

static void
xs_utf8_downgrade(pTHX_ SV *dsv, const U8 *s, STRLEN len) {
  const U8 *e = s + len - 1;
  U8 *d, c, v;

  (void)SvUPGRADE(dsv, SVt_PV);
  (void)SvGROW(dsv, len + 1);
  d = (U8 *)SvPVX(dsv);

  while (s < e) {
    c = *s++;
    if (c < 0x80)
      *d++ = c;
    else {
      if ((c & 0xFE) != 0xC2)
        goto error;
      v = (c & 0x1F) << 6;
      c = *s++;
      if ((c & 0xC0) != 0x80)
        goto error;
      *d++ = (U8)(v | (c & 0x3F));
    }
  }
  if (s < e + 1) {
    if (*s < 0x80)
      *d++ = *s;
    else {
      error:
      croak("Can't decode a wide character string");
    }
  }
  *d = 0;
  SvCUR_set(dsv, d - (U8 *)SvPVX(dsv));
  SvPOK_only(dsv);
}

static SSize_t
PerlIO_read_utf8(pTHX_ PerlIO *fh, SV *bufsv, SSize_t length, SSize_t offset) {
  utf8_valid_stream_t s;
  SSize_t got = 0;      // code points counted so far
  STRLEN fed = 0;       // bytes present in the output region
  STRLEN complete = 0;  // last counted code-point boundary
  STRLEN base = 0;      // byte offset this call writes at
  STRLEN pad = 0;       // zero-fill gap for offset past end
  STRLEN blen;          // existing content length
  char* buf;

  if (length < 0)
    croak("Negative length");

  if (!SvOK(bufsv))
    SvPVCLEAR(bufsv);
  (void)SvPVutf8_force(bufsv, blen);

  // Resolve the byte offset (base) where this call starts writing
  if (offset != 0) {
    char *pv = SvPVX(bufsv);
    size_t chars = utf8_distance_unsafe(pv, blen);
    if (offset < 0) {
      size_t back = (size_t)-offset;
      if (back > chars)
        croak("Offset outside string");
      base = utf8_advance_forward_unsafe(pv, blen, chars - back, NULL);
    }
    else if ((size_t)offset == chars) {
      base = blen;
    }
    else if ((size_t)offset < chars) {
      base = utf8_advance_forward_unsafe(pv, blen, (size_t)offset, NULL);
    }
    else {
      pad = (STRLEN)((size_t)offset - chars);
      base = blen + pad;
    }
  }

  // Single worst-case allocation: FFFD is 3 bytes, a valid code point up
  // to 4, so base + length*4 + 1 covers the call; buffer never regrows.
  buf = SvGROW(bufsv, base + (STRLEN)length * 4 + 1);

  // Zero-fill the offset-past-end gap.
  if (pad) {
    Zero(buf + blen, pad, char);
    SvCUR_set(bufsv, base);
  }

  buf += base;
  utf8_valid_stream_init(&s);

  // Fast-gets layers expose the read buffer directly: validate, copy valid
  // runs and substitute U+FFFD in a single pass out of it. Other layers fall
  // back to the PerlIO_read() path below.
  if (PerlIO_fast_gets(fh)) {
    while (got < length) {
      bool eof = false;

      if (PerlIO_get_cnt(fh) <= 0 && PerlIO_fill(fh) != 0) {
        if (PerlIO_error(fh))
          return -1;
        eof = true;
      }

      const char* ptr = PerlIO_get_ptr(fh);
      STRLEN avail = (STRLEN)PerlIO_get_cnt(fh);
      STRLEN taken = 0;

      if (avail == 0)
        eof = true;

      bool span_eof = eof;  // the whole available span is the tail iff at EOF

      // Drain the span: a single fill may hold several ill-formed subparts.
      for (;;) {
        if (got >= length)
          break;

        // Cap the span to the output room left (length*4 - fed bytes).
        STRLEN span = avail - taken;
        STRLEN room = (STRLEN)length * 4 - fed;
        bool tail_eof = span_eof;
        if (span > room) {
          span = room;
          tail_eof = false;  // a capped span is not the stream tail
        }

        utf8_valid_stream_result_t r;
        r = utf8_valid_stream_check(&s, ptr + taken, span, tail_eof);

        // Copy the valid prefix, then walk it once to count code points and
        // honor the budget. A run resuming a carried sequence spans from
        // `complete`, so measure from there rather than from oldfed.
        if (r.consumed) {
          STRLEN oldfed = fed;

          Copy(ptr + taken, buf + oldfed, r.consumed, char);

          size_t took;
          STRLEN keep = utf8_advance_forward_unsafe(
              buf + complete, (oldfed - complete) + r.consumed,
              (size_t)(length - got), &took);

          fed = complete + keep;
          taken += fed - oldfed;
          got += (SSize_t)took;
          complete = fed;

          if (got >= length)
            break;
        }

        if (r.status == UTF8_VALID_STREAM_OK)
          break;

        if (r.status == UTF8_VALID_STREAM_PARTIAL) {
          // Carry the incomplete trailing sequence into the output; its
          // continuation arrives on the next fill.
          STRLEN tail = span - r.consumed;
          Copy(ptr + taken, buf + fed, tail, char);
          fed += tail;
          taken += tail;
          break;
        }

        // ILLFORMED or TRUNCATED: emit one U+FFFD for the maximal subpart.
        {
          if (ckWARN_d(WARN_UTF8)) {
            STRLEN sublen = r.carried + r.advance;  // <= 3
            char subpart[4];
            if (r.carried)
              memcpy(subpart, buf + fed - r.carried, r.carried);
            if (r.advance)
              memcpy(subpart + r.carried, ptr + taken, r.advance);
            xs_report_illformed_read(aTHX_ subpart, sublen, span_eof);
          }

          fed -= r.carried;   // drop the carried lead already sitting in buf
          memcpy(buf + fed, "\xEF\xBF\xBD", 3);
          fed += 3;
          got += 1;
          taken += r.advance;  // skip this fill's portion of the subpart
          complete = fed;
        }

        if (r.status == UTF8_VALID_STREAM_TRUNCATED)
          break;
      }

      if (avail)
        PerlIO_set_ptrcnt(fh, (char*)ptr + taken, (SSize_t)(avail - taken));

      if (eof)
        break;
    }
  }
  else {
    while (got < (size_t)length) {
      STRLEN req = (STRLEN)(length - got);
      SSize_t count = PerlIO_read(fh, buf + fed, req);

      if (count < 0 || (count == 0 && PerlIO_error(fh)))
        return -1;

      bool eof = (count == 0);
      STRLEN scan = fed;
      fed += (STRLEN)count;

      // Drain the newly read bytes; a single read may contain several
      // ill-formed subparts, each replaced in place with U+FFFD.
      for (;;) {
        utf8_valid_stream_result_t r;
        r = utf8_valid_stream_check(&s, buf + scan, fed - scan, eof);

        if (r.status == UTF8_VALID_STREAM_ILLFORMED ||
            r.status == UTF8_VALID_STREAM_TRUNCATED) {
          STRLEN sub_start = scan + r.consumed - r.carried;  // region-rel
          STRLEN sublen = r.carried + r.advance;             // <= 3
          STRLEN delta = 3 - sublen;                         // >= 0

          if (ckWARN_d(WARN_UTF8))
            xs_report_illformed_read(aTHX_ buf + sub_start, sublen, eof);

          if (delta) { // make room, then write FFFD
            Move(buf + sub_start + sublen,
                 buf + sub_start + sublen + delta,
                 fed - (sub_start + sublen), char);
            fed += delta;
          }

          memcpy(buf + sub_start, "\xEF\xBF\xBD", 3);
          scan = sub_start + 3; // resume just past the FFFD

          if (r.status == UTF8_VALID_STREAM_TRUNCATED)
            break;   // truncated is the final tail
          continue;  // ill-formed: keep draining
        }
        break;  // OK / PARTIAL: chunk drained
      }

      // Count completed code points (FFFD included).
      {
        STRLEN boundary = fed - s.carried;
        got     += utf8_distance_unsafe(buf + complete, boundary - complete);
        complete = boundary;
      }

      if (eof)
        break;
    }

    // A trailing incomplete sequence was read but not emitted; push it back so
    // the next call re-reads it. At EOF the drain already resolved any tail to
    // U+FFFD, so s.pending is 0 there.
    if (s.carried) {
      PerlIO_unread(fh, buf + fed - s.carried, s.carried);
      fed -= s.carried;
    }
  }

  SvCUR_set(bufsv, base + fed);
  *SvEND(bufsv) = '\0';
  SvUTF8_on(bufsv);
  SvSETMAGIC(bufsv);
  return got;
}

// Slurp a whole file, decoded to characters, using unbuffered (:unix) IO.
// Reads in fixed chunks and validates in place with the streaming DFA,
// substituting U+FFFD for each maximal ill-formed subpart (warning in the
// utf8 category).
// Returns a mortal, UTF8-on SV; croaks if the file cannot be opened or read.
static SV *
xs_slurp_utf8(pTHX_ SV *namesv) {
  const STRLEN CHUNK = 65536;
  const char *filename = SvPV_nolen(namesv);
  int fd = PerlLIO_open3(filename, O_RDONLY | O_BINARY, 0);
  if (fd < 0)
    croak("Couldn't open '%s': %s", filename, Strerror(errno));

  utf8_valid_stream_t s;
  utf8_valid_stream_init(&s);

  SV *sv = sv_2mortal(newSVpvn("", 0));
  STRLEN fed = 0;    // bytes emitted so far
  STRLEN cap = 0;    // current buffer capacity

  // Starting size: st_size is only a hint for regular files. The file may
  // grow or shrink after the stat, and ill-formed input expands to U+FFFD,
  // so the read loop below grows the buffer geometrically as needed.
  // Non-regular files (pipes/FIFOs) report no size and start at one chunk.
  {
    Stat_t st;
    if (PerlLIO_fstat(fd, &st) == 0 &&
        S_ISREG(st.st_mode) && st.st_size > 0)
      cap = (STRLEN)st.st_size;
  }
  if (cap < CHUNK)
    cap = CHUNK;

  char *buf = SvGROW(sv, cap + 1);

  for (;;) {
    // Room for a chunk plus its worst-case U+FFFD expansion (each subpart
    // grows by at most 2 bytes). Double the capacity when short.
    if (fed + CHUNK * 3 + 1 > cap) {
      while (cap < fed + CHUNK * 3 + 1)
        cap *= 2;
      buf = SvGROW(sv, cap + 1);
    }

    SSize_t count;
    do {
      count = PerlLIO_read(fd, buf + fed, CHUNK);
    } while (count < 0 && errno == EINTR);
    const int saved = errno;
    if (count < 0) {
      PerlLIO_close(fd);
      croak("Couldn't read '%s': %s", filename, Strerror(saved));
    }

    bool eof = (count == 0);
    STRLEN scan = fed;   // start of the newly read bytes
    fed += (STRLEN)count;

    // Drain the chunk; it may hold several ill-formed subparts.
    for (;;) {
      utf8_valid_stream_result_t r =
          utf8_valid_stream_check(&s, buf + scan, fed - scan, eof);

      if (r.status == UTF8_VALID_STREAM_ILLFORMED ||
          r.status == UTF8_VALID_STREAM_TRUNCATED) {
        STRLEN sub_start = scan + r.consumed - r.carried;
        STRLEN sublen = r.carried + r.advance;   // <= 3
        STRLEN delta = 3 - sublen;               // >= 0

        if (ckWARN_d(WARN_UTF8))
          xs_report_illformed_read(aTHX_ buf + sub_start, sublen, eof);

        if (delta) {
          Move(buf + sub_start + sublen,
               buf + sub_start + sublen + delta,
               fed - (sub_start + sublen), char);
          fed += delta;
        }

        memcpy(buf + sub_start, "\xEF\xBF\xBD", 3);
        scan = sub_start + 3;

        if (r.status == UTF8_VALID_STREAM_TRUNCATED)
          break;
        continue;
      }
      break;  // OK / PARTIAL: chunk drained
    }

    if (eof)
      break;
  }

  PerlLIO_close(fd);

  SvCUR_set(sv, fed);
  *SvEND(sv) = '\0';
  SvPOK_on(sv);
  SvUTF8_on(sv);
  return sv;
}

/* SVt_PV, SVt_PVIV, SVt_PVNV, SVt_PVMG */
#define SvPV_stealable(sv) \
  ((SvFLAGS(sv) & ~(SVTYPEMASK|SVf_UTF8)) == (SVs_TEMP|SVf_POK|SVp_POK) && \
   (SvTYPE(sv) >= SVt_PV && SvTYPE(sv) <= SVt_PVMG) && SvREFCNT(sv) == 1)

MODULE = Unicode::UTF8    PACKAGE = Unicode::UTF8

PROTOTYPES: DISABLE

void
decode_utf8(octets, fallback=NULL)
    SV *octets
    CV *fallback
  PREINIT:
    const U8 *src;
    STRLEN len, off;
    bool reuse_sv;
  PPCODE:
    src = (const U8 *)SvPV_const(octets, len);
    reuse_sv = SvPV_stealable(octets);
    if (SvUTF8(octets)) {
      if (!reuse_sv) {
        octets = sv_newmortal();
        reuse_sv = TRUE;
      }
      xs_utf8_downgrade(aTHX_ octets, src, len);
      if (SvCUR(octets) == len) {
        ST(0) = octets;
        SvUTF8_on(octets);
        XSRETURN(1);
      }
      src = (const U8 *)SvPV_const(octets, len);
    }
    if (utf8_check_ascii((const char *)src, len, &off)) {
      if (reuse_sv) {
        ST(0) = octets;
        SvUTF8_on(octets);
        XSRETURN(1);
      }
      else {
        dXSTARG;
        sv_setpvn(TARG, (const char *)src, len);
        SvUTF8_on(TARG);
        PUSHTARG;
      }
    }
    else {
      dXSTARG;
      xs_utf8_decode_replace(aTHX_ TARG, src, len, off, fallback);
      SvUTF8_on(TARG);
      PUSHTARG;
    }

void
encode_utf8(string, fallback=NULL)
    SV *string
    CV *fallback
  PREINIT:
    const U8 *src;
    STRLEN len;
    bool reuse_sv;
  PPCODE:
    src = (const U8 *)SvPV_const(string, len);
    reuse_sv = SvPV_stealable(string);
    if (!SvUTF8(string)) {
      if (reuse_sv) {
        xs_utf8_encode_native_inplace(aTHX_ string, src, len);
        ST(0) = string;
        XSRETURN(1);
      }
      else {
        dXSTARG;
        xs_utf8_encode_native(aTHX_ TARG, src, len, FALSE);
        SvTAINT(TARG);
        PUSHTARG;
      }
    }
    else {
      STRLEN off;
      if (utf8_check_ascii((const char *)src, len, &off)) {
        if (reuse_sv) {
          ST(0) = string;
          SvUTF8_off(string);
          XSRETURN(1);
        }
        else {
          dXSTARG;
          sv_setpvn(TARG, (const char *)src, len);
          SvUTF8_off(TARG);
          PUSHTARG;
        }
      }
      else {
        dXSTARG;
        xs_utf8_encode_replace(aTHX_ TARG, src, len, off, fallback);
        PUSHTARG;
      }
    }

IV
read_utf8(fh, bufsv, length, offset = 0)
    PerlIO *fh
    SV     *bufsv
    IV     length
    IV     offset
  PROTOTYPE:
    *$$;$
  CODE:
  {
    SSize_t got = PerlIO_read_utf8(aTHX_ fh, bufsv, length, offset);
    if (got < 0)
      XSRETURN_UNDEF;
    RETVAL = (IV)got;
  }
  OUTPUT:
    RETVAL

void
slurp_utf8(filename)
    SV *filename
  PPCODE:
  {
    ST(0) = xs_slurp_utf8(aTHX_ filename);
    XSRETURN(1);
  }

void
valid_utf8(octets)
    SV *octets
  PREINIT:
    const char *src;
    STRLEN len;
  PPCODE:
    src = SvPV_const(octets, len);
    if (SvUTF8(octets)) {
      octets = sv_mortalcopy(octets);
      if (!sv_utf8_downgrade(octets, TRUE))
        croak("Can't validate a wide character string");
      src = SvPV_const(octets, len);
    }
    ST(0) = boolSV(utf8_valid_ascii(src, len));
    XSRETURN(1);

