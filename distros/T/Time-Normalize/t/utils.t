use Test::More tests => 87;

sub begins_with
{
    my ($got, $exp, $name) = @_;
    my $ok = substr($got,0,length $exp) eq $exp;
    if (!$ok)
    {
        diag "expected '$exp...'\n",
             "     got '$got'\n";
    }
    ok $ok, $name;
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

use_ok ('Time::Normalize', qw(mon_name mon_abbr day_name day_abbr days_in is_leap));

# All exports okay?
ok (defined &mon_name, 'mon_name sub imported');
ok (defined &mon_abbr, 'mon_abbr sub imported');
ok (defined &day_name, 'day_name sub imported');
ok (defined &day_abbr, 'day_abbr sub imported');

ok (defined &days_in, 'days_in sub imported');
ok (defined &is_leap, 'is_leap sub imported');

# Month full-names
is (mon_name( 1), $JANUARY,   'January');
is (mon_name( 2), $FEBRUARY,  'February');
is (mon_name( 3), $MARCH,     'March');
is (mon_name( 4), $APRIL,     'April');
is (mon_name( 5), $MAY_FULL,  'May');
is (mon_name( 6), $JUNE,      'June');
is (mon_name( 7), $JULY,      'July');
is (mon_name( 8), $AUGUST,    'August');
is (mon_name( 9), $SEPTEMBER, 'September');
is (mon_name(10), $OCTOBER,   'October');
is (mon_name(11), $NOVEMBER,  'November');
is (mon_name(12), $DECEMBER,  'December');

# Month abbreviations
is (mon_abbr( 1), $JAN, 'Jan');
is (mon_abbr( 2), $FEB, 'Feb');
is (mon_abbr( 3), $MAR, 'Mar');
is (mon_abbr( 4), $APR, 'Apr');
is (mon_abbr( 5), $MAY, 'May');
is (mon_abbr( 6), $JUN, 'Jun');
is (mon_abbr( 7), $JUL, 'Jul');
is (mon_abbr( 8), $AUG, 'Aug');
is (mon_abbr( 9), $SEP, 'Sep');
is (mon_abbr(10), $OCT, 'Oct');
is (mon_abbr(11), $NOV, 'Nov');
is (mon_abbr(12), $DEC, 'Dec');

# Weekday names
is (day_name( 0), $SUNDAY,    'Sunday');
is (day_name( 1), $MONDAY,    'Monday');
is (day_name( 2), $TUESDAY,   'Tuesday');
is (day_name( 3), $WEDNESDAY, 'Wednesday');
is (day_name( 4), $THURSDAY,  'Thursday');
is (day_name( 5), $FRIDAY,    'Friday');
is (day_name( 6), $SATURDAY,  'Saturday');

# Weekday abbreviations
is (day_abbr( 0), $SUN, 'Sun');
is (day_abbr( 1), $MON, 'Mon');
is (day_abbr( 2), $TUE, 'Tue');
is (day_abbr( 3), $WED, 'Wed');
is (day_abbr( 4), $THU, 'Thu');
is (day_abbr( 5), $FRI, 'Fri');
is (day_abbr( 6), $SAT, 'Sat');

# Too few args
eval { mon_name(); };
begins_with ($@, "Too few arguments to mon_name", "Too few (mon_name)");
eval { mon_abbr(); };
begins_with ($@, "Too few arguments to mon_abbr", "Too few (mon_abbr)");
eval { day_name(); };
begins_with ($@, "Too few arguments to day_name", "Too few (day_name)");
eval { day_abbr(); };
begins_with ($@, "Too few arguments to day_abbr", "Too few (day_abbr)");
eval { is_leap(); };
begins_with ($@, "Too few arguments to is_leap", "Too few (is_leap)");
eval { days_in(); };
begins_with ($@, "Too few arguments to days_in", "Too few (days_in)");

# Too many args
eval { mon_name(1,2); };
begins_with ($@, "Too many arguments to mon_name", "Too many (mon_name)");
eval { mon_abbr(-1,3); };
begins_with ($@, "Too many arguments to mon_abbr", "Too many (mon_abbr)");
eval { day_name('a','b'); };
begins_with ($@, "Too many arguments to day_name", "Too many (day_name)");
eval { day_abbr(undef, undef, undef); };
begins_with ($@, "Too many arguments to day_abbr", "Too many (day_abbr)");
eval { is_leap(1,3); };
begins_with ($@, "Too many arguments to is_leap", "Too many (is_leap)");
eval { days_in(2,4,3); };
begins_with ($@, "Too many arguments to days_in", "Too many (days_in)");

# Non-integer value
eval { mon_name('blah'); };
begins_with ($@, "Non-integer month \"blah\" for mon_name",   "Non-integer (mon_name)");
eval { mon_abbr('7h'); };
begins_with ($@, "Non-integer month \"7h\" for mon_abbr",   "Non-integer (mon_abbr)");
eval { day_name('h7'); };
begins_with ($@, "Non-integer weekday \"h7\" for day_name", "Non-integer (day_name)");
eval { day_abbr(''); };
begins_with ($@, "Non-integer weekday \"\" for day_abbr", "Non-integer (day_abbr)");
eval { days_in('abcd', 45); };
begins_with ($@, "Non-integer month \"abcd\" for days_in", "Non-integer (days_in)");

# Value too low
eval { mon_name(0); };
begins_with ($@, "Time::Normalize: Invalid month: \"0\"", "Too low (mon_name)");
eval { mon_abbr(0); };
begins_with ($@, "Time::Normalize: Invalid month: \"0\"", "Too low (mon_abbr)");

# Value too high
eval { mon_name(13); };
begins_with ($@, "Time::Normalize: Invalid month: \"13\"", "Too high (mon_name)");
eval { mon_abbr(13); };
begins_with ($@, "Time::Normalize: Invalid month: \"13\"", "Too high (mon_abbr)");
eval { day_name(7); };
begins_with ($@, "Time::Normalize: Invalid weekday-number: \"7\"", "Too high (day_name)");
eval { day_abbr(7); };
begins_with ($@, "Time::Normalize: Invalid weekday-number: \"7\"", "Too high (day_abbr)");

# is_leap
ok ( is_leap(1996), '1996 is a leap year');
ok ( is_leap(2000), '2000 is a leap year');
ok ( is_leap(2004), '2000 is a leap year');
ok (!is_leap(1995), '1995 is not a leap year');
ok (!is_leap(1900), '1900 is not a leap year');
ok (!is_leap(2100), '2100 is not a leap year');

# days_in
is (days_in( 1, undef), 31, 'Jan: 31 days');
is (days_in( 2, 2008),  29, 'Feb: 29 in leap year');
is (days_in( 2, 2009),  28, 'Feb: 28 in non-leap year');
is (days_in( 3, undef), 31, 'Mar: 31 days');
is (days_in( 4, undef), 30, 'Apr: 30 days');
is (days_in( 5, undef), 31, 'May: 31 days');
is (days_in( 6, undef), 30, 'Jun: 31 days');
is (days_in( 7, undef), 31, 'Jul: 31 days');
is (days_in( 8, undef), 31, 'Aug: 31 days');
is (days_in( 9, undef), 30, 'Sep: 31 days');
is (days_in(10, undef), 31, 'Oct: 31 days');
is (days_in(11, undef), 30, 'Nov: 31 days');
is (days_in(12, undef), 31, 'Dec: 31 days');
