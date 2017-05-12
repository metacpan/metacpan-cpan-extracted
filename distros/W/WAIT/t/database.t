#                              -*- Mode: Perl -*- 
# database.t -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 12:14:23 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:33 1998
# Language        : CPerl
# Update Count    : 16
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
#use diagnostics;
use WAIT::Database;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

$db = create WAIT::Database name => 'test';

print ((defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $db->close();

print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

print ((!defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$db = WAIT::Database->open(name => 'test');

print ((defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$db->sync;
print "ok $test\n"; $test++;

undef $self;                    # perl -w
undef $WAIT::Database::self;     # perl -w
print ((!defined $self)? "ok $test\n" : "not ok $test\n"); $test++;
print ((!defined $WAIT::Database::self)? "ok $test\n" : "not ok $test\n"); $test++;

$status = $db->dispose;

print (($status)? "ok $test\n" : "not ok $test\n"); $test++;
print ((!defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

{my $db = WAIT::Database->create(name => 'test'); $db->close()}
print ((!defined $db)? "ok $test\n" : "not ok $test\n"); $test++;

$status = WAIT::Database->dispose(name => 'test');
print (($status)? "ok $test\n" : "not ok $test\n"); $test++;

$db = WAIT::Database->open(name => 'test');
print ((!defined $db)? "ok $test\n" : "not ok $test\n"); $test++;
