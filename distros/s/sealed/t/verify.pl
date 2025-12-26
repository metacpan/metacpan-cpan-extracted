#!/usr/bin/env -S perl -Ilib -Iblib/arch
use POSIX 'dup2';
#dup2 fileno(STDERR), fileno(STDOUT); # something's up with Perl::Types
POSIX::dup2 fileno(STDERR), fileno(STDOUT);
use Test::More tests => 7;
use v5.38;
use strict;
use warnings;
use Benchmark ':all';

our ($x, $z);
$x = bless {}, "Foo";
$z = Foo->can("foo");
sub method {$x->foo}
sub class  {Foo->foo}
sub anon   {$z->($x)}
sub bar { 2 } # middle level of class heirarchy
sub reentrant;

BEGIN {
  package Foo;
  use base 'sealed';
  sub foo { shift }
  sub bar    { 1 } # lowest level of class heirarchy
  my $n;
  sub _foo :Sealed { my main $x = shift; $n++ ? $x->bar : $x->reentrant }
}
sub func   {Foo::foo($x)}

BEGIN {our @ISA=qw/Foo/}


use constant label => __PACKAGE__;
my label $y; #sealed src filter transforms this into: my label $y = label;

sub sealed :Sealed {
  $y->foo();
}

use sealed 'verify';
use types;
use class;

sub also_sealed :Sealed (label $a, integer $b, string $c="HOLA", integer $d//=3, integer $e||=4) {
  if ($a) {
    my Benchmark $bench;
    my $inner = $a;
    return sub :Sealed (label $z) {
      my Foo $b = $a;
      $inner->foo($b->bar($inner->bar, $inner, $bench->new));
      $a = $inner;
      $a->foo;
      $a->bar;
    };
  }
  $a->bar();
}

sub reentrant :Sealed (__PACKAGE__ $b) { local our @Q=1; my $c = $b->_foo; }

ok(bless({})->reentrant()==2);

my %tests = (
    func => \&func,
    method => \&method,
    sealed => \&sealed,
    class => \&class,
    anon => \&anon,
);

cmpthese 20_000_000, \%tests;

ok(1);

use constant LOOPS => 3;

sub method2 {
  my $obj = bless {};
  for (1..LOOPS) {
    $obj->foo;
    $obj->bar;
    $obj->reentrant;
  }
}

sub sealed2 :Sealed {
  my main $obj = bless {}; # sealed-src-filter
  for (1..LOOPS) {
    $obj->foo;
    $obj->bar;
    $obj->reentrant;
  }
}

cmpthese 1_000_000, {
  method => \&method2,
  sealed => \&sealed2,
};

ok(1);

{
  package Bar;
  BEGIN {our @ISA=qw/main/}
  sub bar { 3 } # top-level of class hierarchy
  my $z = bless {};
  eval {$z->also_sealed(-1)->($z)}; # virtual method lookup verboten
  warn $@;
  main::ok (length($@) > 0);
}

eval {also_sealed($x,-1)->($x)}; # x is a Foo-typed lexical, and a Foo-blessed obj
warn $@;
ok (length($@) > 0);

eval {also_sealed(bless({}), -1)->($x)};
warn $@;
ok (length($@) > 0);

eval {also_sealed(bless({}),"foo")->($x)};
warn $@;
ok (length($@) > 0);
