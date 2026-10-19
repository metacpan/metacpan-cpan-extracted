/* The numbering systems CLDR attaches to a date pattern with its numbers
 * attribute. The compilers keep such a pattern as "\001spec\001pattern":
 * the spec names a system for every numeric field ("hebr", "hanidec") or
 * for one letter ("d=hanidays", "M=romanlow", "y=jpanyear"), several
 * separated by ";". The engine writes the five systems CLDR 48's calendar
 * data uses and the compilers refuse any other, so a new one is seen
 * rather than silently written in digits. Included by tk_format.h after
 * tk_out_num. */
#ifndef TK_NUMBERING_H
#define TK_NUMBERING_H

#define TK_NUMS_MARK '\001'

/* The pattern proper, past a numbering prefix. */
static const char *
tk_pattern_body(const char *p)
{
    if (p && p[0] == TK_NUMS_MARK) {
        const char *e = strchr(p + 1, TK_NUMS_MARK);
        if (e)
            return e + 1;
    }
    return p;
}

/* Splits the prefix off a pattern: the spec, and the pattern moved past it. */
static int
tk_nums_prefix(const char **p, STRLEN *len, const char **spec, STRLEN *spec_len)
{
    const char *e;
    if (!*len || (*p)[0] != TK_NUMS_MARK)
        return 0;
    e = (const char *)memchr(*p + 1, TK_NUMS_MARK, *len - 1);
    if (!e)
        return 0;
    *spec = *p + 1;
    *spec_len = (STRLEN)(e - (*p + 1));
    *len -= (STRLEN)(e + 1 - *p);
    *p = e + 1;
    return 1;
}

/* The system the spec names for a letter: the letter's own entry first,
 * else the entry for every field. */
static int
tk_numsys_for(const char *spec, STRLEN len, char letter, const char **sys, STRLEN *slen)
{
    STRLEN i = 0;
    int found = 0;
    while (i < len) {
        STRLEN j = i;
        while (j < len && spec[j] != ';')
            j++;
        if (j - i >= 2 && spec[i + 1] == '=') {
            if (spec[i] == letter) {
                *sys = spec + i + 2;
                *slen = j - i - 2;
                return 1;
            }
        }
        else if (!found && j > i) {
            *sys = spec + i;
            *slen = j - i;
            found = 1;
        }
        i = j + 1;
    }
    return found;
}

/* hanidec: a numeric system, Chinese numerals as digits. */
static const char *const tk_hanidec_digits[10] = {
    "\343\200\207", "\344\270\200", "\344\272\214", "\344\270\211", "\345\233\233", "\344\272\224", "\345\205\255", "\344\270\203", "\345\205\253", "\344\271\235"
};

/* hanidays: the days of a lunar month, CLDR's zh spellout-numbering-days
 * for 1 to 30 (\345\210\235\344\270\200 to \345\210\235\345\215\201, \345\215\201\344\270\200 to \344\272\214\345\215\201, \345\273\277\344\270\200 to \345\273\277\344\271\235, \344\270\211\345\215\201). */
static const char *const tk_hanidays[31] = {
    "\343\200\207",
    "\345\210\235\344\270\200", "\345\210\235\344\272\214", "\345\210\235\344\270\211", "\345\210\235\345\233\233", "\345\210\235\344\272\224", "\345\210\235\345\205\255", "\345\210\235\344\270\203", "\345\210\235\345\205\253", "\345\210\235\344\271\235", "\345\210\235\345\215\201",
    "\345\215\201\344\270\200", "\345\215\201\344\272\214", "\345\215\201\344\270\211", "\345\215\201\345\233\233", "\345\215\201\344\272\224", "\345\215\201\345\205\255", "\345\215\201\344\270\203", "\345\215\201\345\205\253", "\345\215\201\344\271\235", "\344\272\214\345\215\201",
    "\345\273\277\344\270\200", "\345\273\277\344\272\214", "\345\273\277\344\270\211", "\345\273\277\345\233\233", "\345\273\277\344\272\224", "\345\273\277\345\205\255", "\345\273\277\344\270\203", "\345\273\277\345\205\253", "\345\273\277\344\271\235", "\344\270\211\345\215\201"
};

/* romanlow: CLDR's roman-lower, "n" for zero, up to 4999. */
static void
tk_out_roman_lower(pTHX_ tk_out *o, int v)
{
    static const char *const th[5] = { "", "m", "mm", "mmm", "mmmm" };
    static const char *const hu[10] = { "", "c", "cc", "ccc", "cd", "d", "dc", "dcc", "dccc", "cm" };
    static const char *const te[10] = { "", "x", "xx", "xxx", "xl", "l", "lx", "lxx", "lxxx", "xc" };
    static const char *const un[10] = { "", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix" };
    if (v == 0) {
        tk_out_str(aTHX_ o, "n");
        return;
    }
    tk_out_str(aTHX_ o, th[v / 1000]);
    tk_out_str(aTHX_ o, hu[(v / 100) % 10]);
    tk_out_str(aTHX_ o, te[(v / 10) % 10]);
    tk_out_str(aTHX_ o, un[v % 10]);
}

/* hebr: CLDR's hebrew rules. The letters of 1 to 999, then a geresh after
 * a lone letter or a gershayim before the last of several; 15 and 16 are
 * written with tet; 298, 304, 344, 698 and 744 reorder their letters so
 * no word is spelt; 80 after hundreds takes the final pe. Thousands are
 * the letters of the thousands with a geresh, then the rest, or the word
 * for thousands when nothing follows. A million and up is digits. */
#define TK_HEBR_GERESH "\327\263"
#define TK_HEBR_GERSHAYIM "\327\264"

static void
tk_out_hebrew_under_1000(pTHX_ tk_out *o, int v)
{
    static const char *const units[10] = { "", "\327\220", "\327\221", "\327\222", "\327\223", "\327\224", "\327\225", "\327\226", "\327\227", "\327\230" };
    static const char *const tens[10] = { "", "\327\231", "\327\233", "\327\234", "\327\236", "\327\240", "\327\241", "\327\242", "\327\244", "\327\246" };
    static const char *const hundreds[10] = { "", "\327\247", "\327\250", "\327\251", "\327\252", "\327\252\327\247", "\327\252\327\250", "\327\252\327\251", "\327\252\327\252", "\327\252\327\252\327\247" };
    char letters[16];
    size_t n = 0, nletters;
    const char *special = v == 298 ? "\327\250\327\227\327\246" : v == 304 ? "\327\223\327\251" : v == 344 ? "\327\251\327\223\327\236" : v == 698 ? "\327\252\327\250\327\227\327\246" : v == 744 ? "\327\252\327\251\327\223\327\236" : NULL;
    if (special) {
        n = strlen(special);
        memcpy(letters, special, n);
    }
    else {
        int h = v / 100, rem = v % 100;
        const char *a = hundreds[h], *b, *c = "";
        if (rem == 15) b = "\327\230\327\225";
        else if (rem == 16) b = "\327\230\327\226";
        else if (h && rem == 80) b = "\327\243";
        else {
            b = tens[rem / 10];
            c = units[rem % 10];
        }
        memcpy(letters, a, strlen(a)); n += strlen(a);
        memcpy(letters + n, b, strlen(b)); n += strlen(b);
        memcpy(letters + n, c, strlen(c)); n += strlen(c);
    }
    nletters = n / 2;   /* every Hebrew letter is two bytes */
    if (nletters == 1) {
        tk_out_cat(aTHX_ o, letters, n);
        tk_out_str(aTHX_ o, TK_HEBR_GERESH);
    }
    else {
        tk_out_cat(aTHX_ o, letters, n - 2);
        tk_out_str(aTHX_ o, TK_HEBR_GERSHAYIM);
        tk_out_cat(aTHX_ o, letters + n - 2, 2);
    }
}

static void
tk_out_hebrew(pTHX_ tk_out *o, int64_t v)
{
    int th, rem;
    if (v < 0) {
        tk_out_str(aTHX_ o, "\342\210\222");
        v = -v;
    }
    if (v == 0 || v >= 1000000) {
        tk_out_num(aTHX_ o, v, 1, '0');
        return;
    }
    if (v < 1000) {
        tk_out_hebrew_under_1000(aTHX_ o, (int)v);
        return;
    }
    th = (int)(v / 1000);
    rem = (int)(v % 1000);
    if (rem == 0) {
        if (th == 1) tk_out_str(aTHX_ o, "\327\220\327\234\327\243");
        else if (th == 2) tk_out_str(aTHX_ o, "\327\220\327\234\327\244\327\231\327\231\327\235");
        else {
            tk_out_hebrew_under_1000(aTHX_ o, th);
            tk_out_str(aTHX_ o, " \327\220\327\234\327\244\327\231\327\235");
        }
        return;
    }
    tk_out_hebrew_under_1000(aTHX_ o, th);
    if (th >= 401 || (th >= 10 && th < 100 && th % 10) || (th >= 100 && th % 100))
        tk_out_str(aTHX_ o, TK_HEBR_GERESH);
    tk_out_hebrew_under_1000(aTHX_ o, rem);
}

/* A numeric field of a pattern, in the system its numbering spec names
 * for the letter, else in the locale's digits. An algorithmic system
 * ignores the width, as ICU does. The Hebrew year is written without its
 * thousands between 5001 and 5999, as ICU writes it. */
static void
tk_out_field_num(pTHX_ tk_out *o, char letter, int64_t v, int width)
{
    const char *sys;
    STRLEN slen;
    if (!o->nums || !tk_numsys_for(o->nums, o->nums_len, letter, &sys, &slen)) {
        tk_out_num(aTHX_ o, v, width, '0');
        return;
    }
    if (slen == 7 && memEQ(sys, "hanidec", 7)) {
        const char *const *saved = o->digits;
        o->digits = tk_hanidec_digits;
        tk_out_num(aTHX_ o, v, width, '0');
        o->digits = saved;
        return;
    }
    if (slen == 8 && memEQ(sys, "hanidays", 8) && v >= 1 && v <= 30) {
        tk_out_str(aTHX_ o, tk_hanidays[v]);
        return;
    }
    if (slen == 8 && memEQ(sys, "romanlow", 8) && v >= 0 && v < 5000) {
        tk_out_roman_lower(aTHX_ o, (int)v);
        return;
    }
    if (slen == 8 && memEQ(sys, "jpanyear", 8)) {
        if (v == 1) {
            tk_out_str(aTHX_ o, "\345\205\203");
            return;
        }
        tk_out_num(aTHX_ o, v, width, '0');
        return;
    }
    if (slen == 4 && memEQ(sys, "hebr", 4)) {
        if (letter == 'y' && v > 5000 && v < 6000)
            v -= 5000;
        tk_out_hebrew(aTHX_ o, v);
        return;
    }
    tk_out_num(aTHX_ o, v, width, '0');
}

#endif
