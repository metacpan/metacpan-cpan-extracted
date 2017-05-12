use strict;
use warnings;
use Test::Magic tests => 123;
use lib '../lib';
use Whatever;

diag "Whatever $Whatever::VERSION";

{no warnings 'redefine';
sub is ($) {
    @_ = "@_" if ref $_[0] eq 'Whatever';
    goto &Test::Magic::is
}}

test 'basic',
  is ref(&*) eq 'Whatever',
  is &* == qr/^Whatever.+/,
  is &*->(5) == 5,
  is &*->('a') eq 'a',
  map {is &*->() == $_} 3;

test 'too many args', do {
  my $error_ok = qr/^too many arguments for Whatever.*whatever\.t/s;
  do {eval {&*->(1..2)};      is $@ == $error_ok},
  do {eval {(&*.&*)->(1..3)}; is $@ == $error_ok},
};

my $lhs = &* . 3;

my $rhs = ">$*";

test 'single lhs',
  is ref($lhs) eq 'Whatever',
  is $lhs->(2) == 23,
  map {is $lhs->() == 43} 4;

test 'single rhs',
  is ref($rhs) eq 'Whatever',
  is $rhs->('x') eq '>x',
  map {is $rhs->() eq '>5'} 5;

test 'double',
  is ref($lhs . 8) eq 'Whatever',
  is +($lhs . 8)->('asdf') eq 'asdf38';

sub plus2 {$_[0] + 2}
sub mymap {my $code = shift; map $code->(), @_}

test 'sub',
  is +(3 + plus2 &*)->(5) == 10,
  is join(' ' => mymap &* * 5, 0 .. 10) eq '0 5 10 15 20 25 30 35 40 45 50';

my $greet = "hello, $*!";

test 'compose',
  is $greet->('world') eq 'hello, world!',
  is "hello, $*!"->('world') eq 'hello, world!';

my $ss = &* . &*;

test 'complex compose',
  is +($ss->('a') . 'c')->('b') eq 'abc',
  is +('c' . $ss->('a'))->('b') eq 'cab',
  is +('x' . $ss->('a') . 'c')->('b') eq 'xabc';

my $future;
my $delorean = $future . (' ' . &*);

test 'lazy arg',
  do {$future = 1.21;    is $delorean->('gigawatts!') eq '1.21 gigawatts!'},
  do {$future = 'world'; is $greet->($delorean)->('from the future')
                            eq 'hello, world from the future!'},
  do {$future = &*;      is $delorean->('folks')->("that's all")
                            eq "that's all folks"};

{package Array;
    sub new  {shift; bless [@_]}
    sub map  {new Array map  $_[1]() => @{$_[0]}}
    sub grep {new Array grep $_[1]() => @{$_[0]}}
    sub join {join $_[1]||'' => @{$_[0]}}
    sub str  {$_[0]->join(' ')}
}

my $array = new Array 1 .. 10;

test 'method',
  is $array->map(&_ * 2)->str                   eq '2 4 6 8 10 12 14 16 18 20',
  is $array->map(&_ * 2)->map(&_ + 1)->str      eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map(&_ * 2 + 1)->str               eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map(&_ * 2 + 1)->grep(&* % 5)->str eq '3 7 9 11 13 17 19 21';

test 'method call', do {
  my $str = &*->str;
  my $add1 = &*->map(&* + 1);
  my $add1evens = &*->map(&* + 1)->grep(not &* % 2);
  is $str->($array)                  eq '1 2 3 4 5 6 7 8 9 10',
  is $str->($add1->($array))         eq '2 3 4 5 6 7 8 9 10 11',
  is $str->($add1evens->($array))    eq '2 4 6 8 10',
  is &*->str->($array)               eq '1 2 3 4 5 6 7 8 9 10',
  is &*->grep(&_ % 2)->str->($array) eq '1 3 5 7 9',
  is &*->grep(&_ % 2)->($array)->str eq '1 3 5 7 9',
  is $*->new(1 .. 5)->str->('Array') eq '1 2 3 4 5',
};

test 'method call inner', do {
  my $obj = new Array map {new Array 1 .. $_} 1 .. 4;
  is $obj->map(&*->join)->join(' ') eq '1 12 123 1234',
  is $*->map('['.&*->join.']')->join->($obj) eq '[1][12][123][1234]',
  is +('['.$*->map($*->join('-'))->join('][').']')->($obj) eq '[1][1-2][1-2-3][1-2-3-4]',
};

for (&*) {
    test 'aliased $_',
      is +('a'.$_.'c'.$_.'e')->('b')('d') eq 'abcde';

    test 'method aliased $_',
      is $array->map($_ * 2)->str                   eq '2 4 6 8 10 12 14 16 18 20',
      is $array->map($_ * 2)->map($_ + 1)->str      eq '3 5 7 9 11 13 15 17 19 21',
      is $array->map($_ * 2 + 1)->str               eq '3 5 7 9 11 13 15 17 19 21',
      is $array->map($_ * 2 + 1)->grep($_ % 5)->str eq '3 7 9 11 13 17 19 21';
}

test 'a$*c$*e',
  is "a$*c$*e"->('b')('d') eq 'abcde';

test 'method $*',
  is $array->map($* * 2)->str                   eq '2 4 6 8 10 12 14 16 18 20',
  is $array->map($* * 2)->map($* + 1)->str      eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map($* * 2 + 1)->str               eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map($* * 2 + 1)->grep($* % 5)->str eq '3 7 9 11 13 17 19 21';

test 'sin($*)',
  is +(5 * sin $*)->(0.5) == 5 * sin 0.5;

test 'atan2',
  is atan2(&*, 0)->(1)     == atan2(1, 0),
  is atan2(1, &*)->(0)     == atan2(1, 0),
  is atan2(&*, &*)->(1, 1) == atan2(1, 1),
  do {
    my $xatan2 = &* * atan2 &*, &*;
    is $xatan2->(4, 1, 1) == $xatan2->(2, 1, 0)
  };


my $not = not &*;
test 'not',
  is $not->(1) eq ! 1,
  is $not->(0) == ! 0;

test '&* x &*', do {
  my $rep  = &* x &*;
  my $line = $rep->('-');
  my $hr = $line . "\n";
  is $line->(10)            eq '-' x 10,
  is $rep->($line->(10))(2) eq '-' x 20,
  is $rep->($line)(3)(10)   eq '-' x 30,
  is $hr->(20)              eq '-' x 20 . "\n",
};

use List::Util 'reduce';
our ($a, $b);

test 'chain', do {
  my $chain = reduce {$a . $b} map &*, 0 .. 8;
  my $link = $chain;
  is $chain->(1)(2)(3)(4)(5)(6)(7)(8)(9) eq 123456789,
  is $chain->(1..8)->(910) eq 12345678910,
  do {
      my $x = 9;
      $link = $link->($x--) while ref $link;
      is $link eq 987654321
  }
};

test 'join', do {
  my $join2   = &* . &*;
  my $join4   = $join2 . $join2;
  my $join8   = $join4 . $join4;
  my $join16  = $join8 . $join8;
  my $join16r = reduce {$a . $*} $*, 2 .. 16;
  is $join2  ->(1 .. 2)     eq 12,
  is $join4  ->(2)(4)(6)(8) eq 2468,
  is $join4  ->('a'..'d')   eq 'abcd',
  is $join16 ->(1 .. 16)    eq '12345678910111213141516',
  is $join16r->(1 .. 16)    eq '12345678910111213141516',
};

test 'join bind', do {
  my $join2   = &* .' '. &*;
  my $join4   = $join2->($join2)($join2);
  my $join8   = $join2->($join4, $join4);
  my $join16  = $join2->($join8)($join8);
  is $join2  ->(1 .. 2)     eq '1 2',
  is $join4  ->(2)(4)(6)(8) eq '2 4 6 8',
  is $join4  ->('a'..'d')   eq 'a b c d',
  is $join16 ->(1 .. 16)    eq '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16',
};

test 'inc', do {
  my $inc     = $* + 1;
  my $inc_2   = $inc * 2;
  my $inc_inc = $inc->($inc);
  is $inc->(5)     == 6,
  is $inc_2->(5)   == 12,
  is $inc_inc->(5) == 7,
};

test 'assign &*', do {
  (&*, my $x, &*, my $y) = 1 .. 4;
  is $x == 2,
  is $y == 4,
  is &*->(5) == 5,
};

SKIP: {
    test 'no assign $*', do {
      eval {
        ($*, my $x, $*, my $y) = 1 .. 4;
        ** = \do{&*};
        skip 'no assign $*: no readonly', 2
      };
      is $@ == qr/read.?only/,
      is $*->(5) == 5,
    }
}

test '$* ok',
  is eval {$*->(3)} == 3;

test 'array deref', do {
  my $first  = &*->[0];
  my $second = &*->[1];
  my $last   = &*->[-1];
  my $ntlast = &*->[-2];
  my $slice  = [@{&*}[1, 2]];
  my $slice2 = sub{\@_}->(@{&*}[3, 4]);
  my $array  = [1 .. 5];
  is $first ->($array) == 1,
  is $second->($array) == 2,
  is &*->[2]->($array) == 3,
  is $last  ->($array) == 5,
  is $ntlast->($array) == 4,
  is $slice ->[0]->($array) == 2,
  is $slice ->[1]->($array) == 3,
  is $slice2->[0]->($array) == 4,
  is $slice2->[1]->($array) == 5,
};

test 'array assign', do {
  my $first = &*->[0];
  my $last  = &*->[-1];
  my $array = [1 .. 5];
  $first->($array)  = 8;
  $last->($array)   = 9;
  &*->[2]->($array) = 0;
  is $$array[0] == 8,
  is $$array[4] == 9,
  is $$array[2] == 0,
  is "@$array" eq '8 2 0 4 9',
};

test 'array double', do {
  my $first = &*->[0];
  my $double = $*->[1][1];
  my $double_app = $*->[1]($*->[1]);
  my $array = [1, [2, 3], 4];
  is &*->[0]   ($array) == 1,
  is &*->[1][0]($array) == 2,
  is &*->[1][1]($array) == 3,
  is &*->[2]   ($array) == 4,
  is $first->($array) == 1,
  is $double->($array) == 3,
  is $double_app->($array) == 3,
};

test 'array autoviv', do {
  my $x;
  &*->[1]($x) = 4;
  is $$x[1] == 4
};

test 'array double autoviv', do {
  my $first = &*->[0];
  my $double = $first->($first);
  my $array;
  $double->($array) = 5;
  &*->[1][0]($array) = 8;
  is $$array[0][0] == 5,
  is $$array[1][0] == 8,
};

test 'array deep', do {
  &*->[0][0][0][0][0](my $array) = 3;
  is $$array[0][0][0][0][0] == 3
};

test 'hash deref', do {
  my $bob = &*->{bob};
  my $alice = &*->{alice};
  my $hash = {bob => 1, alice => 2};
  is $bob->($hash) == 1,
  is $alice->($hash) == 2,
  is &*->{alice}->($hash) == 2,
};

test 'hash assign', do {
  my $bob = &*->{bob};
  my $hash = {bob => 1, alice => 2};
  $bob->($hash) = 5;
  &*->{eve}->($hash) = 10;
  is $bob->($hash)  == 5,
  is $hash->{alice} == 2,
  is $hash->{eve}   == 10,
};

test 'hash double', do {
  my $bob_has   = &*->{bob}{has};
  my $alice     = &*->{alice};
  my $has       = &*->{has};
  my $alice_has = $has->($alice);
  my $hash = {bob => {has => 5}, alice => {has => 7}};
  is $bob_has->($hash) == 5,
  is $hash->$bob_has == 5,
  is $hash->$alice_has == 7,
  is $hash->$alice->$has == 7,
  is &*->{alice}{has}($hash) == 7
};

test 'hash autoviv', do {
  my $x;
  &*->{bob}($x) = 4;
  is $$x{bob} == 4
};

test 'hash double autoviv', do {
  my $eve  = &*->{eve};
  my $has  = &*->{has};
  my $eve_has = $has->($eve);
  my $hash;
  $eve_has->($hash) = 12;
  &*->{bob}{has}($hash) = 8;
  is $$hash{eve}{has} == 12,
  is $$hash{bob}{has} == 8,
};

test 'hash deep', do {
  &*->{a}{b}{c}{d}(my $hash) = 12;
  is $$hash{a}{b}{c}{d} == 12
};

test 'array/hash deep', do {
  &*->[0]{a}[1][2]{b}{c}(my $data) = 42;
  is $$data[0]{a}[1][2]{b}{c} == 42
};

test 'array unsupported op', do {
    eval {push @{&*}, 5};
    is $@ == qr/^Whatever::ARRAY::PUSH unsupported/;
};

test 'hash unsupported op', do {
    eval {my @keys = keys %{&*}};
    is $@ == qr/^Whatever::HASH::FIRSTKEY unsupported/;
};
