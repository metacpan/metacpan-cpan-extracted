# @(#) $Id$

use strict;
use warnings;

use Test::More tests => 9;
use Test::XML;

eval { is_xml() };
like( $@, qr/^usage: /, 'is_xml() no args failure' );

eval { is_xml( '<foo/>' ) };
like( $@, qr/^usage: /, 'is_xml() 1 args failure' );

is_xml( '<foo />', '<foo></foo>', 'first usage example' );

#---------------------------------------------------------------------

eval { isnt_xml() };
like( $@, qr/^usage: /, 'isnt_xml() no args failure' );

eval { isnt_xml( '<foo/>' ) };
like( $@, qr/^usage: /, 'isnt_xml() 1 args failure' );

isnt_xml( '<foo />', '<bar />', 'isnt_xml() works' );

#---------------------------------------------------------------------

eval { is_well_formed_xml() };
like( $@, qr/^usage: /, 'is_well_formed_xml() no args failure' );

is_well_formed_xml( '<foo />', 'first usage example' );

is_good_xml( '<foo />', 'first usage example' );

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 syntax=perl :
