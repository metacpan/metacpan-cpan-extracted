#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use WebService::OpenSky::Test qw( set_response );

delete $ENV{OPENSKY_USERNAME};
delete $ENV{OPENSKY_PASSWORD};
my $opensky = WebService::OpenSky->new( testing => 0, config => 'no_such_file' );
is $opensky->config, 'no_such_file', 'config file is set';

throws_ok { $opensky->_config_data } qr/file 'no_such_file' does not exist/,
  'fetching config file when it does not exist should throw an exception';

$opensky = WebService::OpenSky->new( testing => 1, config => 'no_such_file' );
is $opensky->config, 'no_such_file', 'config file is set';

eq_or_diff $opensky->_config_data, {},
  "A non-existent config file should return an empty hashref if we're testing";

done_testing;
