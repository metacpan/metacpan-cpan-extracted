use strict;
use warnings;

use Test::More "tests" => 5;
use FindBin;
use Capture::Tiny qw{capture_merged};

use lib $FindBin::Bin.'/../bin';
require 'testrail-lock';

use lib $FindBin::Bin.'/lib';
use Test::LWP::UserAgent::TestRailMock;

my @args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-lock';
my ($out,(undef,$code)) = capture_merged {TestRail::Bin::Lock::run('args' => \@args)};
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j },"CRUSH ALL HUMANS", '-r', "SEND T-1000 INFILTRATION UNITS BACK IN TIME", qw{--lockname locked});
($out,(undef,$code)) = capture_merged { TestRail::Bin::Lock::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args) };
is($code, 255, "Exit code bad when no case could be locked");
chomp $out;
like($out,qr/failed to lock case/i,"Output is as expected");

#Make sure that the binary itself processes args correctly
$out = `$^X $0 --help`;
like($out,qr/encoding of arguments/i,"Appears we can run binary successfully");
