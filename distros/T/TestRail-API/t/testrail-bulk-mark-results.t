use strict;
use warnings;

use Test::More "tests" => 5;
use FindBin;
use Capture::Tiny qw{capture_merged};

use lib $FindBin::Bin.'/../bin';
require 'testrail-bulk-mark-results';

use lib $FindBin::Bin.'/lib';
use Test::LWP::UserAgent::TestRailMock;

#check plan mode
my @args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j },"CRUSH ALL HUMANS", '-r', "SEND T-1000 INFILTRATION UNITS BACK IN TIME", 'blocked', "Build was bad.");
my ($out,$code) = TestRail::Bin::BulkMarkResults::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running against normal run");
chomp $out;
like($out,qr/set the status of 1 cases to blocked/,"Sets test correctly in single run mode");

@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-bulk-mark-results';
($out,(undef,$code)) = capture_merged {TestRail::Bin::BulkMarkResults::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

#Make sure that the binary itself processes args correctly
$out = `$^X $0 --help`;
like($out,qr/encoding of arguments/i,"Appears we can run binary successfully");

#TODO more thorough testing
