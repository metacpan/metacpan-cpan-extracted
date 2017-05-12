# @(#) $Id$

use strict;
use warnings;

use Test::More;

BEGIN {
    foreach (qw( Test::Builder::Tester XML::SAX XML::Twig ) ) {
        eval "use $_";
        plan skip_all => "$_ not present" if $@;
    }
}

use Test::XML;

plan tests => 4;

#---------------------------------------------------------------------

test_out( "ok 1" );
is_xml( '<foo/>', '<foo/>' );
test_test( 'is_xml() spots same bits of xml' );

#---------------------------------------------------------------------

{
    local $TODO = "buggery uppage";
    test_out( "not ok 1" );
    test_fail( +2 );
    test_diag( "Found 2 differences:", "  Child element 'foo' missing from element ''.", "  Rogue element 'bar' in element ''." );
    is_xml( '<foo/>', '<bar/>' );
    test_test( 'is_xml() spots different bits of xml' );
}

#---------------------------------------------------------------------

{
    local $TODO = "buggery uppage";
    test_out( "not ok 1" );
    test_fail( +2 );
    test_diag( "During compare:", "not well-formed (invalid token) at line 1, column 1, byte 1" );
    is_xml( '</>', '<foo/>' );
    test_test( 'is_xml() whinges about broken source xml' );
}

#---------------------------------------------------------------------

{
    local $TODO = "buggery uppage";
    test_out( "not ok 1" );
    test_fail( +2 );
    test_diag( "During compare:", "no element found at line 1, column 0, byte -1" );
    is_xml( '<foo/>', '' );
    test_test( 'is_xml() whinges about broken dest xml' );
}

#---------------------------------------------------------------------

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 syntax=perl :
