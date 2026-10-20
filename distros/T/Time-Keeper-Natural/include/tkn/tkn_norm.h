#ifndef TKN_NORM_H
#define TKN_NORM_H

/* A text as the lexicon stores and looks it up: what Lexicon->normalise,
 * ->ascii_digits and ->key do. Non-ASCII text goes through Unicode NFC
 * (Unicode::Normalize, as 0.01 used it), typographic apostrophes become
 * the plain one, six invisible marks go, any run of white space becomes
 * one space, every character is lower-cased as Perl's lc does it, one space
 * is trimmed from each end, and a spaceless locale loses every space. */

#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r, v, s) (PERL_REVISION > (r) || (PERL_REVISION == (r) \
        && (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

/* The code point at p in a UTF-8 SV's buffer, and its length in *cl;
 * utf8_to_uvchr_buf is 5.16's. */
static UV
tkn_utf8_cp(const U8 *p, const U8 *e, STRLEN *cl)
{
    STRLEN n = UTF8SKIP(p), i;
    UV cp;
    if (n == 1 || p + n > e) {
        *cl = 1;
        return *p;
    }
    cp = *p & (0x7F >> n);
    for (i = 1; i < n; i++)
        cp = (cp << 6) | (p[i] & 0x3F);
    *cl = n;
    return cp;
}

/* Unicode's White_Space above ASCII, which is what [\s\p{Zs}] adds. */
static int
tkn_is_space_cp(UV cp)
{
    if (cp < 0x80)
        return isSPACE((U8)cp);
    return cp == 0x85 || cp == 0xA0 || cp == 0x1680 || (cp >= 0x2000 && cp <= 0x200A)
        || cp == 0x2028 || cp == 0x2029 || cp == 0x202F || cp == 0x205F || cp == 0x3000;
}

/* One character's lower case, as lc writes it, appended to out. */
static void
tkn_lower_cat(pTHX_ SV *out, const U8 *p, const U8 *e)
{
    U8 buf[UTF8_MAXBYTES_CASE + 1];
    STRLEN len = 0;
#if PERL_VERSION_GE(5, 26, 0)
    toLOWER_utf8_safe(p, e, buf, &len);
#else
    PERL_UNUSED_ARG(e);
    to_utf8_lower(p, buf, &len);
#endif
    sv_catpvn(out, (const char *)buf, len);
}

/* Unicode::Normalize::NFC of a text, loading the module the first time. */
static SV *
tkn_nfc(pTHX_ SV *text)
{
    dSP;
    SV *r, *top;
    int n;
    if (!get_cv("Unicode::Normalize::NFC", 0))
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Unicode::Normalize"), NULL);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(text);
    PUTBACK;
    n = call_pv("Unicode::Normalize::NFC", G_SCALAR);
    SPAGAIN;
    top = n ? POPs : text;
    r = newSVsv(top);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(r);
}

static SV *
tkn_normalise(pTHX_ SV *in, int spaceless)
{
    STRLEN len, i;
    const U8 *s;
    SV *out;
    int hi = 0, space = 0;

    if (!SvOK(in))
        return sv_2mortal(newSVpvs(""));
    s = (const U8 *)SvPV_const(in, len);
    for (i = 0; i < len; i++)
        if (s[i] >= 0x80) {
            hi = 1;
            break;
        }
    out = sv_2mortal(newSVpvs(""));
    if (!hi) {
        for (i = 0; i < len; i++) {
            if (isSPACE(s[i])) {
                if (!space)
                    sv_catpvs(out, " ");
                space = 1;
                continue;
            }
            {
                char c = (char)toLOWER(s[i]);
                sv_catpvn(out, &c, 1);
            }
            space = 0;
        }
    }
    else {
        SV *src = in;
        const U8 *p, *e;
        if (!SvUTF8(in)) {
            src = sv_2mortal(newSVsv(in));
            sv_utf8_upgrade(src);
        }
        src = tkn_nfc(aTHX_ src);
        if (!SvUTF8(src)) {
            src = sv_2mortal(newSVsv(src));
            sv_utf8_upgrade(src);
        }
        p = (const U8 *)SvPV_const(src, len);
        e = p + len;
        SvUTF8_on(out);
        while (p < e) {
            STRLEN cl;
            UV cp = tkn_utf8_cp(p, e, &cl);
            if (cp == 0x2018 || cp == 0x2019 || cp == 0x02BC) {
                sv_catpvs(out, "'");
                space = 0;
            }
            else if ((cp >= 0x200B && cp <= 0x200F) || cp == 0xFEFF || cp == 0x061C) {
                ;
            }
            else if (tkn_is_space_cp(cp)) {
                if (!space)
                    sv_catpvs(out, " ");
                space = 1;
            }
            else {
                if (cp < 0x80) {
                    char c = (char)toLOWER((U8)cp);
                    sv_catpvn(out, &c, 1);
                }
                else
                    tkn_lower_cat(aTHX_ out, p, e);
                space = 0;
            }
            p += cl;
        }
    }
    {
        STRLEN olen;
        char *o = SvPV(out, olen);
        if (olen && o[olen - 1] == ' ')
            SvCUR_set(out, --olen);
        if (olen && o[0] == ' ') {
            sv_chop(out, o + 1);
            o = SvPV(out, olen);
        }
        if (spaceless && memchr(o, ' ', olen)) {
            STRLEN r = 0, w = 0;
            for (; r < olen; r++)
                if (o[r] != ' ')
                    o[w++] = o[r];
            SvCUR_set(out, w);
        }
        *SvEND(out) = '\0';
    }
    return out;
}

/* The text with each of the locale's ten digits as its ASCII one; digits
 * holds their code points, or is NULL for a locale that writes 0 to 9. */
static SV *
tkn_ascii_digits(pTHX_ SV *in, const UV *digits)
{
    STRLEN len;
    const U8 *p, *e;
    SV *out;
    if (!digits || !SvOK(in) || !SvUTF8(in))
        return in;
    p = (const U8 *)SvPV_const(in, len);
    e = p + len;
    out = sv_2mortal(newSVpvs(""));
    SvUTF8_on(out);
    while (p < e) {
        STRLEN cl;
        UV cp = tkn_utf8_cp(p, e, &cl);
        int d = -1, k;
        if (cp >= 0x80)
            for (k = 0; k < 10; k++)
                if (digits[k] == cp) {
                    d = k;
                    break;
                }
        if (d >= 0) {
            char c = (char)('0' + d);
            sv_catpvn(out, &c, 1);
        }
        else
            sv_catpvn(out, (const char *)p, cl);
        p += cl;
    }
    return out;
}

#endif
