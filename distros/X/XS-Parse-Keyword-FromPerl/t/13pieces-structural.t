#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   opcode
   KEYWORD_PLUGIN_EXPR
   XPK_REPEATED XPK_PARENSCOPE XPK_IDENT
   newSVOP newFOROP newUNOP newLISTOP
   register_xs_parse_keyword
);

use constant {
   # Pull out some OP_* constants
   OP_CONST => opcode("const"),
   OP_RV2AV => opcode("rv2av"),
   OP_SAY   => opcode("say"),
};

# repeated
BEGIN {
   register_xs_parse_keyword( repeated =>
      permit_hintkey => "main/repeated",
      pieces => [XPK_REPEATED(XPK_IDENT)],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         my $n = ( shift @$args )->i;
         my $names = join "|", map { $args->[$_]->sv } ( 0 .. $n-1 );

         $$outref = newSVOP(OP_CONST, 0, $names);
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/repeated"}++ }
   my $ret = repeated one two three;
   is( $ret, "one|two|three", 'repeated identifier name' );
}

# parenscope
BEGIN {
   register_xs_parse_keyword( parenscope =>
      permit_hintkey => "main/parenscope",
      pieces => [XPK_PARENSCOPE(XPK_IDENT)],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         my $name = $args->[0]->sv;

         $$outref = newSVOP(OP_CONST, 0, $name);
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/parenscope"}++ }
   my $ret = parenscope ( here );
   is( $ret, "here", 'identifier inside paren scope' );
}

done_testing;
