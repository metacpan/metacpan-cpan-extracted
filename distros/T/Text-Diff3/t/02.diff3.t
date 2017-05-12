use strict;
use warnings;
use Test::Base;
use Text::Diff3;

plan tests => 1 * blocks;

sub testdiff3 {
    my($try) = @_;
    return Text::Diff3::diff3(eval $try);
}

filters {
    input => [qw(testdiff3)],
    expected => [qw(eval)],
};

run_is_deeply 'input' => 'expected';

__END__

=== 0 change
--- input
[qw(a B C D e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
[[0, 2,4, 2,4, 2,4]]

=== 0, 1 change
--- input
[qw(a b c d e f)],
[qw(a B C D E f)],
[qw(a b c d e f)],
--- expected
[[2, 2,5, 2,5, 2,5]]

=== 1 change
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a b C D E f)],
--- expected
[[1, 3,5, 3,5, 3,5]]

=== conflict same length
--- input
[qw(a w x y z f)],
[qw(a B C D E f)],
[qw(a b c d e f)],
--- expected
[['A', 2,5, 2,5, 2,5]]

=== conflict different length
--- input
[qw(a w x y z f)],
[qw(a B C D E f)],
[qw(a b c d f)],
--- expected
[['A', 2,5, 2,4, 2,5]]

=== 0 delete at top
--- input
[qw(c d e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
[[0, 1,0, 1,2, 1,2]]

=== 0 delete at last
--- input
[qw(a b c d)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
[[0, 5,4, 5,6, 5,6]]

=== 0 twice delete
--- input
[qw(a c e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
[[0, 2,1, 2,2, 2,2], [0, 3,2, 4,4, 4,4]]

=== 1 delete at top
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(c d e f)],
--- expected
[[1, 1,2, 1,0, 1,2]]

=== 1 delete at last
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a b c d)],
--- expected
[[1, 5,6, 5,4, 5,6]]

=== 1 twice delete
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a c e f)],
--- expected
[[1, 2,2, 2,1, 2,2], [1, 4,4, 3,2, 4,4]]

=== 0 append at top
--- input
[qw(A A a b c d e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
[[0, 1,2, 1,0, 1,0]]

=== 0 append at last
--- input
[qw(a b c d e f G G)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
[[0, 7,8, 7,6, 7,6]]

=== 0 twice append
--- input
[qw(a B B b c D D D d e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
[[0, 2,3, 2,1, 2,1], [0, 6,8, 4,3, 4,3]]

=== 1 append at top
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(A A a b c d e f)],
--- expected
[[1, 1,0, 1,2, 1,0]]

=== 1 append at last
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a b c d e f G G)],
--- expected
[[1, 7,6, 7,8, 7,6]]

=== 1 twice append
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a B B b c D D D d e f)],
--- expected
[[1, 2,1, 2,3, 2,1], [1, 4,3, 6,8, 4,3]]

=== 0, 1 append at top
--- input
[qw(a b c d e f)],
[qw(c d e f)],
[qw(a b c d e f)],
--- expected
[[2, 1,2, 1,2, 1,0]]

=== 0, 1 append at last
--- input
[qw(a b c d e f)],
[qw(a b c d)],
[qw(a b c d e f)],
--- expected
[[2, 5,6, 5,6, 5,4]]

=== 0, 1 twice append
--- input
[qw(a b c d e f)],
[qw(a c e f)],
[qw(a b c d e f)],
--- expected
[[2, 2,2, 2,2, 2,1], [2, 4,4, 4,4, 3,2]]

=== combination
--- input
[qw(A A b c     f g h i j K l m n O p Q R s)],
[qw(a   b c d e f g h i j k l m n o p q r s)],
[qw(a   b c d   f       j K l M n o p 1 2 s t u)],
--- expected
[
    [0,    1, 2,  1, 1,  1, 1],
    ['A',  5, 4,  4, 4,  4, 5],
    [1,    6, 8,  6, 5,  7, 9],
    [2,   10,10,  7, 7, 11,11],
    [1,   12,12,  9, 9, 13,13],
    [0,   14,14, 11,11, 15,15],
    ['A', 16,17, 13,14, 17,18],
    [1,   19,18, 16,17, 20,19],
]

