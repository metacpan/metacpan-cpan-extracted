use strict;
use warnings;

use Test::More "tests" => 32;
use Test::Fatal;
use FindBin;
use Capture::Tiny qw{capture_merged};

use lib $FindBin::Bin.'/../bin';
require 'testrail-tests';

use lib $FindBin::Bin.'/lib';
use Test::LWP::UserAgent::TestRailMock;

#check plan mode
my @args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{-m t --config testConfig  --no-recurse});
my ($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, no recurse");

#check no-match
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--no-match t --config testConfig });
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running plan mode, no match");
chomp $out;
unlike($out,qr/skipall\.test/,"Omits test correctly in plan mode, recurse, no-match");
unlike($out,qr/NOT SO SEARED AFTER ARR/,"Omits non-file test correctly in plan mode, recurse, no-match");
like($out,qr/faker\.test/,"Omits non-file test correctly in plan mode, recurse, no-match");

#check no-match, no recurse
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--no-match t --config testConfig  --no-recurse});
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running plan mode, no match, no recurse");
chomp $out;
unlike($out,qr/skipall\.test/,"Omits test correctly in plan mode, no recurse, no-match");
unlike($out,qr/NOT SO SEARED AFTER ARR/,"Omits non-file test correctly in plan mode, no recurse, no-match");
like($out,qr/faker\.test/,"Omits non-file test correctly in plan mode, no recurse, no-match");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--config testConfig -m t });
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, recurse");

#check non plan mode
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite -m t  --no-recurse});
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running no plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, no recurse");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite -m t });
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running no plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, recurse");

#Negative case, filtering by config
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{-m t  --config testPlatform1});
isnt(exception {TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)}, undef, "Exit code not OK when passing invalid configs for plan");

#check assignedto filters
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{ --config testConfig --assignedto teodesian});
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK when filtering by assignment");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by assignment");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{ --config testConfig --assignedto billy});
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 255, "Exit code OK when filtering by assignment");
chomp $out;
is($out,"","Gets no tests correctly when filtering by wrong assignment");

#check status filters
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{-m t  --config testConfig --status passed});
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK when filtering by status");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by status");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{ --config testConfig --status failed});
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 255, "Exit code OK when filtering by status");
chomp $out;
is($out,"","Gets no tests correctly when filtering by wrong status");

#Verify no-match returns non path
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite });
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running no plan mode, no-match");
chomp $out;
like($out,qr/\nskipall\.test$/,"Gets test correctly in no plan mode, no-match");

#Verify no-match returns non path
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite --orphans t });
($out,$code) = TestRail::Bin::Tests::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running no plan mode, no recurse");
chomp $out;
like($out,qr/NOT SO SEARED AFTER ARR/,"Gets test correctly in orphan mode");

#Verify no-match returns non path
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-tests';
($out,(undef,$code)) = capture_merged {TestRail::Bin::Tests::run('args' => \@args)};
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

#Make sure that the binary itself processes args correctly
$out = `$^X $0 --help`;
like($out,qr/encoding of arguments/i,"Appears we can run binary successfully");
