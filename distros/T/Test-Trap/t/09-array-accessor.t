#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/09-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 6;
use strict;
use warnings;

BEGIN {
  use_ok( 'Test::Trap', 'trap', '$T' );
}

my @r = trap { 10, 20, 30 };
is_deeply( $T->return, [10, 20, 30], 'Deeply' );
is_deeply( [ $T->return(0,2,1,1) ], [10, 30, 20, 20], 'Slice' );
is( $T->return(0), 10, 'Index 0' );
is( $T->return(1), 20, 'Index 1' );
is( $T->return(2), 30, 'Index 2' );
