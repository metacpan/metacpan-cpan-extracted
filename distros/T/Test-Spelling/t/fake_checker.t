use Test::Tester;
use Test::More;
use Test::Spelling;

# Use perl to fake a working spell checker
# so we can test module portability even where no spell checker is present.

my $spell_cmd = $^X . q< -e "print STDERR q[FOOBAR]">;
set_spell_cmd($spell_cmd);

is eval { pod_file_spelling_ok('t/corpus/bad-pod.pm', 'expect STDERR'); 1 },
    undef, 'spell check died';

like $@,
    qr/Unable to find a working spellchecker:\n    Unable to run '\Q$spell_cmd\E': spellchecker had errors: FOOBAR/,
    'died with text found on STDERR';


my $badword = 'Xzaue';
$spell_cmd = $^X . qq< -ane "print grep { /$badword/i } \@F">;
set_spell_cmd($spell_cmd);

check_test(sub { pod_file_spelling_ok('t/corpus/good-pod.pm', 'no mistakes') }, {
    ok   => 1,
    name => 'no mistakes',
});

check_test(sub { pod_file_spelling_ok('t/corpus/stopword.pm', 'found misspelled word') }, {
    ok   => 0,
    name => 'found misspelled word',
    diag => "Errors:\n    $badword",
});

add_stopwords(lc $badword);

check_test(sub { pod_file_spelling_ok('t/corpus/stopword.pm', 'used stopword') }, {
    ok   => 1,
    name => 'used stopword',
});

done_testing;
