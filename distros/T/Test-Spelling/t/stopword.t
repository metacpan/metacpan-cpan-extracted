use Test::Tester;
use Test::More;
use Test::Spelling;

BEGIN {
    if (!has_working_spellchecker()) {
        plan skip_all => "no working spellchecker found";
    }
}

check_test(sub { pod_file_spelling_ok('t/corpus/stopword.pm', 'stopword pod file') }, {
    ok   => 0,
    name => 'stopword pod file',
    diag => "Errors:\n    Xzaue",
});

add_stopwords('xzaue');

check_test(sub { pod_file_spelling_ok('t/corpus/stopword.pm', 'stopword pod file') }, {
    ok   => 1,
    name => 'stopword pod file',
});

done_testing;


