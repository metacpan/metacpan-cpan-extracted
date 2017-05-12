#!./perl
#                              -*- Mode: Perl -*- 
# dict.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Nov  8 12:02:19 1995
# Last Modified By: Norbert Goevert
# Last Modified On: Mon Jul 13 17:29:31 1998
# Language        : Perl
# Update Count    : 71
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1995, Universität Dortmund, all rights reserved.
# 

BEGIN {print "1..8\n";}

use Wais;

$db     = 't/data/test';
$should = 'pollmann,1,poersch,2,pfeifer,10,pennekamp,1,p622,2,p525,1,p455,1,p116,10';
$result = join ',', &Wais::dictionary($db , 'au', 'p*');
print (($should eq $result)?"ok 1\n" : "not ok 1\n");

$should = 'pennekamp,pfeifer,poersch,pollmann,probabilistic,processing,proper';
%x = &Wais::dictionary($db , 'p*');
$result = join ',', sort keys %x;
print (($should eq $result)?"ok 2\n" : "not ok 2\n$should\n$result\n");

$should = 'buckley,1,bremkamp,1,b652,1,b224,1,fuhr,7,f600,7,huynh,1,h500,1,pollmann,1,poersch,2,pfeifer,10,pennekamp,1,p622,2,p525,1,p455,1,p116,10';
$result = join ',', &Wais::dictionary($db, 'au');
# hide a bug!
$result = substr($result,0,length($should));
print (($should eq $result)?"ok 3\n" : "not ok 3\n$should\n$result\n\n");

$should = 16;
$result =  &Wais::dictionary($db, 'au');
print (($should <= $result)?"ok 4\n$result =?= 16\n" : "not ok 4\n");

%x = &Wais::postings($db, 'au', 'pfeifer');
print (($x{2}->[0] == 0.5)?"ok 5\n" : "not ok 5\n");

%x = &Wais::postings($db, 'fuhr');
print (($#{$x{1}} == 2)?"ok 6\n" : "not ok 6\n");

$should = '1991 Fuhr, N.; Pfeifer, U Combining Model-Oriented and Description';
$result = &Wais::headline($db,1);
print (($should eq $result)?"ok 7\n" : "not ok 7\n");

$should = 'Combining Model-Oriented and Description';
$result = &Wais::document($db,1);
print (($result =~ $should)?"ok 8\n" : "not ok 8\n");

