use Test::More tests => 31;

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
ok (defined &normalize_rct, 'normalize_rct sub imported');


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


my ($year, $mon, $day, $hour, $min, $sec, $hash, @vals);

# ISO
# scalar return
eval { $hash = normalize_rct('iso',
                             '2008-05-11T09:59:19',
                             '2008', '05', '11', '09', '59', '19') };
is ($@,    '', q{iso, scalar: no error});
is_deeply ($hash,
       {
        year => 2008, mon => '05', day => 11,
        dow  => 0,
        dow_name => $SUNDAY,
        dow_abbr => $SUN,
        mon_name => $MAY_FULL,
        mon_abbr => $MAY,
        h12  => 9,
        h24  => '09',
        hour => '09',
        min  => 59,
        sec  => 19,
        ampm => 'a',
        since_midnight => ((9*60)+59)*60+19,
       },
       'iso, scalar');

# list return
eval { @vals = normalize_rct('iso',
                             '2008-05-11T09:59:19',
                             '2008', '05', '22', '09', '59', '19') };
is ($@,    '', q{iso, list: no error});
is_deeply (\@vals,
       [
        2008, '05', 22,
        '09', 59, 19,
       ],
       'iso, list');

# mail
# scalar context
eval { $hash = normalize_rct('mail',
                             '11 May 2008 09:59:19 +0500',
                             '11', 'May', '2008', '09', '59', '19', '+0500') };
is ($@,    '', q{mail, scalar: no error});
is_deeply ($hash,
       {
        year => 2008, mon => '05', day => 11,
        dow  => 0,
        dow_name => $SUNDAY,
        dow_abbr => $SUN,
        mon_name => $MAY_FULL,
        mon_abbr => $MAY,
        h12  => 9,
        h24  => '09',
        hour => '09',
        min  => 59,
        sec  => 19,
        ampm => 'a',
        since_midnight => ((9*60)+59)*60+19,
       },
       'mail, scalar');

# list context
eval { @vals = normalize_rct('MAIL',
                             '11 May 2008 09:59:19 +0500',
                             '11', 'May', '2008', '09', '59', '19', '+0500') };
is ($@,    '', q{MAIL, list: no error});
is_deeply (\@vals,
       [
        2008, '05', 11,
        '09', 59, 19,
       ],
       'mail, list');


# american
# scalar context
eval { $hash = normalize_rct('american',
                             "$MARCH 9, '02",
                             $MARCH, 9, "'02") };
is ($@,    '', q{american, scalar: no error});
is_deeply ($hash,
       {
        year => 2002, mon => '03', day => '09',
        dow  => 6,
        dow_name => $SATURDAY,
        dow_abbr => $SAT,
        mon_name => $MARCH,
        mon_abbr => $MAR,
       },
       'american, scalar');

# list context
eval { @vals = normalize_rct('american',
                             "$MARCH 9, '02",
                             $MARCH, 9, "'02") };
is ($@,    '', q{american, list: no error});
is_deeply (\@vals,
       [
        2002, '03', '09',
        6, $SATURDAY, $SAT,
        $MARCH, $MAR,
       ],
       'american, list');


# ymd
# scalar context
eval { $hash = normalize_rct('ymd',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{ymd, scalar: no error});
is_deeply ($hash,
       {
        year => 2001, mon => '02', day => '03',
        dow  => 6,
        dow_name => $SATURDAY,
        dow_abbr => $SAT,
        mon_name => $FEBRUARY,
        mon_abbr => $FEB,
       },
       'ymd, scalar');

# list context
eval { @vals = normalize_rct('ymd',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{ymd, list: no error});
is_deeply (\@vals,
       [
        2001, '02', '03',
        6, $SATURDAY, $SAT,
        $FEBRUARY, $FEB,
       ],
       'ymd, list');


# mdy
# scalar context
eval { $hash = normalize_rct('mdy',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{mdy, scalar: no error});
is_deeply ($hash,
       {
        year => 2003, mon => '01', day => '02',
        dow  => 4,
        dow_name => $THURSDAY,
        dow_abbr => $THU,
        mon_name => $JANUARY,
        mon_abbr => $JAN,
       },
       'mdy, scalar');

# list context
eval { @vals = normalize_rct('mdy',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{mdy, list: no error});
is_deeply (\@vals,
       [
        2003, '01', '02',
        4, $THURSDAY, $THU,
        $JANUARY, $JAN,
       ],
       'mdy, list');


# dmy
# scalar context
eval { $hash = normalize_rct('dmy',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{dmy, scalar: no error});
is_deeply ($hash,
       {
        year => 2003, mon => '02', day => '01',
        dow  => 6,
        dow_name => $SATURDAY,
        dow_abbr => $SAT,
        mon_name => $FEBRUARY,
        mon_abbr => $FEB,
       },
       'dmy, scalar');

# list context
eval { @vals = normalize_rct('dmy',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{dmy, list: no error});
is_deeply (\@vals,
       [
        2003, '02', '01',
        6, $SATURDAY, $SAT,
        $FEBRUARY, $FEB,
       ],
       'dmy, list');


# hms
# scalar context
eval { $hash = normalize_rct('hms',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{hms, scalar: no error});
is_deeply ($hash,
       {
        h12  => 1,
        h24  => '01',
        hour => '01',
        min  => '02',
        sec  => '03',
        ampm => 'a',
        since_midnight => ((1*60)+2)*60+3,
       },
       'hms, scalar');

# list context
eval { @vals = normalize_rct('hms',
                             '01.02.03',
                             '01', '02', '03') };
is ($@,    '', q{hms, list: no error});
is_deeply (\@vals,
       [
        '01', '02', '03',
        1,
        'a',
        ((1*60)+2)*60+3,
       ],
       'hms, list');


# Unknown
eval { $hash = normalize_rct('brzyxct',
                             '01.02.03.04.05',
                             '01', '02', '03', '04', '05') };
ok begins_with ($@, 'Unknown Regexp::Common::time pattern: "brzyxct"', q{Unknown type: error});
