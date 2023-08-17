#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   KEYWORD_PLUGIN_EXPR
   XPK_PARENS XPK_TERMEXPR XPK_BLOCK
   register_xs_parse_keyword
);
use Optree::Generate qw(
   opcode
   op_scope
   newCONDOP
);

# cond
BEGIN {
   register_xs_parse_keyword( cond =>
      permit_hintkey => "main/cond",
      pieces => [XPK_PARENS(XPK_TERMEXPR), XPK_BLOCK, XPK_BLOCK],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         my $condition = $args->[0]->op;
         my $consequent = op_scope( $args->[1]->op );
         my $alternative = op_scope( $args->[2]->op );

         $$outref = newCONDOP(0, $condition, $consequent, $alternative);

         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/cond"}++ }
   my @ret = map { cond($_) { "yes" } { "no" } } 0 .. 2;
   is( \@ret, [qw( no yes yes )], 'result of cond in map' );
}

done_testing;
