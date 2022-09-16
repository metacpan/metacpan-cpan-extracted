use strict;
use warnings;
use FindBin;

use lib $FindBin::Bin.'/../bin';
require 'testrail-report';

use Test::More 'tests' => 17;
use Capture::Tiny qw{capture_merged};

use lib $FindBin::Bin.'/lib';
use Test::LWP::UserAgent::TestRailMock;

my @args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project}, "CRUSH ALL HUMANS", '--run', "SEND T-1000 INFILTRATION UNITS BACK IN TIME", qw{ t/test_multiple_files.tap});
my ($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with multiple files");
my $matches = () = $out =~ m/Reporting result of case/ig;
is($matches,2,"Attempts to upload multiple times");

#Test version, case-ok
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run TestingSuite --version 1.0.14  t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with subtests (case-ok mode)");
$matches = () = $out =~ m/Reporting result of case/ig;
is($matches,1,"version can be uploaded");

#Test plans/configs
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run}, "Executing the great plan", qw{--plan GosPlan --config testConfig  t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with plans");
$matches = () = $out =~ m/Reporting result of case.*OK/ig;
is($matches,1,"Attempts to to plans work");

#Test that spawn works
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run TestingSuite2 --testsuite_id 9  t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with spawn");
$matches = () = $out =~ m/Reporting result of case.*OK/ig;
is($matches,1,"Attempts to spawn work: testsuite_id");

#Test that spawn works w/sections
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run TestingSuite2 --testsuite}, "HAMBURGER-IZE HUMANITY", qw{ --section}, "CARBON LIQUEFACTION", qw{ t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with spawn");
$matches = () = $out =~ m/with specified sections/ig;
is($matches,1,"Attempts to spawn work: testsuite name");

#Test that the autoclose option works
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run FinalRun --plan FinalPlan --config testConfig --autoclose  t/fake.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK when doing autoclose");
like($out,qr/closing plan/i,"Run closure reported to user");

#Test that the max_tries option works
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run FinalRun --plan FinalPlan --config testConfig --max_tries 2 t/no_such_test.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK ");
like($out,qr/re-trying request/i,"Re-try attepmt reported to user");

#Test that help works
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-report';
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('args' => \@args)};
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

#Make sure that the binary itself processes args correctly
$out = `$^X $0 --help`;
like($out,qr/encoding of arguments/i,"Appears we can run binary successfully");
