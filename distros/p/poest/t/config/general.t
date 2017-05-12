#!/usr/bin/perl
# $Id: general.t,v 1.1 2003/03/12 20:42:39 cwest Exp $
use strict;
$^W = 1;

use Test::More qw[no_plan];
use FindBin;
use lib qw[lib ../lib];

BEGIN {
	use_ok 'POEST::Config::General';
}

my $configfile = "$FindBin::Bin/../../etc/poest.config.general";
ok -e $configfile, 'Config file exists';
ok -f $configfile, 'Config file is a file';
ok -r $configfile, 'Config file is readable';
ok -s $configfile, 'Config file is not empty';

my $config = POEST::Config::General->new( ConfigFile => $configfile );
isa_ok $config, 'POEST::Config::General';

can_ok $config, 'new';
can_ok $config, 'get';
can_ok $config, 'config';

my $hostname = $config->get( 'hostname' );
is $hostname->{hostname}, 'localhost', 'get( hostname )';

my $conf = $config->config;
is $conf->{hostname}, 'localhost', 'config->{hostname}';
is $conf->{port}, '2525', 'config->{port}';
