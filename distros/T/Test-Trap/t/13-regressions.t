#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/13-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 11;
use strict;
use warnings;

BEGIN {
  use_ok( 'Test::Trap' );
}

() = trap { @_ };
is( $trap->leaveby, 'return', 'We may access @_' );
is_deeply( $trap->return, [], 'Empty @_ in the trap block, please' );

() = trap { $_[1] = 1; @_ };
is( $trap->leaveby, 'return', 'We may modify @_' );
is_deeply( $trap->return, [ undef, 1 ], 'Modified @_ in the trap block' );

TIMELY_DESTRUCTION: {
  my $destroyed=0;
  sub Foo::DESTROY {
    $destroyed++;
  }
SCOPE: {
    my $foo = [];
    bless $foo, 'Foo';
    trap { $foo };
    is( $destroyed, 0, 'No Foo yet destroyed' );
  }
  is( $destroyed, 1, 'One Foo destroyed' );
}

local $^E;
scalar trap { die Data::Dump::dump($^E) if $^E; $^E };
$trap->return_is(0, '', '$^E is unchanged inside return_is()') or $trap->diag_all;
my $copy = $^E;
is( $copy, '', '$^E is unchanged after return_is()');

local $^E;
scalar trap { die Data::Dump::dump($^E) if $^E; $^E };
$trap->did_return() or $trap->diag_all;
$copy = $^E;
is( $copy, '', '$^E is unchanged after did_return()');
