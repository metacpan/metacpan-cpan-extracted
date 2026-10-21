#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Time::Keeper::Sky is the observer, and Time::Keeper::Sun, which this dist
# was, is one: a Sky made with the same arguments answers the same, either is
# taken wherever a place is, and new makes the class it was called on.

use_ok('Time::Keeper::Sky') or BAIL_OUT('Time::Keeper::Sky does not load');
is($Time::Keeper::Sky::VERSION, '0.02', 'Time::Keeper::Sky is 0.02');
is($Time::Keeper::Sun::VERSION, '0.03', 'and loads Time::Keeper::Sun, at 0.03, above the 0.02 on CPAN');
ok($INC{'Time/Keeper/Sun/Day.pm'}, 'with its Day');
ok(!$INC{'Time/Keeper.pm'}, 'and not Time::Keeper, until a method needs it');

require Time::Keeper;
require Time::Keeper::Moon;

my %london = (latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
my $sky = Time::Keeper::Sky->new(%london);
my $sun = Time::Keeper::Sun->new(%london);
is(ref $sky, 'Time::Keeper::Sky', 'Time::Keeper::Sky->new makes a Sky');
is(ref $sun, 'Time::Keeper::Sun', 'Time::Keeper::Sun->new makes a Sun, as it always has');
ok($sun->isa('Time::Keeper::Sky'), 'a Sun is a Sky');
ok(!$sky->isa('Time::Keeper::Sun'), 'a Sky is not a Sun');
is(ref $sky->new(place => 'Asia/Tokyo'), 'Time::Keeper::Sky', 'new on an object makes one of its class');
is(ref Time::Keeper::Sky->new(place => 'Asia/Tokyo'), 'Time::Keeper::Sky', 'place => works on a Sky');

{
    package My::Place;
    our @ISA = ('Time::Keeper::Sky');
}
my $mine = My::Place->new(%london);
is(ref $mine, 'My::Place', 'a subclass of Sky gets its own objects');

# ---- the same answers ------------------------------------------------------------

my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 15, zone => 'UTC');
is_deeply($sky->position($t), $sun->position($t), 'position: the same from a Sky as from a Sun');
is($sky->on(year => 2026, month => 10, day => 19)->sunrise . '', $sun->on(year => 2026, month => 10, day => 19)->sunrise . '', 'sunrise too');
is_deeply($sky->track(from => $t, to => $t->epoch + 600), $sun->track(from => $t, to => $t->epoch + 600), 'and the track');
is($sky->latitude, 51.5074, 'the accessors');
is($sky->zone_name, 'Europe/London', '  all of them');
is(Time::Keeper::Sky->equinox(year => 2026, month => 'march') . '', Time::Keeper::Sun->equinox(year => 2026, month => 'march') . '', 'the class methods, on either class');
is_deeply([Time::Keeper::Sky->place_of('Asia/Tokyo')], [Time::Keeper::Sun->place_of('Asia/Tokyo')], '  place_of too');

# ---- either is a place -------------------------------------------------------------

for my $p ([sky => $sky], [sun => $sun], [subclass => $mine]) {
    my ($what, $place) = @$p;
    my $q = Time::Keeper::Moon->position($t, place => $place);
    ok(defined $q->{altitude}, "Moon->position takes a $what as its place");
    my $md = Time::Keeper::Moon->on(Time::Keeper->new(year => 2026, month => 10, day => 19, zone => 'Europe/London'), place => $place);
    ok(defined $md->moonrise || defined $md->moonset, "  and Moon->on");
}
is(ref $sky->on(year => 2026, month => 10, day => 19)->place, 'Time::Keeper::Sun', 'a Day hands back its place as a Sun, as 0.02 did (a Sky too)');

# ---- refusals ------------------------------------------------------------------------

ok(!eval { Time::Keeper::Sky::latitude(bless({}, 'Time::Keeper::Sky')); 1 }, 'a blessed hash is not a place');
like($@, qr/^latitude: not a Time::Keeper::Sun place/, '  by name');
ok(!eval { Time::Keeper::Moon->position($t, place => { latitude => 51 }); 1 }, 'nor a plain hash');
ok(!eval { Time::Keeper::Sky->new(latitude => 91, longitude => 0); 1 }, 'a bad latitude dies');
like($@, qr/^Time::Keeper::Sky->new: latitude must be between -90 and 90/, '  naming Time::Keeper::Sky->new');
ok(!eval { Time::Keeper::Sun->new(latitude => 91, longitude => 0); 1 }, 'and from a Sun');
like($@, qr/^Time::Keeper::Sun->new: latitude must be between -90 and 90/, '  naming Time::Keeper::Sun->new, as 0.02 did');
ok(!eval { My::Place->new(colour => 'red'); 1 }, 'a subclass\'s mistakes');
like($@, qr/^My::Place->new: unknown argument 'colour'/, '  name the subclass');
ok(defined &Time::Keeper::Sun::latitude, 'the methods are still Time::Keeper::Sun\'s by their full names');

done_testing;
