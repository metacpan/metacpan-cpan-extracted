#                              -*- Mode: Perl -*- 
# document-split.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sun Sep 15 17:10:53 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:32 1998
# Language        : CPerl
# Update Count    : 22
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use WAIT::Document::Split;
$loaded = 1;
print "ok 1\n";

$test = 2;

my %D;
my $x = tie %D, WAIT::Document::Split, 'sep', '\f', 't/test.ste';
print ((defined $x)? "ok $test\n" : "not ok $test\n"); $test++;
print ((scalar(keys %D) == 16)? "ok $test\n" : "not ok $test\n"); $test++;
my $f = $x->FIRSTKEY;
my($start, $len) = ($f =~ /(\d+) (\d+)/);
print (($start == 0)? "ok $test\n" : "not ok $test\n"); $test++;

undef $x;
untie %D;

my $y = tie %D, WAIT::Document::Split, 'end', '\f', 't/test.ste';
print ((defined $y)? "ok $test\n" : "not ok $test\n"); $test++;

$f = $y->FIRSTKEY;
my ($nlen) = ($f =~ /(\d+)$/);
print (($nlen == $len+2)? "ok $test\n" : "not ok $test\n"); $test++;

$f = $y->NEXTKEY;
($start) = ($f =~ /(\d+) \d+$/);

undef $y;
untie %D;
$y = tie %D, WAIT::Document::Split, 'start', '\f', 't/test.ste';
print ((defined $y)? "ok $test\n" : "not ok $test\n"); $test++;
$f = $y->FIRSTKEY;
$f = $y->NEXTKEY;
my ($nstart) = ($f =~ /(\d+) \d+$/);
print (($nstart == $start-2)? "ok $test\n" : "not ok $test\n"); $test++;


