#!/usr/bin/env perl
#
# $Id$
#
use Test::More;

BEGIN {
  eval {require Net::Traceroute::PurePerl;};

  if ( $@ ) {
    plan skip_all => 'Net::Traceroute::PurePerl not installed'
  } elsif ( $< != 0 ) {
    plan skip_all => 'Net::Traceroute::PurePerl only works as root'
  }else{
    plan tests => 2
  }
}

use_ok("Traceroute::Similar");
my $ts = Traceroute::Similar->new('backend' => 'Net::Traceroute::PurePerl');

# it is not possible to predict possible ip configurations
SKIP: {
    skip 'traceroutes cannot be tested and are different on every host', 1, if(!defined $ENV{TEST_AUTHOR});
    my $expected_routes = [ { 'name' => '', 'addr' => '127.0.0.1' } ];
    my $local_route = $ts->_get_route_for_host('localhost');
    is_deeply($expected_routes, $local_route, 'route for localhost');
}