#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Infix::FromPerl qw(
   register_xs_parse_infix
   XPI_CLS_ADD_MISC
);
use Optree::Generate qw(
   newBINOP

   OP_ADD
);

BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my %called;

BEGIN {
   my $arr = [];

   register_xs_parse_infix( add =>
      # lhs_flags, rhs_flags
      cls => XPI_CLS_ADD_MISC,
      permit => sub {
         my ( $hookdata ) = @_;
         $called{permit}++;
         ref_is( $hookdata, $arr, 'hookdata to permit callback' );
         return 1;
      },
      new_op => sub {
         my ( $flags, $lhs, $rhs, undef, $hookdata ) = @_;
         $called{new_op}++;
         ref_is( $hookdata, $arr, 'hookdata to new_op callback' );
         return newBINOP( OP_ADD, 0, $lhs, $rhs );
      },
      hookdata => $arr,
   );
}

ok( $called{permit}, 'add permit callback was called' );
ok( $called{new_op}, 'add new_op callback was called' );

# TODO: If this was `1 add 2` then it crashes due to S_fold_contants
my $two = 2;
my $result = 1 add $two;
is( $result, 3, 'result of add operator' );

done_testing;
