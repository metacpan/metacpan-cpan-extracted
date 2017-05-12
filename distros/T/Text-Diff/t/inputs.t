#!/usr/bin/perl

use strict;
use Test;
use Text::Diff;

my @A = map "$_\n", qw( 1 2 3 4 );
my @B = map "$_\n", qw( 1 2 3 5 );

my $A = join "", @A;
my $B = join "", @B;

my $Af = "io_A";
my $Bf = "io_B";

open A, ">$Af" or die $!; print A @A or die $! ; close A or die $! ;
open B, ">$Bf" or die $!; print B @B or die $! ; close B or die $! ;

my @tests = (
sub { ok !diff \@A, \@A },
sub {
    my $d = diff \@A, \@B;
    $d =~ /-4.*\+5/s ? ok 1 : ok $d, "a valid diff";
},
sub { ok !diff \$A, \$A },
sub {
    my $d = diff \$A, \$B;
    $d =~ /-4.*\+5/s ? ok 1 : ok $d, "a valid diff";
},
sub { ok !diff $Af, $Af },
sub {
    my $d = diff $Af, $Bf;
    $d =~ /-4.*\+5/s ? ok 1 : ok $d, "a valid diff";
},
sub { 
    open A1, "<$Af" or die $!;
    open A2, "<$Af" or die $!;
    ok !diff \*A1, \*A2;
    close A1;
    close A2;
},
sub { 
    open A, "<$Af" or die $!;
    open B, "<$Bf" or die $!;
    my $d = diff \*A, \*B;
    $d =~ /-4.*\+5/s ? ok 1 : ok $d, "a valid diff";
    close A;
    close B;
},
sub {
    ok !diff sub { \@A}, sub { \@A };
},
sub {
    my $d = diff sub { \@A }, sub { \@B };
    $d =~ /-4.*\+5/s ? ok 1 : ok $d, "a valid diff";
},
);

plan tests => scalar @tests;

$_->() for @tests;

unlink "io_A" or warn $!;
unlink "io_B" or warn $!;
