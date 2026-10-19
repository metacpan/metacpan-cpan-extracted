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
like($@, qr/^Time::Keeper::Business::Rule->observed: the form is none, next_business_day, nearest_business_day, next_monday or a code ref/, '  by name');
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
ok(!eval { Storable::freeze($b); 1 }, 'a schedule with a rule cannot be frozen');
my @fr = Time::Keeper::Business->new(holidays => [ $R->uk, $R->target2 ])->holidays(year => 2026);
is(scalar @fr, 10, 'two sets as sources merge: 8 UK plus May Day and 26 December');

# Not serialised, threads, subclasses.
{
    require Storable;
    ok(!eval { Storable::dclone($xmas); 1 }, 'a rule is not frozen');
    like($@, qr/a rule is not serialised; build it again from its constructors/, '  by name');
    ok(!eval { $xmas->FREEZE('CBOR'); 1 }, '  nor through FREEZE');
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
