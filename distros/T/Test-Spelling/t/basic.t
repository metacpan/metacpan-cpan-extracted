use Test::Tester;
use Test::More;
use Test::Spelling;

BEGIN {
    if (!has_working_spellchecker()) {
        plan skip_all => "no working spellchecker found";
    }
}

check_test(sub { pod_file_spelling_ok('t/corpus/no-pod.pm', 'no pod has no errors') }, {
    ok   => 1,
    name => 'no pod has no errors',
});

check_test(sub { pod_file_spelling_ok('t/corpus/good-pod.pm', 'good pod has no errors') }, {
    ok   => 1,
    name => 'good pod has no errors',
});

check_test(sub { pod_file_spelling_ok('t/corpus/bad-pod.pm', 'bad pod has no errors') }, {
    ok   => 0,
    name => 'bad pod has no errors',
    diag => "Errors:\n    incorectly",
});

done_testing;

