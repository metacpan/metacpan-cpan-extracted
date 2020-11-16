use strict;
use warnings;

use Test::More;
use Tk::GraphViz;

my @DATA = (
  [
    '{<port1> echo\ $\{hallo\}\ perl\\lib\ double\\\\l \| wc -l\l|true\l}',
    [
      [
        { 'port1' => 'echo\\ $\\{hallo\\}\\ perl\\lib\\ double\\\\l \\| wc -l\\l' },
        { '' => 'true\\l' }
      ],
    ],
  ],
  [
    '{<port1> echo\ hi\\l|wc -l\l|true\l}',
    [
      [
        { 'port1' => 'echo\\ hi\\l' },
        { '' => 'wc -l\\l' },
        { '' => 'true\\l' }
      ],
    ],
  ],
  [
    '<f0> |<f1> |<f2> |<f3> |<f4> |<f5> |<f6> | ',
    [
      { 'f0' => '' },
      { 'f1' => '' },
      { 'f2' => '' },
      { 'f3' => '' },
      { 'f4' => '' },
      { 'f5' => '' },
      { 'f6' => '' },
      { '' => ' ' },
    ],
  ],
  [
    '<port1> echo|{wc -l|{true}}',
    [
      { 'port1' => 'echo' },
      [
        { '' => 'wc -l' },
        [ { '' => 'true' } ],
      ],
    ],
  ],
);

plan tests => 2 * @DATA;

for my $d (@DATA) {
  my $got = eval { Tk::GraphViz::_parse($d->[0]) };
  is $@, '', "no error $d->[0]";
  is_deeply_dump($got, $d->[1], $d->[0]);
}

sub is_deeply_dump {
  my ($got, $expected, $label) = @_;
  is_deeply $got, $expected, $label or diag explain $got;
}
