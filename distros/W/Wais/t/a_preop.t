#                              -*- Mode: Perl -*- 
# a_preop.t -- index test database, start server
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Feb 14 13:28:59 1997
# Last Modified By: Norbert Goevert
# Last Modified On: Mon Jul 13 17:25:37 1998
# Language        : CPerl
# Update Count    : 29
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Universität Dortmund, all rights reserved.
# 

BEGIN { print "1..3\n"; $|=1 };

my $pid = open(INDEX, "waisindex -d t/data/test -t fields t/data/TEST 2>&1|")
  or die "Couldn't run `waisindex -d t/data/test -t fields t/data/TEST': $!\n";

print <INDEX>;

close INDEX;

my $wstatus = $?;
my $estatus = $wstatus >> 8;

print qq{
Subprocess "waisindex -d t/data/test -t fields t/data/TEST"
  returned status $estatus (wstat $wstatus)
} if $wstatus;

print "not " if $wstatus;
print "ok 1\n";

$pid = open(INDEX,"waisindex -d t/data/testg -t fields t/data/TESTG 2>&1|")
  or die "Couldn't run `waisindex -d t/data/testg -t fields t/data/TESTG': $!\n";

print <INDEX>;

close INDEX;

$wstatus = $?;
$estatus = $wstatus >> 8;

print qq{
Subprocess "waisindex -d t/data/test -t fields t/data/TEST"
  returned status $estatus (wstat $wstatus)
} if $wstatus;

print "not " if $wstatus;
print "ok 2\n";

$SIG{CHLD} = sub { print "not "; };


if (!($pid = fork())) {
  open(STDOUT, "> t/data/waisserver.log")
    or die "Couldn't write open `t/data/waisserver.log': $!\n";
  open(STDERR, '>& STDOUT')
    or die "Could not redirect STDERR: $!\n";
  exec qw(waisserver -d t/data -p 4171)
    or die "Couldn't run `waisserver -d t/data -p 4171 2>&1': $!\n";
} else {
  open(PID, '> t/data/waisserver.pid')
    or die "Couldn't write open `t/data/waisserver.pid': $!\n";
  print PID $pid;
  close(PID);
}

sleep 5;

print "ok 3\n";

exit(0);
