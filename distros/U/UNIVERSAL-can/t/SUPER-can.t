use UNIVERSAL::can;

use strict;
use warnings;


package MyClass;

my @caller;

sub can {
    push @caller, caller;
}

sub test {
    my ($invocant, $method) = @_;
    $invocant->SUPER::can($method);
}


package main;

use Test::More tests => 2;

my @warning;
local $SIG{__WARN__} = sub { push @warning, @_ };

MyClass->test("foo");

is_deeply(\@warning, [],
    "CLASS->SUPER::can(METHOD) does not give a warning");

is_deeply(\@caller, [],
    "CLASS->SUPER::can(METHOD) does not invoke CLASS->can(METHOD)");
