#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers 'run_perl';

plan tests => 11 + 5 * 2 + 5 * 3;

{
 my $desc = 'peephole optimization of conditionals';
 my $x;

 local $@;
 my $code = eval <<' TESTCASE';
  no autovivification;
  sub {
   if ($_[0]) {
    my $z = $x->{a};
    return 1;
   } elsif ($_[1] || $_[2]) {
    my $z = $x->{b};
    return 2;
   } elsif ($_[3] && $_[4]) {
    my $z = $x->{c};
    return 3;
   } elsif ($_[5] ? $_[6] : 0) {
    my $z = $x->{d};
    return 4;
   } else {
    my $z = $x->{e};
    return 5;
   }
   return 0;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->(1);
 is_deeply $x, undef, "$desc : first branch did not autovivify";
 is      $ret, 1,     "$desc : first branch returned 1";

 $ret = $code->(0, 1);
 is_deeply $x, undef, "$desc : second branch did not autovivify";
 is      $ret, 2,     "$desc : second branch returned 2";

 $ret = $code->(0, 0, 0, 1, 1);
 is_deeply $x, undef, "$desc : third branch did not autovivify";
 is      $ret, 3,     "$desc : third branch returned 3";

 $ret = $code->(0, 0, 0, 0, 0, 1, 1);
 is_deeply $x, undef, "$desc : fourth branch did not autovivify";
 is      $ret, 4,     "$desc : fourth branch returned 4";

 $ret = $code->();
 is_deeply $x, undef, "$desc : fifth branch did not autovivify";
 is      $ret, 5,     "$desc : fifth branch returned 5";
}

{
 my $desc = 'peephole optimization of C-style loops';
 my $x;

 local $@;
 my $code = eval <<' TESTCASE';
  no autovivification;
  sub {
   my $ret = 0;
   for (
     my ($z, $i) = ($x->[100], 0)
    ;
     do { my $z = $x->[200]; $i < 4 }
    ;
     do { my $z = $x->[300]; ++$i }
   ) {
    my $z = $x->[$i];
    $ret += $i;
   }
   return $ret;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->();
 is_deeply $x, undef, "$desc did not autovivify";
 is      $ret, 6,     "$desc returned 0+1+2+3";
}

{
 my $desc = 'peephole optimization of range loops';
 my $x;

 local $@;
 my $code = eval <<' TESTCASE';
  no autovivification;
  sub {
   my $ret = 0;
   for ((do { my $z = $x->[100]; 0 }) .. (do { my $z = $x->[200]; 3 })) {
    my $z = $x->[$_];
    $ret += $_;
   }
   return $ret;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->();
 is_deeply $x, undef, "$desc did not autovivify";
 is      $ret, 6,     "$desc returned 0+1+2+3";
}

{
 my $base_desc = 'peephole optimization of infinite';
 my %infinite_tests = (
  "$base_desc for loops (RT #64435)" => <<'  TESTCASE',
   no autovivification;
   my $ret = 0;
   for (;;) {
    ++$ret;
    exit $ret;
   }
   exit $ret;
  TESTCASE
  "$base_desc while loops" => <<'  TESTCASE',
   no autovivification;
   my $ret = 0;
   while (1) {
    ++$ret;
    exit $ret;
   }
   exit $ret;
  TESTCASE
  "$base_desc postfix while (RT #99458)" => <<'  TESTCASE',
   no autovivification;
   my $ret = 0;
   ++$ret && exit $ret while 1;
   exit $ret;
  TESTCASE
  "$base_desc until loops" => <<'  TESTCASE',
   no autovivification;
   my $ret = 0;
   until (0) {
    ++$ret;
    exit $ret;
   }
   exit $ret;
  TESTCASE
  "$base_desc postfix until" => <<'  TESTCASE',
   no autovivification;
   my $ret = 0;
   ++$ret && exit $ret until 0;
   exit $ret;
  TESTCASE
 );

 for my $desc (keys %infinite_tests) {
  my $code = $infinite_tests{$desc};
  my $ret  = run_perl $code;
  SKIP: {
   skip RUN_PERL_FAILED() => 2 unless defined $ret;
   my $stat = $ret & 255;
   $ret   >>= 8;
   is $stat, 0, "$desc testcase did not crash";
   is $ret,  1, "$desc compiled fine";
  }
 }
}

{
 my $desc = 'peephole optimization of map';
 my $x;

 local $@;
 my $code = eval <<' TESTCASE';
  no autovivification;
  sub {
   join ':', map {
    my $z = $x->[$_];
    "x${_}y"
   } @_
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->(1, 2);
 is_deeply $x, undef,     "$desc did not autovivify";
 is      $ret, 'x1y:x2y', "$desc returned the right value";
}

{
 my $desc = 'peephole optimization of grep';
 my $x;

 local $@;
 my $code = eval <<' TESTCASE';
  no autovivification;
  sub {
   join ':', grep {
    my $z = $x->[$_];
    $_ <= 3
   } @_
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->(1 .. 5);
 is_deeply $x, undef,   "$desc did not autovivify";
 is      $ret, '1:2:3', "$desc returned the right value";
}

{
 my $desc = 'peephole optimization of substitutions';
 my $x;

 local $@;
 my $code = eval <<' TESTCASE';
  no autovivification;
  sub {
   my $str = $_[0];
   $str =~ s{
    ([0-9])
   }{
    my $z = $x->[$1];
    9 - $1;
   }xge;
   $str;
  }
 TESTCASE
 is $@, '', "$desc compiled fine";

 my $ret = $code->('0123456789');
 is_deeply $x, undef,        "$desc did not autovivify";
 is      $ret, '9876543210', "$desc returned the right value";
}
