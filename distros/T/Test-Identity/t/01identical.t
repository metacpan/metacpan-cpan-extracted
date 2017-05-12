#!/usr/bin/perl -w

use strict;

use Test::Builder::Tester tests => 8;

use Test::Identity;

my $arr = [];

test_out( "ok 1 - undef" );
identical( undef, undef, 'undef' );
test_test( "undef succeeds" );

test_out( "ok 1 - anon ARRAY ref" );
identical( $arr, $arr, 'anon ARRAY ref' );
test_test( "anon ARRAY ref succeeds" );

test_out( "not ok 1 - undef/ARRAY" );
test_fail( +2 );
test_err( "# Expected an anonymous ARRAY ref, got undef" );
identical( undef, [], 'undef/ARRAY' );
test_test( "undef vs ARRAY fails" );

test_out( "not ok 1 - ARRAY/undef" );
test_fail( +2 );
test_err( "# Expected undef, got an anonymous ARRAY ref" );
identical( [], undef, 'ARRAY/undef' );
test_test( "ARRAY vs undef fails" );

test_out( "not ok 1 - ARRAY/ARRAY" );
test_fail( +2 );
test_err( "# Expected an anonymous ARRAY ref to the correct object" );
identical( [], [], 'ARRAY/ARRAY' );
test_test( "ARRAY vs ARRAY fails" );

my $obj = bless [], "SomePackage";

test_out( "ok 1 - object" );
identical( $obj, $obj, 'object' );
test_test( "object succeeds" );

test_out( "not ok 1 - undef/object" );
test_fail( +2 );
test_err( "# Expected a reference to a SomePackage, got undef" );
identical( undef, $obj, 'undef/object' );
test_test( "undef vs object fails" );

test_out( "not ok 1 - ARRAY/object" );
test_fail( +2 );
test_err( "# Expected a reference to a SomePackage, got an anonymous ARRAY ref" );
identical( [], $obj, 'ARRAY/object' );
test_test( "ARRAY vs object fails" );
