#!/usr/bin/env -S perl -Ilib -Iblib/arch
use Test::More tests => 4;
use v5.38;
use POSIX 'dup2';
dup2 fileno(STDERR), fileno(STDOUT);
use strict;
use warnings;
use Benchmark ':all';
our ($x, $z);
$x = bless {}, "Foo";
$z = Foo->can("foo");
sub method {$x->foo}
sub class  {Foo->foo}
sub anon   {$z->($x)}
sub bar { 2 }
sub reentrant;
BEGIN {
  package Foo;
  use base 'sealed';
  use sealed 'deparse';
  sub foo { shift }
  sub bar    { 1 }
  my $n;
  sub _foo :Sealed (main $x) { $n++ ? $x->bar : $x->reentrant }
}
sub func   {Foo::foo($x)}

BEGIN {our @ISA=qw/Foo/}

my main $y; #sealed src filter transforms this into: my main $y = 'main';

sub sealed :Sealed {
    $y->foo();
  }

use sealed 'verify';
sub also_sealed;
sub also_sealed :Sealed (__PACKAGE__ $a, Int $b, Str $c="HOLA", Int $d//=3, Int $e||=4) {
    if ($a) {
        my Benchmark $bench;
        my $inner = $a;
        return sub :Sealed {
            my Foo $b = $a;
            $inner->foo($b->bar($inner->bar, $inner, $bench->new));
            $a = $inner;
            $a->foo;
            $a->bar; # error!
          };
    }
    $a->bar();
}

use sealed;
sub reentrant :Sealed (__PACKAGE__ $b) { local our @Q=1; my $c = $b->_foo }

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

eval {also_sealed($x,-1)->()};
warn $@;
ok (length($@) > 0);
