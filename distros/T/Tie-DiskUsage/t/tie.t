#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 8;
use Tie::DiskUsage;

my $path = File::Spec->catfile($Bin, 'data');

{
    tie my %usage, 'Tie::DiskUsage', $path;
    cmp_ok($usage{$path}, '>', 0, 'basic tie (default du location)');
    untie %usage;
}

{
    my $du_bin_default = $Tie::DiskUsage::DU_BIN;

    # let File::Which figure out where du is located
    $Tie::DiskUsage::DU_BIN = '/invalid/path/to/du';

    local $@;

    my %usage;
    eval { tie %usage, 'Tie::DiskUsage', $path };
    ok(!$@, 'basic tie (gather du location)');
    untie %usage;

    $Tie::DiskUsage::DU_BIN = $du_bin_default;
}

{
    tie my %usage, 'Tie::DiskUsage', $path;

    ok(exists $usage{$path},           'tie path exists');
    ok(defined $usage{$path},          'tie path defined');
    is((keys %usage)[0], $path,        'tie path keys');
    cmp_ok((values %usage)[0], '>', 0, 'tie path values');
    is(()=each %usage, 2,              'tie path each');
    ok(defined scalar %usage,          'tie path scalar');

    untie %usage;
}
