#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Infix::FromPerl qw(
   register_xs_parse_infix
   XPI_CLS_ADD_MISC
);
use Optree::Generate qw( make_entersub_op );

BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

# We now know we're on at least 5.38 and therefore we can enable nonexperimental signatures
use feature 'signatures';

sub combine ( $lhs, $rhs ) {
   return "<$lhs+$rhs>";
}

BEGIN {
   register_xs_parse_infix( combine =>
      cls => XPI_CLS_ADD_MISC,
      permit_hintkey => "main/combine",
      new_op => sub ( $flags, $lhs, $rhs, $, $ ) {
         return make_entersub_op( \&combine, [ $lhs, $rhs ] );
      },
   );
}

{
   BEGIN { $^H{"main/combine"}++ }
   my $result = "abc" combine "def";
   is( $result, "<abc+def>", 'result of invoking infix combine operator' );
}

BEGIN {
   register_xs_parse_infix( combinebyname =>
      cls => XPI_CLS_ADD_MISC,
      permit_hintkey => "main/combinebyname",
      new_op => sub ( $flags, $lhs, $rhs, $, $ ) {
         return make_entersub_op( "main::combine", [ $lhs, $rhs ] );
      },
   );
}

{
   BEGIN { $^H{"main/combinebyname"}++ }
   my $result = "abc" combinebyname "def";
   is( $result, "<abc+def>", 'result of invoking infix combinebyname operator' );
}

done_testing;
