#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 1;

use Test::Mock::Net::SNMP;
use Net::SNMP;

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

my ($snmp, $error) = Net::SNMP->session(-hostname => 'localhost', -version => 'v2c');

ok($snmp->snmp_dispatcher(), 'snmp dispatcher returns true');
