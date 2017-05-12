#!/usr/bin/perl -Iblib/lib/

use strict;
use warnings;

use Test::More tests => 5;

BEGIN
{
    use_ok( "TinyDNS::Reader",         "We could load the module" );
    use_ok( "TinyDNS::Reader::Merged", "We could load the module" );
    use_ok( "TinyDNS::Record",         "We could load the module" );
}

ok( $TinyDNS::Reader::VERSION, "Version defined" );
ok( $TinyDNS::Reader::VERSION =~ /^([0-9\.]+)/, "Version is numeric" );
