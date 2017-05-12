#!/usr/bin/perl

use warnings;
use strict;

use Test::LectroTest::Generator ':all';
use Test::LectroTest::Property;
use Test::More tests => 12;

=head1 NAME

t/props2.t - Additional property checks

=head1 SYNOPSIS

    perl -Ilib t/props2.t

=head1 DESCRIPTION

These checks are designed to exercise Properties independent
of a test harness.

First, we see whether LectroTest::Property prevents you from
using the reserved identifier "tcon" in a generator-binding
declaration.

=cut

eval { 
    Property { [ tcon => 1 ] } sub {
        1;
    }
};
like($@, qr/cannot use reserved name 'tcon' in a generator binding/,
   "Property->new disallows use of 'tcon' in bindings");

eval { 
    Property { ##[ tcon <- 1 ]##
        1;
    }
};
like($@, qr/cannot use reserved name 'tcon' in a generator binding/,
   "magic Property syntax disallows use of 'tcon' in bindings");


=pod

Second, we check to see if C<new> catches and complains
about bad arguments in its pre-flight checks:

=cut

eval {
    Test::LectroTest::Property->new();
};
like( $@, qr/test subroutine must be provided/,
      "pre-flight: new w/ no args" );


eval {
    Test::LectroTest::Property->new('inputs');
};
like( $@, qr/invalid list of named parameters/,
      "pre-flight: unbalanced arguments list" );


eval {
    Test::LectroTest::Property->new(inputs=>[]);
};
like( $@, qr/test subroutine must be provided/,
      "pre-flight: new w/o test sub" );


eval { Property { ##[ x <- Unit(0)], [ ]##
                1 } 
};

like( $@, qr/\(\) does not match \(x\)/,
      "pre-flight: sets of bindings must have same vars (x) vs ()" );

eval { Property { ##[ x <- Unit(0)], [ y <- Unit(0) ]##
                1 } 
};

like( $@, qr/\(y\) does not match \(x\)/,
      "pre-flight: sets of bindings must have same vars (x) vs (y)" );

eval { Property { ##[ x <- Unit(0)], [ x <- Unit(0) ], [ ]##
                1 } 
};

like( $@, qr/\(\) does not match \(x\)/,
      "pre-flight: sets of bindings must have same vars (x) vs (x) vs ()" );


eval { Property { ##[ x <- Unit(0), 1 ]##
                1 } 
};

like( $@, qr/did not get a set of valid input-generator bindings/,
      "pre-flight: odd params in binding is caught" );



like( eval { Test::LectroTest::Property->new( inputs => [] ) } || $@,
      qr/test subroutine must be provided/,
      "pre-flight: no test subroutine" );

like( eval { Test::LectroTest::Property->new(inputs=>{1,1}, test=>sub{}) }
      || $@,
      qr/did not get a set of valid input-generator bindings/,
      "pre-flight: invalid set of generator bindings" );

like( eval { Test::LectroTest::Property->new(inputs=>[{1,1}], test=>sub{}) }
      || $@,
      qr/did not get a set of valid input-generator bindings/,
      "pre-flight: invalid inner set of generator bindings" );





=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 COPYRIGHT and LICENSE

Copyright (C) 2004 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
