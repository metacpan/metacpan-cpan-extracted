# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-BBB-API.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings; 

my ($host, $salt);

use Test::More;
use Module::Build;

my $build = Module::Build->current;

my $run_network = $build->notes('run_network');
my $bbb_host = $build->notes('bbb_host');
my $bbb_salt = $build->notes('bbb_salt');

plan 'skip_all' => "User request to not run network tests" unless $run_network; 

plan skip_all
    => "Please pass both a host and its salt key to run this test $bbb_salt."
	    unless ($bbb_host && $bbb_salt); 

plan tests => 2;

use_ok('WWW::BBB::API');

my $bbb             = new WWW::BBB::API(salt => $bbb_salt, host => $bbb_host);
my $obj				= $bbb->getMeetings();
ok($obj->{returncode} eq "SUCCESS","Get Meetings list");

