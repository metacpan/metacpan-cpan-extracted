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
   newSVOP newUNOP newBINOP
);

use constant {
   # Pull out some OP_* constants
   OP_CONST => opcode("const"),
   OP_ADD   => opcode("add"),
   OP_INT   => opcode("int"),
   OP_RAND  => opcode("rand"),
};

# const
BEGIN {
   register_xs_parse_keyword( hello =>
      permit_hintkey => "main/hello",
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $$outref = newSVOP(OP_CONST, 0, "Hello, world");
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/hello"}++ }
   my $val = hello;
   is( $val, "Hello, world", '$val contains constant' );
}

# expressions
BEGIN {
   register_xs_parse_keyword( d6 =>
      permit_hintkey => "main/d6",
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         # int(rand(6)) + 1
         $$outref = newBINOP(OP_ADD, 0,
            newUNOP(OP_INT, 0,
               newUNOP(OP_RAND, 0,
                  newSVOP(OP_CONST, 0, 6))),
            newSVOP(OP_CONST, 0, 1));
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}
{
   BEGIN { $^H{"main/d6"}++ }
   my $roll = d6;
      ok( ($roll == int $roll and $roll >= 1 and $roll <= 6),
         'd6 yields some number' );
}

done_testing;
