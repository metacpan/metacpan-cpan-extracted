#!/usr/bin/perl

use v5.14;
use warnings;

use Carp;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   KEYWORD_PLUGIN_EXPR
   XPK_LEXVAR XPK_LEXVAR_SCALAR
   register_xs_parse_keyword
);
use Optree::Generate qw(
   newBINOP newSVOP newPADxVOP

   OP_PADSV OP_CONST OP_SASSIGN
);

# zero
BEGIN {
   register_xs_parse_keyword( zero =>
      permit_hintkey => "main/zero",
      pieces => [XPK_LEXVAR(XPK_LEXVAR_SCALAR)],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         my $padix = $args->[0]->padix;

         $$outref = newBINOP(OP_SASSIGN, 0,
            newSVOP(OP_CONST, 0, 0),
            newPADxVOP(OP_PADSV, 0, $padix)
         );

         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/zero"}++ }
   my $x = 123;
   zero $x;
   is( $x, 0, 'zero sets a var to 0' );
}

done_testing;
