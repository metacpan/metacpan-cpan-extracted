#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/05-*.t" -*-
use Test::More tests => 8;
use strict;
use warnings;

BEGIN {
  use_ok( 'Test::Trap' );
}

eval { Test::Trap->import(qw( trap1 trap2 )) };
like( $@,
      qr/^\QThe Test::Trap module does not export more than one function at ${\__FILE__} line/,
      'Export of two functions',
    );

eval { Test::Trap->import(qw( $trap1 $trap2 )) };
like( $@,
      qr/^\QThe Test::Trap module does not export more than one scalar at ${\__FILE__} line/,
      'Export of two globs',
    );

eval { Test::Trap->import(qw( @bad )) };
like( $@,
      qr/^"\@bad"\Q is not exported by the Test::Trap module at ${\__FILE__} line/,
      'Export of an array',
    );

eval { Test::Trap->import(qw( :no_such_layer )) };
like( $@,
      qr/^\QUnknown trap layer "no_such_layer" at ${\__FILE__} line/,
      'Export of an unknown layer',
    );

my %got;
$got{perlio} = eval q{ use PerlIO 'scalar'; 1 };
$got{tempfile} = eval q{ use File::Temp; 1 };

eval { Test::Trap->import(qw( test1 $T1 :stdout(perlio) )) };
like( $@,
      $got{perlio} ?
      qr/\A\z/ :
      qr/^\QNo capture strategy found for "perlio" at ${\__FILE__} line/,
      'Export of capture strategy :stdout(perlio)',
    );

eval { Test::Trap->import(qw( test2 $T2 :stdout(nosuch;tempfile) )) };
like( $@,
      $got{tempfile} ?
      qr/\A\z/ :
      qr/^\QNo capture strategy found for ("nosuch", "tempfile") at ${\__FILE__} line/,
      'Export of capture strategy :stdout(nosuch;tempfile)',
    );

eval { Test::Trap->import(qw( test2 $T2 :stdout(nosuch1;nosuch2) )) };
like( $@,
      qr/^\QNo capture strategy found for ("nosuch1", "nosuch2") at ${\__FILE__} line/,
      'Export of capture strategy:stdout(nosuch1;nosuch2)',
    );

