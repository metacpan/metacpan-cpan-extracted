#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use Data::Dumper;

my $CLASS = 'YATT::Lite::XHF';

sub parser {
  my $input = shift;
  $CLASS->new(string => $input, @_);
}
sub test_parser ($$;$) {
  my ($result, $struct, $theme) = @_;
  is_deeply $result, $struct
    , join " ", grep {defined} $theme
      , Data::Dumper->new([$struct])->Terse(1)->Indent(0)->Dump;
}
sub test_error {
  my ($input, $wanterr, $theme) = @_;
  my $err = do {
    local $@;
    eval { $CLASS->new(string => $input)->read };
    $@;
  };
  like $err, $wanterr, $theme;
}

sub read_times {
  my ($num, $input, @opts) = @_;
  my $parser = parser($input, @opts);
  my @result;
  while ($num-- > 0) {
    push @result, [$parser->read];
  }
  \@result;
}
require_ok($CLASS);

{
  test_parser [parser("")->read], [];
  test_parser [do {my $p = parser(""); ([$p->read], [$p->read])}]
  , [[], []];
  test_parser [do {my $p = parser("foo: bar"); ([$p->read], [$p->read])}]
  , [[foo => "bar"], []];
  test_parser [do {my $p = parser("foo: bar"); (scalar $p->read, scalar $p->read)}]
  , [{foo => "bar"}, undef];
  test_parser [do {my $p = parser("foo: bar\n\n"); ([$p->read], [$p->read])}]
  , [[foo => "bar"], []];
  test_parser [do {my $p = parser("foo: bar\n\n"); (scalar $p->read, scalar $p->read)}]
  , [{foo => "bar"}, undef];

  test_parser [do {my $p = parser("- foo\n\n- bar"); ([$p->read], [$p->read])}]
  , [["foo"], ["bar"]];

  test_parser [parser(<<END)->read]
foo: 1
bar: 2
baz: 3
END
    , [foo => 1, bar => 2, baz => 3];

  test_parser [parser(<<END)->read]
- foo
- bar
= #undef
- baz
END
    , [qw(foo bar), undef, 'baz'];

  test_parser [parser(<<END)->read]
# -*- mode: xhf; coding: utf-8 -*-
foo: after comment
bar: 2
baz: before next chunk.
qux= #null

next: not read.
END
    , [foo => "after comment", bar => 2, baz => "before next chunk."
      , qux => undef];

  test_parser [parser(<<END)->read]
foo: 1
bar: 
 2
baz:
 3
END
    , [foo => 1, bar => 2, baz => "3\n"];

  test_parser [parser(<<END)->read]
foo: 1
bar/bar: 2
baz.html: 3
bang-4: 4
END
    , ["foo" => 1, "bar/bar" => 2, "baz.html" => 3, "bang-4" => 4];

  test_parser read_times(2, <<END)
foo:   1   
bar:
 
 2
baz: 
 3


x: 1
y: 2

END
    , [[foo => 1, bar => "\n2\n", baz => 3], [x => 1, y => 2]];

  test_parser [parser(<<END, filename_for_error => __FILE__, first_lineno => __LINE__+1)->read]
foo: 1
bar{
x: 2.1
y: 2.2
}
baz: 3
END
    , [foo => 1, bar => {x => 2.1, y => 2.2}, baz => 3];

  test_parser [parser(<<END)->read]
{
foo: 1
bar: 2
}
END
    , [{foo => 1, bar => 2}];

  test_parser [parser(<<END)->read]
YATT_CONFIG[
special_entities[
- HTML
]
]
END
    , [YATT_CONFIG => [special_entities => ['HTML']]];

  test_parser [parser(<<END)->read]
stash{
user{
login: foo
}
}
END
    , [stash => {user => {login => 'foo'}}];

  test_parser [parser(<<END)->read]
{
foo: 1
bar: 2
- ba z
= #null
}
{
- 
= #null
}
[
= #null
- baz
- bang
]
END
    , [{foo => 1, bar => 2, 'ba z' => undef}
       , {'' => undef}
       , [undef, 'baz', 'bang']];

  test_parser [parser(<<END)->read]
{
- foo bar
- baz
qux: quux
}
END
    , [{"foo bar" => "baz", qux => "quux"}];


  test_parser [parser(<<END)->read]
foo: 1
bar[
- 2.1
, 2.2
- 2.3
]
baz: 3
END
    , [foo => 1, bar => [2.1, 2.2, 2.3], baz => 3];

  test_parser [parser(<<END)->read]
foo: 1
bar[
- 2.1
{
hoe:
 2.1.1
moe:   2.1.2
}
- 2.3
]
baz: 3
END
    , [foo => 1
       , bar => [2.1, {hoe => "2.1.1\n", moe => "2.1.2"}, 2.3]
       , baz => 3];

  test_parser [parser(<<END)->read]
#foo
#bar
foo: 1
bar: 
 2
# baz (needs space)
baz:
 3
END
    , [foo => 1, bar => 2, baz => "3\n"];

  test_parser [parser(<<END)->read]
chklst[]: 1
chklst[]: 2
chklst[]: 5
END
    , ['chklst[]' => 1, 'chklst[]' => 2, 'chklst[]' => 5];

  test_error <<END, qr/Missing close '\]'/, "missing close ]";
foo[
- x
- y
END

  test_error <<END, qr/Missing close '\}'/, "missing close }";
foo{
- x
- y
END

  test_error <<END, qr/paren mismatch. '\[' (?:\(line \d+\) )?is closed by '\}'/, "Mismatching [} ";
foo[
- x
- y
}
END

  test_error <<END, qr/paren mismatch. '\{' (?:\(line \d+\) )?is closed by '\]'/, "Mismatching {]";
foo{
- x
- y
]
END

  test_error <<END, qr/Field close '\]' (?:\(line \d+\) )?without open!/, "close without open";
- x
- y
]
END

  test_error <<END, qr/Field close '\}' (?:\(line \d+\) )?without open!/, "close without open";
- x
- y
}
END

}

done_testing();
