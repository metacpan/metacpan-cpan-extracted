#!/usr/bin/perl -w

#
# $Id: Import.t,v 1.2 2004/04/02 12:01:49 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 6;
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
}

require_ok( 'Tk::Zinc' );
require_ok( 'Tk::Zinc::Debug' );
require_ok( 'Tk::Zinc::Trace' );
# require_ok( 'Tk::Zinc::TraceErrors' ); # incompatible with the previous one
# we do not test the previous, as it should be equivalent!
require_ok( 'Tk::Zinc::Graphics' );
require_ok( 'Tk::Zinc::Logo' );
require_ok( 'Tk::Zinc::Text' );
diag("############## all imports");
