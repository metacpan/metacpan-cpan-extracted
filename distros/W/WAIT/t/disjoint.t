#                              -*- Mode: Perl -*- 
# scan.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 12:14:23 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:33 1998
# Language        : CPerl
# Update Count    : 128
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..32\n"; }
END {print "not ok 1\n" unless $loaded;
     system 'rm -rf test' if -d 'test';
}
#use diagnostics;
use WAIT::Database;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$test = 2;

$db = create WAIT::Database name => 'test';
print ((defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$tb = create_table $db name => 'sample', attr => ['docid', 'term'],
  djk => ['docid'];

print ((defined $tb)? "ok $test\n" : "not ok $test\n"); $test++;

$etid = 1;
while (<DATA>) {
  chomp;
  my($weight, $did, $term) = split;
  $tid = $tb->insert($weight, docid => $did, term => $term);
  push @db, [$did, $term, $weight];
  print (($tid == $etid++)? "ok $test\n" : "not ok $test\n"); $test++;
}

$sc = $tb->open_scan();
print ((defined $sc)? "ok $test\n" : "not ok $test\n"); $test++;

$tid = 0; 
while (%tp = $sc->next()) {
  printf "%s", (($tp{docid} == $db[$tid]->[0]
          and $tp{term} eq $db[$tid]->[1])?
         "ok $test\n" : "not ok $test\n"); $test++;
  $tid++;
}

$sc = $tb->open_scan(sub {$_[0]->{term} eq 'IR'});
print ((defined $sc)? "ok $test\n" : "not ok $test\n"); $test++;

$tid=0;
@ndb = @db[1,4];
while (%tp = $sc->next()) {
  printf "%s",  (($tp{docid} == $ndb[$tid]->[0]
          and $tp{term} eq $ndb[$tid]->[1])?
         "ok $test\n" : "not ok $test\n"); $test++;
  $tid++;
}

$sc = $tb->open_index_scan(['docid', 'term']);
print ((defined $sc)? "ok $test\n" : "not ok $test\n"); $test++;

$etid = 1; 
while (%tp = $sc->next()) {
  print (($tp{_id} == $etid++)?"ok $test\n" : "not ok $test\n"); $test++;
}

$sc = $tb->open_index_scan(['docid', 'term'], sub {$_[0]->{term} eq 'IR'});
print ((defined $sc)? "ok $test\n" : "not ok $test\n"); $test++;

@ndb = (1,4);
while (%tp = $sc->next()) {
  print (($tp{_id} == shift(@ndb)+1)?"ok $test\n" : "not ok $test\n"); $test++;
}

$status = $tb->close;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

# must have destroyed all handles here !
# clean up
$status = $db->dispose;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;
print ((!defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

__END__
0.1 1 DB
0.2 1 IR
0.3 2 DB
0.4 2 KI
0.5 3 IR
0.6 3 KI
