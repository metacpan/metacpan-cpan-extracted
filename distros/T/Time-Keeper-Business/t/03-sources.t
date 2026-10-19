#!perl
use 5.010;
use strict;
use warnings;
use Config;
BEGIN { if ($Config{useithreads}) { require threads; threads->import } }
use Test::More;
use Storable qw(dclone freeze);

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
sub d { Time::Keeper::Date->parse($_[0]) }
sub span { [Time::Keeper::Business::_materialised_span($_[0])] }
sub dates { [map { "$_->[0]" } @_] }

# A literal schedule is never lazy.
my $lit = $C->new(holidays => ['2026-12-25']);
is_deeply(span($lit), [], 'a literal schedule has no span to materialise');
$lit->is_business_day(d('2031-01-01'));
is_deeply(span($lit), [], '  and a question about a far year changes nothing');
is_deeply([$lit->holidays(year => 2030)], [], 'a year with no holiday is an empty list');

# Yearly dates.
my $y = $C->new(holidays => [ '--12-25', { '--01-01' => "New Year's Day", '--02-29' => 'Leap Day' },
                              Time::Keeper::MonthDay->new(month => 7, day => 4),
                              { month => 11, day => 11, name => 'Armistice Day' } ]);
is_deeply(span($y), ['none'], 'a yearly schedule starts with nothing materialised');
is($y->is_holiday(d('2026-12-25')), 1, '--12-25 is a holiday in 2026');
is_deeply(span($y), [2025, 2027], '  which materialised the year and one either side');
is($y->is_holiday(d('2031-01-01')), "New Year's Day", 'a named yearly date in a far year');
is_deeply(span($y), [2025, 2032], '  widening the span contiguously');
is($y->is_holiday(d('2028-02-29')), 'Leap Day', '--02-29 falls in a leap year');
is($y->is_holiday(d('2027-02-28')), undef, '  and nowhere in a common year');
is($y->is_holiday(d('2027-03-01')), undef, '  not clamped either way');
is($y->is_holiday(d('2030-07-04')), 1, 'a MonthDay as a source');
is($y->is_holiday(d('2029-11-11')), 'Armistice Day', 'a month-and-day hash with a name');
is($y->is_business_day(d('2026-12-25')), 0, 'the yearly holiday closes the Friday');
is($y->is_business_day(d('2027-12-25')), 0, 'the Saturday is closed anyway');
is($y->is_holiday(d('2027-12-25')), 1, '  and still a holiday');
is($y->is_business_day(Time::Keeper->new(year => 2045, month => 12, day => 25, zone => 'Asia/Tokyo')), 0,
   'a Time::Keeper far away materialises too');
is($C->new(holidays => '--1225')->is_holiday(d('2026-12-25')), 1, '--MMDD is the basic form');
is_deeply($y->TO_JSON->{holidays},
          { '--12-25' => undef, '--01-01' => "New Year's Day", '--02-29' => 'Leap Day', '--07-04' => undef, '--11-11' => 'Armistice Day' },
          'the plain form carries yearly dates as --MM-DD keys, not the expanded days');
my $thawed = dclone($y);
is($thawed->is_holiday(d('2040-12-25')), 1, 'a thawed yearly schedule still has every year');
is_deeply(span($thawed), [2039, 2041], '  from scratch');
for my $bad (['--02-30', qr/--02-30 is not a date/], ['--13-01', qr/--13-01 is not a date/], [{ month => 2, day => 30 }, qr/--02-30 is not a date/]) {
    ok(!eval { $C->new(holidays => $bad->[0]); 1 }, 'a yearly date that never exists is refused');
    like($@, $bad->[1], '  by name');
}
is($C->new(holidays => { month => 2, day => 29 })->is_holiday(d('2028-02-29')), 1, '29 February is a yearly date');

# Code refs.
my $calls = 0;
my %years;
my $code = $C->new(holidays => sub {
    my $year = shift;
    $calls++;
    $years{$year}++;
    return ("$year-07-04", [ "$year-12-25", 'Christmas Day' ],
            { '0101' => "New Year's Day", '11-11' => 'Armistice Day', '--05-01' => 'May Day', "$year-06-06" => undef },
            Time::Keeper::Date->new(year => $year, month => 3, day => 3),
            Time::Keeper::MonthDay->new(month => 2, day => 29));
});
is($code->is_holiday(d('2026-12-25')), 'Christmas Day', 'a code ref: a [date, name] pair');
is($calls, 3, '  called for the year and one either side');
is_deeply([sort keys %years], [2025, 2026, 2027], '  those three');
is($code->is_holiday(d('2026-07-04')), 1, '  a date string');
is($code->is_holiday(d('2026-01-01')), "New Year's Day", '  an MMDD key of the year');
is($code->is_holiday(d('2026-11-11')), 'Armistice Day', '  an MM-DD key');
is($code->is_holiday(d('2026-05-01')), 'May Day', '  a --MM-DD key');
is($code->is_holiday(d('2026-06-06')), 1, '  a full date key with undef');
is($code->is_holiday(d('2026-03-03')), 1, '  a Date object');
is($code->is_holiday(d('2028-02-29')), 1, '  a MonthDay in a leap year');
is($code->is_holiday(d('2027-03-01')), undef, '  and not in a common year');
my $strings = $C->new(holidays => sub { ('0229', { '02-29' => 'Leap Day' }) });
is($strings->is_holiday(d('2028-02-29')), 'Leap Day', 'an MMDD or MM-DD string of 29 February in a leap year');
is($strings->is_holiday(d('2027-03-01')), undef, '  is nothing in a common year, not 1 March');
is($strings->is_holiday(d('2027-02-28')), undef, '  nor 28 February');
$calls = 0;
$code->is_holiday(d('2026-02-02'));
is($calls, 0, 'a year already seen is not asked again');
$code->is_holiday(d('2031-02-02'));
is($calls, 3, '  and a step out asks for the new years only');
is(scalar(grep { $_ > 1 } values %years), 0, 'no year was asked twice');
is_deeply(span($code), [2025, 2032], 'the span is contiguous');

my @h = $code->holidays(year => 2026);
is(scalar @h, 7, 'holidays(year => ) lists the seven of 2026');
is_deeply(dates(@h), [qw(2026-01-01 2026-03-03 2026-05-01 2026-06-06 2026-07-04 2026-11-11 2026-12-25)], '  in date order');
is_deeply([map { $_->[1] } @h], ["New Year's Day", undef, 'May Day', undef, undef, 'Armistice Day', 'Christmas Day'], '  with names, or undef');
isa_ok($h[0][0], 'Time::Keeper::Date', 'the date of a pair');
is_deeply(dates($code->holidays(d('2026-06-01'), d('2026-07-04'))), [qw(2026-06-06 2026-07-04)], 'two dates, both ends included');
is_deeply(dates($code->holidays(d('2026-07-04'), d('2026-06-01'))), [qw(2026-06-06 2026-07-04)], '  either way round');
is_deeply(dates($code->holidays(Time::Keeper::YearMonth->new(year => 2026, month => 12))), ['2026-12-25'], 'a month');
is_deeply(dates($code->holidays(d('2026-11-30'))), ['2026-11-11'], 'a date alone gives its month');
is_deeply(dates($code->holidays(Time::Keeper->new(year => 2026, month => 5, day => 31, hour => 23, zone => 'America/Los_Angeles'))), ['2026-05-01'],
          'a Time::Keeper alone gives the month its own zone shows');
ok(!eval { $code->holidays; 1 }, 'holidays with nothing is refused');
like($@, qr/^Time::Keeper::Business->holidays: takes year => \$y, two dates, or a month/, '  by name');
ok(!eval { $code->holidays(year => 'x'); 1 }, 'a year that is not a number is refused');
like($@, qr/the year is not an integer/, '  by name');

is_deeply([$C->new(holidays => sub { return })->holidays(year => 2026)], [], 'a code ref returning nothing is a year with none');
is_deeply([$C->new(holidays => sub { undef })->holidays(year => 2026)], [], 'a code ref returning undef too');
my $dies = $C->new(holidays => sub { die "no data for $_[0]\n" });
ok(!eval { $dies->is_holiday(d('2026-01-01')); 1 }, 'a source that dies propagates');
like($@, qr/^Time::Keeper::Business->is_holiday: a holiday source died for 2025: no data for 2025/, '  with the year and the reason');
is_deeply(span($dies), ['none'], '  and nothing was kept');
ok(!eval { $C->new(holidays => sub { [ '2026-01-01', 'x', 'y' ] })->is_holiday(d('2026-01-01')); 1 }, 'a pair of three is refused');
like($@, qr/gave a list of 3 for 2025, not a \[date, name\] pair/, '  by name');
ok(!eval { $C->new(holidays => sub { \"x" })->is_holiday(d('2026-01-01')); 1 }, 'a scalar ref answer is refused');
like($@, qr/gave a reference for 2025 that is not a date, a \[date, name\] pair or a name map/, '  by name');
ok(!eval { $C->new(holidays => sub { 'not a date' })->is_holiday(d('2026-01-01')); 1 }, 'an answer that is not a date is refused');
like($@, qr/Time::Keeper::Date->parse/, '  with the core\'s reason');

# Objects with a holidays method.
{
    package Fake::Holidays;
    sub new { my ($class, %a) = @_; bless { %a, calls => 0, years => [] }, $class }
    sub holidays { my ($self, %a) = @_; $self->{calls}++; push @{$self->{years}}, $a{year}; return $self->{data}->($a{year}) }
}
my $fake = Fake::Holidays->new(data => sub { { '1225' => 'Christmas Day', '1226' => 'Boxing Day' } });
my $fo = $C->new(holidays => [$fake]);
is($fo->is_holiday(d('2026-12-25')), 'Christmas Day', 'a Date::Holidays-shaped object: MMDD keys');
is($fake->{calls}, 3, '  asked for three years');
is_deeply($fake->{years}, [2025, 2026, 2027], '  by year => ');
is($fo->is_holiday(d('2026-12-26')), 'Boxing Day', '  the second key');
is($fo->is_business_day(d('2026-12-28')), 1, '  and nothing else');
my $adapter = Fake::Holidays->new(data => sub { my $year = shift; { "$year-12-25" => 'Christmas Day' } });
is($C->new(holidays => $adapter)->is_holiday(d('2026-12-25')), 'Christmas Day', 'an object giving full-date keys');
my $pairs = Fake::Holidays->new(data => sub { my $year = shift; ([ "$year-12-25", 'Christmas Day' ], [ "$year-12-26", undef ]) });
is_deeply(dates($C->new(holidays => $pairs)->holidays(year => 2026)), [qw(2026-12-25 2026-12-26)], 'an object giving pairs');
ok(!eval { $C->new(holidays => Fake::Holidays->new(data => sub { undef }))->is_holiday(d('2026-12-25')); 1 }, 'an object giving undef is refused');
like($@, qr/gave undef for 2025 \(Date::Holidays gives undef for a country it has no module for\)/, '  with the hint');
is_deeply([$C->new(holidays => Fake::Holidays->new(data => sub { {} }))->holidays(year => 2026)], [], 'an object giving an empty hash is a year with none');
ok(!eval { $C->new(holidays => bless {}, 'Something'); 1 }, 'an object without a holidays method is refused');
like($@, qr/^Time::Keeper::Business->new: an object with no holidays method is not a holiday source/, '  by name');
my $base = $C->new(holidays => { '--12-25' => 'Christmas Day' }, weekend => []);
my $derived = $C->new(holidays => [$base, '--01-01']);
is($derived->is_holiday(d('2030-12-25')), 'Christmas Day', 'a schedule as a source gives its holidays');
is($derived->is_holiday(d('2030-01-01')), 1, '  beside the others');
is_deeply([$fo->holiday_sources], [$fake], 'holiday_sources gives the sources as given');
is(scalar(() = $y->holiday_sources), 4, '  all of them');
is(scalar(() = $lit->holiday_sources), 1, '  one for a single source');

# Names, worked days and the plain form with lazy sources.
my $merge = $C->new(holidays => [ { '2026-12-25' => 'Literal' }, sub { [ "$_[0]-12-25", 'Generated' ] }, '--12-25' ]);
is($merge->is_holiday(d('2026-12-25')), 'Literal', 'a literal name is kept over a generated one');
is($merge->is_holiday(d('2027-12-25')), 'Generated', 'a generated name fills a day --12-25 left blank');
my $lit_and_yearly = $C->new(holidays => [ { '2026-12-25' => 'Literal' }, '--12-25' ]);
$lit_and_yearly->is_holiday(d('2026-12-25'));
is_deeply($lit_and_yearly->TO_JSON->{holidays}, { '2026-12-25' => 'Literal', '--12-25' => undef }, 'a literal day stays literal in the plain form when a yearly date lands on it too');
my $work = $C->new(working => ['2027-12-25'], holidays => sub { "$_[0]-12-25" });
is($work->is_business_day(d('2027-12-25')), 0, 'a holiday a source gives closes a day listed as working');
is($work->is_business_day(d('2027-12-25')), 0, '  and stays closed');
my $w = $code->with(weekend => []);
is($w->is_holiday(d('2026-12-25')), 'Christmas Day', 'with on a lazy schedule rebuilds it');
is_deeply(span($w), [2025, 2027], '  and it materialises afresh');

# The cap.
my $capped = $C->new(holidays => sub { () });
ok(!eval { $capped->holidays(d('1000-01-01'), d('2100-01-01')); 1 }, 'a span of eleven centuries is refused');
like($@, qr/^Time::Keeper::Business->holidays: the holiday sources were asked for 1103 years \(999 to 2101\); list the holidays instead/,
     '  with the count and the years');
is_deeply(span($capped), ['none'], '  and nothing was materialised');
ok(eval { $capped->holidays(d('1200-01-01'), d('2100-01-01')); 1 }, 'a span of nine centuries is allowed');
is_deeply(span($capped), [1199, 2101], '  and materialised');
ok(!eval { $capped->is_holiday(d('3000-01-01')); 1 }, 'widening past the cap is refused');
is_deeply(span($capped), [1199, 2101], '  and the span is unchanged');
is($code->is_holiday(d('3100-12-25')), undef, 'a far year on a schedule whose span cannot reach it dies') if 0;
ok(!eval { $code->is_holiday(d('3100-12-25')); 1 }, 'a far year beyond the cap from the span dies');
is($C->new(holidays => sub { [ "$_[0]-12-25", 'Christmas Day' ] })->is_holiday(d('3100-12-25')), 'Christmas Day', 'and works on a fresh schedule');

# Freezing.
ok(!eval { freeze($code); 1 }, 'a schedule with a code ref cannot be frozen');
like($@, qr/^Time::Keeper::Business->STORABLE_freeze: cannot freeze a schedule with a source asked year by year; list its holidays/, '  by name');
ok(!eval { $code->TO_JSON; 1 }, 'nor given as JSON');
like($@, qr/^Time::Keeper::Business->TO_JSON: cannot freeze/, '  by name');
ok(!eval { $code->FREEZE('CBOR'); 1 }, 'nor through FREEZE');
ok(!eval { $fo->TO_JSON; 1 }, 'an object source is the same');

# Joins of lazy schedules.
my $j = $y->join($code);
is($j->is_holiday(d('2035-11-11')), 'Armistice Day', 'a join of lazy schedules materialises both parts');
is($j->is_business_day(d('2035-07-04')), 0, '  and closes a day either has');
is($j->is_business_day(d('2035-05-01')), 0, '  from either part');
my $jb = $y->join($code, mode => 'both');
is($jb->is_holiday(d('2035-12-25')), 'Christmas Day', 'both: a day both have, named by the one that names it');
is($jb->is_business_day(d('2035-12-25')), 0, '  is closed');
is($jb->is_business_day(d('2035-05-01')), 1, '  a day one alone has works');
is($jb->is_holiday(d('2035-05-01')), undef, '  and is no holiday');
ok(!eval { freeze($j); 1 }, 'a join of lazy schedules cannot be frozen');
like($@, qr/cannot freeze a join of schedules with yearly or generated sources; join the thawed schedules again/, '  by name');
ok(eval { freeze($lit->join($lit)); 1 }, 'a join of literal schedules freezes');
my $jy = $y->join($y->with(weekend => []));
ok(!eval { freeze($jy); 1 }, 'a join of yearly schedules does not: the thaw would lose the years');

SKIP: {
    skip 'no ithreads', 2 unless $Config{useithreads};
    my $thr = threads->create(sub { $code->is_holiday(d('2050-12-25')) });
    is($thr->join, 'Christmas Day', 'a thread\'s copy asks the code ref for itself');
    my $t2 = threads->create(sub { $y->is_holiday(d('2050-01-01')) });
    is($t2->join, "New Year's Day", 'and a yearly date expands there');
}

done_testing;
