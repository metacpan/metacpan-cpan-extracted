use strict;
use warnings;
use Test::Base;
use Text::Diff3;

plan tests => 1 * blocks;

sub testdiff {
    my($try) = @_;
    return Text::Diff3::diff(eval $try);
}

filters {
    input => [qw(testdiff)],
    expected => [qw(eval)],
};

run_is_deeply 'input' => 'expected';

__END__

=== 2,2c2,2; 4,3a4,5; 5,7d7,6
--- input
[qw(a b c     f g h i j)],
[qw(a B c d e f       j)],
--- expected
[[qw(c 2 2 2 2)], [qw(a 4 3 4 5)], [qw(d 5 7 7 6)]]

=== 1,0a1,1
--- input
[qw(a b c )],
[qw(A a b c)],
--- expected
[[qw(a 1 0 1 1)]]

=== 4,3a4,4
--- input
[qw(a b c)],
[qw(a b c D)],
--- expected
[[qw(a 4 3 4 4)]]

=== 1,1d1,0
--- input
[qw(A b c)],
[qw(b c)],
--- expected
[[qw(d 1 1 1 0)]]

=== 2,2d2,1
--- input
[qw(a B c)],
[qw(a c)],
--- expected
[[qw(d 2 2 2 1)]]

=== 3,3d3,2
--- input
[qw(a b C)],
[qw(a b)],
--- expected
[[qw(d 3 3 3 2)]]

