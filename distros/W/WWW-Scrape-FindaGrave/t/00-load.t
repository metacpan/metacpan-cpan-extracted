#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('WWW::Scrape::FindaGrave') || print 'Bail out!';
}

require_ok('WWW::Scrape::FindaGrave') || print 'Bail out!';

diag( "Testing WWW::Scrape::FindaGrave $WWW::Scrape::FindaGrave::VERSION, Perl $], $^X" );
