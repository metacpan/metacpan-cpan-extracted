use strict;
use warnings;
use UNIVERSAL::which;
use Test::More;

{
    no warnings 'once';
    package Foo;
    my $code = bless sub { 1 } => 'Foo';
    *moge = \&Bar::muge;
    package Bar;
    *muge = $code;
}

plan tests => 3;
is(Bar->which('muge'), undef);
my @bar = Bar->which('muge');
is ($bar[1], '__ANON__');
is(Foo->which('moge'), 'Bar::muge');
