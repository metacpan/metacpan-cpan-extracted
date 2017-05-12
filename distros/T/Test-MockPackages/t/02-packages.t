#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::Tester;
use Test::Exception;
use Test::More;
use Test::MockPackages::Package();

use FindBin qw($RealBin);
use lib "$RealBin/lib";
use TMPTestPackage();

throws_ok(
    sub {
        Test::MockPackages::Package->new();
    },
    qr/^\$\Qpackage_name is required and must be a SCALAR/x,
    'requires package_name'
);

throws_ok(
    sub {
        Test::MockPackages::Package->new( [] );
    },
    qr/^\$\Qpackage_name is required and must be a SCALAR/x,
    'requires package_name to be a SCALAR'
);

my $m = Test::MockPackages::Package->new( 'TMPTestPackage' );
isa_ok( $m, 'Test::MockPackages::Package' );

my $mock = $m->mock( 'subroutine' );
isa_ok( $mock, 'Test::MockPackages::Mock' );
is( $mock, $m->mock( 'subroutine' ), 'same object returned' );
isnt( $mock, Test::MockPackages::Package->new( 'TMPTestPackage' )->mock( 'subroutine' ), 'different objects returned' );

throws_ok(
    sub {
        $m->mock();
    },
    qr/^\$\Qname is required and must be a SCALAR/,
    'missing $name'
);

throws_ok(
    sub {
        $m->mock( [] );
    },
    qr/^\$\Qname is required and must be a SCALAR/,
    '$name not a SCALAR'
);

done_testing();
