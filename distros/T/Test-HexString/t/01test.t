#!/usr/bin/perl -w

use strict;

use Test::Builder::Tester tests => 5;

use Test::HexString;

test_out( "ok 1 - hello" );
is_hexstr( "hello", "hello", 'hello' );
test_test( "equal strings succeeds" );

test_out( "not ok 1 - binary" );
test_fail( +4 );
test_err( "#   at bytes 0-0xf (0-15)",
          "#   got: | 01 02 03 04 .. .. .. .. .. .. .. .. .. .. .. .. |....            |",
          "#   exp: | 01 02 03 05 .. .. .. .. .. .. .. .. .. .. .. .. |....            |" );
is_hexstr( "\1\2\3\4", "\1\2\3\5", 'binary' );
test_test( "differing binary strings fails" );

test_out( "not ok 1 - text" );
test_fail( +4 );
test_err( "#   at bytes 0-0xf (0-15)",
          "#   got: | 66 6f 6f 62 61 72 .. .. .. .. .. .. .. .. .. .. |foobar          |",
          "#   exp: | 66 6f 30 62 61 72 .. .. .. .. .. .. .. .. .. .. |fo0bar          |" );
is_hexstr( "foobar", "fo0bar", 'text' );
test_test( "differing text strings fails" );

my $longstring = join( "", map chr, 0 .. 255 ) x 10;
my $different = $longstring;
substr( $different, 1000, 1 ) = "A";

test_out( "not ok 1 - long string" );
test_fail( +4 );
test_err( "#   at bytes 0x3e0-0x3ef (992-1007)",
          "#   got: | e0 e1 e2 e3 e4 e5 e6 e7 41 e9 ea eb ec ed ee ef |........A.......|",
          "#   exp: | e0 e1 e2 e3 e4 e5 e6 e7 e8 e9 ea eb ec ed ee ef |................|" );
is_hexstr( $different, $longstring, 'long string' );
test_test( "differing long text strings fails" );

test_out( "not ok 1 - ARRAY ref" );
test_fail( +2 );
test_err( "#   expected a plain string, was given a reference to ARRAY" );
is_hexstr( [], "array", 'ARRAY ref' );
test_test( "giving ARRAY ref fails" );
