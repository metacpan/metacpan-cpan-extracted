#!/usr/bin/perl -w

#
# $Id: Import.t,v 1.1 2003/09/17 14:33:09 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
        use Test::More qw(6);
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
}

require_ok( 'SVG::SVG2zinc::Conversions;' );
require_ok( 'Tk::Zinc::SVGExtension;' );
require_ok( 'SVG::SVG2zinc::Backend::Exec' );
require_ok( 'SVG::SVG2zinc::Backend::PerlScript' );
require_ok( 'SVG::SVG2zinc::Backend::PerlModule' );
require_ok( 'SVG::SVG2zinc::Backend::Print' );
diag("############## all imports");
