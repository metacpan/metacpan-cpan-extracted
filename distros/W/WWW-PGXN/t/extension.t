#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use Test::More tests => 41;
#use Test::More 'no_plan';
use WWW::PGXN;
use File::Spec::Functions qw(catfile);

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'file:t/mirror' ];

##############################################################################
# Try to get a nonexistent distribution.
ok !$pgxn->get_extension('nonexistent'),
    'Should get nothing when searching for a nonexistent extension';

# Fetch extension data.
ok my $ext = $pgxn->get_extension('pair'),
    'Find extension "pair"';
isa_ok $ext, 'WWW::PGXN::Extension', 'It';
can_ok $ext, qw(
    new
    name
    latest
    stable_info
    testing_info
    unstable_info
    latest_info
    stable_distribution
    testing_distribution
    unstable_distribution
    latest_distribution
    distribution_for_version
    info_for_version
    download_stable_to
    download_latest_to
    download_testing_to
    download_unstable_to
    download_version_to
);

is $ext->name, 'pair', 'Name should be "pair"';
is $ext->latest, 'stable', 'Latest should be "stable"';
ok my $dist = $ext->stable_distribution, 'Get the stable distribution';
isa_ok $dist, 'WWW::PGXN::Distribution', 'It';
is $dist->name, 'pair', 'It should be the "pair" distribution';
is $dist->version, '0.1.1', 'It should be v0.1.1';

ok $dist = $ext->latest_distribution, 'Get the latest distribution';
isa_ok $dist, 'WWW::PGXN::Distribution', 'It';
is $dist->name, 'pair', 'It should be the "pair" distribution';
is $dist->version, '0.1.1', 'It should be v0.1.1';

is $ext->testing_distribution, undef, 'Should have no testing distribution';
is $ext->unstable_distribution, undef, 'Should have no unstable distribution';

# Fetch for verions.
ok $dist = $ext->distribution_for_version('0.1.1'),
    'Get the distribution for pair 0.1.2';
isa_ok $dist, 'WWW::PGXN::Distribution', 'It';
is $dist->name, 'pair', 'It should be the "pair" distribution';
is $dist->version, '0.1.1', 'It should be v0.1.1';

ok $dist = $ext->distribution_for_version('0.0.5'),
    'Get the distribution for pair 0.0.5';
isa_ok $dist, 'WWW::PGXN::Distribution', 'It';
is $dist->name, 'pair', 'It should be the "pair" distribution';
is $dist->version, '0.1.0', 'It should be v0.1.0';

# Check status data.
is_deeply $ext->stable_info, {
    dist => 'pair',
    version => '0.1.1',
    sha1 => 'c552c961400253e852250c5d2f3def183c81adb3',
}, 'Should have stable data';
is_deeply $ext->latest_info, $ext->stable_info, 'Should have latest data';
is_deeply $ext->testing_info, {}, 'Should have empty testing info';
is_deeply $ext->unstable_info, {}, 'Should have empty unstable info';

##############################################################################
# Test downloading.
my $pgz = catfile qw(t pair-0.1.1.pgz);
ok !-e $pgz, "$pgz should not yet exist";
END { unlink $pgz }
is $ext->download_stable_to($pgz), $pgz, "Download to $pgz";
ok -e $pgz, "$pgz should now exist";

# Download latest.
my $zip = catfile qw(t pair-0.1.1.zip);
ok !-e $zip, "$zip should not yet exist";
END { unlink $zip }
is $ext->download_latest_to('t'), $zip, 'Download to t/';
ok -e $zip, "$zip should now exist";

# Should get undef for nonexistent statuses.
ok !$ext->download_testing_to('t'), 'Should not download testing';
ok !$ext->download_unstable_to('t'), 'Should not download unstable';

# Try by version.
my $ver = catfile qw(t pair-0.0.5.ver);
ok !-e $ver, "$ver should not yet exist";
END { unlink $ver }
is $ext->download_version_to('0.0.5', $ver), $ver, "Download to $ver";
ok -e $ver, "$ver should now exist";

# Try non-existent version.
ok !$ext->download_version_to('1.1.1', 't'), 'Should now download 1.1.1';

