#!perl
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/99-*.t" -*-
use strict;
use warnings;

# Tests for the purpose of shutting up Devel::Cover about some stuff
# that really is tested.  Like, trust me already?

use Test::Trap;

# Set up a plan:
use Test::Builder; BEGIN { my $t = Test::Builder->new; $t->plan( tests => 7 ) }

BEGIN {
  scalar trap { exists &Test::More::ok };
  $trap->return_nok( 0, '&Test::More::ok not created before the use' );
  $trap->quiet;
}

use Test::More;

BEGIN {
  scalar trap { exists &Test::More::ok };
  $trap->return_ok( 0, '&Test::More::ok created now' );
  $trap->quiet;
}

trap {
  Test::Trap::Builder->new->layer_implementation('Test::Trap', []);
};
$trap->die_like( qr/^Unknown trap layer \"ARRAY/, 'Cannot specify layers as arrayrefs' );

my $early_exit = 1;
END {
  ok( $early_exit, 'Failing to raise an exception: Early exit' );
  is( $?, 8, 'Exiting with exit code 8' );
  # let Test::More handle exit codes different from 8:
  $? = 0 if $? == 8;
}
$trap->Exception("Failing");
undef $early_exit;
