#!/usr/bin/perl

# Test that Devel::CheckLib _findcc() produces helpful error messages
# and does not die at module load time.

use strict;
use warnings;
use Test::More tests => 3;
use Config;
use File::Spec;

# Load CheckLib from the inc directory
use lib './inc';

# Test 1: Module loads without dying even when called normally.
# (Before the fix, _findcc() was called at load time and would die
# with the unhelpful "Couldn't find your C compiler" if cc wasn't found.)
use_ok('Devel::CheckLib');

# Test 2: _findcc should not be called at module load time.
# Verify by checking that the module source does not have a bare _findcc()
# call outside of a sub definition.
{
    my $module_file = File::Spec->catfile('inc', 'Devel', 'CheckLib.pm');
    open my $fh, '<', $module_file or die "Cannot open $module_file: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    # Match _findcc() calls that are NOT inside a sub body (i.e., at package level)
    # The old code had: _findcc(); # bomb out early if there's no compiler
    # This should no longer exist.
    my $has_load_time_findcc = ($source =~ /^_findcc\(\);/m);
    ok(!$has_load_time_findcc,
       '_findcc() is not called at module load time');
}

# Test 3: The die message in _findcc includes the compiler name
# so users know what was being looked for.
{
    my $module_file = File::Spec->catfile('inc', 'Devel', 'CheckLib.pm');
    open my $fh, '<', $module_file or die "Cannot open $module_file: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    # The die() in _findcc should interpolate the compiler name, not just
    # say "Couldn't find your C compiler"
    # Match within a single line to avoid false positives across the file
    my $found = grep { /die\(.*\$Config\{cc\}/ } split /\n/, $source;
    ok($found,
       '_findcc die message includes $Config{cc} for helpful diagnostics');
}
