#                              -*- Mode: Perl -*- 
# base.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug 15 18:47:58 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:32 1998
# Language        : CPerl
# Update Count    : 22
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 
# 

BEGIN { $| = 1; print "1..25\n"; }
END {print "not ok 1\n" unless $loaded;}
use WAIT::Filter qw(Stem Soundex Phonix Metaphone);
$loaded = 1;
print "ok 1\n";

@inputs = qw(computer computers pfeifer pfeiffer knight night);
@stems  = qw(comput comput pfeifer pfeiffer knight night);
@sounds = qw(C513 C513 P116 P116 K523 N230);
@phonos = qw(K5130000 K5138000 F7000000 F7000000 N3000000 N3000000);
@mphone = qw(KMPTR KMPTR PFFR PFFR NT NT);
$test = 2;
for (@inputs) {
 print ((Stem($_)      eq shift @stems )?"ok $test\n":"not ok $test\n");$test++;
 print ((Soundex($_)   eq shift @sounds)?"ok $test\n":"not ok $test\n");$test++;
 print ((Phonix($_)    eq shift @phonos)?"ok $test\n":"not ok $test\n");$test++;
 print ((Metaphone($_) eq shift @mphone)?"ok $test\n":"not ok $test\n");$test++;
}
