#!/usr/bin/env perl

use strict;
use warnings;

use blib;

my $x = 7;
my @a = qw<ba na na>;

{
 use subs::auto;
 foo;             # Compile to "foo()"     instead of croaking
 foo $x;          # Compile to "foo($x)"   instead of "$x->foo"
 foo 1;           # Compile to "foo(1)"    instead of croaking
 foo 1, 2;        # Compile to "foo(1, 2)" instead of croaking
 foo(@a);         # Still ok
 foo->import;     # Compile to "foo()->import()"
 select STDERR;
 print foo 'wut'; # Compile to "print(foo('wut'))"
}

print "\n";

eval "bar"; # not defined, BOOM
warn 'died: ' . $@ if $@;

sub foo {
 my $s = @_ ? join ',', @_ : '(nothing)';
 warn "foo got $s\n";
 'strict';
}
