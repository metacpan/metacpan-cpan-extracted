#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('WWW::Google::APIDiscovery')                || print "Bail out!\n";
    use_ok('WWW::Google::APIDiscovery::API')           || print "Bail out!\n";
    use_ok('WWW::Google::APIDiscovery::API::MetaData') || print "Bail out!\n";
}

diag( "Testing WWW::Google::APIDiscovery $WWW::Google::APIDiscovery::VERSION, Perl $], $^X" );
