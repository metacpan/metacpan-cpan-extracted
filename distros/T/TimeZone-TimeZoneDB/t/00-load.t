#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('TimeZone::TimeZoneDB') || print 'Bail out!';
}

require_ok('TimeZone::TimeZoneDB') || print 'Bail out!';

diag("Testing TimeZone::TimeZoneDB $TimeZone::TimeZoneDB::VERSION, Perl $], $^X");
