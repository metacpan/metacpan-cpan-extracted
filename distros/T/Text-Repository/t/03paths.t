package Text::Repository::Test03;
# vim: ft=perl:

use strict;

use Test::More tests => 9;
use Text::Repository;

# Initial instantiation
my $rep = Text::Repository->new("/tmp", "/etc", $ENV{'HOME'});

# Get a list of paths
my @paths = $rep->paths;

# Test 1 -- Correct number of paths
is(scalar @paths, 3, "Correct number of paths");

# Test 2 -- The paths are what we expect.
ok((($paths[0] eq "/tmp") &&
    ($paths[1] eq "/etc") &&
    ($paths[2] eq $ENV{'HOME'})
   ), "Paths are set correctly");

# Try it again, after removing a path
$rep->remove_path("/tmp");
@paths = $rep->paths;

# Test 3 -- Same as test 1, after removing a path
is(scalar @paths, 2, "Paths can be removed correctly");

# Test 4 -- Same as test 2, after removing a path
ok((($paths[0] eq "/etc") &&
    ($paths[1] eq $ENV{'HOME'})
   ), "Paths are set correctly");

$rep->add_path($ENV{'HOME'});
# Test 5 -- Same as test 1, after adding a duplicate path
is(scalar @paths, 2, "Duplicate paths are handled correctly");

# Test 6 -- Same as test 2, after adding a duplicate path
ok((($paths[0] eq "/etc") &&
    ($paths[1] eq $ENV{'HOME'})
   ), "Duplicate paths are handled correctly");

# Add a few more paths, as an arrayref rather than as an array

$rep->add_path([ qw(/usr/bin /usr/lib) ]);
@paths = $rep->paths;
# Test 7 -- Same as test 1, after adding a duplicate path
is(scalar @paths, 4, "Adding paths using arrayref");

# Test 8 -- Same as test 2, after adding a duplicate path
ok((($paths[0] eq "/etc") &&
    ($paths[1] eq $ENV{'HOME'}) &&
    ($paths[2] eq "/usr/bin") &&
    ($paths[3] eq "/usr/lib")
   ), "Adding paths using arrayrefs works");

$rep->add_path("/etc/passwd");
@paths = $rep->paths;

# Test 9 -- add_paths ignores non-directories
is(scalar @paths, 4, "add_path ignores non-directories");
