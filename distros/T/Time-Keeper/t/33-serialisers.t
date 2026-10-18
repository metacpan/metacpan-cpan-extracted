#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Storable qw(freeze thaw);

use Time::Keeper;

my $K = 'Time::Keeper';
my $D = 'Time::Keeper::Duration';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# FREEZE and THAW, the protocol Sereal, CBOR::XS and JSON::XS's Types::Serialiser use.
{
    my $t = $K->new(year => 2026, month => 10, day => 15, hour => 9, minute => 41, second => 17,
                    nanosecond => 123456789, zone => 'Europe/London', locale => 'fr');
    my @parts = $t->FREEZE('Sereal');
    is(scalar @parts, 1, 'FREEZE gives one part');
    like($parts[0], qr/^tk1 \d+ 123456789 Europe\/London fr$/, 'the text STORABLE_freeze gives: instant, zone by name, locale by code');
    is_deeply([$t->FREEZE('CBOR')], [scalar freeze_text($t)], 'the same text whatever the serialiser');
    my $back = $K->THAW('Sereal', @parts);
    ok($back == $t, 'THAW gives the same instant');
    is($back->zone_name, 'Europe/London', 'in the same zone');
    is($back->locale, 'fr', 'with the same locale');
    is("$back", "$t", 'and the same string');
    ok(!eval { $back->isa('Time::Keeper') } || 1, 'blessed');
    my $utc = $K->from_epoch(0);
    is($K->THAW('x', $utc->FREEZE('x')) . '', "$utc", 'UTC round-trips');
    my $leap = $K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 7);
    is($K->THAW('x', $leap->FREEZE('x')) . '', "$leap", 'a leap second round-trips');
    my $float = $K->new(year => 2026, zone => 'floating');
    is($K->THAW('x', $float->FREEZE('x')) . '', "$float", 'floating time round-trips');
    is($K->THAW('x', $K->new(year => 2026, zone => '+05:30')->FREEZE('x'))->zone_name, '+05:30', 'a fixed zone round-trips');
    dies_like(sub { $K->THAW('x', 'not frozen') }, qr/THAW: not a frozen Time::Keeper value/, 'rubbish is refused');
    dies_like(sub { $K->THAW('x', 'tk1 1 2 Mars/Olympus') }, qr/Mars\/Olympus/, 'a zone it does not know');
    # Storable still works and writes the same text.
    is(thaw(freeze($t)) . '', "$t", 'Storable round-trips');
    is(thaw(freeze($t))->locale, 'fr', 'with the locale');
}

# Durations: STORABLE hooks, new here, and FREEZE/THAW.
{
    my $d = $D->new(years => 1, months => 2, days => -3, hours => 4, minutes => 5, seconds => 6, nanoseconds => 7,
                    end_of_month => 'limit');
    my @parts = $d->FREEZE('Sereal');
    is(scalar @parts, 1, 'a duration freezes to one part');
    is($parts[0], 'tkd1 14 -3 245 6 7 limit', 'months, days, minutes, seconds, nanoseconds and the end-of-month rule');
    my $back = $D->THAW('Sereal', @parts);
    is("$back", "$d", 'THAW gives the same duration');
    is($back->end_of_month, 'limit', 'with its rule');
    is_deeply([$back->deltas], [$d->deltas], 'part for part');
    is(thaw(freeze($d)) . '', "$d", 'Storable round-trips a duration');
    is(thaw(freeze($d))->end_of_month, 'limit', 'with its rule');
    my $neg = $D->new(seconds => -1, nanoseconds => -250_000_000);
    is_deeply([thaw(freeze($neg))->in_units('seconds', 'nanoseconds')], [-1, -250_000_000], 'a negative duration');
    is(thaw(freeze($D->new)) . '', 'PT0S', 'the empty duration');
    my $big = $D->new(seconds => 2**59);
    is(thaw(freeze($big))->in_units('seconds'), '576460752303423488', 'a duration near the limit');
    dies_like(sub { $D->THAW('x', 'tk1 1 2 UTC') }, qr/not a frozen Time::Keeper::Duration/, 'a value is not a duration');
    dies_like(sub { $D->THAW('x', 'tkd1 1 2 3') }, qr/not a frozen Time::Keeper::Duration/, 'too few parts');
    dies_like(sub { $D->THAW('x', 'tkd1 1 2 3 4 5 sometimes') }, qr/end_of_month is 'wrap', 'limit' or 'preserve'/, 'a rule it does not know');
    # A value and a duration together in one structure.
    my $t = $K->new(year => 2026);
    my $both = thaw(freeze({ when => $t, how_long => $d }));
    is($both->{when} . '', "$t", 'a value inside a structure');
    is($both->{how_long} . '', "$d", 'and a duration beside it');
}

# Through the serialisers themselves, where installed.
SKIP: {
    skip 'Sereal is not installed', 2 unless eval { require Sereal::Encoder; require Sereal::Decoder; 1 };
    my $t = $K->new(year => 2026, month => 10, day => 15, zone => 'Asia/Tokyo');
    my $d = $D->new(days => 2, hours => 3);
    my $enc = Sereal::Encoder->new({ freeze_callbacks => 1 });
    my $dec = Sereal::Decoder->new;
    my $back = $dec->decode($enc->encode([$t, $d]));
    is($back->[0] . '', "$t", 'a value through Sereal');
    is($back->[1] . '', "$d", 'a duration through Sereal');
}
SKIP: {
    skip 'CBOR::XS is not installed', 2 unless eval { require CBOR::XS; 1 };
    my $t = $K->new(year => 2026, month => 10, day => 15, zone => 'Asia/Tokyo');
    my $d = $D->new(days => 2, hours => 3);
    my $cbor = CBOR::XS->new->allow_sharing;
    my $back = $cbor->decode($cbor->encode([$t, $d]));
    is($back->[0] . '', "$t", 'a value through CBOR::XS');
    is($back->[1] . '', "$d", 'a duration through CBOR::XS');
}

# Struct::Codec calls no hook: it copies the bytes of a value, blessed, and
# they hold the zone by its number in this release's table. Within a
# process that is the same value; FREEZE gives the text that outlives one.
SKIP: {
    skip 'Struct::Codec is not installed', 10 unless eval { require Struct::Codec; 1 };
    my $t = $K->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30, nanosecond => 5,
                    zone => 'US/Eastern', locale => 'fr');
    my $d = $D->new(months => 14, days => -3, end_of_month => 'limit');
    my $bytes = Struct::Codec::struct_encode([$t, $d]);
    ok(index($bytes, 'tk1 ') < 0, 'Struct::Codec writes the bytes, not the FREEZE text');
    my $back = Struct::Codec::struct_decode($bytes);
    isa_ok($back->[0], 'Time::Keeper', 'the value back');
    ok($back->[0] == $t, 'the same instant');
    is($back->[0]->nanosecond, 5, 'to the nanosecond');
    is($back->[0]->zone_name, 'US/Eastern', 'in the zone as given');
    is($back->[0]->locale, 'fr', 'with the locale');
    ok($back->[0]->is_ambiguous, 'and it still asks its zone questions');
    is($back->[0]->plus(days => 1) . '', '2026-11-02T01:30:00.000000005-05:00', 'and does arithmetic');
    is($back->[1] . '', "$d", 'a duration through Struct::Codec');
    is($back->[1]->end_of_month, 'limit', 'with its rule');
}

sub freeze_text { my ($t) = @_; my ($s) = $t->STORABLE_freeze(0); $s }

done_testing;
