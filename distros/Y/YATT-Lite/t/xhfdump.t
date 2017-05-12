#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::Test::TestUtil;
use Data::Dumper;

my $LOADER = 'YATT::Lite::XHF';
my $DUMPER = 'YATT::Lite::XHF::Dumper';

# undef
# 空文字列
# 空白入り文字列

# 入れ子
# 先頭/末尾の、空白/空行

my @tests
  = ([<<END, undef]
= #null
END
     , [<<END, 'foo']
- foo
END
     #
     , undef
     , [<<END, '' => 'bar']
- 
- bar
END
     , [<<END, undef, 'bar']
= #null
- bar
END
     , [<<END, foo => undef]
foo= #null
END
     , [<<END, '', undef]
- 
= #null
END
     , [<<END, undef, undef]
= #null
= #null
END
     #
     , [<<END, foo => 'bar', baz => 'qux']
foo: bar
baz: qux
END

     , [<<END, foo => "bar\nbaz\n"]
foo:
 bar
 baz
END

     , [<<END, foo => "bar\n\n", baz => "qux\n\n\n"]
foo:
 bar
 
baz:
 qux
 
 
END

     , [<<END, "foo bar" => 'baz']
- foo bar
- baz
END

     , [<<END, [qw(foo bar baz)]]
[
- foo
- bar
- baz
]
END

     , [<<END, [foo => undef, 'bar'], baz => undef]
[
- foo
= #null
- bar
]
baz= #null
END
     , [<<END, foo => {bar => 'baz', hoe => 1}, bar => [1..3]]
foo{
bar: baz
hoe: 1
}
bar[
- 1
- 2
- 3
]
END

     , [<<END, [bar => 1, baz => 2], [1..3], [1..3, [4..7]]]
[
bar: 1
baz: 2
]
[
- 1
- 2
- 3
]
[
1: 2
3[
4: 5
6: 7
]
]
END

     , [<<END, {foo => 'bar', '' => 'baz', bang => undef}]
{
- 
- baz
bang= #null
foo: bar
}
END
    );

my @dumponly =
  (
   [<<END, foo => [bless([foo => 1, bar => 2], "ARRAY"), "baz"]]
foo[
[
foo: 1
bar: 2
]
- baz
]
END

  );

plan tests => 2 + 3*grep(defined $_, @tests) + @dumponly;

use_ok($LOADER);
use_ok($DUMPER);

sub breakpoint {}

foreach my $data (@tests) {
  unless (defined $data) {
    breakpoint();
    next;
  }

  my ($exp, @data) = @$data;
  my $title = join(", ", Data::Dumper->new(\@data)->Terse(1)->Indent(0)->Dump);
  eq_or_diff my $got = $DUMPER->dump_xhf(@data)."\n", $exp, "dump: $title";
  is_deeply [$LOADER->new(string => $got)->read], \@data, "read: $title";
  is_deeply [$LOADER->new(string => $exp)->read], \@data, "read_exp: $title";
}

foreach my $data (@dumponly) {
  my ($exp, @data) = @$data;
  my $title = join(", ", Data::Dumper->new(\@data)->Terse(1)->Indent(0)->Dump);
  eq_or_diff my $got = $DUMPER->dump_xhf(@data)."\n", $exp, "dump: $title";
}

{
  package ARRAY;
  use overload qw("" stringify);
  sub stringify {
    "faked_string";
  }
}

done_testing();
