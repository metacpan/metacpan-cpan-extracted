#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   XPK_FLAG_AUTOSEMI KEYWORD_PLUGIN_STMT
   register_xs_parse_keyword
);

my %called;

BEGIN {
   my $arr = [];

   register_xs_parse_keyword( donothing =>
      flags => XPK_FLAG_AUTOSEMI,
      pieces => [],
      permit => sub {
         my ( $hookdata ) = @_;
         $called{permit}++;
         ref_is( $hookdata, $arr, 'hookdata to permit callback' );
         return 1;
      },
      check => sub {
         my ( $hookdata ) = @_;
         ref_is( $hookdata, $arr, 'hookdata to check callback' );
         $called{check}++;
      },
      build => sub {
         my ( undef, undef, $hookdata ) = @_;
         ref_is( $hookdata, $arr, 'hookdata to build callback' );
         $called{build}++;
         return KEYWORD_PLUGIN_STMT;
      },
      hookdata => $arr,
   );
}

donothing;

ok( $called{permit}, 'donothing permit callback was called' );
ok( $called{check},  'donothing check callback was called' );
ok( $called{build},  'donothing build callback was called' );

done_testing;
