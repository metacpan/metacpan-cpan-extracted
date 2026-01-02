#!/usr/bin/perl

use v5.14;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

use Test::ExpectAndCheck;

my ( $controller, $mock ) = Test::ExpectAndCheck->create(
   isa => [qw( A::Class B::Class )],
);

ok( $mock->isa( "A::Class" ), '$mock claims to be A::Class' );
ok( !$mock->isa( "D::Class" ), '$mock does not claim to be D::Class' );

done_testing;
