use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Video::Pattern;

# Test.
my $obj = Video::Pattern->new;
my $temp_dir = tempdir('CLEANUP' => 1);
my $ret = $obj->create($temp_dir);
is($ret, undef, "'create' method returns undef.");
