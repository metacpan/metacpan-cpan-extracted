#!perl -T

use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( "Test::Pod::Coverage::Permissive" );
}

my @files = Test::Pod::Coverage::Permissive::all_modules( "blib" );

# The expected files have slashes, not File::Spec separators, because
# that's how File::Find does it.
my @expected = qw( Test::Pod::Coverage::Permissive );
@files = sort @files;
@expected = sort @expected;
is_deeply( \@files, \@expected, "Got all the distro files" );
