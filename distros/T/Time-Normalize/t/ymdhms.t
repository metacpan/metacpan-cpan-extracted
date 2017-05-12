use Test::More tests => 20;

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

use_ok ('Time::Normalize');

# function exported okay?
ok (defined &normalize_ymdhms, 'normalize_ymdhms sub imported');


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


my ($year, $mon, $day, $hour, $min, $sec, $hash);

# Simple basic case
eval {($year, $mon, $day, $hour, $min, $sec)
          = normalize_ymdhms(2005, 11, 8, 13, 14, 15) };
is ($@,    '', q{basic test: no error});
is_deeply ([$year, $mon, $day, $hour, $min, $sec],
           [2005, 11, '08', 13, 14, 15], 'basic test');

# Simple basic case: with am/pm
eval {($year, $mon, $day, $hour, $min, $sec)
          = normalize_ymdhms(2005, 11, 8, 4, 14, 15, 'am') };
is ($@,    '', q{basic test am: no error});
is_deeply ([$year, $mon, $day, $hour, $min, $sec],
           [2005, 11, '08', '04', 14, 15], 'basic test, am');

eval {($year, $mon, $day, $hour, $min, $sec)
          = normalize_ymdhms(2005, 11, 8, 4, 14, 15, 'pm') };
is ($@,    '', q{basic test pm: no error});
is_deeply ([$year, $mon, $day, $hour, $min, $sec],
           [2005, 11, '08', 16, 14, 15], 'basic test, pm');

# Basic case, with no seconds
eval {($year, $mon, $day, $hour, $min, $sec)
          = normalize_ymdhms(2005, 11, 8, 13, 14) };
is ($@,    '', q{basic test, no seconds: no error});
is_deeply ([$year, $mon, $day, $hour, $min, $sec],
           [2005, 11, '08', 13, 14, '00'], 'basic test, no seconds');

# Too many args
eval {($year, $mon, $day, $hour, $min, $sec)
          = normalize_ymdhms(2005, 11, 8, 3, 0, 0, 'am', 'A.D.') };
ok (begins_with ($@, 'Too many arguments to normalize_ymdhms'), q{too many ymdhms args});

# Too few args
eval {($year, $mon, $day, $hour, $min, $sec) = normalize_ymdhms(2005, 11) };
ok (begins_with ($@, 'Too few arguments to normalize_ymdhms'), q{too few ymdhms args});


# Hash usage
eval {$hash = normalize_ymdhms(2005, 11, 8, 13, 14, 15) };
is ($@,    '', q{basic hash: no error});
is_deeply ($hash,
       {
        year => 2005, mon => 11, day => '08',
        dow  => 2,
        dow_name => $TUESDAY,
        dow_abbr => $TUE,
        mon_name => $NOVEMBER,
        mon_abbr => $NOV,
        h12  => 1,
        h24  => 13,
        hour => 13,
        min  => 14,
        sec  => 15,
        ampm => 'p',
        since_midnight => 47_655,
       },
       'basic hash');

# Simple basic case: with am/pm
eval {$hash = normalize_ymdhms(2005, 11, 8, 4, 14, 15, 'am') };
is ($@,    '', q{basic hash am: no error});
is_deeply ($hash,
       {
        year => 2005, mon => 11, day => '08',
        dow  => 2,
        dow_name => $TUESDAY,
        dow_abbr => $TUE,
        mon_name => $NOVEMBER,
        mon_abbr => $NOV,
        h12  => 4,
        h24  => '04',
        hour => '04',
        min  => 14,
        sec  => 15,
        ampm => 'a',
        since_midnight => 15_255,
       },
       'basic hash, am');

eval {$hash = normalize_ymdhms(2005, 11, 8, 4, 14, 15, 'pm') };
is ($@,    '', q{basic hash pm: no error});
is_deeply ($hash,
       {
        year => 2005, mon => 11, day => '08',
        dow  => 2,
        dow_name => $TUESDAY,
        dow_abbr => $TUE,
        mon_name => $NOVEMBER,
        mon_abbr => $NOV,
        h12  => 4,
        h24  => 16,
        hour => 16,
        min  => 14,
        sec  => 15,
        ampm => 'p',
        since_midnight => 58_455,
       },
       'basic hash, pm');

# Basic case, with no seconds
eval {$hash = normalize_ymdhms(2005, 11, 8, 13, 14) };
is ($@,    '', q{basic hash, no seconds: no error});
is_deeply ($hash,
       {
        year => 2005, mon => 11, day => '08',
        dow  => 2,
        dow_name => $TUESDAY,
        dow_abbr => $TUE,
        mon_name => $NOVEMBER,
        mon_abbr => $NOV,
        h12  => 1,
        h24  => 13,
        hour => 13,
        min  => 14,
        sec  => '00',
        ampm => 'p',
        since_midnight => 47_640,
       },
       'basic hash, no seconds');
