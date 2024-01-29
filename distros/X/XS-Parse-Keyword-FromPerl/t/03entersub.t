#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   KEYWORD_PLUGIN_EXPR
   register_xs_parse_keyword
);
use Optree::Generate qw(
   newSVOP
   make_entersub_op

   OP_CONST
);

sub add1 { return $_[0] + 1 }

BEGIN {
   register_xs_parse_keyword( callbyop =>
      permit_hintkey => "main/call",
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $$outref = make_entersub_op(
            newSVOP(OP_CONST, 0, \&main::add1), [ newSVOP(OP_CONST, 0, 100) ]
         );
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/call"}++ }
   my $val = callbyop;
   is( $val, 101, 'result of callbyop' );
}

BEGIN {
   register_xs_parse_keyword( callbyref =>
      permit_hintkey => "main/call",
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $$outref = make_entersub_op(
            \&main::add1, [ newSVOP(OP_CONST, 0, 100) ]
         );
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/call"}++ }
   my $val = callbyref;
   is( $val, 101, 'result of callbyref' );
}

BEGIN {
   register_xs_parse_keyword( callbyname =>
      permit_hintkey => "main/call",
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $$outref = make_entersub_op(
            "main::add1", [ newSVOP(OP_CONST, 0, 100) ]
         );
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/call"}++ }
   my $val = callbyname;
   is( $val, 101, 'result of callbyname' );
}

done_testing;
