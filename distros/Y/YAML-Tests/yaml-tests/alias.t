use t::TestYAMLTests tests => 5;

my ($a, $b) = Load(<<'...');
---
- &one [ a, b, c]
- foo: *one
--- &1
foo: &2 [*2, *1]
...

is "$a->[0]", "$a->[1]{'foo'}",
   'Loading an alias works';
is "$b->{'foo'}", "$b->{'foo'}[0]",
   'Another alias load test';
is "$b", "$b->{'foo'}[1]",
   'Another alias load test';

my $value = { xxx => 'yyy' };
my $array = [$value, 'hello', $value];
is Dump($array), <<'...', 'Duplicate node has anchor/alias';
---
- &1
  xxx: yyy
- hello
- *1
...

my $list = [];
push @$list, $list;
push @$list, $array;

is Dump($list), <<'...', 'Dump of multiple and circular aliases';
--- &1
- *1
- - &2
    xxx: yyy
  - hello
  - *2
...
