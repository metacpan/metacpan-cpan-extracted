use strict;
use warnings;
use Test::Base;
use Text::Diff3;

plan tests => 1 * blocks;

sub testdiff3 {
    my($try) = @_;
    return Text::Diff3::merge(eval $try);
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
{
  'body' => [qw(a B C D e f)],
  'conflict' => 0
}

=== 0, 1 change
--- input
[qw(a b c d e f)],
[qw(a B C D E f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a b c d e f)],
  'conflict' => 0
}

=== 1 change
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a b C D E f)],
--- expected
{
  'body' => [qw(a b C D E f)],
  'conflict' => 0
}

=== conflict same length
--- input
[qw(a w x y z f)],
[qw(a B C D E f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [
    'a',
    '<<<<<<<',
    'w',
    'x',
    'y',
    'z',
    '|||||||',
    'B',
    'C',
    'D',
    'E',
    '=======',
    'b',
    'c',
    'd',
    'e',
    '>>>>>>>',
    'f'
  ],
  'conflict' => 1
}

=== conflict diffent length
--- input
[qw(a w x y z f)],
[qw(a B C D E f)],
[qw(a b c d f)],
--- expected
{
  'body' => [
    'a',
    '<<<<<<<',
    'w',
    'x',
    'y',
    'z',
    '|||||||',
    'B',
    'C',
    'D',
    'E',
    '=======',
    'b',
    'c',
    'd',
    '>>>>>>>',
    'f'
  ],
  'conflict' => 1
}

=== 0 delete at top
--- input
[qw(c d e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(c d e f)],
  'conflict' => 0
}

=== 0 delete at last
--- input
[qw(a b c d)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a b c d)],
  'conflict' => 0
}

=== 0 twice delete
--- input
[qw(a c e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a c e f)],
  'conflict' => 0
}

=== 1 delete at top
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(c d e f)],
--- expected
{
  'body' => [qw(c d e f)],
  'conflict' => 0
}

=== 1 delete at last
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a b c d)],
--- expected
{
  'body' => [qw(a b c d)],
  'conflict' => 0
}

=== 1 twice delete
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a c e f)],
--- expected
{
  'body' => [qw(a c e f)],
  'conflict' => 0
}

=== 0 append at top
--- input
[qw(A A a b c d e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(A A a b c d e f)],
  'conflict' => 0
}

=== 0 append at last
--- input
[qw(a b c d e f G G)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a b c d e f G G)],
  'conflict' => 0
}

=== 0 twice append
--- input
[qw(a B B b c D D D d e f)],
[qw(a b c d e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a B B b c D D D d e f)],
  'conflict' => 0
}

=== 1 append at top
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(A A a b c d e f)],
--- expected
{
  'body' => [qw(A A a b c d e f)],
  'conflict' => 0
}

=== 1 append at last
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a b c d e f G G)],
--- expected
{
  'body' => [qw(a b c d e f G G)],
  'conflict' => 0
}

=== 1 twice append
--- input
[qw(a b c d e f)],
[qw(a b c d e f)],
[qw(a B B b c D D D d e f)],
--- expected
{
  'body' => [qw(a B B b c D D D d e f)],
  'conflict' => 0
}

=== 0, 1 append at top
--- input
[qw(a b c d e f)],
[qw(c d e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a b c d e f)],
  'conflict' => 0
}

=== 0, 1 append at last
--- input
[qw(a b c d e f)],
[qw(a b c d)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a b c d e f)],
  'conflict' => 0
}

=== 0, 1 twice append
--- input
[qw(a b c d e f)],
[qw(a c e f)],
[qw(a b c d e f)],
--- expected
{
  'body' => [qw(a b c d e f)],
  'conflict' => 0
}

=== combination
--- input
[qw(A A b c     f g h i j K l m n O p Q R s)],
[qw(a   b c d e f g h i j k l m n o p q r s)],
[qw(a   b c d   f       j K l M n o p 1 2 s t u)],
--- expected
{
  'body' => [
    qw(A A b c f j K l M n O p),
    '<<<<<<<',
    'Q',
    'R',
    '|||||||',
    'q',
    'r',
    '=======',
    '1',
    '2',
    '>>>>>>>',
    qw(s t u),
  ],
  'conflict' => 1
}

