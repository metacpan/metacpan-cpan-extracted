
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Text/TFIDF/Ngram.pm',
    't/00-compile.t',
    't/01-methods.t',
    't/1.txt',
    't/2.txt',
    't/3.txt',
    't/4.txt',
    't/5.txt'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
