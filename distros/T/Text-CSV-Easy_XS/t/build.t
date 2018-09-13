#!perl
use strict;
use warnings;
use utf8;

use Data::Dumper;
use Encode;
use Test::Deep;
use Test::More;
use Text::CSV::Easy_XS qw(csv_build);

is( csv_build( 0, 1, 2, 3 ), q{0,1,2,3}, 'simple integers' );
is( csv_build(qw(one two)), q{"one","two"}, 'simple strings' );
is( csv_build( 1, "two", q{some "quote"} ), q{1,"two","some ""quote"""}, 'complex build' );

is( csv_build( undef, '' ), q{,""}, 'undef and empty' );
is( encode_utf8( csv_build( "utf-8", "check ✓" ) ), encode_utf8(q{"utf-8","check ✓"}), 'utf-8 ok' );

done_testing();
