#ifndef TK_PARSE_XS_H
#define TK_PARSE_XS_H

/* The text as UTF-8 bytes, so it can be matched against the locale's names
 * and CLDR's no-break spaces. */
static SV *
tk_utf8_text(pTHX_ SV *sv)
{
    STRLEN len, k;
    const char *p = SvPV(sv, len);
    if (SvUTF8(sv))
        return sv;
    for (k = 0; k < len; k++)
        if ((unsigned char)p[k] >= 0x80) {
            SV *u = sv_mortalcopy(sv);
            sv_utf8_upgrade(u);
            return u;
        }
    return sv;
}

/* The text with every digit of another script as its ASCII digit, so the
 * readers need only know 0 to 9. One character becomes one character, so
 * an offset in characters is the same in both. */
static SV *
tk_ascii_digits(pTHX_ SV *t)
{
    STRLEN len, i = 0;
    const U8 *s = (const U8 *)SvPV(t, len);
    SV *out = NULL;
    if (!SvUTF8(t))
        return t;
    while (i < len) {
        UV cp;
        STRLEN cl = 1;
        int d = -1;
        if (s[i] >= 0xC0) {
            cl = s[i] >= 0xF0 ? 4 : s[i] >= 0xE0 ? 3 : 2;
            if (i + cl <= len) {
                STRLEN k;
                cp = s[i] & (0x7F >> cl);
                for (k = 1; k < cl; k++)
                    cp = (cp << 6) | (s[i + k] & 0x3F);
                d = tk_unicode_digit(cp);
            }
            else
                cl = len - i;
        }
        if (d >= 0) {
            char ch = (char)('0' + d);
            if (!out) {
                out = sv_2mortal(newSVpvn((const char *)s, i));
                SvUTF8_on(out);
            }
            sv_catpvn(out, &ch, 1);
        }
        else if (out)
            sv_catpvn(out, (const char *)s + i, cl);
        i += cl;
    }
    return out ? out : t;
}

/* A parse error, with the offset in characters of the text that was read
 * (scanned), quoting the text as given (shown). */
static void
tk_parse_croak(pTHX_ const char *what, SV *shown, SV *scanned, const tk_cursor *c)
{
    STRLEN len;
    const char *s = SvPV(scanned, len);
    STRLEN at = c->err_at > len ? len : c->err_at;
    STRLEN chars = SvUTF8(scanned) ? (STRLEN)utf8_length((const U8 *)s, (const U8 *)s + at) : at;
    croak("%s: cannot parse '%" SVf "' at offset %lu: %s", what, SVfARG(shown), (unsigned long)chars,
          c->err ? c->err : "it is not a date and time");
}

static void
tk_cursor_init(tk_cursor *c, const char *s, STRLEN len)
{
    c->s = s;
    c->len = len;
    c->i = 0;
    c->err = NULL;
    c->err_at = 0;
}

#endif
