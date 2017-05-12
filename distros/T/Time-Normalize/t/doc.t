use Test::More tests => 21;

sub begins_with
{
    my ($got, $exp) = @_;
    my $ok = substr($got,0,length $exp) eq $exp;
    if (!$ok)
    {
        diag "expected '$exp...'\n",
             "     got '$got'\n";
    }
    return $ok;
}

# Figure out the month and day names in this locale
my ($JANUARY, $FEBRUARY, $MARCH, $APRIL, $MAY_FULL, $JUNE, $JULY, $AUGUST, $SEPTEMBER, $OCTOBER, $NOVEMBER, $DECEMBER);
my ($JAN, $FEB, $MAR, $APR, $MAY, $JUN, $JUL, $AUG, $SEP, $OCT, $NOV, $DEC);
my ($SUNDAY, $MONDAY, $TUESDAY, $WEDNESDAY, $THURSDAY, $FRIDAY, $SATURDAY);
my ($SUN, $MON, $TUE, $WED, $THU, $FRI, $SAT);
eval
{
    require I18N::Langinfo;
    I18N::Langinfo->import ('langinfo');
    ($JANUARY, $FEBRUARY, $MARCH, $APRIL, $MAY_FULL, $JUNE, $JULY, $AUGUST, $SEPTEMBER, $OCTOBER, $NOVEMBER, $DECEMBER)
        = map langinfo($_), I18N::Langinfo::MON_1(), I18N::Langinfo::MON_2(), I18N::Langinfo::MON_3(), I18N::Langinfo::MON_4(), I18N::Langinfo::MON_5(), I18N::Langinfo::MON_6(), I18N::Langinfo::MON_7(), I18N::Langinfo::MON_8(), I18N::Langinfo::MON_9(), I18N::Langinfo::MON_10(), I18N::Langinfo::MON_11(), I18N::Langinfo::MON_12();
    ($JAN, $FEB, $MAR, $APR, $MAY, $JUN, $JUL, $AUG, $SEP, $OCT, $NOV, $DEC)
        = map langinfo($_), I18N::Langinfo::ABMON_1(), I18N::Langinfo::ABMON_2(), I18N::Langinfo::ABMON_3(), I18N::Langinfo::ABMON_4(), I18N::Langinfo::ABMON_5(), I18N::Langinfo::ABMON_6(), I18N::Langinfo::ABMON_7(), I18N::Langinfo::ABMON_8(), I18N::Langinfo::ABMON_9(), I18N::Langinfo::ABMON_10(), I18N::Langinfo::ABMON_11(), I18N::Langinfo::ABMON_12();
    ($SUNDAY, $MONDAY, $TUESDAY, $WEDNESDAY, $THURSDAY, $FRIDAY, $SATURDAY)
        = map langinfo($_), I18N::Langinfo::DAY_1(), I18N::Langinfo::DAY_2(), I18N::Langinfo::DAY_3(), I18N::Langinfo::DAY_4(), I18N::Langinfo::DAY_5(), I18N::Langinfo::DAY_6(), I18N::Langinfo::DAY_7();
    ($SUN, $MON, $TUE, $WED, $THU, $FRI, $SAT)
        = map langinfo($_), I18N::Langinfo::ABDAY_1(), I18N::Langinfo::ABDAY_2(), I18N::Langinfo::ABDAY_3(), I18N::Langinfo::ABDAY_4(), I18N::Langinfo::ABDAY_5(), I18N::Langinfo::ABDAY_6(), I18N::Langinfo::ABDAY_7();
};
if ($@)
{
    ($JANUARY, $FEBRUARY, $MARCH, $APRIL, $MAY_FULL, $JUNE, $JULY, $AUGUST, $SEPTEMBER, $OCTOBER, $NOVEMBER, $DECEMBER)
        = qw(January February March April May June July August September October November December);
    ($JAN, $FEB, $MAR, $APR, $MAY, $JUN, $JUL, $AUG, $SEP, $OCT, $NOV, $DEC)
        = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    ($SUNDAY, $MONDAY, $TUESDAY, $WEDNESDAY, $THURSDAY, $FRIDAY, $SATURDAY)
        = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    ($SUN, $MON, $TUE, $WED, $THU, $FRI, $SAT)
        = qw(Sun Mon Tue Wed Thu Fri Sat);
}

use_ok ('Time::Normalize');

# All exports okay?
ok (defined &normalize_hms, 'normalize_hms sub imported');
ok (defined &normalize_ymd, 'normalize_ymd sub imported');
ok (defined &normalize_time, 'normalize_time sub imported');
ok (defined &normalize_gmtime, 'normalize_gmtime sub imported');

# Example 1
$h = normalize_ymd (2005, lc($JANUARY), 4);
is_deeply ($h,
       {
        day =>        "04",
        dow =>        2,
        dow_abbr =>   $TUE,
        dow_name =>   $TUESDAY,
        mon =>        "01",
        mon_abbr =>   $JAN,
        mon_name =>   $JANUARY,
        year =>       2005,
       },
           q{Example 1, hashref});

@v = normalize_ymd (2005, lc $JANUARY, 4);
is_deeply (\@v, [2005, "01", "04", 2, $TUESDAY, $TUE, $JANUARY, $JAN],
           q{Example 1, list context});

$h = normalize_ymd ('05', 12, 31);
is_deeply ($h,
       {
        day =>        31,
        dow =>        6,
        dow_abbr =>   $SAT,
        dow_name =>   $SATURDAY,
        mon =>        12,
        mon_abbr =>   $DEC,
        mon_name =>   $DECEMBER,
        year =>       2005,
       },
           q{Example 2, hashref});

@v = normalize_ymd ('05', 12, 31);
is_deeply (\@v, [2005, 12, 31, 6, $SATURDAY, $SAT, $DECEMBER, $DEC],
           q{Example 2, list context});


eval {$h = normalize_ymd (2005, 2, 29)};
ok (begins_with($@, q{Time::Normalize: Invalid day: "29"}), q{Example 3, error});


$h = normalize_hms (9, 10, 0, 'AM');
is_deeply ($h,
       {
        ampm =>       "a",
        h12 =>        9,
        h24 =>        "09",
        hour =>       "09",
        min =>        10,
        sec =>        "00",
        since_midnight =>    33000,
       },
           q{Example 4, hashref});

@v = normalize_hms (9, 10, 0, 'AM');
is_deeply (\@v, ["09", 10, "00", 9, "a", 33000], q{Example 4, list context});

$h = normalize_hms (9, 10, undef, 'p.m.');
is_deeply ($h,
       {
        ampm =>       "p",
        h12 =>        9,
        h24 =>        21,
        hour =>       21,
        min =>        10,
        sec =>        "00",
        since_midnight =>    76200,
       },
           q{Example 5, hashref});

@v = normalize_hms (9, 10, undef, 'p.m.');
is_deeply (\@v, [21, 10, "00", 9, "p", 76200], q{Example 5, list context});

$h = normalize_hms (1, 10);
is_deeply ($h,
       {
        ampm =>       "a",
        h12 =>        1,
        h24 =>        "01",
        hour =>       "01",
        min =>        10,
        sec =>        "00",
        since_midnight =>    4200,
       },
           q{Example 6, hashref});

@v = normalize_hms (1, 10);
is_deeply (\@v, ["01", 10, "00", 1, "a", 4200], q{Example 6, list context});

$h = normalize_hms (13, 10);
is_deeply ($h,
       {
        ampm =>       "p",
        h12 =>        1,
        h24 =>        13,
        hour =>       13,
        min =>        10,
        sec =>        "00",
        since_midnight =>    47400,
       },
           q{Example 7, hashref});

@v = normalize_hms (13, 10);
is_deeply (\@v, [13, 10, "00", 1, "p", 47400], q{Example 7, list context});

eval {$h = normalize_hms (13, 10, undef, 'pm')};
ok (begins_with($@, q{Time::Normalize: Invalid hour: "13"}),
                q{Example 8, error});

$h = normalize_gmtime(1131725587);
is_deeply ($h,
       {
        sec   =>    "07",
        min   =>    13,
        hour   =>   16,
        h24    =>   16,
        day   =>    11,
        mon   =>    11,
        year   =>   2005,
        dow   =>    5,
        yday   =>   314,
        isdst   =>  0,
        h12   =>    4,
        ampm   =>   "p",
        since_midnight   =>    58_387,
        dow_name   =>    $FRIDAY,
        dow_abbr   =>    $FRI,
        mon_name   =>    $NOVEMBER,
        mon_abbr   =>    $NOV,
       },
           q{Example 9, hashref});

@v = normalize_gmtime(1131725587);
is_deeply (\@v,
           ["07", 13, 16, 11, 11, 2005, 5, 314, 0, 4, "p", 58_387, $FRIDAY, $FRI, $NOVEMBER, $NOV],
           q{Example 9, list context});
