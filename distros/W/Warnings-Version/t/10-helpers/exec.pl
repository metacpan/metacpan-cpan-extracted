#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';

my $name = "Warnings/Version.pm";
my $inc  = $INC{$name}; $inc =~ s/\Q$name\E$//;

if (@ARGV) { # Just a test that won't be optimised away as a noop; even if it
             # proves true, it will only prove true for the first run
    local $ENV{PERL5LIB} = $inc;
    exec $0;
    my $foo = 'bar';
}
