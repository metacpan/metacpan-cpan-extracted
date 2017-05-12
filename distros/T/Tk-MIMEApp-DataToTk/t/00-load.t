#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tk::MIMEApp::DataToTk' ) || print "Bail out!\n";
}

diag( "Testing Tk::MIMEApp::DataToTk $Tk::MIMEApp::DataToTk::VERSION, Perl $], $^X" );
