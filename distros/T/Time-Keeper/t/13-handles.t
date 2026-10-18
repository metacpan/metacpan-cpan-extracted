#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Storable qw(freeze thaw dclone);

use Time::Keeper;

my $K = 'Time::Keeper';
my $size = Time::Keeper::_value_size();
my ($at_nsec, $at_utoff, $at_zone) = Time::Keeper::_value_layout();

# Forged and damaged values.
{
    my $real = $K->new(year => 2026, zone => 'Europe/London');
    my $bytes = ${$real};
    is(length $bytes, $size, 'a value holds its bytes');

    # The referent is writable (a serialiser may re-bless it), so a value
    # is checked on every read instead.
    my $changed = $K->new(year => 2026, zone => 'Europe/London');
    ${$changed} = 'x';
    ok(!eval { $changed->year; 1 }, 'a value whose bytes were changed is refused');
    like($@, qr/not a Time::Keeper value/, 'as not a value');

    my $short = bless \(my $s = substr($bytes, 1)), $K;
    ok(!eval { $short->year; 1 }, 'a value one byte short');
    like($@, qr/not a Time::Keeper value/, 'is not a value');

    my $long = bless \(my $l = $bytes . "x"), $K;
    ok(!eval { $long->year; 1 }, 'a value one byte long');
    like($@, qr/not a Time::Keeper value/, 'is not a value either');

    my $hash = bless {}, $K;
    ok(!eval { $hash->year; 1 }, 'nor is a blessed hash');

    my $bad_nsec = $bytes;
    substr($bad_nsec, $at_nsec, 4, pack('l', 1_500_000_000));
    my $f = bless \$bad_nsec, $K;
    ok(!eval { $f->year; 1 }, 'a second and a half of nanoseconds on a day with no leap second');
    like($@, qr/a damaged Time::Keeper value/, 'is damaged');

    my $bad_zone = $bytes;
    substr($bad_zone, $at_zone, 2, pack('S', 60_000));
    $f = bless \$bad_zone, $K;
    ok(!eval { $f->zone_name; 1 }, 'a zone id past the end of the table');
    like($@, qr/a damaged Time::Keeper value/, 'is damaged');

    my $utc = ${ $K->new(year => 2026) };
    substr($utc, $at_utoff, 4, pack('l', 3600));
    $f = bless \$utc, $K;
    ok(!eval { $f->year; 1 }, 'a UTC value with an offset');
}

# A subclass.
{
    package My::Time;
    our @ISA = ('Time::Keeper');
    sub weekday_name { (qw(Mon Tue Wed Thu Fri Sat Sun))[ $_[0]->day_of_week - 1 ] }
}
{
    my $t = My::Time->new(year => 2026, month => 10, day => 15);
    isa_ok($t, 'My::Time');
    is($t->weekday_name, 'Thu', 'a subclass\'s own method');
    isa_ok($t->with(day => 16), 'My::Time', 'with keeps the subclass');
    isa_ok($t->in_zone('Asia/Tokyo'), 'My::Time', 'so does in_zone');
    isa_ok(My::Time->now, 'My::Time', 'and now');
    ok($t == $K->new(year => 2026, month => 10, day => 15), 'and it compares with the base class');
}

# Storable.
{
    my $t = $K->new(year => 2026, month => 10, day => 15, hour => 9, nanosecond => 7, zone => 'US/Eastern');
    my $c = thaw(freeze($t));
    isa_ok($c, $K);
    ok($c == $t, 'freeze and thaw: the same instant');
    is($c->zone_name, 'US/Eastern', 'in the same zone, by its own name');
    is("$c", "$t", 'and the same string');
    is(dclone($t) . '', "$t", 'dclone');
    for my $z ('UTC', 'floating', '+05:30') {
        my $v = $K->new(year => 2026, month => 3, hour => 4, zone => $z);
        is(thaw(freeze($v)) . '', "$v", "and in $z");
    }
    my $l = $K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60);
    is(thaw(freeze($l)) . '', "$l", 'a leap second');
    like(Time::Keeper::STORABLE_freeze($t, 0), qr/^tk1 1792069200 7 US\/Eastern$/, 'frozen as its instant and its zone\'s name');
    ok(!eval { Time::Keeper::STORABLE_thaw(bless(\(my $x), $K), 0, 'tk2 0 0 UTC'); 1 }, 'a form it does not know is refused');
    ok(!eval { Time::Keeper::STORABLE_thaw(bless(\(my $x), $K), 0, 'tk1 0 0 Nowhere/Special'); 1 }, 'and a zone it does not have');
}

# Threads.
SKIP: {
    skip 'this perl has no threads', 3 unless $Config{useithreads};
    require threads;
    my $t = $K->new(year => 2026, month => 10, day => 15, zone => 'Asia/Tokyo');
    my $r = threads->create(sub {
        my $u = $K->new(year => 2026, month => 10, day => 15, zone => 'Asia/Tokyo');
        return join ' ', "$t", $t->zone_abbr, ($t == $u ? 'equal' : 'unequal'), ref($K->now);
    })->join;
    is($r, '2026-10-15T00:00:00+09:00 JST equal Time::Keeper', 'a value copied into a thread, and values made there');
    ok($t->zone_abbr eq 'JST', 'the original is untouched');
    is(threads->create(sub { $K->now->zone_name })->join, 'UTC', 'now in a new thread');
}

done_testing;
