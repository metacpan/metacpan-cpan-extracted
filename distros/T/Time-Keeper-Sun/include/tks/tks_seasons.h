#ifndef TKS_SEASONS_H
#define TKS_SEASONS_H

/* The equinoxes and solstices by chapter 27: the JDE of the mean event from
 * the polynomials of tables 27.A (years before 1000) and 27.B (1000 on), the
 * correction of 27.1 from the 24 periodic terms of table 27.C. The book
 * states the result within 51 s for 1951 to 2050 and valid for -1000 to
 * 3000; before -1000 the polynomials are extrapolated. Tables in
 * sources/meeus-27-terms.tsv. */

#define TKS_SEASON_MARCH     0
#define TKS_SEASON_JUNE      1
#define TKS_SEASON_SEPTEMBER 2
#define TKS_SEASON_DECEMBER  3

static const char *const tks_season_name[4] = { "march", "june", "september", "december" };

static const double tks_season_c0[4][5] = {
    { 1721139.29189, 365242.13740,  0.06134,  0.00111, -0.00071 },
    { 1721233.25401, 365241.72562, -0.05232,  0.00907,  0.00025 },
    { 1721325.70455, 365242.49558, -0.11677, -0.00297,  0.00074 },
    { 1721414.39987, 365242.88257, -0.00769, -0.00933, -0.00006 },
};
static const double tks_season_c2[4][5] = {
    { 2451623.80984, 365242.37404,  0.05169, -0.00411, -0.00057 },
    { 2451716.56767, 365241.62603,  0.00325,  0.00888, -0.00030 },
    { 2451810.21715, 365242.01767, -0.11575,  0.00337,  0.00078 },
    { 2451900.05952, 365242.74049, -0.06223, -0.00823,  0.00032 },
};
static const double tks_season_terms[24][3] = {
    { 485, 324.96,   1934.136 }, { 203, 337.23,  32964.467 }, { 199, 342.08,     20.186 },
    { 182,  27.85, 445267.112 }, { 156,  73.14,  45036.886 }, { 136, 171.52,  22518.443 },
    {  77, 222.54,  65928.934 }, {  74, 296.72,   3034.906 }, {  70, 243.58,   9037.513 },
    {  58, 119.81,  33718.147 }, {  52, 297.17,    150.678 }, {  50,  21.02,   2281.226 },
    {  45, 247.54,  29929.562 }, {  44, 325.15,  31555.956 }, {  29,  60.93,   4443.417 },
    {  18, 155.12,  67555.328 }, {  17, 288.79,   4562.452 }, {  16, 198.04,  62894.029 },
    {  14, 199.76,  31436.921 }, {  12,  95.39,  14577.848 }, {  12, 287.11,  31931.756 },
    {  12, 320.81,  34777.259 }, {   9, 227.73,   1222.114 }, {   8,  15.45,  16859.074 },
};

/* The JDE (TT) of a season's event in a year. */
static double
tks_season_jde(int64_t year, int which)
{
    const double *c = year < 1000 ? tks_season_c0[which] : tks_season_c2[which];
    double y = (year < 1000 ? (double)year : (double)(year - 2000)) / 1000.0;
    double J0 = c[0] + y * (c[1] + y * (c[2] + y * (c[3] + y * c[4])));
    double T = tks_T(J0);
    double W = tks_rad(tks_deg_norm(35999.373 * T - 2.47));
    double dl = 1.0 + 0.0334 * cos(W) + 0.0007 * cos(2.0 * W);
    double S = 0.0;
    int i;
    for (i = 0; i < 24; i++)
        S += tks_season_terms[i][0] * cos(tks_rad(tks_deg_norm(tks_season_terms[i][1] + tks_season_terms[i][2] * T)));
    return J0 + 0.00001 * S / dl;
}

/* The event's instant in UT, rounded to the second. */
static int64_t
tks_season_instant(pTHX_ int64_t year, int which)
{
    double jde = tks_season_jde(year, which);
    time_keeper_instant t;
    tks_instant_from_jd(jde, &t);
    return tks_round_jd(jde - tks_delta_t(aTHX_ &t) / 86400.0);
}

/* month => march | june | september | december, as an index. */
static int
tks_season_arg(pTHX_ SV *v, const char *what)
{
    STRLEN len;
    const char *s;
    int i;
    if (v)
        SvGETMAGIC(v);
    if (!v || !SvOK(v))
        croak("%s needs month => march, june, september or december", what);
    s = SvPV(v, len);
    for (i = 0; i < 4; i++)
        if (strlen(tks_season_name[i]) == len && memEQ(s, tks_season_name[i], len))
            return i;
    croak("%s: no season turns in '%.*s' (march, june, september or december)", what, (int)len, s);
    return 0;
}

#endif
