#!perl -T

use strict;
use warnings;

use Test::More 0.98;
use Text::NonWideChar::Util qw(
    length_height);

subtest "length_height" => sub {
    is_deeply(length_height(""), [0, 0]);
    is_deeply(length_height("abc"), [3, 1]);
    is_deeply(length_height("abc\nde"), [3, 2]);
    is_deeply(length_height("ab\ncde\n"), [3, 3]);
};

DONE_TESTING:
done_testing();
