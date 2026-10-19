#!perl
use 5.010;
use strict;
use warnings;
use Config;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# The layout of 0.02: a day computes its twilights the first time they are
# asked for and keeps them; a place and a day hold their zone and locale
# names as interned ids.

my $sun = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
my $date = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);

# ---- lazy twilights ----------------------------------------------------------

Time::Keeper::Sun::_day_walks();
my $d = $sun->on($date);
is(Time::Keeper::Sun::_day_walks(), 1, 'on walks the transits once');
is(Time::Keeper::Sun::_day_done($d), 1, 'and computes rise and set only');
ok($d->sunrise && $d->sunset && $d->solar_noon && $d->day_length, 'which is all sunrise, sunset, noon and day_length need');
is(Time::Keeper::Sun::_day_walks(), 0, 'without walking again');
my $dawn = $d->dawn;
is(Time::Keeper::Sun::_day_walks(), 1, 'the first civil dawn walks once');
is(Time::Keeper::Sun::_day_done($d), 3, 'and computes the civil depth');
is("${\ $d->dawn }", "$dawn", 'asked again it is the same');
is("${\ $d->dusk }", '2026-10-15T18:41:00+01:00', 'and the dusk came with it');
is(Time::Keeper::Sun::_day_walks(), 0, 'without walking again');
my @n = $d->dawns(kind => 'nautical');
is(Time::Keeper::Sun::_day_done($d), 7, 'the nautical depth on asking');
my @ev = $d->events;
is(Time::Keeper::Sun::_day_done($d), 15, 'events computes the rest');
is(Time::Keeper::Sun::_day_walks(), 2, 'one walk for nautical, one for the astronomical events needed');

my $fresh = $sun->on($date);
my @all = $fresh->events;
is(Time::Keeper::Sun::_day_walks(), 2, 'events on a fresh day walks once more, for the three twilights together');
is(join(' ', map { "$_->[0]=$_->[1]" } @ev), join(' ', map { "$_->[0]=$_->[1]" } @all), 'a day filled piecemeal gives the same events as one filled at once');
my $other = $sun->on($date);
is("${\ $other->dawn(kind => 'astronomical') }", "${\ $fresh->dawn(kind => 'astronomical') }", 'one depth alone is the same as with the rest');
{
    my $copy = ${ $sun->on($date) };
    my $d2 = bless \$copy, 'Time::Keeper::Sun::Day';
    my $d3 = bless \(my $c3 = $copy), 'Time::Keeper::Sun::Day';
    $d2->dawn;
    is(Time::Keeper::Sun::_day_done($d2), 3, 'a copy of a day fills itself');
    is(Time::Keeper::Sun::_day_done($d3), 1, 'and not a copy that shared its bytes');
}
{
    my $polar = Time::Keeper::Sun->new(latitude => 71.2906, longitude => -156.7886, zone => 'America/Anchorage')
        ->on(year => 2026, month => 11, day => 19);
    ok($polar->is_polar_night, 'a polar night is known without the twilights');
    is(Time::Keeper::Sun::_day_done($polar), 1, 'which are still not computed');
    ok(defined $polar->dawn, 'and then its civil dawn is there');
}

# ---- interned names ---------------------------------------------------------

{
    my ($place_size, $day_size, $moonday_size) = Time::Keeper::Sun::_sizes();
    cmp_ok($place_size, '<=', 48, "a place's struct is $place_size bytes");
    cmp_ok($day_size, '<=', 192, "a day's is $day_size");
    note("a Moon::Day's is $moonday_size");
    my $id = Time::Keeper::Sun::_name_id('Europe/London');
    is(Time::Keeper::Sun::_name_id('Europe/London'), $id, 'a name has one id');
    is(Time::Keeper::Sun::_name_str($id), 'Europe/London', 'and reads back');
    my $before = Time::Keeper::Sun::_name_count();
    Time::Keeper::Sun->new(latitude => 0, longitude => 0, zone => 'Europe/London') for 1 .. 100;
    is(Time::Keeper::Sun::_name_count(), $before, 'a hundred places in one zone add no name');
    my @names = map { "Test/Zone$_" } 1 .. 1000;
    my @ids = map { Time::Keeper::Sun::_name_id($_) } @names;
    is(scalar(grep { $_ } map { Time::Keeper::Sun::_name_str($ids[$_]) eq $names[$_] } 0 .. $#names), 1000, 'a thousand names interned and read back');
    ok(!eval { Time::Keeper::Sun::_name_str(-1); 1 }, 'an id that is no name dies');
    like($@, qr/no name has the id -1/, 'by name');
    my $tokyo = Time::Keeper::Sun->new(latitude => 35, longitude => 139, zone => 'Asia/Tokyo', locale => 'ja');
    is($tokyo->zone_name, 'Asia/Tokyo', 'zone_name through the table');
    is($tokyo->locale, 'ja', 'locale through the table');
    ok(!utf8::is_utf8($tokyo->locale), 'a locale code is not marked UTF-8');
    is($tokyo->on($date)->zone_name, 'Asia/Tokyo', 'a day\'s zone_name');
    is(Time::Keeper::Moon->on($date, zone => 'Asia/Tokyo')->zone_name, 'Asia/Tokyo', 'a moon day\'s');
    is($tokyo->on($date)->place->locale, 'ja', 'a day\'s place keeps the locale');
}

SKIP: {
    skip 'this perl has no threads', 4 unless $Config{useithreads} && eval { require threads; 1 };
    my $place = Time::Keeper::Sun->new(latitude => -33.8688, longitude => 151.2093, zone => 'Australia/Sydney', locale => 'fr');
    my $t = threads->create(sub {
        my $d = $place->on(year => 2026, month => 10, day => 15);
        my $new = Time::Keeper::Sun->new(latitude => 1, longitude => 1, zone => 'Pacific/Fiji');
        return join '|', $place->zone_name, $place->locale, "${\ $d->sunrise }", $new->zone_name;
    });
    my ($zone, $locale, $rise, $fiji) = split /\|/, $t->join;
    is($zone, 'Australia/Sydney', 'a thread reads a place made before it');
    is($locale, 'fr', 'and its locale');
    is($rise, "${\ $place->on(year => 2026, month => 10, day => 15)->sunrise }", 'and computes the same day');
    is($fiji, 'Pacific/Fiji', 'and interns a name of its own');
}

done_testing;
