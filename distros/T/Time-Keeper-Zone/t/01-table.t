#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper::Zone;

is(Time::Keeper::Zone::_tzdata_version(), '2026e', 'compiled from tzdata 2026e');

my ($zones, $links, $lookup, $types, $trans, $footers, $windows) = Time::Keeper::Zone::_counts();
is($zones, 344, '344 zones');
is($links, 253, '253 links');
is($lookup, $zones + $links, 'and one name to look up for each');

my @rows = Time::Keeper::Zone::_lookup_table();
my (@names, %target, %is_link);
while (my ($name, $zone, $link) = splice @rows, 0, 3) {
    push @names, $name;
    $target{$name} = $zone;
    $is_link{$name} = $link;
}
is(scalar @names, $lookup, 'the lookup table has every name');
is_deeply(\@names, [sort { lc $a cmp lc $b } @names], 'sorted without regard to case');
my %lc;
$lc{lc $_}++ for @names;
is(scalar(grep { $_ > 1 } values %lc), 0, 'and no two names differ only in case');

is(scalar(grep { !$is_link{$_} } @names), $zones, 'the zones are the names that are not links');
is(scalar(grep { !$is_link{$_} && $target{$_} ne $_ } @names), 0, 'each zone is its own target');
is(scalar(grep { $is_link{$_} && $is_link{ $target{$_} } } @names), 0, 'each link leads to a zone, not to another link');

is($target{'US/Eastern'}, 'America/New_York', 'US/Eastern is New York');
is($target{'Asia/Calcutta'}, 'Asia/Kolkata', 'Calcutta is Kolkata');
is($target{'GB'}, 'Europe/London', 'GB is London');
is($target{'UTC'}, 'Etc/UTC', 'UTC is Etc/UTC');
ok(!exists $target{'Factory'}, 'the Factory zone is not compiled in');
ok(!exists $target{'posixrules'}, 'nor posixrules');

my $bad_order = 0;
my $no_footer = 0;
for my $name (grep { !$is_link{$_} } @names) {
    my $z = Time::Keeper::Zone::_zone_dump($name);
    my @at = map { $_->[0] } @{ $z->{transitions} };
    $bad_order++ if grep { $at[$_] <= $at[$_ - 1] } 1 .. $#at;
    $no_footer++ unless $z->{footer};
}
is($bad_order, 0, 'every zone\'s transitions are in order, none twice');
is($no_footer, 0, 'every zone has a rule for the years after its last transition');

is(Time::Keeper::Zone::_zone_dump('US/Eastern'), undef, 'a link has no table of its own');
is(Time::Keeper::Zone::_zone_dump('Nowhere/Special'), undef, 'nor does a name that is not there');

{
    my $z = Time::Keeper::Zone::_zone_dump('Etc/UTC');
    is(scalar @{ $z->{transitions} }, 0, 'UTC has no transitions');
    is_deeply($z->{initial}, [0, 0, 'UTC'], 'it is UTC from the start');
    is($z->{footer}{text}, 'UTC0', 'and for ever');
    ok(!$z->{footer}{dst}, 'with no daylight time');
}

{
    my $z = Time::Keeper::Zone::_zone_dump('Europe/London');
    is($z->{initial}[2], 'LMT', 'London starts in local mean time');
    is($z->{initial}[0], -75, 'which was 75 seconds behind GMT');
    my $f = $z->{footer};
    is($f->{text}, 'GMT0BST,M3.5.0/1,M10.5.0', 'its rule now');
    is_deeply($f->{std}, [0, 0, 'GMT'], 'GMT in winter');
    is_deeply($f->{dst}, [3600, 1, 'BST'], 'BST in summer');
    is_deeply($f->{start}, { kind => 'M', month => 3, week => 5, wday => 0, day => 0, time => 3600 },
              'from 01:00 on the last Sunday in March');
    is_deeply($f->{end}, { kind => 'M', month => 10, week => 5, wday => 0, day => 0, time => 7200 },
              'to 02:00 on the last Sunday in October');
    my ($bdst) = grep { $_->[3] eq 'BDST' } @{ $z->{transitions} };
    is($bdst->[1], 7200, 'double summer time during the war was two hours ahead');
}

{
    my $f = Time::Keeper::Zone::_zone_dump('Australia/Lord_Howe')->{footer};
    is($f->{std_utoff}, 37800, 'Lord Howe is ten and a half hours ahead');
    is($f->{dst_utoff}, 39600, 'and moves on only half an hour in summer');
    is($f->{dst}[2], '+11', 'an abbreviation that is a number');
}

{
    my $f = Time::Keeper::Zone::_zone_dump('Europe/Dublin')->{footer};
    is_deeply($f->{std}, [3600, 0, 'IST'], 'Irish Standard Time is the summer one');
    is_deeply($f->{dst}, [0, 1, 'GMT'], 'and GMT is daylight time, an hour behind it');
}

{
    my $f = Time::Keeper::Zone::_zone_dump('America/Sao_Paulo')->{footer};
    is($f->{text}, '<-03>3', 'Sao Paulo has had no daylight time since 2019');
    is($f->{std_utoff}, -10800, 'three hours behind');
}

my %win = Time::Keeper::Zone::_windows_table();
is(scalar keys %win, $windows, 'every Windows name once');
is($win{'GMT Standard Time'}, 'Europe/London', 'GMT Standard Time is London');
is($win{'Eastern Standard Time'}, 'America/New_York', 'Eastern Standard Time is New York');
is($win{'Tokyo Standard Time'}, 'Asia/Tokyo', 'Tokyo Standard Time is Tokyo');
is($win{'India Standard Time'}, 'Asia/Kolkata', 'India Standard Time is Kolkata');
is($win{UTC}, 'Etc/UTC', 'and UTC is UTC');

done_testing;
