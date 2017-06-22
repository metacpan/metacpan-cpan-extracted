#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

BEGIN {
    use_ok( 'WWW::Google::URLShortener'                              ) || print "Bail out!\n";
    use_ok( 'WWW::Google::URLShortener::Analytics'                   ) || print "Bail out!\n";
    use_ok( 'WWW::Google::URLShortener::Analytics::Result'           ) || print "Bail out!\n";
    use_ok( 'WWW::Google::URLShortener::Analytics::Result::Country'  ) || print "Bail out!\n";
    use_ok( 'WWW::Google::URLShortener::Analytics::Result::Browser'  ) || print "Bail out!\n";
    use_ok( 'WWW::Google::URLShortener::Analytics::Result::Referrer' ) || print "Bail out!\n";
    use_ok( 'WWW::Google::URLShortener::Analytics::Result::Platform' ) || print "Bail out!\n";
}

diag( "Testing WWW::Google::URLShortener $WWW::Google::URLShortener::VERSION, Perl $], $^X" );
