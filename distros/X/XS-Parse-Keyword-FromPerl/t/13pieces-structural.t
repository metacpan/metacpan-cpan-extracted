#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   KEYWORD_PLUGIN_EXPR
   XPK_REPEATED XPK_PARENS XPK_IDENT
   register_xs_parse_keyword
);
use Optree::Generate qw(
   opcode
   newSVOP newFOROP newUNOP newLISTOP
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

# parens
BEGIN {
   register_xs_parse_keyword( parens =>
      permit_hintkey => "main/parens",
      pieces => [XPK_PARENS(XPK_IDENT)],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         my $name = $args->[0]->sv;

         $$outref = newSVOP(OP_CONST, 0, $name);
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/parens"}++ }
   my $ret = parens ( here );
   is( $ret, "here", 'identifier inside parens' );
}

done_testing;
