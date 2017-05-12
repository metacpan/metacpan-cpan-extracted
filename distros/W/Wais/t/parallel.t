#                              -*- Mode: Perl -*- 
# parallel.t -- test the new interface
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Tue Dec 12 16:55:05 1995
# Last Modified By: Norbert Goevert
# Last Modified On: Mon Jul 13 17:28:12 1998
# Language        : Perl
# Update Count    : 112
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1995, Universität Dortmund, all rights reserved.
# 
BEGIN {print "1..6\n";}
use Wais;

$db1  = 'test';
$host = 'localhost';
$db2  = 'testg';

print "Testing local searches\n";
$result = Wais::Search
  (
   {
    'query'    => 'pfeifer', 
    'database' => "t/data/$db1",
    'database' => "t/data/$db2",
    }
  );

&headlines($result);
$id     = ($result->header)[3]->[6];
$length = ($result->header)[3]->[3];
@header = $result->header;
print (($#header == 4)?"ok 1\n" : "not ok 1\n");

print "Testing local retrieve\n";

$result = Wais::Retrieve
  (
   'database' => "t/data/$db1",
   'docid'    => $id, 
   'type'     => 'TEXT',
  );

print $result->text;
print length($result->text), "***\n";
print ((length($result->text) == $length)?"ok 2\n" : "not ok 2\n");

print "Testing remote searches\n";
eval {
  $result = Wais::Search
    (
     {
      'query'    => 'au=pfeifer',
      'host'     => $host,
      'port'     => 4171,
      'database' => $db1,
     }
    );
};


&headlines($result);
@header = $result->header;

unless ($@ eq '' and @header) {
  for (3 .. 6) {
    print "not ok $_\n";
  }
  exit;
}

print (($#header == 9)?"ok 3\n" : "not ok 3\n");
$long    = ($result->header)[7]->[6];
$short   = ($result->header)[0]->[6];
$long_l  = ($result->header)[7]->[3];
$short_l = ($result->header)[0]->[3];
print "Testing remote retrieve\n";

$result = Wais::Retrieve
  (
   'host'     => $host,
   'port'     => 4171,
   'database' => $db1,
   'docid'    => $short,
   'type'     => 'TEXT',
  );

print $result->text;
print length($result->text), "===\n";
print ((length($result->text) == $short_l)?"ok 4\n" : "not ok 4\n");

print "Testing long documents\n";

$result = Wais::Retrieve
  (
   'host'     => $host,
   'port'     => 4171,
   'database' => $db1,
   'database' => $db2,
   'docid'    => $long, 
   'type'     => 'TEXT',
  );

print $result->text;
print ((length($result->text) == $long_l)?"ok 5\n" : "not ok 5\n");

sub headlines {
  my $result = shift;
  my ($tag, $score, $lines, $length, $headline, $types, $id);
  
  for ($result->header) {
    ($tag, $score, $lines, $length, $headline, $types, $id) = @{$_};
    printf "%5d %5d %s %s\n", 
    $score, $lines, $headline, join(',', @{$types});
  }
}

@x = $short->split;
print (($x[0] =~ /:4171/)? "ok 6\n" : "$x[0]\nnot ok 6\n");
