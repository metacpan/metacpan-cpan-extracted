#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use XS::Parse::Keyword::FromPerl qw(
   KEYWORD_PLUGIN_EXPR KEYWORD_PLUGIN_STMT
   XPK_IDENT XPK_IDENT_OPT XPK_PACKAGENAME XPK_COMMA XPK_VSTRING
   XPK_LEXVARNAME XPK_LEXVAR_SCALAR XPK_KEYWORD
   register_xs_parse_keyword
);
use Optree::Generate qw(
   opcode
   newSVOP
);

use constant {
   # Pull out some OP_* constants
   OP_CONST => opcode("const"),
};

# ident
BEGIN {
   register_xs_parse_keyword( ident =>
      permit_hintkey => "main/ident",
      pieces => [XPK_IDENT],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         is($args->[0]->sv, "name_here", '->sv of args[0]');

         $$outref = newSVOP(OP_CONST, 0, $args->[0]->sv);
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/ident"}++ }
   my $val = ident name_here;
   is( $val, "name_here", '$val contains ident name' );
}

# packagename comma vstring
my ( $packagename, $versionnumber );
BEGIN {
   register_xs_parse_keyword( pkgver =>
      permit_hintkey => "main/pkgver",
      pieces => [XPK_PACKAGENAME, XPK_COMMA, XPK_VSTRING],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $packagename = $args->[0]->sv;
         # XPK_COMMA does not add an arg
         $versionnumber = $args->[1]->sv;

         return KEYWORD_PLUGIN_STMT;
      },
   );
}

{
   BEGIN { $^H{"main/pkgver"}++ }
   pkgver Some::Package, v1.234;
   is( $packagename, "Some::Package", '->sv of XPK_PACKAGENAME arg' );
   is( $versionnumber, version->new(v1.234), '->sv of XPK_VSTRING arg' );
}

# optional ident
BEGIN {
   register_xs_parse_keyword( optident =>
      permit_hintkey => "main/optident",
      pieces => [XPK_IDENT_OPT],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $$outref = newSVOP(OP_CONST, 0, $args->[0]->has_sv);
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/optident"}++ }
   ok(  optident hello, 'optident true for identifier' );
   ok( !optident,       'optident false for non-identifier' );
}

# lexvarname
BEGIN {
   register_xs_parse_keyword( lexvarname =>
      permit_hintkey => "main/lexvarname",
      pieces => [XPK_LEXVARNAME(XPK_LEXVAR_SCALAR)],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         my $varname = $args->[0]->sv;

         $$outref = newSVOP(OP_CONST, 0, $varname);
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/lexvarname"}++ }
   my $name = lexvarname $avariable;
   is( $name, '$avariable', 'lexvarname' );
}

# keyword
BEGIN {
   register_xs_parse_keyword( keyword =>
      permit_hintkey => "main/keyword",
      pieces => [XPK_KEYWORD("here")],
      build => sub {
         my ( $outref, $args, $hookdata ) = @_;

         $$outref = newSVOP(OP_CONST, 0, 1);
         return KEYWORD_PLUGIN_EXPR;
      },
   );
}

{
   BEGIN { $^H{"main/keyword"}++ }
   my $ok = keyword here;
   ok( $ok, 'keyword' );
}

done_testing;
