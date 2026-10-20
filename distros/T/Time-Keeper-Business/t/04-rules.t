#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();

use Time::Keeper;
use Time::Keeper::Business;

my $R = 'Time::Keeper::Business::Rule';
sub d { Time::Keeper::Date->parse($_[0]) }
sub dates { [map { "$_->[0]" } @_] }
sub pairs { [map { [ "$_->[0]", $_->[1] ] } @_] }

# fixed
my $xmas = $R->fixed(month => 12, day => 25, name => 'Christmas Day');
isa_ok($xmas, $R);
is($xmas->name, 'Christmas Day', 'name');
is_deeply(pairs($xmas->holidays(year => 2026)), [['2026-12-25', 'Christmas Day']], 'a fixed date');
is_deeply(dates($R->fixed(month => 2, day => 29)->holidays(year => 2028)), ['2028-02-29'], '29 February in a leap year');
is_deeply(dates($R->fixed(month => 2, day => 29)->holidays(year => 2027)), [], '  and nothing in a common year');
is($R->fixed(month => 1, day => 1)->name, undef, 'no name is undef');
for my $bad ([{ month => 13, day => 1 }, qr/^Time::Keeper::Business::Rule->fixed: month must be 1 to 12/],
             [{ month => 2, day => 30 }, qr/^Time::Keeper::Business::Rule->fixed: --02-30 is not a date/],
             [{ month => 1 }, qr/^Time::Keeper::Business::Rule->fixed: day is needed/],
             [{ month => 'x', day => 1 }, qr/month must be a whole number/],
             [{ month => 1, day => 1, foo => 1 }, qr/^Time::Keeper::Business::Rule->fixed: unknown argument 'foo'/]) {
    ok(!eval { $R->fixed(%{ $bad->[0] }); 1 }, 'fixed refuses');
    like($@, $bad->[1], '  by name');
}

# nth
is_deeply(dates($R->nth(month => 11, day_of_week => 4, n => 4)->holidays(year => 2026)), ['2026-11-26'], 'the fourth Thursday of November 2026');
is_deeply(dates($R->nth(month => 5, day_of_week => 1, n => -1)->holidays(year => 2026)), ['2026-05-25'], 'the last Monday of May 2026');
is_deeply(dates($R->nth(month => 5, day_of_week => 1, n => 1)->holidays(year => 2026)), ['2026-05-04'], 'the first Monday of May 2026');
is_deeply(dates($R->nth(month => 11, day_of_week => 1, n => 5)->holidays(year => 2026)), ['2026-11-30'], 'a fifth Monday that exists');
is_deeply(dates($R->nth(month => 11, day_of_week => 2, n => 5, name => 'Fifth')->holidays(year => 2026)), [], 'a fifth that the year does not have is nothing that year');
is_deeply(dates($R->nth(month => 11, day_of_week => 2, n => 5)->holidays(year => 2027)), ['2027-11-30'], '  and the fifth where there is one');
ok(!eval { $R->nth(month => 1, day_of_week => 1, n => 0); 1 }, 'n of 0 is refused');
like($@, qr/n is 1 to 5, or -1 for the last/, '  by name');
ok(!eval { $R->nth(month => 1, day_of_week => 8, n => 1); 1 }, 'a weekday of 8 is refused');

# easter
is_deeply(dates($R->easter->holidays(year => 2026)), ['2026-04-05'], 'Easter 2026');
is_deeply(dates($R->easter(offset => -2)->holidays(year => 2026)), ['2026-04-03'], 'Good Friday 2026');
is_deeply(dates($R->easter(offset => 1)->holidays(year => 2026)), ['2026-04-06'], 'Easter Monday 2026');
is_deeply(dates($R->easter(offset => 39)->holidays(year => 2026)), ['2026-05-14'], 'Ascension 2026');
is_deeply(dates($R->easter(orthodox => 1)->holidays(year => 2026)), ['2026-04-12'], 'Orthodox Easter 2026');
is_deeply(dates($R->easter(orthodox => 1)->holidays(year => 2027)), ['2027-05-02'], 'Orthodox Easter 2027');
{
    open my $fh, '<', "$FindBin::Bin/easter-1900-2199.tsv" or die "easter table: $!";
    my ($bad_g, $bad_o, $n) = (0, 0, 0);
    my $g = $R->easter;
    my $o = $R->easter(orthodox => 1);
    while (my $line = <$fh>) {
        next if $line =~ /^year/;
        chomp $line;
        my ($year, $greg, $orth) = split /\t/, $line;
        $n++;
        $bad_g++ unless dates($g->holidays(year => $year))->[0] eq $greg;
        $bad_o++ unless dates($o->holidays(year => $year))->[0] eq $orth;
    }
    is($n, 300, 'the Easter table has 300 years');
    is($bad_g, 0, 'the Gregorian computus agrees with the table for 1900 to 2199');
    is($bad_o, 0, 'and the Julian one, on the Gregorian calendar');
}

# relative
my $boxing = $R->relative(rule => $xmas, days => 1, name => 'Boxing Day');
is_deeply(dates($boxing->holidays(year => 2026)), ['2026-12-26'], 'a day after a rule');
is_deeply(dates($R->relative(rule => $xmas->observed('next_business_day'), days => 1)->holidays(year => 2027)), ['2027-12-26'],
          'counted from the rule before its observed move');
ok(!eval { $R->relative(rule => 'x', days => 1); 1 }, 'relative needs a rule');
like($@, qr/rule must be a Time::Keeper::Business::Rule/, '  by name');

# observed
my $nbd = $xmas->observed('next_business_day');
is_deeply(dates($nbd->holidays(year => 2027)), ['2027-12-27'], 'next_business_day: Saturday to Monday');
is_deeply(dates($nbd->holidays(year => 2022)), ['2022-12-26'], '  Sunday to Monday');
is_deeply(dates($nbd->holidays(year => 2026)), ['2026-12-25'], '  a Friday stays');
is_deeply(dates($xmas->holidays(year => 2027)), ['2027-12-25'], '  and the original rule is unchanged');
my $near = $xmas->observed('nearest_business_day');
is_deeply(dates($near->holidays(year => 2027)), ['2027-12-24'], 'nearest_business_day: Saturday to Friday');
is_deeply(dates($near->holidays(year => 2022)), ['2022-12-26'], '  Sunday to Monday');
my $ny = $R->fixed(month => 1, day => 1, name => "New Year's Day")->observed('nearest_business_day');
is_deeply(pairs($ny->holidays(year => 2027)), [['2027-01-01', "New Year's Day"], ['2027-12-31', "New Year's Day"]],
          '  New Year\'s Day 2028, a Saturday, is kept on 31 December 2027 and listed under 2027');
is_deeply(dates($ny->holidays(year => 2028)), [], '  and not under 2028');
is_deeply(dates($xmas->observed('next_monday')->holidays(year => 2027)), ['2027-12-27'], 'next_monday: Saturday');
is_deeply(dates($xmas->observed('next_monday')->holidays(year => 2022)), ['2022-12-26'], '  Sunday');
is_deeply(dates($xmas->observed('next_monday')->holidays(year => 2026)), ['2026-12-25'], '  a Friday stays');
is_deeply(dates($xmas->observed(sub { $_[0]->plus(days => 7) })->holidays(year => 2026)), ['2026-01-01'],
          'a code ref sees every year and may move anywhere: Christmas 2025 plus a week is listed under 2026');
is_deeply(dates($xmas->observed(sub { undef })->holidays(year => 2026)), [], '  or give undef for none');
ok(!eval { $xmas->observed(sub { 'x' })->holidays(year => 2026); 1 }, '  but not a string');
like($@, qr/an observed code ref must give a Time::Keeper::Date or undef/, '  by name');
is_deeply(dates($nbd->observed('none')->holidays(year => 2027)), ['2027-12-25'], 'none takes the move back off');
is_deeply(dates($xmas->observed('next_business_day', weekend => [5, 6])->holidays(year => 2027)), ['2027-12-26'],
          'with a Friday and Saturday weekend, Saturday goes to Sunday');
is_deeply(dates($xmas->observed('nearest_business_day', weekend => [5, 6])->holidays(year => 2027)), ['2027-12-26'],
          '  and the nearest is the Sunday');
is_deeply(dates($xmas->observed('nearest_business_day', weekend => [5, 6])->holidays(year => 2026)), ['2026-12-24'],
          '  a Friday goes back to the Thursday');
ok(!eval { $xmas->observed('sometime'); 1 }, 'an unknown form is refused');
like($@, qr/^Time::Keeper::Business::Rule->observed: the form is none, next_business_day, nearest_business_day, next_monday, previous_business_day, next_business_day_if_sunday or a code ref/, '  by name');
ok(!eval { $xmas->observed('none', weekend => [8]); 1 }, 'a weekend day of 8 is refused');

# the collision in a set
my $ukx = $R->set($xmas->observed('next_business_day'), $boxing->observed('next_business_day'));
is_deeply(pairs($ukx->holidays(year => 2027)), [['2027-12-27', 'Christmas Day'], ['2027-12-28', 'Boxing Day']],
          '2027: Christmas on Saturday takes the Monday, Boxing Day on Sunday the Tuesday');
is_deeply(pairs($ukx->holidays(year => 2026)), [['2026-12-25', 'Christmas Day'], ['2026-12-28', 'Boxing Day']],
          '2026: Boxing Day on Saturday takes the Monday');
is_deeply(pairs($ukx->holidays(year => 2022)), [['2022-12-26', 'Boxing Day'], ['2022-12-27', 'Christmas Day']],
          '2022: Boxing Day on Monday stays, Christmas on Sunday takes the Tuesday');
is_deeply(pairs($ukx->holidays(year => 2021)), [['2021-12-27', 'Christmas Day'], ['2021-12-28', 'Boxing Day']],
          '2021: Saturday and Sunday take Monday and Tuesday');
is($ukx->name, undef, 'a set without a name');
is($R->set($xmas, name => 'x')->name, 'x', '  or with one');
ok(!eval { $R->set(name => 'x'); 1 }, 'a set needs a rule');
like($@, qr/a set needs at least one rule/, '  by name');
ok(!eval { $R->set($xmas, 'name'); 1 }, 'a key needs a value');
my $nested = $R->set($R->set($xmas, $boxing, name => 'inner'), $R->fixed(month => 1, day => 1), name => 'outer');
is(scalar(() = $nested->holidays(year => 2026)), 3, 'a set may hold a set');

# between and only_if
my $since = $xmas->between(from => 2025);
is_deeply(dates($since->holidays(year => 2024)), [], 'between from: not before');
is_deeply(dates($since->holidays(year => 2025)), ['2025-12-25'], '  from the year');
is_deeply(dates($xmas->between(to => 2024)->holidays(year => 2025)), [], 'between to: not after');
is_deeply(dates($xmas->between(from => 2020, to => 2024)->holidays(year => 2022)), ['2022-12-25'], '  within');
is_deeply(dates($xmas->only_if(sub { $_[0] % 2 })->holidays(year => 2026)), [], 'only_if: no in an even year');
is_deeply(dates($xmas->only_if(sub { $_[0] % 2 })->holidays(year => 2027)), ['2027-12-25'], '  yes in an odd one');
is_deeply(dates($R->set($xmas, $boxing)->between(to => 2025)->holidays(year => 2026)), [], 'between on a set covers its members');
is_deeply(dates($R->set($xmas->between(to => 2025), $boxing)->holidays(year => 2026)), ['2026-12-26'], 'and on a member only that member');
ok(!eval { $xmas->only_if('x'); 1 }, 'only_if needs a code ref');
ok(!eval { $xmas->holidays(2026); 1 }, 'holidays needs year =>');
like($@, qr/^Time::Keeper::Business::Rule->holidays: takes year => \$y/, '  by name');
ok(!eval { $xmas->holidays(year => 'x'); 1 }, '  as a number');

# The three countries against the published lists.
{
    open my $fh, '<', "$FindBin::Bin/uk-bank-holidays.tsv" or die "uk table: $!";
    my %want;
    while (my $line = <$fh>) {
        next if $line =~ /^#/;
        chomp $line;
        my ($date, $title, $notes) = split /\t/, $line;
        push @{ $want{ substr $date, 0, 4 } }, [ $date, $title ];
    }
    my $uk = $R->uk;
    is($uk->name, 'England and Wales', 'uk is named');
    for my $year (sort keys %want) {
        is_deeply(pairs($uk->holidays(year => $year)), $want{$year}, "England and Wales $year agrees with gov.uk");
    }
    is_deeply(dates($uk->holidays(year => 2023)), [], 'and says nothing before 2024');
}
{
    open my $fh, '<', "$FindBin::Bin/opm-federal-holidays-2026.tsv" or die "opm table: $!";
    my @want;
    while (my $line = <$fh>) {
        next if $line =~ /^#/;
        chomp $line;
        push @want, [ split /\t/, $line ];
    }
    my $us = $R->us_federal;
    is($us->name, 'United States federal', 'us_federal is named');
    is_deeply(pairs($us->holidays(year => 2026)), \@want, 'the United States federal holidays of 2026 agree with OPM');
    is_deeply(dates($us->holidays(year => 2027)),
              [qw(2027-01-01 2027-01-18 2027-02-15 2027-05-31 2027-06-18 2027-07-05 2027-09-06 2027-10-11 2027-11-11 2027-11-25 2027-12-24 2027-12-31)],
              '2027: Juneteenth on Saturday is Friday the 18th, Independence Day on Sunday is Monday the 5th, Christmas on Saturday is Friday the 24th, and New Year\'s Day 2028 is the 31st');
    is_deeply(dates($us->holidays(year => 2020)), [qw(2020-01-01 2020-01-20 2020-02-17 2020-05-25 2020-07-03 2020-09-07 2020-10-12 2020-11-11 2020-11-26 2020-12-25)],
              '2020 has no Juneteenth');
}
is_deeply(dates($R->target2->holidays(year => 2026)), [qw(2026-01-01 2026-04-03 2026-04-06 2026-05-01 2026-12-25 2026-12-26)], 'TARGET2 2026');

# As a schedule's source.
my $b = Time::Keeper::Business->new(holidays => $R->uk, weekend => 'en-GB');
is($b->is_holiday(d('2027-12-28')), 'Boxing Day', 'a rule as a schedule source, named');
is($b->is_business_day(d('2027-12-28')), 0, '  closes the day');
is($b->is_business_day(d('2027-12-29')), 1, '  and not the next');
is($b->is_holiday(d('2027-12-25')), undef, '  the Saturday itself is not a holiday: the substitute is');
require Storable;
my $thawed = Storable::thaw(Storable::freeze($b));
is($thawed->is_holiday(d('2027-12-28')), 'Boxing Day', 'a schedule with a rule freezes and thaws with its rule');
ok(!eval { Storable::freeze(Time::Keeper::Business->new(holidays => $R->uk->only_if(sub { 1 }))); 1 }, '  but not with a code ref in the rule');
like($@, qr/cannot freeze a schedule whose rules hold a code ref/, '  by name');
ok(!eval { Storable::freeze(Time::Keeper::Business->new(holidays => $R->relative(rule => $R->fixed(month => 1, day => 1)->only_if(sub { 1 }), days => 1))); 1 }, '  nor with one deep in a rule it counts from');
like($@, qr/cannot freeze a schedule whose rules hold a code ref/, '  by the schedule\'s message');
my @fr = Time::Keeper::Business->new(holidays => [ $R->uk, $R->target2 ])->holidays(year => 2026);
is(scalar @fr, 10, 'two sets as sources merge: 8 UK plus May Day and 26 December');

# The shapes of 0.02: a weekday on or after, a sandwiched day, except and also, two observed forms, keep.
{
    my $election = $R->weekday_on_or_after(rule => $R->nth(month => 11, day_of_week => 1, n => 1), day_of_week => 2, days => 1, name => 'Election Day');
    is_deeply([ map { dates($election->holidays(year => $_))->[0] } 2024, 2026, 2030 ], [qw(2024-11-05 2026-11-03 2030-11-05)], 'Election Day, the Tuesday after the first Monday in November');
    my $midsummer = $R->weekday_on_or_after(rule => $R->fixed(month => 6, day => 19), day_of_week => 5, name => 'Midsummer Eve');
    is_deeply([ map { dates($midsummer->holidays(year => $_))->[0] } 2026, 2027 ], [qw(2026-06-19 2027-06-25)], 'Midsummer Eve, the Friday from 19 June');
    is(dates($R->weekday_on_or_after(rule => $R->fixed(month => 10, day => 31), day_of_week => 6)->holidays(year => 2026))->[0], '2026-10-31', 'All Saints\' Day in Sweden, the Saturday from 31 October: the day itself when it is one');
    is(dates($R->weekday_on_or_before(rule => $R->fixed(month => 5, day => 24), day_of_week => 1)->holidays(year => 2026))->[0], '2026-05-18', 'weekday_on_or_before: the Monday on or before 24 May (Victoria Day)');
    is(dates($R->weekday_on_or_after(rule => $R->fixed(month => 1, day => 1), day_of_week => 1, n => 3)->holidays(year => 2026))->[0], '2026-01-19', '  n counts on: the third Monday from 1 January');
    is(dates($R->weekday_on_or_before(rule => $R->fixed(month => 12, day => 31), day_of_week => 5, n => 2)->holidays(year => 2026))->[0], '2026-12-18', '  and back: the second Friday on or before 31 December');
    for my $bad ([ [rule => $R->set($xmas), day_of_week => 1], qr/rule must not be a set/ ], [ [rule => $R->sandwiched, day_of_week => 1], qr/rule must not be a sandwiched day/ ],
                  [ [rule => $xmas, day_of_week => 8], qr/day_of_week must be 1 to 7/ ], [ [rule => $xmas, day_of_week => 1, n => 6], qr/n must be 1 to 5/ ], [ [day_of_week => 1], qr/rule must be a Time::Keeper::Business::Rule/ ]) {
        ok(!eval { $R->weekday_on_or_after(@{ $bad->[0] }); 1 }, 'weekday_on_or_after refuses');
        like($@, $bad->[1], '  by name');
    }

    my $sw = $R->set($R->fixed(month => 3, day => 2), $R->fixed(month => 3, day => 4), $R->sandwiched(name => 'between'));
    is_deeply(pairs($sw->holidays(year => 2026)), [['2026-03-02', undef], ['2026-03-03', 'between'], ['2026-03-04', undef]], 'a weekday between two holidays of the set becomes one');
    is_deeply(dates($R->set($R->fixed(month => 3, day => 6), $R->fixed(month => 3, day => 8), $R->sandwiched)->holidays(year => 2026)), [qw(2026-03-06 2026-03-08)], '  but not a Saturday');
    is_deeply(dates($R->set($R->fixed(month => 3, day => 2), $R->fixed(month => 3, day => 3), $R->fixed(month => 3, day => 4), $R->sandwiched)->holidays(year => 2026)), [qw(2026-03-02 2026-03-03 2026-03-04)], '  nor a day already a holiday');
    is_deeply(dates($R->set($R->fixed(month => 3, day => 2), $R->fixed(month => 3, day => 5), $R->sandwiched)->holidays(year => 2026)), [qw(2026-03-02 2026-03-05)], '  and two days apart is no sandwich');
    is_deeply(dates($R->sandwiched->holidays(year => 2026)), [], 'a sandwiched day alone gives nothing');
    is_deeply(dates($R->set($R->fixed(month => 3, day => 2), $R->fixed(month => 3, day => 4), $R->sandwiched->between(from => 2027))->holidays(year => 2026)), [qw(2026-03-02 2026-03-04)], '  and between applies to it');

    my $may = $R->nth(month => 5, day_of_week => 1, n => 1, name => 'Early May')->except(years => [2020])->also(dates => ['2020-05-08']);
    is_deeply(pairs($may->holidays(year => 2020)), [['2020-05-08', 'Early May']], "except a year and also a date: 2020's VE Day bank holiday");
    is_deeply(dates($may->holidays(year => 2021)), ['2021-05-03'], '  other years as the rule says');
    is_deeply(dates($may->also(dates => ['2021-05-04'])->holidays(year => 2021)), [qw(2021-05-03 2021-05-04)], '  also adds to also');
    is_deeply(dates($R->set($xmas, $boxing)->except(years => [2026])->holidays(year => 2026)), [], 'except on a set holds for every member');
    is_deeply(dates($R->set($xmas->except(years => [2026]), $boxing)->holidays(year => 2026)), ['2026-12-26'], '  on a member for that member');
    is_deeply(dates($R->set($xmas)->also(dates => [ Time::Keeper::Date->parse('2026-08-31') ])->holidays(year => 2026)), [qw(2026-08-31 2026-12-25)], 'also on a set, with a Date');
    is_deeply(dates($xmas->observed('next_business_day')->also(dates => ['2027-12-25'])->holidays(year => 2027)), [qw(2027-12-25 2027-12-27)], 'an also date never moves');
    ok(!eval { $xmas->except(years => 2020); 1 }, 'except needs a list');
    like($@, qr/years is a list/, '  by name');
    ok(!eval { $xmas->also(dates => ['not a date']); 1 }, 'also needs dates');
    ok(!eval { $xmas->except(when => [2020]); 1 }, 'except refuses another key');

    my $prev = $xmas->observed('previous_business_day');
    my $ifsun = $xmas->observed('next_business_day_if_sunday');
    my %want_prev = (2021 => '2021-12-24', 2022 => '2022-12-23', 2023 => '2023-12-25', 2024 => '2024-12-25', 2025 => '2025-12-25', 2026 => '2026-12-25', 2027 => '2027-12-24');
    my %want_sun  = (2021 => '2021-12-25', 2022 => '2022-12-26', 2023 => '2023-12-25', 2024 => '2024-12-25', 2025 => '2025-12-25', 2026 => '2026-12-25', 2027 => '2027-12-25');
    for my $y (sort keys %want_prev) {
        is(dates($prev->holidays(year => $y))->[0], $want_prev{$y}, "previous_business_day in $y (Christmas on a " . Time::Keeper::Date->new(year => $y, month => 12, day => 25)->format('EEEE') . ')');
        is(dates($ifsun->holidays(year => $y))->[0], $want_sun{$y}, '  next_business_day_if_sunday');
    }
    is_deeply(dates($xmas->observed('next_business_day_if_sunday', keep => 1)->holidays(year => 2022)), [qw(2022-12-25 2022-12-26)], 'keep: the Sunday stays a holiday and the Monday is added');
    is_deeply(dates($xmas->observed('next_business_day', keep => 1)->observed('next_business_day')->holidays(year => 2022)), ['2022-12-26'], '  and a later observed without keep drops it');
    is_deeply(dates($R->set($R->fixed(month => 3, day => 2)->observed(sub { $_[0]->plus(days => 7) }, keep => 1), $R->fixed(month => 3, day => 1)->observed('next_business_day'))->holidays(year => 2026)), [qw(2026-03-02 2026-03-03 2026-03-09)],
              '  a kept weekday is taken: Sunday 1 March moves past Monday the 2nd, kept by the other rule, to the 3rd');
    is_deeply(dates($R->set($xmas->observed('next_business_day', keep => 1), $R->fixed(month => 12, day => 26)->observed('next_business_day', keep => 1))->holidays(year => 2021)), [qw(2021-12-25 2021-12-26 2021-12-27 2021-12-28)], '  two kept and moved in a set do not collide');
}

# Not serialised, threads, subclasses.
{
    require Storable;
    is_deeply($xmas->TO_JSON, { kind => 'fixed', month => 12, day => 25, name => 'Christmas Day' }, 'a rule as data');
    is_deeply($xmas->observed('next_business_day', keep => 1, weekend => [5, 6])->between(from => 2000)->except(years => [2001])->also(dates => ['2001-12-24'])->TO_JSON,
              { kind => 'fixed', month => 12, day => 25, name => 'Christmas Day', observed => 'next_business_day', keep => 1, weekend => [5, 6], from => 2000, except => [2001], also => ['2001-12-24'] },
              '  with every change');
    my @every = (
        $xmas, $R->nth(month => 11, day_of_week => 4, n => 4), $R->nth(month => 5, day_of_week => 1, n => -1)->observed('nearest_business_day'),
        $R->easter, $R->easter(offset => -2, orthodox => 1), $R->relative(rule => $xmas, days => 1, name => 'Boxing Day'),
        $R->weekday_on_or_after(rule => $R->fixed(month => 6, day => 19), day_of_week => 5, n => 2, days => -1),
        $R->weekday_on_or_before(rule => $R->fixed(month => 5, day => 24), day_of_week => 1),
        $R->fixed(calendar => 'hebrew', month_code => 'M05L', day => 14, leap_month => 'common'),
        $R->nth(calendar => 'chinese', month_code => 'M08', day_of_week => 6, n => 2),
        $R->set($R->fixed(month => 9, day => 21), $R->fixed(month => 9, day => 23), $R->sandwiched(name => 'sw'), weekend => [6, 7], name => 'set', to => 2100),
        $R->nth(month => 5, day_of_week => 1, n => 1, name => 'Early May')->except(years => [2020])->also(dates => ['2020-05-08', '2045-01-02']),
        $R->uk, $R->us_federal, $R->target2,
    );
    for my $rule (@every) {
        my $back = $R->from_spec($rule->TO_JSON);
        my $clone = Storable::dclone($rule);
        my @frozen = $rule->FREEZE('CBOR');
        my $thawed = $R->THAW('CBOR', @frozen);
        my ($bad, $bad2, $bad3) = (0, 0, 0);
        for my $y (1990 .. 2060) {
            my $want = join ' ', map { "$_->[0]=" . ($_->[1] // '') } $rule->holidays(year => $y);
            $bad++ if $want ne join ' ', map { "$_->[0]=" . ($_->[1] // '') } $back->holidays(year => $y);
            $bad2++ if $want ne join ' ', map { "$_->[0]=" . ($_->[1] // '') } $clone->holidays(year => $y);
            $bad3++ if $want ne join ' ', map { "$_->[0]=" . ($_->[1] // '') } $thawed->holidays(year => $y);
        }
        my $k = $rule->TO_JSON->{kind};
        is("$bad/$bad2/$bad3", '0/0/0', "a $k rule round-trips through from_spec, Storable and FREEZE/THAW, 1990 to 2060");
        is_deeply($back->TO_JSON, $rule->TO_JSON, '  and its data is the same');
    }
    { package My::FrozenRule; our @ISA = ('Time::Keeper::Business::Rule'); }
    is(ref Storable::dclone(My::FrozenRule->fixed(month => 1, day => 1)), 'My::FrozenRule', 'a subclass thaws in itself');
    is(ref My::FrozenRule->from_spec({ kind => 'fixed', month => 1, day => 1 }), 'My::FrozenRule', '  and from_spec builds in it');
    for my $bad (['observed', $xmas->observed(sub { $_[0] })], ['only_if', $xmas->only_if(sub { 1 })], ['a member', $R->set($xmas->only_if(sub { 1 }))], ['a base rule', $R->relative(rule => $xmas->only_if(sub { 1 }), days => 1)]) {
        ok(!eval { $bad->[1]->TO_JSON; 1 }, "a code ref in $bad->[0] has no data form");
        like($@, qr/a rule with a code ref \(observed or only_if\) cannot be written as data/, '  by name');
    }
    ok(!eval { Storable::dclone($xmas->only_if(sub { 1 })); 1 }, '  nor freezes');
    for my $bad ([ 'x', qr/a rule's data is a hash/ ], [ {}, qr/a rule's data needs its kind/ ], [ { kind => 'lunar' }, qr/a rule of kind 'lunar' needs a later release of Time::Keeper::Business/ ],
                 [ { kind => 'fixed', month => 13, day => 1 }, qr/^Time::Keeper::Business::Rule->fixed: month must be 1 to 12/ ], [ { kind => 'set' }, qr/a set's data needs its members/ ],
                 [ { kind => 'fixed', month => 1, day => 1, colour => 'red' }, qr/unknown argument 'colour'/ ], [ { kind => 'fixed', month => 1, day => 1, observed => 'later' }, qr/the form is none/ ]) {
        ok(!eval { $R->from_spec($bad->[0]); 1 }, 'from_spec refuses damaged data');
        like($@, $bad->[1], '  with the constructor\'s own message');
    }
    ok(!eval { Time::Keeper::Business::Rule::name(\1); 1 }, 'a plain ref is not a rule');
    like($@, qr/not a Time::Keeper::Business::Rule/, '  by name');
    {
        package My::Rule;
        our @ISA = ('Time::Keeper::Business::Rule');
    }
    my $m = My::Rule->fixed(month => 12, day => 25);
    is(ref $m, 'My::Rule', 'a subclass constructs in itself');
    is(ref $m->observed('next_monday'), 'My::Rule', '  observed keeps it');
    is(ref $m->between(from => 2000), 'My::Rule', '  between keeps it');
    is(ref My::Rule->set($m), 'My::Rule', '  set too');
    is(ref My::Rule->uk, 'My::Rule', '  and the example sets');
    my $uk = $R->uk;
    my @c = $uk->holidays(year => 2026);
    $c[0][1] = 'changed';
    is(($uk->holidays(year => 2026))[0][1], "New Year's Day", 'changing a pair given back does not change the memo');
    is(($R->fixed(month => 1, day => 1, observed => 'next_business_day', from => 2020, name => 'x')->holidays(year => 2022))[0][0] . '', '2022-01-03', 'a constructor takes observed and from as the changes would');
    ok(!eval { $R->fixed(month => 1, day => 1, observed => 'sometime'); 1 }, '  and checks them');
}
SKIP: {
    require Config;
    skip 'no ithreads', 2 unless $Config::Config{useithreads};
    require threads;
    my $uk = $R->uk;
    $uk->holidays(year => 2027);
    my $t = threads->create(sub { join ',', map { "$_->[0]" } $uk->holidays(year => 2027) });
    is($t->join, join(',', map { "$_->[0]" } $uk->holidays(year => 2027)), "a thread's copy computes for itself");
    my $t2 = threads->create(sub { my $r = $R->easter(offset => 1)->only_if(sub { 1 }); "" . ($r->holidays(year => 2026))[0][0] });
    is($t2->join, '2026-04-06', '  and a rule made in a thread with a code ref works there');
}

done_testing;
