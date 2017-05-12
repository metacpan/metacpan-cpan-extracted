/*
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

  The GPG signature in this file may be checked with 'gpg --verify format.c'. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <locale.h>
#include <ctype.h>
#include <config.h>

#ifdef I_LANGINFO
#include <langinfo.h>
#endif

#define unless(cond)  if (!(cond))

static char _VERSION[] = "1.03";

/* format.c, version 1.03

This is part of the Time::Format_XS module.  See the .pm file for documentation.

This code is copyright (c) 2003-2009 by Eric J. Roode -- all rights reserved.

See the Changes file for change history.

*/

#define DEBUG 0
#if DEBUG
#define BUG(args)  fprintf args
#else
#define BUG(args)
#endif

#define TF_INTERNAL "Time::Format_XS internal error: "
typedef struct state_struct
{
    int year, month, day, hour, min, sec, dow;
    int micro, milli;
    char am;
    int h12;
    size_t length;
    const char *start, *fmt;
    char *out, *outptr;
    int modifying;
    int upper, lower, ucnext, lcnext;
    int quoting;
    char tzone[60];
} st_struct, *state;


/* Month and weekday names, and their abbreviations.  Populated by setup_locale. */

#ifdef HAS_NL_LANGINFO
static char *Month_Name[13];
static char *Mon_Name[13];
static char *Weekday_Name[7];
static char *Day_Name[7];

nl_item NL_MONTH_IX[13] = {  MON_1,  MON_1,   MON_2,   MON_3,   MON_4,   MON_5,   MON_6,   MON_7,   MON_8,   MON_9,   MON_10,   MON_11,   MON_12};
nl_item NL_MON_IX  [13] = {ABMON_1, ABMON_1, ABMON_2, ABMON_3, ABMON_4, ABMON_5, ABMON_6, ABMON_7, ABMON_8, ABMON_9, ABMON_10, ABMON_11, ABMON_12};
nl_item NL_WKDAY_IX[ 7] = {  DAY_1,   DAY_2,   DAY_3,   DAY_4,   DAY_5,   DAY_6,   DAY_7};
nl_item NL_DAY_IX  [ 7] = {ABDAY_1, ABDAY_2, ABDAY_3, ABDAY_4, ABDAY_5, ABDAY_6, ABDAY_7};
#else
char *ENGLISH_MONTH_NAME[13] = {"n/a", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
char *ENGLISH_MON_NAME[13] = {"n/a", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
char *ENGLISH_WKD_NAME[7] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
char *ENGLISH_DAY_NAME[7] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
#endif

/* Croak.  Calls Time::Format_XS::_croak, which calls Carp::croak */
void c_croak (const char *str)
{
    STRLEN len=strlen(str);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(str,len)));
    PUTBACK;
    call_pv("Time::Format_XS::_croak", G_DISCARD);
    FREETMPS;
    LEAVE;
}

/* setup_locale
   Populate day/month names based on current locale.
   Alas, I don't know how portable this code is.
*/
static void setup_locale(void)
{
    static int checked_locale = 0;
    int i;

    char *cur_locale;
    static char prev_locale[40];

    /* have we checked the locale yet? */
    if (checked_locale)
    {
        /* Yes.  Has it changed? */
        cur_locale = setlocale(LC_TIME, NULL);
        if (NULL != cur_locale  &&  !strcmp(cur_locale, prev_locale))
            /* No, it's the same */
            return;
    }
    else
    {
        cur_locale = setlocale(LC_TIME, "");
        checked_locale = 1;
    }

    /* Locale either was never set, or has just changed.  Store it. */
    strncpy(prev_locale, cur_locale, 39);
    prev_locale[39] = '\0';

#ifdef HAS_NL_LANGINFO
    /* Zero out the month names; they'll be filled in as needed */
    for (i=0; i<13; i++)
        Month_Name[i] = Mon_Name[i] = "";
    for (i=0; i<7; i++)
        Weekday_Name[i] = Day_Name[i] = "";
#endif
}

#ifdef HAS_NL_LANGINFO
// Delay populating the names until we actually need one of them.
char *Get_Month_Name(int m)
{
    if (! Month_Name[m][0])
        Month_Name[m] = nl_langinfo(NL_MONTH_IX[m]);
    return Month_Name[m];
}

char *Get_Mon_Name(int m)
{
    if (! Mon_Name[m][0])
        Mon_Name[m] = nl_langinfo(NL_MON_IX[m]);
    return Mon_Name[m];
}
char *Get_Weekday_Name(int w)
{
    if (! Weekday_Name[w][0])
        Weekday_Name[w] = nl_langinfo(NL_WKDAY_IX[w]);
    return Weekday_Name[w];
}
char *Get_Day_Name(int w)
{
    if (! Day_Name[w][0])
        Day_Name[w] = nl_langinfo(NL_DAY_IX[w]);
    return Day_Name[w];
}
#else
// No NL_LANGINFO; use english names
#define Get_Month_Name(m)    ENGLISH_MONTH_NAME[m]
#define Get_Mon_Name(m)      ENGLISH_MON_NAME[m]
#define Get_Weekday_Name(m)  ENGLISH_WKD_NAME[m]
#define Get_Day_Name(m)      ENGLISH_DAY_NAME[m]
#endif


int is_leap (int year)
{
    return !(year%4) && ( (year%100) || !(year%400) );
}
int days_in (int month, int year)
{
    switch (month)
    {
    case 1: case 3: case 5: case 7: case 8: case 10: case 12:
        return 31;
    case 4: case 6: case 9: case 11:
        return 30;
    case 2:
        return is_leap(year)? 29 : 28;
    default:
        croak (TF_INTERNAL "invalid call to days_in");
    }
}
int dow (int yr, int mo, int dy)
{
    int dow;
    if (mo < 3)
    {
        mo += 12;
        --yr;
    }

    /* Zeller's congruence - or at least, some form of it. */
    dow = dy + (13 * mo - 27) / 5 + yr + yr/4 - yr/100 + yr/400;
    while (dow < 0) dow += 7;
    dow %= 7;
    return dow;
}


#define RESET_UCLC       self->ucnext = self->lcnext = 0
#define OUTPUSH(c)       *(self->outptr)++ = (c)
#define OUT_FIRST_UPPER(c)     *(self->outptr)++ = (self->lcnext||(self->lower&&!self->ucnext))? tolower(c) : toupper(c)
#define OUT_FIRST_LOWER(c)     *(self->outptr)++ = (self->ucnext||(self->upper&&!self->lcnext))? toupper(c) : tolower(c)
#define OUT_FIRST_MIXED(c)     *(self->outptr)++ = self->ucnext? toupper(c) : self->lcnext? tolower(c) : self->upper? toupper(c) : self->lower? tolower(c) : (c)
#define OUT_REST_UPPER(c)      *(self->outptr)++ = self->lower? tolower(c) : toupper(c)
#define OUT_REST_LOWER(c)      *(self->outptr)++ = self->upper? toupper(c) : tolower(c)
#define OUT_REST_MIXED(c)      *(self->outptr)++ = self->upper? toupper(c) : self->lower? tolower(c) : (c)

static int pack_02d (char *out, int num)
{
    int t = num / 10;    /* tens position */
    *out++ = t + '0';
    num -= t*10;
    *out = num + '0';
    return 2;
}
static int pack_2d (char *out, int num)
{
    int t = num/10;
    if (t)
    {
        *out++ = t + '0';
        num -= t*10;
    }
    else
        *out++ = ' ';
    *out = num + '0';
    return 2;
}
static int pack_d (char *out, int num)
{
    int t = num/10;
    int rv = 1;
    if (t)
    {
        rv++;
        *out++ = t + '0';
        num -= t*10;
    }
    *out = num + '0';
    return rv;
}

static void standard_x (state self, int num)
{
    if (self->modifying)
        self->outptr += pack_d (self->outptr, num);
    else
        self->length += num>9? 2 : 1;
    self->fmt += 1;
    RESET_UCLC;
}
static void standard_xx (state self, int num)
{
    if (self->modifying)
        self->outptr += pack_02d (self->outptr, num);
    else
        self->length += 2;
    self->fmt += 2;
    RESET_UCLC;
}
static void standard__x (state self, int num)   /* ?x */
{
    if (self->modifying)
        self->outptr += pack_2d (self->outptr, num);
    else
        self->length += 2;
    self->fmt += 2;
    RESET_UCLC;
}


static void yyyy (state self)
{
    if (self->modifying)
    {
        int c = self->year/100;
        int y = self->year%100;
        self->outptr += pack_02d(self->outptr, c);
        self->outptr += pack_02d(self->outptr, y);
    }
    else
        self->length += 4;
    self->fmt += 4;
    RESET_UCLC;
}
#define yy(self) standard_xx(self, self->year%100)

#define mm_on_(self) do{standard_xx(self, self->month); self->fmt += 4;} while(0)
#define  m_on_(self) do{standard_x (self, self->month); self->fmt += 4;} while(0)
#define _m_on_(self) do{standard__x(self, self->month); self->fmt += 4;} while(0)

#define dd(self) standard_xx (self, self->day)
#define  d(self) standard_x  (self, self->day)
#define _d(self) standard__x (self, self->day)

#define hh(self) standard_xx (self, self->hour)
#define  h(self) standard_x  (self, self->hour)
#define _h(self) standard__x (self, self->hour)

static void get_h12(state self)
{
    if (self->h12) return;
    self->h12 = self->hour % 12;
    if (self->h12 == 0) self->h12 = 12;
    self->am = self->hour<12? 'a' : 'p';
}
#define HH(self)  do{get_h12(self); standard_xx(self, self->h12); } while(0)
#define  H(self)  do{get_h12(self); standard_x (self, self->h12); } while(0)
#define _H(self)  do{get_h12(self); standard__x(self, self->h12); } while(0)

#define mm_in_(self) do{standard_xx(self, self->min); self->fmt += 4;} while(0)
#define  m_in_(self) do{standard_x (self, self->min); self->fmt += 4;} while(0)
#define _m_in_(self) do{standard__x(self, self->min); self->fmt += 4;} while(0)

#define ss(self) standard_xx (self, self->sec)
#define  s(self) standard_x  (self, self->sec)
#define _s(self) standard__x (self, self->sec)

static void mmm (state self)
{
    self->fmt += 3;
    if (!self->modifying)
    {
        self->length += 3;
        return;
    }
    RESET_UCLC;
    if (self->milli == 0)
    {
        OUTPUSH('0');
        OUTPUSH('0');
        OUTPUSH('0');
    }
    else
    {
        int h  = self->milli / 100;
        int to = self->milli % 100;
        OUTPUSH(h + '0');
        self->outptr += pack_02d (self->outptr, to);
    }
}

static void uuuuuu (state self)
{
    self->fmt += 6;
    if (!self->modifying)
    {
        self->length += 6;
        return;
    }
    RESET_UCLC;
    if (self->micro == 0)
    {
        OUTPUSH('0');
        OUTPUSH('0');
        OUTPUSH('0');
        OUTPUSH('0');
        OUTPUSH('0');
        OUTPUSH('0');
    }
    else
    {
        int u  = self->micro/100;
        int u3 = self->micro % 100;
        int u2 = u % 100;
        int u1 = u / 100;
        self->outptr += pack_02d (self->outptr, u1);
        self->outptr += pack_02d (self->outptr, u2);
        self->outptr += pack_02d (self->outptr, u3);
    }
}

/* Ambiguous mm, ?m, m codes */
static void mm (state self)
{
    if (!self->modifying)
    {
        self->length += 2;
        self->fmt    += 2;
        return;
    }
    if (month_context (self, 2))
        return standard_xx(self, self->month);

    if (minute_context(self, 2))
        return standard_xx(self, self->min);

    OUT_FIRST_LOWER('m');
    OUT_REST_LOWER('m');
    self->fmt += 2;
    RESET_UCLC;
}
static void m (state self)
{
    if (month_context (self, 2))
    {
        standard_x(self, self->month);
        return;
    }

    if (minute_context(self, 2))
    {
        standard_x(self, self->min);
        return;
    }

    if (!self->modifying)
    {
        self->length += 1;
        self->fmt    += 1;
        return;
    }

    OUT_FIRST_LOWER('m');
    self->fmt += 1;
    RESET_UCLC;
}
static void _m (state self)
{
    if (!self->modifying)
    {
        self->length += 2;
        self->fmt    += 2;
        return;
    }

    if (month_context (self, 2))
    {
        standard__x(self, self->month);
        return;
    }

    if (minute_context(self, 2))
    {
        standard__x(self, self->min);
        return;
    }

    OUTPUSH('?');
    OUT_REST_LOWER('m');
    self->fmt += 2;
    RESET_UCLC;
}

static char *suffix[] = {"th", "st", "nd", "rd"};
static void th (state self)
{
    int ones, tens;
    self->fmt += 2;
    if (!self->modifying)
    {
        self->length += 2;
        return;
    }
    ones = self->day % 10;
    tens = self->day / 10;
    if (tens == 1  ||  ones > 3) ones = 0;

    OUT_FIRST_LOWER(suffix[ones][0]);
    OUT_REST_LOWER (suffix[ones][1]);
    RESET_UCLC;
    return;
}
static void TH (state self)
{
    int ones, tens;
    self->fmt += 2;
    if (!self->modifying)
    {
        self->length += 2;
        return;
    }
    ones = self->day % 10;
    tens = self->day / 10;
    if (tens == 1  ||  ones > 3) ones = 0;

    OUT_FIRST_UPPER(suffix[ones][0]);
    OUT_REST_UPPER (suffix[ones][1]);
    RESET_UCLC;
}

static void am (state self)
{
    self->fmt += 2;
    if (!self->modifying)
    {
        self->length += 2;
        return;
    }
    get_h12(self);
    OUT_FIRST_LOWER(self->am);
    OUT_REST_LOWER('m');
    RESET_UCLC;
}

static void AM (state self)
{
    self->fmt += 2;
    if (!self->modifying)
    {
        self->length += 2;
        return;
    }
    get_h12(self);
    OUT_FIRST_UPPER(self->am);
    OUT_REST_UPPER('M');
    RESET_UCLC;
}

static void a_m_ (state self)
{
    self->fmt += 4;
    if (!self->modifying)
    {
        self->length += 4;
        return;
    }
    get_h12(self);
    OUT_FIRST_LOWER(self->am);
    OUTPUSH('.');
    OUT_REST_LOWER('m');
    OUTPUSH('.');
    RESET_UCLC;
}

static void A_M_ (state self)
{
    self->fmt += 4;
    if (!self->modifying)
    {
        self->length += 4;
        return;
    }
    get_h12(self);
    OUT_FIRST_UPPER(self->am);
    OUTPUSH('.');
    OUT_REST_UPPER('M');
    OUTPUSH('.');
    RESET_UCLC;
}

#define pm(self)   am(self)
#define PM(self)   AM(self)
#define p_m_(self) a_m_(self)
#define P_M_(self) A_M_(self)

static void packstr_mc(state self, int fmtlen, const char *name)
{
    int ch;
    self->fmt += fmtlen;
    if (!self->modifying)
    {
        self->length += strlen(name);
        return;
    }

    OUT_FIRST_MIXED(*name);
    while (*++name)
        OUT_REST_MIXED(*name);
    RESET_UCLC;
}
static void packstr_uc(state self, int fmtlen, const char *name)
{
    int ch;
    self->fmt += fmtlen;
    if (!self->modifying)
    {
        self->length += strlen(name);
        return;
    }

    OUT_FIRST_UPPER(*name);
    while (*++name)
        OUT_REST_UPPER(*name);
    RESET_UCLC;
}
static void packstr_lc(state self, int fmtlen, const char *name)
{
    int ch;
    self->fmt += fmtlen;
    if (!self->modifying)
    {
        self->length += strlen(name);
        return;
    }

    OUT_FIRST_LOWER(*name);
    while (*++name)
        OUT_REST_LOWER(*name);
    RESET_UCLC;
}
static void packstr_mc_limit(state self, int fmtlen, const char *name, size_t limit)
{
    int ch;
    self->fmt += fmtlen;
    if (!limit)  return;   /* output length zero */

    if (!self->modifying)
    {
        self->length += limit;
        return;
    }

    OUT_FIRST_MIXED(*name);
    while (*++name  &&  --limit)
        OUT_REST_MIXED(*name);
    RESET_UCLC;
}

#define Month(self)   do {setup_locale(); packstr_mc(self, 5, Get_Month_Name(self->month));} while(0)
#define MONTH(self)   do {setup_locale(); packstr_uc(self, 5, Get_Month_Name(self->month));} while(0)
#define month(self)   do {setup_locale(); packstr_lc(self, 5, Get_Month_Name(self->month));} while(0)

#define Mon(self)     do {setup_locale(); packstr_mc(self, 3, Get_Mon_Name(self->month));}   while(0)
#define MON(self)     do {setup_locale(); packstr_uc(self, 3, Get_Mon_Name(self->month));}   while(0)
#define mon(self)     do {setup_locale(); packstr_lc(self, 3, Get_Mon_Name(self->month));}   while(0)

#define Weekday(self) do {setup_locale(); packstr_mc(self, 7, Get_Weekday_Name(self->dow));} while(0)
#define WEEKDAY(self) do {setup_locale(); packstr_uc(self, 7, Get_Weekday_Name(self->dow));} while(0)
#define weekday(self) do {setup_locale(); packstr_lc(self, 7, Get_Weekday_Name(self->dow));} while(0)

#define Day(self)     do {setup_locale(); packstr_mc(self, 3, Get_Day_Name(self->dow));}     while(0)
#define DAY(self)     do {setup_locale(); packstr_uc(self, 3, Get_Day_Name(self->dow));}     while(0)
#define day(self)     do {setup_locale(); packstr_lc(self, 3, Get_Day_Name(self->dow));}     while(0)

#if HAVE_TZNAME && !HAVE_DECL_TZNAME
extern char *tzname[2];
#endif
static void tz (state self)
{
    if (strlen(self->tzone) == 0)
    {
        tzset();
        strcpy (self->tzone, tzname[0]);
    }
    packstr_mc(self, 2, self->tzone);
}

static void literal (state self)
{
    if (!self->modifying)
    {
        self->length++;
        self->fmt++;
        return;
    }
    *(self->outptr)++ = *(self->fmt++);
}

#define bs_literal(self) do{self->fmt++; literal(self);} while(0)
#define bs_Q(self) do{self->fmt+=2; self->quoting = 1;} while(0)
#define bs_E(self) do{self->fmt += 2; self->quoting = self->upper = self->lower = self->lcnext = self->ucnext = 0;} while(0)
#define bs_U(self) do{self->fmt += 2; self->upper = 1;} while(0)
#define bs_L(self) do{self->fmt += 2; self->lower = 1;} while(0)
#define bs_u(self) do{self->fmt += 2; self->lcnext = 0; self->ucnext = 1;} while(0)
#define bs_l(self) do{self->fmt += 2; self->ucnext = 0; self->lcnext = 1;} while(0)


/* forward
   Returns true if the beginning of fmt matches the whole of pat.
*/
#define forward(fmt,pat) (!strncmp(fmt, pat, strlen(pat)))

/* backward
   Returns true if fmt ends with pat, and is not preceded by an odd backslash.
   <start> is a pointer to the beginning of fmt, so we know not to go back too far.
*/
static int backward(const char *start, const char *fmt, const char *pat)
{
    size_t patlen = strlen(pat);
    int bs = 1;
    if (fmt - start < patlen)  return 0;
    fmt -= patlen;
    if (strncmp(fmt, pat, patlen))   return 0;

    /* we have a match; check that it's not preceded by an odd number of backslashes */
    while (fmt >= start  &&  *fmt-- == '\\')
        bs = !bs;
    return bs;
}

/* bool = month_context(start, fmt, patlen);
   Returns TRUE if the current format (delimited by fmt and patlen)
   is in a "month" context; that is, it is followed or preceeded by
   a year or a day.
   We check immediately following and immediately preceeding, and
   also we check one character away in either direction.  So mm/dd
   will work (because there's one character in between).
*/
int month_context(state self, size_t patlen)
{
    const char *backskip = self->fmt-2;
    const char *fwdskip  = self->fmt + patlen + 1;
    if (*backskip != '\\') backskip++;
    if (*fwdskip == '\\') fwdskip++;

    return  forward(self->fmt+patlen, "?d")
        ||  forward(self->fmt+patlen , "d")
        ||  forward(fwdskip,          "?d")
        ||  forward(fwdskip,           "d")
        ||  forward(self->fmt+patlen, "yy")
        ||  forward(fwdskip,          "yy")
        ||  backward(self->start, self->fmt, "yy")
        ||  backward(self->start, backskip,  "yy")
        ||  backward(self->start, self->fmt,  "d")
        ||  backward(self->start, backskip,   "d");
}

/* bool = minute_context(start, fmt, patlen);
   Returns TRUE if the current format is in a "minute" context.
   That is, if it's preceeded by an hour and/or followed by a second.
*/
int minute_context(state self, size_t patlen)
{
    const char *backskip = self->fmt-1;
    const char *fwdskip  = self->fmt+patlen+1;
    if (*backskip == '\\') backskip--;
    if (*fwdskip == '\\')  fwdskip++;

    return  forward(self->fmt+patlen, "?s")
        ||  forward(self->fmt+patlen,  "s")
        ||  forward(fwdskip,    "?s")
        ||  forward(fwdskip,     "s")
        ||  backward(self->start, self->fmt, "h")
        ||  backward(self->start, backskip,  "h")
        ||  backward(self->start, self->fmt, "H")
        ||  backward(self->start, backskip,  "H");
}

int get_2_digits(const char *str)
{
    if (isDIGIT(str[0])  &&  isDIGIT(str[1]))
        return 10 * (str[0] - '0') + (str[1] - '0');
    return -1;
}
int get_4_digits(const char *str)
{
    if (isDIGIT(str[0])  &&  isDIGIT(str[1])  &&  isDIGIT(str[2])  &&  isDIGIT(str[3]))
        return 100 * get_2_digits(str) + get_2_digits(str + 2);
    return -1;
}
int is_date_sep(char ch)
{
    return (ch == '-' || ch == '/' || ch == '.');
}
int is_time_sep(char ch)
{
    return (ch == ':' || ch == '.');
}
int is_datetime_sep(char ch)
{
    return (ch == '_' || ch == 'T' || ch == ' ');
}

/* Calls a DateTime method that takes NO arguments and returns ONE integer. */
int _datetime_method_int (SV *dt_obj, const char *method)
{
    dSP;
    int retval, retval_count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(dt_obj);  /* object */
    PUTBACK;
    retval_count = call_method(method, G_SCALAR);   /* $datetime->$method */
    SPAGAIN;
    if (retval_count != 1)
    {
        char msg[99];
        sprintf(msg, TF_INTERNAL "confusion in DateTime->%s method call, retval_count=%d", method, retval_count);
        croak (msg);
    }
    retval = POPi;

    FREETMPS;
    LEAVE;

    return retval;
}

/* Calls a DateTime method that takes NO arguments and returns ONE string. */
char * _datetime_method_str (SV *dt_obj, const char *method)
{
    dSP;
    STRLEN n_a;
    int retval_count;
    char *retval;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(dt_obj);  /* object */
    PUTBACK;
    retval_count = call_method(method, G_SCALAR);   /* $datetime->$method */
    SPAGAIN;
    if (retval_count != 1)
    {
        char msg[99];
        sprintf(msg, TF_INTERNAL "confusion in DateTime->%s method call, retval_count=%d", method, retval_count);
        croak (msg);
    }
    retval = POPpx;

    FREETMPS;
    LEAVE;

    return retval;
}

/* Returns true if data successfully parsed. */
int parse_datetime_obj  (SV *time_value, state st)
{
    int retval_count;
    char *cptr;

    BUG((stderr, "parse_datetime_obj: starts!\n"));

    /* This routine applies only to DateTime objects. */
    unless (SvROK(time_value)  &&  sv_derived_from(time_value, "DateTime"))
        return 0;

    /* Basic date/time elements */
    st->year  = _datetime_method_int(time_value, "year");
    st->month = _datetime_method_int(time_value, "month");
    st->day   = _datetime_method_int(time_value, "day");
    st->hour  = _datetime_method_int(time_value, "hour");
    st->min   = _datetime_method_int(time_value, "minute");
    st->sec   = _datetime_method_int(time_value, "second");
    st->dow   = _datetime_method_int(time_value, "day_of_week");
    cptr = _datetime_method_str(time_value, "time_zone_short_name");;
    strncpy (st->tzone, cptr, 60);
    st->tzone[59] = '\0';

    // Setting h12 to zero means "calculate on demand" */
    st->h12   = 0;

    /* microseconds and milliseconds */
    st->micro = _datetime_method_int(time_value, "microsecond");
    st->milli = (int) (st->micro / 1000);

    return 1;
}


void _validate_date(int yr, int mo, int dy)
{
    char msg[99];

    if (mo < 1  ||  mo > 12)
    {
        sprintf(msg, "Invalid month \"%02d\" in iso8601 string", mo);
        c_croak(msg);
    }

    if (dy < 1  ||  dy > 31)
    {
        sprintf(msg, "Invalid day \"%02d\" in iso8601 string", dy);
        c_croak(msg);
    }

    if (dy > days_in(mo, yr))
    {
        if (dy == 29  &&  mo == 2)
            sprintf(msg, "Invalid day \"29\" for 02/%04d in iso8601 string", yr);
        else
            sprintf(msg, "Invalid day \"%02d\" for month %02d in iso8601 string", dy, mo);
        c_croak(msg);
    }
}

void _validate_time(int hr, int mn, int sc)
{
    char msg[99];

    if (hr > 23)
    {
        sprintf(msg, "Invalid hour \"%02d\" in iso8601 string", hr);
        c_croak(msg);
    }

    if (mn > 59)
    {
        sprintf(msg, "Invalid minute \"%02d\" in iso8601 string", mn);
        c_croak(msg);
    }

    if (sc > 61)
    {
        sprintf(msg, "Invalid second \"%02d\" in iso8601 string", sc);
        c_croak(msg);
    }
}

/* Datetime string: YYYY-MM-DD HH:MM:SS */
/* ISO 8601, and DateTime/Date::Manip stringification */
int parse_iso8601_str(SV *timeval, state st)
{
    STRLEN len;
    char *str;
    char sep;
    int got_date=0;

    str = SvPV(timeval, len);
    if (NULL == str)
        return 0;

    /* Year */
    if ((st->year = get_4_digits(str)) >= 0)
    {
        str += 4;

        /* Date separator */
        if (is_date_sep(sep = *str))
            ++str;
        else
            sep = '\0';

        /* Month */
        if ((st->month = get_2_digits(str)) < 0)
            return 0;
        str += 2;
        BUG ((stderr, "_is_iso: month= [%02d]\n", st->month));

        /* Date separator. Should match previous one. */
        if (sep)
            if (sep == *str)
                ++str;
            else
                return 0;

        /* Day */
        if ((st->day = get_2_digits(str)) < 0)
            return 0;
        str += 2;
        BUG ((stderr, "_is_iso: day= [%02d]\n", st->day));

        st->dow = dow(st->year, st->month, st->day);

        /* If there was a date separator, it's okay for the string (date-only) to end here */
        if (sep)
            if (*str == '\0')
            {
                _validate_date(st->year, st->month, st->day);
                st->hour = st->min = st->sec = st->h12 = st->milli = st->micro = 0;
                BUG ((stderr, "_is_iso: Success!  date-only.\n"));
                return 1;
            }

        got_date = 1;

        /* Date-Time separator */
        if (is_datetime_sep(*str))
            ++str;
    }
    else   /* No date. */
    {
        st->year  = 1969;
        st->month =   12;
        st->day   =   31;
        st->dow   =    3;
    }

    /* Hour */
    if ((st->hour = get_2_digits(str)) < 0)
        return 0;
    str += 2;
    st->h12 = 0;    /* means: compute it later */
    BUG ((stderr, "_is_iso: hour= [%02d]\n", st->hour));

    /* MUST have a separator if this is a time-only string */
    if (is_time_sep(sep = *str))
        str++;
    else if (!got_date)
        return 0;
    else
        sep = '\0';

    /* Minute */
    if ((st->min = get_2_digits(str)) < 0)
        return 0;
    str += 2;

    /* Separator must match earlier */
    if (sep)
        if (sep == *str)
            ++str;
        else
            return 0;

    /* second */
    if ((st->sec = get_2_digits(str)) < 0)
        return 0;
    str += 2;

    /* fractional part is optional. */
    if (*str  &&  *str == '.'  &&  isDIGIT(str[1]))
    {
        int micro = 0;
        int ndig  = 0;
        ++str;

        while (isDIGIT(*str) && ndig++ < 6)
            micro = micro * 10  +  *str-'0';
        while (ndig++ < 6)
            micro *= 10;
        while (isDIGIT(*str))
            ++str;

        st->micro = micro;
        st->milli = micro / 1000;
    }
    else
        st->milli = st->micro = 0;

    /* Schmutz after the time */
    if (*str)
        return 0;

    _validate_date(st->year, st->month, st->day);
    _validate_time(st->hour, st->min  , st->sec);
    BUG((stderr, "_is_iso: success!\n"));
    return 1;
}

int parse_time_num    (SV *time_value, state st)
{
    STRLEN len=0;
    char *str;
    time_t epoch = 0;
    struct tm *tmstruct;

    BUG((stderr, "parse_time_num: starts!\n"));

    /* We should have been passed a numeric value */
    str = SvPV(time_value, len);
    if (NULL == str)
        return 0;

    /* Get integer portion */
    while (isDIGIT(*str))
        epoch = 10 * epoch + *str++ - '0';

    /* get fractional part, if any */
    if (*str == '.')
    {
        int micro = 0;
        int ndig  = 0;
        ++str;

        while (isDIGIT(*str) && ndig++ < 6)
            micro = micro * 10  +  *str++ - '0';
        while (ndig++ < 6)
            micro *= 10;
        while (isDIGIT(*str))
            ++str;

        st->micro = micro;
        st->milli = micro / 1000;
    }
    else
        st->milli = st->micro = 0;

    /* Any schmutz after the time? */
    if (*str)
        return 0;

    tmstruct  =  localtime(&epoch);
    st->year  = tmstruct->tm_year + 1900;
    st->month = tmstruct->tm_mon + 1;
    st->day   = tmstruct->tm_mday;
    st->hour  = tmstruct->tm_hour;
    st->min   = tmstruct->tm_min;
    st->sec   = tmstruct->tm_sec;
    st->dow   = tmstruct->tm_wday;
    st->h12   = 0;    /* Compute later */
    st->tzone[0] = '\0';

    return 1;
}

/* This function exists in case the clueless user typed "time", which
   isn't too hard to do as the second argument to the tied hash */
int parse_time_literal (SV *time_value, state st)
{
    STRLEN len=0;
    char *str;
    time_t epoch;
    struct tm *tmstruct;

    str = SvPV(time_value, len);
    if (NULL == str)
        return 0;

    if (strcmp(str, "time"))
        return 0;

    epoch = time(NULL);
    tmstruct  =  localtime(&epoch);
    st->year  = tmstruct->tm_year + 1900;
    st->month = tmstruct->tm_mon + 1;
    st->day   = tmstruct->tm_mday;
    st->hour  = tmstruct->tm_hour;
    st->min   = tmstruct->tm_min;
    st->sec   = tmstruct->tm_sec;
    st->dow   = tmstruct->tm_wday;
    st->h12   = 0;    /* Compute later */
    st->tzone[0] = '\0';

    return 1;
}


void in_parse (SV *in_time, state time_state)
{
    /* in_time may be:
       A time value (floating-point or integer)
       A DateTime object
       A stringified DateTime
       A Date::Manip string
       An ISO-8601 date, time, or datetime string.

       time_state is assumed to already be allocated.
    */

    if (! (
           parse_datetime_obj(in_time, time_state)
        || parse_iso8601_str (in_time, time_state)
        || parse_time_num    (in_time, time_state)
        || parse_time_literal(in_time, time_state)
           ))
    {
        char msg[99];
        char *in_str;
        STRLEN len;

        in_str = SvPV(in_time, len);
        if (NULL == in_str)
            sprintf(msg, "Can't understand time value");
        else
            sprintf(msg, "Can't understand time value \"%.50s\"", in_str);
        c_croak(msg);
    }
}

#define THISCHAR      (st->fmt[0])
#define NEXTCHAR      (st->fmt[1])
#define CHARPLUS2     (st->fmt[2])
#define FORMATCODE(f) (forward(st->fmt, (f)))

/* time_format
   Given a format, and a string that represents a time number, returns a malloc'd output string.
   The time input is a string, because it could be ten digits plus six or more decimals, which
   exceeds the precision of most double-precision floats.  So we parse it into a long and a double.
   See the documentation for the Time::Format module on what formats are expanded.
*/
char *time_format(const char *fmt, SV *in_time)
{
    struct state_struct mystate;
    state st = &mystate;
    BUG ((stderr, "time_format: begins\n"));

    /* Parse the in_time parameter into the state structure */
    in_parse(in_time, st);

    BUG((stderr, "tf: st->year  = %d\n", st->year));
    BUG((stderr, "tf: st->month = %d\n", st->month));
    BUG((stderr, "tf: st->day   = %d\n", st->day));
    BUG((stderr, "tf: st->hour  = %d\n", st->hour));
    BUG((stderr, "tf: st->min   = %d\n", st->min));
    BUG((stderr, "tf: st->sec   = %d\n", st->sec));
    BUG((stderr, "tf: st->dow   = %d\n", st->dow));
    BUG((stderr, "tf: st->milli = %d\n", st->milli));
    BUG((stderr, "tf: st->micro = %d\n", st->micro));
    BUG((stderr, "tf: st->h12   = %d\n", st->h12));
    BUG((stderr, "tf: st->tzone = [%s]\n", st->tzone));

    /* other intialization */
    st->length = 0;
    st->fmt    = st->start = fmt;
    st->out = st->outptr = NULL;

    /* First, compute length of result string.  Then actually populate it. */
    for (st->modifying=0; st->modifying<=1; st->modifying++)
    {
        st->quoting = st->upper = st->lower = st->ucnext = st->lcnext = 0;

        while (THISCHAR)
        {
            char *jump;

            if (st->quoting)
                jump = strstr(st->fmt, "\\E");    /* look for end of literal-quote */
            else
                jump = strpbrk(st->fmt, "\\dDy?hHsaApPMmWwutT");  /* jump to one of these */

            if (NULL == jump)
            {
                packstr_mc (st, strlen(st->fmt), st->fmt);
                break;
            }
            else if (jump > st->fmt)    /* skip over the section that does not contain codes */
            {
                packstr_mc_limit (st, jump - st->fmt, st->fmt, jump - st->fmt);
            }

            switch (THISCHAR)
            {
            case '\\':        /* escape character */
                switch (NEXTCHAR)
                {
                case 'Q':  bs_Q(st);    break;
                case 'E':  bs_E(st);    break;
                case 'U':  bs_U(st);    break;
                case 'L':  bs_L(st);    break;
                case 'u':  bs_u(st);    break;
                case 'l':  bs_l(st);    break;
                default :  bs_literal(st); break;
                }
                break;

            case 'd':        /* dd, day, d */

                if      (NEXTCHAR == 'd')    dd(st);
                else if (FORMATCODE("day"))  day(st);
                else                         d(st);
                break;

            case 'y':        /* yyyy, yy */

                if      (FORMATCODE("yyyy"))  yyyy(st);
                else if (FORMATCODE("yy"))    yy(st);
                else                          literal(st);
                break;

            case 'h':        /* hh, h */

                if (NEXTCHAR == 'h')  hh(st);
                else                  h(st);
                break;

            case 'H':        /* HH, H */

                if (NEXTCHAR == 'H')  HH(st);
                else                   H(st);
                break;

            case 's':        /* ss, s */

                if (NEXTCHAR == 's')  ss(st);
                else                  s(st);
                break;

            case 'm':        /* month, mon, mm{on}, m{on}, mm{in}, m{in}, mmm, mm, m */

                if      (FORMATCODE("month"))   month(st);
                else if (FORMATCODE("mon"))     mon(st);
                else if (FORMATCODE("mm{on}"))  mm_on_(st);
                else if (FORMATCODE("m{on}"))   m_on_(st);
                else if (FORMATCODE("mm{in}"))  mm_in_(st);
                else if (FORMATCODE("m{in}"))   m_in_(st);
                else if (FORMATCODE("mmm"))     mmm(st);
                else if (NEXTCHAR == 'm')       mm(st);
                else                            m(st);
                break;

            case 'M':        /* Month, MONTH, Mon, MON */

                if      (FORMATCODE("Month"))  Month(st);
                else if (FORMATCODE("MONTH"))  MONTH(st);
                else if (FORMATCODE("Mon"))    Mon(st);
                else if (FORMATCODE("MON"))    MON(st);
                else                           literal(st);
                break;

            case 'W':        /* Weekday, WEEKDAY */

                if      (FORMATCODE("Weekday"))  Weekday(st);
                else if (FORMATCODE("WEEKDAY"))  WEEKDAY(st);
                else                             literal(st);
                break;

            case 'w':        /* weekday */

                if      (FORMATCODE("weekday"))   weekday(st);
                else                              literal(st);
                break;

            case 'D':        /* Day, DAY */

                if      (FORMATCODE("Day"))  Day(st);
                else if (FORMATCODE("DAY"))  DAY(st);
                else                         literal(st);
                break;

            case 'a':        /* am, a.m. */

                if      (FORMATCODE("am"))    am(st);
                else if (FORMATCODE("a.m."))  a_m_(st);
                else                          literal(st);
                break;

            case 'p':        /* pm, p.m. */

                if      (FORMATCODE("pm"))    pm(st);
                else if (FORMATCODE("p.m."))  p_m_(st);
                else                          literal(st);
                break;

            case 'A':        /* AM, A.M. */

                if      (FORMATCODE("AM"))    AM(st);
                else if (FORMATCODE("A.M."))  A_M_(st);
                else                          literal(st);
                break;

            case 'P':        /* PM, P.M. */

                if      (FORMATCODE("PM"))    PM(st);
                else if (FORMATCODE("P.M."))  P_M_(st);
                else                          literal(st);
                break;

            case '?':        /* ?d, ?h, ?H, ?s, ?m{on}, ?m{in}, ?m */

                switch (NEXTCHAR)
                {
                case 'd':  _d(st);  break;
                case 'h':  _h(st);  break;
                case 'H':  _H(st);  break;
                case 's':  _s(st);  break;
                case 'm':
                    if      (FORMATCODE("?m{on}"))  _m_on_(st);
                    else if (FORMATCODE("?m{in}"))  _m_in_(st);
                    else                            _m(st);
                    break;

                default:  literal(st);   /* just a question mark */
                }
                break;

            case 'u':        /* uuuuuu (microseconds) */

                if (FORMATCODE("uuuuuu"))  uuuuuu(st);
                else
                    literal(st);
                break;

            case 't':        /* th, tz */
                if      (NEXTCHAR == 'h')  th(st);
                else if (NEXTCHAR == 'z')  tz(st);
                else                       literal(st);
                break;

            case 'T':        /* TH */

                if      (NEXTCHAR == 'H')  TH(st);
                else                       literal(st);
                break;

            default:
                literal(st);
                break;
            }

        }
        if (st->modifying)
            *(st->outptr) = '\0';
        else
        {
            st->out = st->outptr = malloc(st->length+1);
            if (NULL == st->out) return st->out;  /* Yikes */
            st->fmt = st->start;    /* Start over! */
        }
    }

    return st->out;
}

/*
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.9 (Cygwin)

iEYEARECAAYFAko671oACgkQwoSYc5qQVqrGTgCfbXD94tpfPSRMv7KLmnx4eDWe
ZXkAoJiyBxkQ0sLJ7/NOYMCdjW6wfT88
=lQyf
-----END PGP SIGNATURE-----
*/
