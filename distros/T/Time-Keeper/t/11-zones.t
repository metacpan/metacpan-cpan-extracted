#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# The zone kinds that are the core's own.
for my $z ('UTC', 'utc', 'GMT', 'Z', 'z', undef) {
    my $t = $K->new(year => 2026, zone => $z);
    ok($t->is_utc && $t->zone_name eq 'UTC', 'zone ' . ($z // 'undef') . ' is UTC');
}
{
    my $t = $K->new(year => 2026, month => 7, hour => 9, zone => '+05:30');
    is("$t", '2026-07-01T09:00:00+05:30', 'a fixed offset');
    is($t->offset, 19800, 'of 19800 seconds');
    is($t->zone_name, '+05:30', 'named by its offset');
    is($t->zone_abbr, '+05:30', 'and abbreviated so');
    is($t->as_utc->hour, 3, 'and 09:00 there is 03:30 UTC');
    is($K->new(year => 2026, zone => '-0800')->offset, -28800, '-0800');
    is($K->new(year => 2026, zone => '+01')->offset, 3600, '+01');
    is($K->new(year => 2026, zone => '+05:45:30')->offset, 20730, 'with seconds');
    is($K->new(year => 2026, zone => '+00:00')->zone_name, 'UTC', '+00:00 is UTC');
    is($K->new(year => 2026, zone => '+23:59:59')->offset, 86399, 'just under a day');
}
dies_like(sub { $K->new(year => 2026, zone => '+24:00') }, qr/is not an offset/, 'a day is too much');
dies_like(sub { $K->new(year => 2026, zone => '+5:30') }, qr/is not an offset/, 'one digit of hours');
dies_like(sub { $K->new(year => 2026, zone => '+05:60') }, qr/is not an offset/, 'sixty minutes');
dies_like(sub { $K->new(year => 2026, zone => '+05:30x') }, qr/is not an offset/, 'trailing rubbish');
dies_like(sub { $K->new(year => 2026, zone => []) }, qr/a time zone is a name, an offset or a Time::Keeper value/, 'a reference');

{
    my $f = $K->new(year => 2026, month => 7, hour => 9, zone => 'floating');
    is("$f", '2026-07-01T09:00:00', 'floating time has no offset');
    ok($f->is_floating, 'is_floating');
    is($f->zone_name, 'floating', 'zone_name');
    is($f->zone_abbr, '', 'no abbreviation');
    is($f->tai_offset, undef, 'no TAI offset');
    my $tokyo = $f->in_zone('Asia/Tokyo');
    is("$tokyo", '2026-07-01T09:00:00+09:00', 'floating into a zone keeps the wall-clock time');
    is($tokyo->as_floating . '', '2026-07-01T09:00:00', 'and back');
}

# Named zones.
{
    my $t = $K->new(year => 2026, month => 7, day => 1, hour => 12, zone => 'Europe/London');
    is("$t", '2026-07-01T12:00:00+01:00', 'London in summer');
    is($t->zone_abbr, 'BST', 'BST');
    ok($t->is_dst, 'on daylight saving time');
    is($t->zone_name, 'Europe/London', 'zone_name');
    my $w = $t->with(month => 1);
    is("$w", '2026-01-01T12:00:00+00:00', 'with a winter month: the same wall time, now GMT, an offset of zero and not Z');
    is($w->zone_abbr, 'GMT', 'GMT');
    ok(!$w->is_dst, 'not on daylight saving time');
    is($K->new(year => 2026, zone => 'europe/london')->zone_name, 'Europe/London', 'a name in any case');
    is($K->new(year => 2026, zone => 'GB')->zone_name, 'GB', 'a link keeps its own name');
    is($K->new(year => 2026, month => 7, zone => 'US/Eastern')->zone_abbr, 'EDT', 'and follows its zone');
    my $u = $K->new(year => 2026, zone => $t);
    is($u->zone_name, 'Europe/London', 'another value as the zone');
    is($K->new(year => 2026, zone => $K->new(year => 1, zone => '+03:00'))->offset, 10800, 'a value in a fixed offset');
}
dies_like(sub { $K->new(year => 2026, zone => 'Nowhere/Special') }, qr/no time zone named 'Nowhere\/Special'/, 'a zone that is not there');

{
    my $t = $K->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Asia/Tokyo');
    my $l = $t->in_zone('Europe/London');
    is("$l", '2026-10-15T01:00:00+01:00', 'in_zone: the same instant');
    ok($l == $t, 'equal to the first');
    is($t->as_utc . '', '2026-10-15T00:00:00Z', 'as_utc');
    dies_like(sub { $t->in_zone }, qr/which zone\?/, 'in_zone needs a zone');
    dies_like(sub { $t->in_zone('UTC', colour => 1) }, qr/unknown argument 'colour'/, 'and takes only gap and overlap');
}

# Gaps and overlaps, the owner's defaults: a gap croaks, an overlap takes the
# earlier instant.
{
    my %ny = (year => 2026, month => 3, day => 8, hour => 2, minute => 30, zone => 'America/New_York');
    dies_like(sub { $K->new(%ny) }, qr/2026-03-08 02:30:00 did not happen in America\/New_York/, 'a gap croaks');
    is($K->new(%ny, gap => 'forward') . '', '2026-03-08T03:30:00-04:00', 'forward');
    is($K->new(%ny, gap => 'backward') . '', '2026-03-08T01:30:00-05:00', 'backward');
    dies_like(sub { $K->new(%ny, gap => 'sideways') }, qr/gap is 'croak', 'forward' or 'backward'/, 'a gap choice that is not one');

    my %fb = (year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York');
    is($K->new(%fb) . '', '2026-11-01T01:30:00-04:00', 'an overlap takes the earlier instant');
    is($K->new(%fb, overlap => 'later') . '', '2026-11-01T01:30:00-05:00', 'or the later');
    dies_like(sub { $K->new(%fb, overlap => 'both') }, qr/overlap is 'earlier' or 'later'/, 'an overlap choice that is not one');

    my $before = $K->new(year => 2026, month => 3, day => 8, hour => 1, minute => 30, zone => 'America/New_York');
    dies_like(sub { $before->with(hour => 2) }, qr/did not happen/, 'with into a gap croaks');
    is($before->with(hour => 2, gap => 'forward')->hour, 3, 'unless told what to do');
    is($K->new(%fb, overlap => 'later')->with(minute => 45)->offset, -14400, 'with in an overlap takes the earlier, whichever the value was');
}

{
    my $t = $K->today(zone => 'America/Santiago');
    is($t->hour . ':' . $t->minute, '0:0', 'today is midnight');
    ok(!eval { $K->new(year => 2026, month => 9, day => 6, zone => 'America/Santiago'); 1 },
       'Santiago had no midnight on 6 September 2026');
    is(Time::Keeper::_today_at($K->new(year => 2026, month => 9, day => 6, hour => 12, zone => 'America/Santiago')) . '',
       '2026-09-06T01:00:00-03:00', 'and today there is its first moment, 01:00');
}

# Leap seconds in a zone.
{
    my $l = $K->new(year => 2017, month => 1, day => 1, hour => 8, minute => 59, second => 60, zone => 'Asia/Tokyo');
    is("$l", '2017-01-01T08:59:60+09:00', '08:59:60 in Tokyo');
    is($l->as_utc . '', '2016-12-31T23:59:60Z', 'is the leap second');
    dies_like(sub { $K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, zone => 'Asia/Tokyo') },
              qr/there was no leap second at 2016-12-31 23:59:60/, '23:59:60 in Tokyo was not');
    dies_like(sub { $K->new(year => 2026, month => 6, day => 30, hour => 23, minute => 59, second => 60) },
              qr/there was no leap second/, 'nor is there one this year');
    is($l->in_zone('America/New_York') . '', '2016-12-31T18:59:60-05:00', 'in New York it was 18:59:60');
}

# The local zone.
{
    local $ENV{TZ} = 'Pacific/Auckland';
    is($K->now(zone => 'local')->zone_name, 'Pacific/Auckland', 'local is TZ when TZ names a zone');
    local $ENV{TZ} = '';
    is($K->now(zone => 'local')->zone_name, 'Etc/UTC', 'and UTC when TZ is empty');
}

done_testing;
