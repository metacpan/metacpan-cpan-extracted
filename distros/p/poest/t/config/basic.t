#!/usr/bin/perl
# $Id: basic.t,v 1.1 2003/03/12 20:42:39 cwest Exp $
use strict;
$^W = 1;

use Test::More qw[no_plan];
use FindBin;
use lib qw[lib ../lib];

BEGIN {
	use_ok 'POEST::Config';
}

my $config = POEST::Config->new(
	hostname => 'localhost',
	port     => 2525,
);
isa_ok $config, 'POEST::Config';

can_ok $config, 'new';
can_ok $config, 'get';
can_ok $config, 'set';
can_ok $config, 'config';

my $hostname = $config->get( 'hostname' );
is $hostname->{hostname}, 'localhost', 'get( hostname )';

$config->set( hostname => 'foobar' );
my $newhost = $config->get( 'hostname' );
is $newhost->{hostname}, 'foobar', 'set( hostname )';

my $conf = $config->config;
is $conf->{hostname}, 'foobar', 'config->{hostname}';
is $conf->{port}, '2525', 'config->{port}';
