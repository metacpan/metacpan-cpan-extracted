use strict;
use warnings;
use utf8;
use Test::Base::Less;

filters {
    test_trim => [qw/trim/],
    test_lines => [qw/lines/],
};

my (@blocks) = blocks();
is($blocks[0]->test_trim, $blocks[0]->expected_trim, 'trim');

is_deeply([$blocks[1]->test_lines], ["a\n","b\n","c\n",], 'lines');

done_testing;
__END__

=== trim
--- test_trim

xxx


--- expected_trim
xxx
--- test_
=== lines
--- test_lines
a
b
c
