use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;
use Dir::Self;
use lib __DIR__ . '/..';
use Module::Path 'module_path';

use Test::Pod::CoverageChange;

my $test_module            = "t::CorrectPod";
my $test_module_path       = 't/CorrectPod.pm';
my $main_module_path       = module_path('Test::Pod::CoverageChange');
my $current_test_file_path = 't/correct_pod.t';

subtest 'Module with full pod coverage' => sub {
    test_out("ok 1 - Pod coverage on $test_module", "ok 2 - Pod structure is OK in the file $test_module_path.");
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path);
    test_test("Pods are completely correct.");
    done_testing;
};

subtest 'Module with full pod coverage should not be in the $allowed_naked_packages' => sub {
    my $allowed_naked_packages = {'t::CorrectPod' => 2};

    test_out(
        "not ok 1 - $test_module modules has 100% POD coverage. Please remove it from the $current_test_file_path file \$allowed_naked_packages variable to fix this error.",
        "ok 2 - Pod structure is OK in the file $test_module_path."
    );
    test_err(
        "#   Failed test '$test_module modules has 100% POD coverage. Please remove it from the $current_test_file_path file \$allowed_naked_packages variable to fix this error.'",
        "#   at $main_module_path line 143."
    );
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path, allowed_naked_packages => $allowed_naked_packages);
    test_test("Pods are completely correct.");
    done_testing;
};

subtest 'We can ignore Subs by passing their name as a ignore sub' => sub {
    my $test_module_path       = 't/PartiallyCoveredPod.pm';

    test_out(
        "ok 1 - Pod coverage on t::PartiallyCoveredPod",
        "ok 2 - Pod structure is OK in the file $test_module_path."
    );
    Test::Pod::CoverageChange::pod_coverage_syntax_ok(path => $test_module_path, ignored_subs => ['bar' , qr/baz/]);
    test_test("Handles files with no pod at all");
    done_testing;
};

done_testing;
