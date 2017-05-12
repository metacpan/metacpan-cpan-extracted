#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
use lib "$FindBin::Bin/..";

#========================================
use YATT::Test qw(no_plan);

my $CLASS = 'YATT::XHF';

sub parse_by ($$$$) {
  my ($method, $title, $struct, $input) = @_;
  is_deeply scalar($CLASS->new(string => $input)->$method())
    , $struct, "$method $title";
}

require_ok($CLASS);

{
  my ($theme, $par);
  parse_by read_as_hash => $theme = 'depth=1, count=1'
    , {foo => 1, bar => 2, baz => "3\n"}
    , $par = <<END
foo: 1
bar: 
 2
baz:
 3
END
      ;

  is_deeply [$CLASS->new->tokenize($par)]
    , [[foo => 1, ':']
       , [bar => 2, ':']
       , [baz => "3\n", ':']], "tokenize $theme";

  parse_by read_as_hash => 'depth=1, count=1, escaped name and allowed syms.'
    , {"f o o" => 1, "bar/bar" => 2, "baz.html" => 3, "bang-4" => 4}
    , <<END
f%20o%20o: 1
bar/bar: 2
baz.html: 3
bang-4: 4
END
      ;

parse_by read_as_hashlist => 'depth=1, count=2'
    , [{foo => 1, bar => "\n2\n", baz => 3}, {x => 1, y => 2}]
    , <<END
foo:   1   
bar:
 
 2
baz: 
 3


x: 1
y: 2

END
      ;

  parse_by read_as_hash => $theme = 'hash->hash, count=1'
    , {foo => 1, bar => {x => 2.1, y => 2.2}, baz => 3}
    , $par = <<END
foo: 1
bar{
x: 2.1
y: 2.2
}
baz: 3
END
      ;

  is_deeply [$CLASS->new->tokenize($par)]
    , [[foo => 1, ':']
       , [bar => '', '{']
       , [x => 2.1, ':']
       , [y => 2.2, ':']
       , ['' => '' => '}']
       , [baz => 3, ':']], "tokenize $theme";

  parse_by read_as_hash => $theme = 'hash->array, count=1'
    , {foo => 1, bar => [2.1, 2.2, 2.3], baz => 3}
    , $par = <<END
foo: 1
bar[
: 2.1
, 2.2
- 2.3
]
baz: 3
END
      ;

  is_deeply [$CLASS->new->tokenize($par)]
    , [[foo => 1, ':']
       , [bar => '', '[']
       , ['' => 2.1, ':']
       , ['' => 2.2, ',']
       , ['' => 2.3, '-']
       , ['' => '' => ']']
       , [baz => 3, ':']], "tokenize $theme";

  parse_by read_as_hash => $theme = 'hash->array->hash, count=1'
    , {foo => 1, bar => [2.1, {hoe => "2.1.1\n", moe => "2.1.2"}, 2.3]
       , baz => 3}
    , $par = <<END
foo: 1
bar[
: 2.1
{
hoe:
 2.1.1
moe:   2.1.2
}
: 2.3
]
baz: 3
END
      ;

  is_deeply [$CLASS->new->tokenize($par)]
    , [[foo => 1, ':']
       , [bar => '', '[']
       , ['' => 2.1, ':']
       , ['' => '' => '{']
       , [hoe => "2.1.1\n", ':']
       , [moe => "2.1.2", ':']
       , ['' => '' => '}']
       , ['' => 2.3 => ':']
       , ['' => '' => ']']
       , [baz => 3, ':']], "tokenize $theme";

  parse_by read_as_hash => $theme = 'with comment, depth=1, count=1'
    , {foo => 1, bar => 2, baz => "3\n"}
    , $par = <<END
#foo
#bar
foo: 1
bar: 
 2
# baz (needs space)
baz:
 3
END
      ;

}
