#                              -*- Mode: Perl -*- 
# base.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug 15 18:47:58 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Feb 14 14:04:27 1997
# Language        : CPerl
# Update Count    : 22
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use Wais;
$loaded = 1;
print "ok 1\n";

@inputs = qw(computer computers pfeifer pfeiffer knight night);
@stems  = qw(comput comput pfeifer pfeiffer knight night);
@sounds = qw(C513 C513 P116 P116 K523 N230);
@phonos = qw(K5130000 K5138000 F7000000 F7000000 N3000000 N3000000);


$test = 2;
for (@inputs) {
  print "$_\t", join "\t", (Wais::Type::stemmer($_), Wais::Type::soundex($_) , Wais::Type::phonix($_));
  print "\n";
  print ((Wais::Type::stemmer($_)    eq shift @stems )? "ok $test\n":"not ok $test\n");$test++;
  print ((Wais::Type::soundex($_) eq shift @sounds)? "ok $test\n":"not ok $test\n");$test++;
  print ((Wais::Type::phonix($_)  eq shift @phonos)? "ok $test\n":"not ok $test\n");$test++;
}
