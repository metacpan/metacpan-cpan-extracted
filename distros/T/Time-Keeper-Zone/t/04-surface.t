#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Time::Keeper::Zone;

my $Z = 'Time::Keeper::Zone';

is($Z->tzdata_version, '2026e', 'tzdata_version');

my @names = $Z->names;
is(scalar @names, 344, 'names gives every zone');
is_deeply(\@names, [sort @names], 'in order');
ok((grep { $_ eq 'Europe/London' } @names), 'London among them');
ok(!(grep { $_ eq 'GB' } @names), 'and no links');

my %links = $Z->links;
is(scalar keys %links, 253, 'links gives every link');
is($links{'US/Pacific'}, 'America/Los_Angeles', 'each to its zone');
ok(!exists $links{'Europe/London'}, 'and no zones');

ok($Z->is_valid('Europe/London'), 'is_valid: a zone');
ok($Z->is_valid('europe/LONDON'), 'in any case');
ok($Z->is_valid('GB'), 'a link');
ok(!$Z->is_valid('Europe/Londo'), 'not a name one short');
ok(!$Z->is_valid('Europe/Londonx'), 'nor one long');
ok(!$Z->is_valid(''), 'nor an empty string');
ok(!$Z->is_valid(undef), 'nor undef');
ok(!$Z->is_valid("Europe/London\0"), 'nor a name with a NUL in it');
ok(!$Z->is_valid('+05:30'), 'an offset is not a zone name');

is($Z->name('europe/london'), 'Europe/London', 'name gives the name in its own case');
is($Z->name('us/eastern'), 'US/Eastern', 'a link\'s own name');
is($Z->canonical_name('us/eastern'), 'America/New_York', 'canonical_name gives the zone it follows');
is($Z->canonical_name('Europe/London'), 'Europe/London', 'a zone is its own');
is($Z->name('Nowhere'), undef, 'undef for a name that is not there');

for my $n (map { $_, lc $_, uc $_ } @names, keys %links) {
    next if $Z->is_valid($n);
    fail("$n is not found");
}
pass('every name is found in its own case, in lower case and in upper case');

my %countries = $Z->countries;
cmp_ok(scalar keys %countries, '>', 240, 'countries');
is($countries{GB}, 'Britain (UK)', 'with their names, as iso3166.tab has them');
is_deeply([$Z->zones_for_country('GB')], ['Europe/London'], 'Britain has one zone');
is_deeply([$Z->zones_for_country('no')], ['Europe/Oslo'], 'Norway has Oslo, though Oslo follows Berlin');
cmp_ok(scalar(my @us = $Z->zones_for_country('US')), '>', 20, 'the United States has many');
is_deeply([$Z->zones_for_country('XX')], [], 'no zones for a country that is not there');
is_deeply([$Z->zones_for_country('GBR')], [], 'nor for a three-letter code');

is($Z->windows_zone('GMT Standard Time'), 'Europe/London', 'windows_zone');
is($Z->windows_zone('Pacific Standard Time'), 'America/Los_Angeles', 'the Windows Pacific zone');
is($Z->windows_zone('Nowhere Standard Time'), undef, 'undef for a name Windows does not have');

# The local zone. TZ first, then the files, each stood in for here.
sub local_from { Time::Keeper::Zone::_local_zone_from(@_) }
is(local_from('Asia/Tokyo', undef, undef, undef), 'Asia/Tokyo', 'TZ names a zone');
is(local_from(':Asia/Tokyo', undef, undef, undef), 'Asia/Tokyo', 'TZ with a colon before it');
is(local_from('asia/tokyo', undef, undef, undef), 'Asia/Tokyo', 'TZ in the wrong case');
is(local_from('', undef, undef, undef), 'Etc/UTC', 'an empty TZ is UTC');
is(local_from('/usr/share/zoneinfo/Asia/Tokyo', undef, undef, undef), 'Asia/Tokyo', 'TZ as a path into zoneinfo');
is(local_from(undef, undef, undef, undef), 'Etc/UTC', 'nothing at all is UTC');

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/timezone" or die;
print $fh "  America/Chicago  \n";
close $fh;
open $fh, '>', "$dir/clock" or die;
print $fh "# comment\nUTC=true\nZONE=\"Africa/Lagos\"\n";
close $fh;
SKIP: {
    skip 'no symlinks here', 3 unless eval { symlink("/var/db/timezone/zoneinfo/Australia/Perth", "$dir/localtime") };
    is(local_from(undef, "$dir/localtime", "$dir/timezone", "$dir/clock"), 'Australia/Perth', 'the link of /etc/localtime first');
    is(local_from('EST5EDT', "$dir/localtime", undef, undef), 'EST5EDT', 'but TZ before it');
    is(local_from('Not/AZone', "$dir/localtime", undef, undef), 'Australia/Perth', 'and a TZ that names nothing is passed over');
}
is(local_from(undef, "$dir/missing", "$dir/timezone", "$dir/clock"), 'America/Chicago', 'then /etc/timezone, trimmed');
is(local_from(undef, undef, "$dir/missing", "$dir/clock"), 'Africa/Lagos', 'then /etc/sysconfig/clock');
is(local_from(undef, "$dir/timezone", undef, undef), 'Etc/UTC', 'a localtime that is a file and not a link names nothing');

{
    local $ENV{TZ} = 'Pacific/Auckland';
    is($Z->local_name, 'Pacific/Auckland', 'local_name reads TZ from %ENV');
    local $ENV{TZ} = '';
    is($Z->local_name, 'Etc/UTC', 'and an empty one is UTC');
}

# The ABI table, called through its pointers.
sub abi { Time::Keeper::Zone::_abi_call(@_) }
my $id = abi('lookup', 'us/eastern');
cmp_ok($id, '>=', 0, 'lookup gives an id');
is(abi('lookup', 'nowhere'), -1, 'or -1');
is(abi('name', $id), 'US/Eastern', 'name');
is(abi('canonical_name', $id), 'America/New_York', 'canonical_name');
is(abi('is_link', $id), 1, 'is_link');
is(abi('is_link', abi('lookup', 'Europe/London')), 0, 'and a zone is not one');
is(abi('name', -1), undef, 'name of a bad id');
is(abi('name', abi('zone_count')), undef, 'or one past the end');
is(abi('zone_count'), 597, 'zone_count counts zones and links');
is_deeply([abi('offset_at', $id, 1793516400)], [1, -18000, 0, 'EST'], 'offset_at');
is_deeply([abi('offset_at', 9999, 0)], [0], 'offset_at a bad id');
is(abi('next_change', $id, 1767225600), 1772953200, 'next_change');
is_deeply([abi('resolve_local', $id, 1793496600, 0, 1)], [1, 1793511000], 'resolve_local');
is((abi('resolve_local', 9999, 0, 0, 0))[0], -1, 'resolve_local with a bad id');
is(abi('name', abi('local_zone', 'Asia/Tokyo')), 'Asia/Tokyo', 'local_zone');
is(abi('tzdata_version'), '2026e', 'tzdata_version');

done_testing;
