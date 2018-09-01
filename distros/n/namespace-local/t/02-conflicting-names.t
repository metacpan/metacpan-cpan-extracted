#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Carp by hand was used to catch errors caused by wrong _ localisation
$SIG{__WARN__} = sub {
    print STDERR $_[0];
    foreach (my $i = 1; my @stack = caller $i; $i++) {
        print STDERR "\tat $stack[1]:$stack[2]\n";
    };
};

BEGIN {
    package Foo;
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(frobnicate);

    sub frobnicate { 42 };

    $INC{"Foo.pm"} = 1;
};

BEGIN {
    package Bar;
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(frobnicate);

    sub frobnicate { 137 };

    $INC{"Bar.pm"} = 1;
};

# now the test begins

use Foo;

sub first {
    frobnicate();
};

sub second {
    use namespace::local;
    use Bar;
    frobnicate();
};

sub third {
    frobnicate();
};

is first(), 42, "Before scope";
is second(), 137, "Within scope";
is third(), 42, "After scope";

done_testing;


