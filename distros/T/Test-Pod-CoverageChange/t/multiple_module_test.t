use strict;
use warnings;

use Dir::Self;
use lib __DIR__ . '/..';
use Test::More;
use Test::Builder::Tester;
use Module::Path 'module_path';

use Test::Pod::CoverageChange;
use t::Nopod;
use t::CorrectPod;
use t::PodSyntaxError;
use t::PartiallyCoveredPod;

# Initializing variables
my $test_module_path       = ['t/CorrectPod.pm', 't/Nopod.pm', 't/PartiallyCoveredPod.pm'];
my $main_module_path       = module_path('Test::Pod::CoverageChange');

subtest 'every modules will check in the process' => sub {
    test_out(
        "not ok 1 # TODO & SKIP You have 0.00% POD coverage for the module 't::Nopod'.",
        "not ok 2 # TODO & SKIP You have 33.33% POD coverage for the module 't::PartiallyCoveredPod'.",
        "not ok 3 - Your last changes increased the number of naked subs in the t::PartiallyCoveredPod package from 1 to 2. Please add pod for your new subs.",
        "ok 4 - Pod coverage on t::CorrectPod",
        "ok 5 - Pod structure is OK in the file t/CorrectPod.pm.",
        "not ok 6 # TODO & SKIP There is no POD in the file t/Nopod.pm.",
        "ok 7 - Pod structure is OK in the file t/PartiallyCoveredPod.pm.",
    );
    test_diag(
        "  Failed test 'Your last changes increased the number of naked subs in the t::PartiallyCoveredPod package from 1 to 2. Please add pod for your new subs.'",
        "  at $main_module_path line 143."
    );

    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path,
        allowed_naked_packages => {'t::Nopod' => 3, 't::PartiallyCoveredPod' => 1});
    test_test("Handles multiple modules at once");
    done_testing;
};

subtest 'modules order does not matter' => sub {
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => [$test_module_path->@[2,1,0]],
        allowed_naked_packages => {'t::Nopod' => 3, 't::PartiallyCoveredPod' => 2});
    done_testing;
};

done_testing;
