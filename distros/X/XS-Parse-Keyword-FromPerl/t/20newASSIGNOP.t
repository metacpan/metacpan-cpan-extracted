#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   KEYWORD_PLUGIN_EXPR
   register_xs_parse_keyword
);
use Optree::Generate qw(
   opcode
   newASSIGNOP newGVOP newSVOP newUNOP
);

use constant {
   # Pull out some OP_* constants
   OP_CONST => opcode("const"),
   OP_ADD   => opcode("add"),
   OP_GV    => opcode("gv"),
   OP_RV2SV => opcode("rv2sv"),
};

# addten
BEGIN {
   register_xs_parse_keyword( addten =>
      permit_hintkey => "main/addten",
      pieces => [],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $$outref = newASSIGNOP(0,
            newUNOP(OP_RV2SV, 0, newGVOP(OP_GV, 0, \*_)),
            OP_ADD,
            newSVOP(OP_CONST, 0, 10)
         );

         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/addten"}++ }
   $_ = 5;
   addten;
   is( $_, 15, '$_ has 10 added' );
}

done_testing;
