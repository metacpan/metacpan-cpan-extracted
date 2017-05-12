#                              -*- Mode: Perl -*- 
# database.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 12:14:23 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon May  8 16:06:01 2000
# Language        : CPerl
# Update Count    : 78
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;
     system 'rm -rf test' if -d 'test';}
#use diagnostics;
use WAIT::Database;
$loaded = 1;
print "ok 1\n";

$test = 2;

$db = create WAIT::Database name => 'test';
print ((defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$tb = create_table $db name => 'sample', attr => ['docid', 'term'];
print ((defined $tb)? "ok $test\n" : "not ok $test\n"); $test++;

$status = drop_table $db name => 'sample';
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

eval {$status = $tb->drop};
print (($@)? "ok $test\n" : "not ok $test\n"); $test++;

$tb = create_table $db name => 'sample', attr => ['docid', 'term'];
print ((defined $tb)? "ok $test\n" : "not ok $test $@\n"); $test++;

$status = $tb->open;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->close;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;
print ((defined $tb)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $db->close;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$db = WAIT::Database->open(name => 'test');
print ((defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$tb = table $db name => 'sample';
print ((defined $tb)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->open;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->set(top=>1);
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $tb->drop;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;
print ((!defined $tb)? "ok $test\n" : "not ok $test\n"); $test++;

# clean up
$status = $db->dispose;
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;
print ((!defined $db)? "ok $test\n" : "not ok $test\n"); $test++;



