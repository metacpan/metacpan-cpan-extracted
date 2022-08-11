use strict;
use warnings;

use Dir::Self;
use lib __DIR__ . '/..';
use Test::More;
use Test::Builder::Tester;
use Module::Path 'module_path';

use Test::Pod::CoverageChange;
use t::Nopod;

# Initializing variables
my $test_module            = "t::Nopod";
my $test_module_path       = 't/Nopod.pm';
my $current_test_file_path = 't/no_pod.t';
my $main_module_path       = module_path('Test::Pod::CoverageChange');

subtest 'Module with no pod, unexpected' => sub {
    test_out("not ok 1 - Pod coverage on $test_module", "not ok 2 # TODO & SKIP There is no POD in the file $test_module_path.");
    test_diag("  Failed test 'Pod coverage on $test_module'", "  at $main_module_path line 149.", "$test_module: couldn't find pod");
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path);
    test_test("Handles files with no pod");
    done_testing;
};

subtest 'Can expect module naked sub' => sub {
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path, allowed_naked_packages => {'t::Nopod' => 3});
    done_testing;
};

subtest 'Test will fail if we increased the number of naked subs' => sub {
    test_out(
        "not ok 1 # TODO & SKIP You have 0.00% POD coverage for the module '$test_module'.",
        "not ok 2 - Your last changes increased the number of naked subs in the $test_module package from 2 to 3. Please add pod for your new subs.",
        "not ok 3 # TODO & SKIP There is no POD in the file $test_module_path."
    );
    test_diag("  Failed test 'Your last changes increased the number of naked subs in the $test_module package from 2 to 3. Please add pod for your new subs.'",
        "  at $main_module_path line 143.");
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path,
        allowed_naked_packages => {'t::Nopod' => 2});
    test_test("Handles files with no pod");
    done_testing;
};

subtest 'this is another subtest' => sub {
    test_out(
        "not ok 1 # TODO & SKIP You have 0.00% POD coverage for the module '$test_module'.",
        "not ok 2 - Your last changes decreased the number of naked subs in the $test_module package.",
        "# Change the $test_module => 3 in the $current_test_file_path file please.",
        "not ok 3 # TODO & SKIP There is no POD in the file $test_module_path."
    );
    test_diag(
        "  Failed test 'Your last changes decreased the number of naked subs in the $test_module package.",
        "Change the $test_module => 3 in the $current_test_file_path file please.'",
        "  at $main_module_path line 143."
    );
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path,
        allowed_naked_packages => {'t::Nopod' => 4});
    test_test("Handles files with no pod");
    done_testing;
};

subtest 'Ignore some tests' => sub {
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path, ignored_packages => ['t::Nopod']);
    pass('Even bad Pods can be ignored successfully.');
};

done_testing;
