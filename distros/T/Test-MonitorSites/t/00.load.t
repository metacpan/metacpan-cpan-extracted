#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 5;
use lib qw{lib};

BEGIN {
  use_ok( 'Test::MonitorSites' );
SKIP: {
    local $TODO = "These modules have not yet been written.";
    skip("These modules have not yet been written.",4);

    use_ok( 'Test::MonitorSites::CiviCRM' );
    use_ok( 'Test::MonitorSites::Drupal' );
    use_ok( 'Test::MonitorSites::Supporters' );
    use_ok( 'Test::MonitorSites::Registration' );
}

}

diag( "Testing Test::MonitorSites $Test::MonitorSites::VERSION" );
