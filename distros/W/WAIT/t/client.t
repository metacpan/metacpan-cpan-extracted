#                              -*- Mode: Perl -*- 
# $Basename: client.t $
# $Revision: 1.2 $
# Author          : Ulrich Pfeifer
# Created On      : Fri Jan 31 16:34:58 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Nov  5 16:44:56 1997
# Language        : CPerl
# Update Count    : 18
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use WAIT::Client;

$loaded = 1;
print "ok 1\n";
my $test   = 2;

$SIG{ALRM} =
  sub {
    print "Cannot connect to ls6.informatik.uni-dortmund.de\n";
    print "# skipping tests 10..15\n";
    for ($test .. 8) {print "ok $_\n";}
    exit 0;
  };


alarm(10);
my $con = new WAIT::Client 'ls6.informatik.uni-dortmund.de', Port => 1404;
print "not " unless $con; print "ok $test\n"; $test++;
exit unless $con;
alarm(0);
$status = $con->help();
print "not " unless $status; print "ok $test\n"; $test++;

$status = $con->database('DB');
print "not " unless $status; print "ok $test\n"; $test++;

$status = $con->table('cpan');
print "not " unless $status; print "ok $test\n"; $test++;

$status = $con->hits(3);
print "not " unless $status; print "ok $test\n"; $test++;

$status = $con->search(qw(au=wall and au=larry));
print "not " unless $status; print "ok $test\n"; $test++;

$status = $con->info(1);
print "not " unless $status; print "ok $test\n"; $test++;

