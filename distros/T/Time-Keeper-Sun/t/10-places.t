#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# A zone's representative place from zone1970.tab and backward, compiled in
# by tools/placecompile: the coordinates of the city the zone is named after.

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }

# zone1970.tab rows, read by hand from tzdata 2026e:
#   GB,GG,IM,JE  +513030-0000731  Europe/London       (seconds form)
#   JP,AU        +353916+1394441  Asia/Tokyo          (seconds form)
#   AU           -3352+15113      Australia/Sydney    (minutes form)
#   US           +394421-1045903  America/Denver
#   AQ           -720041+0023206  Antarctica/Troll
#   backward: Link Europe/London Europe/Jersey; Link Asia/Kolkata Asia/Calcutta

my ($lat, $lon) = Time::Keeper::Sun->place_of('Europe/London');
near($lat, 51 + 30 / 60 + 30 / 3600, 0.0001, 'London\'s latitude, 51 30 30');
near($lon, -(0 + 7 / 60 + 31 / 3600), 0.0001, 'and longitude, 0 07 31 west');
($lat, $lon) = Time::Keeper::Sun->place_of('Asia/Tokyo');
near($lat, 35.6544, 0.0001, 'Tokyo');
near($lon, 139.7447, 0.0001, 'Tokyo, east');
($lat, $lon) = Time::Keeper::Sun->place_of('Australia/Sydney');
near($lat, -(33 + 52 / 60), 0.0001, 'Sydney, south, the minutes form');
near($lon, 151 + 13 / 60, 0.0001, 'Sydney, east');
($lat, $lon) = Time::Keeper::Sun->place_of('Antarctica/Troll');
near($lat, -(72 + 0 / 60 + 41 / 3600), 0.0001, 'Troll, south, the seconds form');
near($lon, 2 + 32 / 60 + 6 / 3600, 0.0001, 'Troll, east');
($lat, $lon) = Time::Keeper::Sun->place_of('America/Denver');
near($lon, -(104 + 59 / 60 + 3 / 3600), 0.0001, 'Denver, west');

{
    my @london = Time::Keeper::Sun->place_of('Europe/London');
    my @jersey = Time::Keeper::Sun->place_of('Europe/Jersey');
    is("@jersey", "@london", 'a link has its target\'s coordinates');
    my @calcutta = Time::Keeper::Sun->place_of('Asia/Calcutta');
    is("@calcutta", join(' ', Time::Keeper::Sun->place_of('Asia/Kolkata')), 'and so does an old name');
}

# the constructor
{
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    near($sun->latitude, 51.5083, 0.0001, 'new(place) sets the latitude');
    near($sun->longitude, -0.1253, 0.0001, 'and the longitude');
    is($sun->zone_name, 'Europe/London', 'and the zone');
    is($sun->elevation, 0, 'elevation 0');
    like("${\ $sun->on(year => 2026, month => 10, day => 15)->sunrise }", qr/^2026-10-15T07:24:\d\d\+01:00$/, 'and the sunrise is London\'s');
    my $jersey = Time::Keeper::Sun->new(place => 'Europe/Jersey');
    is($jersey->zone_name, 'Europe/Jersey', 'a link keeps its own name as the zone');
    is($jersey->latitude, $sun->latitude, 'with the target\'s coordinates');
    my $denver = Time::Keeper::Sun->new(place => 'America/Denver', zone => 'UTC');
    is($denver->zone_name, 'UTC', 'zone => beside place replaces the zone');
    near($denver->longitude, -104.9842, 0.0001, 'not the coordinates');
    my $first = Time::Keeper::Sun->new(zone => 'Asia/Tokyo', place => 'America/Denver');
    is($first->zone_name, 'Asia/Tokyo', 'in either order');
    is(Time::Keeper::Sun->new(place => 'Asia/Tokyo', locale => 'ja', elevation => 10)->locale, 'ja', 'the other arguments still apply');
    for my $bad (
        [[place => 'Nowhere/City'], qr/^Time::Keeper::Sun->new: no place is known for 'Nowhere\/City' \(a zone of tzdata 2026e\)/],
        [[place => 'UTC'], qr/no place is known for 'UTC'/],
        [[place => 'Etc/GMT'], qr{no place is known for 'Etc/GMT'}],
        [[place => 'europe/london'], qr/no place is known for 'europe\/london'/],
        [[place => 'Europe/London', latitude => 51], qr/give place, or latitude and longitude, not both/],
        [[place => 'Europe/London', longitude => 0], qr/give place, or latitude and longitude, not both/],
        [[place => undef], qr/place must be a zone name/],
        [[], qr/needs latitude and longitude, or place/],
    ) {
        my ($args, $re) = @$bad;
        ok(!eval { Time::Keeper::Sun->new(@$args); 1 }, 'new(' . join(' ', map { $_ // 'undef' } @$args) . ') dies');
        like($@, $re, 'by name');
    }
    ok(!eval { Time::Keeper::Sun->place_of('Mars/Olympus'); 1 }, 'place_of an unknown name dies');
    like($@, qr/^Time::Keeper::Sun->place_of: no place is known for 'Mars\/Olympus'/, 'by name');
    ok(!eval { Time::Keeper::Sun->place_of(undef); 1 }, 'place_of undef dies');
}

# the table
{
    my @names = Time::Keeper::Sun->places;
    is(scalar @names, 549, '549 names: 312 zones and 237 links (the fifteen links to Etc/GMT and Etc/UTC have no place)');
    is(Time::Keeper::Sun->places_release, '2026e', 'from tzdata 2026e');
    my $sorted = 1;
    $sorted &&= ($names[$_ - 1] lt $names[$_]) for 1 .. $#names;
    ok($sorted, 'sorted, with no duplicate');
    ok((grep { $_ eq 'Europe/London' } @names), 'London is in it');
    ok((grep { $_ eq 'Europe/Jersey' } @names), 'and Jersey');
    ok(!(grep { $_ eq 'UTC' || $_ eq 'Etc/GMT' } @names), 'UTC and Etc/GMT are not');
    # the first and the last, so a binary search off by one shows
    my ($lat0, $lon0) = Time::Keeper::Sun->place_of($names[0]);
    ok(defined $lat0, "the first name, $names[0], is found");
    my ($latn, $lonn) = Time::Keeper::Sun->place_of($names[-1]);
    ok(defined $latn, "and the last, $names[-1]");
    ok(!eval { Time::Keeper::Sun->place_of($names[0] . 'x'); 1 }, 'a name one character longer is not');
    like($@, qr/no place is known for/, 'and it is the name that is unknown, not the argument');
    ok(!eval { Time::Keeper::Sun->place_of(substr($names[0], 0, -1)); 1 }, 'nor one shorter');
    like($@, qr/no place is known for 'Africa\/Abidja'/, 'and it is the name that is unknown (substr passes a magical value)');
    my $short = substr($names[0], 0, -1);
    ok(!eval { Time::Keeper::Sun->place_of($short); 1 }, 'the same name copied is unknown too');
    like($@, qr/no place is known for 'Africa\/Abidja'/, 'by name');

    # every name is a zone Time::Keeper knows, and every place is on the earth
    my ($bad_zone, $bad_coord) = (0, 0);
    for my $name (@names) {
        my $sun = eval { Time::Keeper::Sun->new(place => $name) };
        if (!$sun) { $bad_zone++; diag("$name: $@"); next }
        $bad_coord++ if abs($sun->latitude) > 90 || abs($sun->longitude) > 180;
    }
    is($bad_zone, 0, 'every name is a zone Time::Keeper::Zone knows');
    is($bad_coord, 0, 'every coordinate is in range');
}

# Magical arguments: a tied scalar, and substr passed straight in, are read
# through their magic by every method that takes a value.
{
    package Tied;
    sub TIESCALAR { my ($class, $v) = @_; bless \$v, $class }
    sub FETCH { ${ $_[0] } }
    sub STORE { ${ $_[0] } = $_[1] }
}
{
    tie my $name, 'Tied', 'Asia/Tokyo';
    my @p = Time::Keeper::Sun->place_of($name);
    near($p[0], 35.6544, 0.0001, 'place_of reads a tied name');
    tie my $lat, 'Tied', 51.5;
    tie my $lon, 'Tied', -0.1;
    my $sun = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => 'Europe/London');
    is($sun->latitude, 51.5, 'new reads a tied latitude');
    tie my $zone, 'Tied', 'Asia/Tokyo';
    is(Time::Keeper::Sun->new(place => 'Asia/Tokyo', zone => $zone)->zone_name, 'Asia/Tokyo', 'and a tied zone');
    my $ymd = '2026-10-15';
    my $d = $sun->on(year => substr($ymd, 0, 4), month => substr($ymd, 5, 2), day => substr($ymd, 8, 2));
    is("${\ $d->date }", '2026-10-15', 'on reads year, month and day passed as substr');
    tie my $epoch, 'Tied', 1760000000;
    ok($sun->position($epoch)->{altitude}, 'position reads a tied epoch');
    ok(Time::Keeper::Moon->phase_name($epoch), 'and so does the moon');
    tie my $kind, 'Tied', 'nautical';
    is("${\ $d->dawn(kind => $kind) }", "${\ $d->dawn(kind => 'nautical') }", 'dawn reads a tied kind');
    tie my $month, 'Tied', 'june';
    ok(Time::Keeper::Sun->solstice(year => 2026, month => $month), 'solstice reads a tied month');
    tie my $phase, 'Tied', 'full';
    ok(Time::Keeper::Moon->next(phase => $phase, after => $epoch), 'next reads a tied phase');
}

done_testing;
