#                              -*- Mode: Perl -*- 
# database.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 12:14:23 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:30 1998
# Language        : CPerl
# Update Count    : 80
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..18\n"; }
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

$tb = create_table $db name => 'sample', attr => ['docid', 'term'];
print ((defined $tb)? "ok $test\n" : "not ok $test\n"); $test++;

$tid = $tb->insert(docid => 1, term => IR);
print (($tid)? "ok $test\n" : "not ok $test\n"); $test++;

$tb->sync;

%tp = $tb->fetch($tid);
print (($tp{docid} == 1 and $tp{term} eq IR)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->close;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $db->close;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$db = WAIT::Database->open(name => 'test');
print ((defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$tb = table $db name => 'sample';
print ((defined $tb)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->open;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

%tp = $tb->fetch($tid);
print (($tp{docid} == 1 and $tp{term} eq IR)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->delete(%tp);
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->delete_by_key($tid);
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

# can we reuse tid?
$ntid = $tb->insert(docid => 1, term => IR);
print (($ntid == $tid)? "ok $test\n" : "not ok $test\n"); $test++;

%tp = $tb->fetch($ntid);
print (($tp{docid} == 1 and $tp{term} eq IR)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->close;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

# must have destroyed all handles here !
# clean up
$status = $db->dispose;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;
print ((!defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

