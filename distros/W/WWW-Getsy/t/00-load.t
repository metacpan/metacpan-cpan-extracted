#!/usr/bin/perl -w

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Getsy' ) || print "Bail out!";
}

diag( "Testing WWW::Getsy $WWW::Getsy::VERSION, Perl $], $^X" );
