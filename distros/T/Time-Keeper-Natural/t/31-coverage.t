#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use File::Temp qw(tempdir);
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Words;

my $N = 'Time::Keeper::Natural';
my $W = 'Time::Keeper::Natural::Words';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# Coverage follows the files.
{
    is($N->coverage('en'), 'words', 'en has a table');
    is($N->coverage('en-GB'), 'words', 'en-GB reads it');
    is($N->coverage('en-AU'), 'words', 'so does en-AU');
    is($N->coverage('fr'), 'words', 'fr has one');
    is($N->coverage('pt-PT'), 'words', 'pt-PT reads pt\'s');
    is($N->coverage('sw'), 'data', 'sw has none');
    is($N->coverage('tr'), 'data', 'nor tr');
    is($N->new->coverage('en'), 'words', 'on a parser too');
    dies_like(sub { $N->coverage('xx-YY') }, qr/^\Q$N->coverage: there is no locale 'xx-YY'\E/, 'a locale that is not there');
    is_deeply([$N->locales], [qw(ar bn de el en es fr hi it ja ko nl pt ru th zh)], 'the locales with a table of their own');
    is_deeply([$W->chain('zh-Hant-HK')], [qw(zh-Hant-HK zh-Hant zh)], 'the chain');
    my $w = $W->for('en-GB');
    isa_ok($w, $W);
    is($w->code, 'en', 'the file read is en');
    like($w->file, qr{/words/en\.txt\z}, 'and where it is');
    is($w, $W->for('en-GB'), 'read once');
    is($w->starts('end of last month', 'end_of'), 'end of', 'starts');
    is($w->starts('the end of the year', 'end_of'), 'the end of', 'the longest phrase');
    is($w->starts('ending soon', 'end_of'), undef, 'a word is not a prefix');
    is_deeply([$w->phrases('on')], ['on'], 'phrases');
    is_deeply([$w->keys], [qw(after and at before end_of last of on range skip start_of weekend)], 'every key named, the empty one too');
    is_deeply([$w->phrases('and')], [], 'and is empty: English\'s list pattern has it');
    cmp_ok(scalar($w->tests), '>=', 5, 'the test lines');
    is($W->for('sw'), undef, 'no table is undef');
}

# A table may not take a CLDR word.
{
    my $dir = tempdir(CLEANUP => 1);
    my $bad = "$dir/en.txt";
    open my $fh, '>:encoding(UTF-8)', $bad or die $!;
    print $fh "end_of\tend of|tomorrow\n";
    close $fh;
    dies_like(sub { $W->from_file($bad, 'en') }, qr/'tomorrow' is a CLDR word in en \(day 1\); a table may not take one/, 'a phrase that is a relative word');
    open $fh, '>:encoding(UTF-8)', $bad or die $!;
    print $fh "at\tnoon\n";
    close $fh;
    dies_like(sub { $W->from_file($bad, 'en') }, qr/'noon' is a CLDR word in en \(period noon\)/, 'or a day period');
    open $fh, '>:encoding(UTF-8)', $bad or die $!;
    print $fh "colour\tred\n";
    close $fh;
    dies_like(sub { $W->from_file($bad, 'en') }, qr/'colour' is not a key; the keys are after, and, at, before, end_of, last, of, on, range, skip, start_of, weekend/, 'a key that is not one');
    open $fh, '>:encoding(UTF-8)', $bad or die $!;
    print $fh "# a comment\nend_of\tclose of\n\nskip\n# test: close of last month => x\n";
    close $fh;
    my $w = $W->from_file($bad, 'en');
    is_deeply([$w->phrases('end_of')], ['close of'], 'a good file reads');
    is_deeply([$w->tests], [['close of last month', 'x']], 'with its test line');
}

done_testing;
