#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';
use File::Basename;

my $name  = 'Warnings/Version.pm';
my $inc   = $INC{$name}; $inc =~ s/\Q$name\E$//;
my $p5lib = $ENV{PERL5LIB}; defined $p5lib or $p5lib = '';
my $plib  = $ENV{PERLLIB};  defined $plib  or $plib  = '';
my @lib   = map { "-I$_" }
                split(/:/, $p5lib), split(/:/, $plib);

my $foo = $ENV{PATH} . kill 0;

system( $^X, '-T', "-I$inc", @lib, $0 ) or die "Taint check didn't kill us";
    # $^X is the currently running perl interpreter
    # when this is run with -T, it should die before calling system()
