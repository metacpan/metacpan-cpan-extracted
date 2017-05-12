use strict;
use warnings;
use Test::More;
use Test::More::Unlike;

if ($ENV{AUTHOR_TEST}) {
    unlike 'abcdef', qr/cd/;
}

ok 1;

done_testing;
