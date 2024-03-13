#!/usr/bin/env -S perl -Ilib
use Test::More tests => 2;
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
BEGIN {
  package Foo;
  use base 'sealed';
  use sealed 'deparse';
  sub foo { shift }
  sub bar  { 1 }
  my $n;
  sub _foo :Sealed { my Foo $x = shift; $n++ ? $x->bar : $x->main::reentrant }
}
sub func   {Foo::foo($x)}

BEGIN {our @ISA=qw/Foo/}
use sealed 'deparse'; # invokes Lexical::Types->import into this namespace

# assigned to 'main' by UNIVERSAL::TYPESCALAR
my main $y;

sub sealed :Sealed {
    $y->foo();
}

sub also_sealed :Sealed {
    my main $a = shift;
    if ($a) {
        my Benchmark $bench;
        my $inner = $a;
        return sub :Sealed {
            my Foo $b = $a;
            $inner->foo($b->foo($inner->bar, $inner, $bench->cmpthese));
            $a = $inner;
            $a->foo;
            $b->bar;
        };
    }
    $a->bar();
}

sub reentrant :Sealed { my main $b = shift; local our @Q=1; my $c = $b->_foo }

ok($y->main::reentrant()==1);

my %tests = (
    func => \&func,
    method => \&method,
    sealed => \&sealed,
    class => \&class,
    anon => \&anon,
);

cmpthese 20_000_000, \%tests;

ok(1);
