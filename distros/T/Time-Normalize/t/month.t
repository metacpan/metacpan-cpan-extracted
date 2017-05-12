use Test::More tests => 187;

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

# YM export okay?
ok (defined &normalize_month, 'normalize_month sub imported');


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


my ($mon, $mnum);


# Test the twelve month numbers (33)
foreach my $mo (1 .. 9)
{
    eval {$mon = normalize_month($mo) };
    is ($@, '', qq{Month number $mo: no error});
    ok ($mon == $mo, "Month number $mo ==");
    is ($mon, "0$mo", "Month number $mo eq");
}
foreach my $mo (10 .. 12)
{
    eval {$mon = normalize_month($mo) };
    is ($@, '', qq{Month number $mo: no error});
    ok ($mon == $mo, "Month number $mo ==");
}

# Full month names (24)
$mnum = '01';
for my $mname ($JANUARY, $FEBRUARY, $MARCH, $APRIL, $MAY_FULL, $JUNE, $JULY, $AUGUST, $SEPTEMBER, $OCTOBER, $NOVEMBER, $DECEMBER)
{
    eval {$mon = normalize_month($mname) };
    is ($@, '', qq{Month full name $mname: no error});
    ok ($mon eq $mnum, "Month full name $mname");
    ++$mnum;
}

# Full month names, uppercase (24)
$mnum = '01';
for my $mname ($JANUARY, $FEBRUARY, $MARCH, $APRIL, $MAY_FULL, $JUNE, $JULY, $AUGUST, $SEPTEMBER, $OCTOBER, $NOVEMBER, $DECEMBER)
{
    my $ucname = uc $mname;
    eval {$mon = normalize_month($ucname) };
    is ($@, '', qq{Month full name uc $mname: no error});
    ok ($mon eq $mnum, "Month full name uc $ucname");
    ++$mnum;
}

# Full month names, lowercase (24)
$mnum = '01';
for my $mname ($JANUARY, $FEBRUARY, $MARCH, $APRIL, $MAY_FULL, $JUNE, $JULY, $AUGUST, $SEPTEMBER, $OCTOBER, $NOVEMBER, $DECEMBER)
{
    my $lcname = lc $mname;
    eval {$mon = normalize_month($lcname) };
    is ($@, '', qq{Month full name lc $mname: no error});
    ok ($mon eq $mnum, "Month full name lc $lcname");
    ++$mnum;
}

# Month abbreviations (24)
$mnum = '01';
for my $mname ($JAN, $FEB, $MAR, $APR, $MAY, $JUN, $JUL, $AUG, $SEP, $OCT, $NOV, $DEC)
{
    eval {$mon = normalize_month($mname) };
    is ($@, '', qq{Month abbrev $mname: no error});
    ok ($mon eq $mnum, "Month abbrev $mname");
    ++$mnum;
}

# Month abbreviations, uppercase (24)
$mnum = '01';
for my $mname ($JAN, $FEB, $MAR, $APR, $MAY, $JUN, $JUL, $AUG, $SEP, $OCT, $NOV, $DEC)
{
    my $ucname = uc $mname;
    eval {$mon = normalize_month($ucname) };
    is ($@, '', qq{Month abbrev uc $ucname: no error});
    ok ($mon eq $mnum, "Month abbrev uc $ucname");
    ++$mnum;
}

# Month abbreviations, lowercase (24)
$mnum = '01';
for my $mname ($JAN, $FEB, $MAR, $APR, $MAY, $JUN, $JUL, $AUG, $SEP, $OCT, $NOV, $DEC)
{
    my $lcname = lc $mname;
    eval {$mon = normalize_month($lcname) };
    is ($@, '', qq{Month abbrev lc $lcname: no error});
    ok ($mon eq $mnum, "Month abbrev lc $lcname");
    ++$mnum;
}

# Too many args (1)
eval {$mon = normalize_month(1, 2) };
ok (begins_with ($@, 'Too many arguments to normalize_month'), q{too many month args});

# Too few args (1)
eval {$mon = normalize_month() };
ok (begins_with ($@, 'Too few arguments to normalize_month'), q{too few month args});

# Numeric out of range (3)
eval {$mon = normalize_month(0) };
ok (begins_with ($@, 'Time::Normalize: Invalid month'), q{Month zero});

eval {$mon = normalize_month(-1) };
ok (begins_with ($@, 'Time::Normalize: Invalid month'), q{Month negative});

eval {$mon = normalize_month(13) };
ok (begins_with ($@, 'Time::Normalize: Invalid month'), q{Month thirteen});

# Bogus strings (3)
eval {$mon = normalize_month('abcdef') };
ok (begins_with ($@, 'Time::Normalize: Invalid month'), q{Month nonsense string});

eval {$mon = normalize_month(undef) };
ok (begins_with ($@, 'Time::Normalize: Invalid month'), q{Month undef});

eval {$mon = normalize_month('') };
ok (begins_with ($@, 'Time::Normalize: Invalid month'), q{Month empty});

