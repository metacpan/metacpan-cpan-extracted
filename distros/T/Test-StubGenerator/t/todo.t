#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author test.  Set $ENV{ TEST_AUTHOR } to enable this test.' unless $ENV{ TEST_AUTHOR };

use File::Spec;
use File::Find;

# Check that all files do not contain any
# lines with "XXX" - such markers should
# either have been converted into Todo-stuff
# or have been resolved.
# The test was provided by Andy Lester.
# Added a check for "TODO" - Kent Cowgill

my @files;
my $blib = File::Spec->catfile(qw(lib));
find(\&wanted, $blib);
plan tests => scalar @files * 2;
foreach my $file (@files) {
  source_file_ok($file);
}

sub wanted {
  push @files, $File::Find::name if /\.p(l|m|od)$/;
}

sub source_file_ok {
    my $file = shift;

    open( my $fh, '<', $file ) or die "Can't open $file: $!";
    my @lines = <$fh>;
    close $fh;

    my $n = 0;
    for ( @lines ) {
        ++$n;
        s/^/$file ($n): /;
    }

    my @x = grep /XXX/, @lines;

    if ( !is( scalar @x, 0, "Looking for XXXes in $file" ) ) {
        diag( $_ ) for @x;
    }
    my @y = grep /TODO/, @lines;
    if ( !is( scalar @y, 0, "Looking for TODOs in $file" ) ) {
        diag( $_ ) for @y;
    }
}
