#!/usr/bin/perl -w

BEGIN {print "1..27\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}


use WWW::Link;
$loaded = 1;
ok(1);

$WWW::Link::inter_test_time = -1; #accept immediate testing.. 

$start_time=time;

$::link=new WWW::Link "http://www.bounce.com/";
ok(2);
##############################################################
$::link->failed_test;
ok(3);
$::link->is_okay && nogo;
ok(4);
$::link->is_broken && nogo;
ok(5);
$::link->last_test() >= $start_time or nogo;
ok(6);
$::link->time_want_test() > $start_time or nogo;
ok(7);
$i=10;
$::link->failed_test while $i--;
$::link->is_broken || nogo;
ok(8);

$::link=new WWW::Link "http://www.bounce.com/";
ok(9);
##############################################################
$::link->passed_test();
ok(10);
$::link->is_okay || nogo;
ok(11);
$::link->last_test() >= $start_time or nogo;
ok(12);
##############################################################
$::link->failed_test;
ok(13);
$::link->is_okay && nogo;
ok(14);
##############################################################
$::link->passed_test();
$::link->is_okay || nogo;
ok(15);
##############################################################
$::link->disallowed();
$::link->is_disallowed || nogo;
ok(16);
$::link->is_okay && nogo;
ok(17);
$::link->is_broken && nogo;
ok(18);
##############################################################
$::link->passed_test();
$::link->is_okay || nogo;
ok(19);
$::link->is_broken && nogo;
ok(20);
$::link->is_disallowed && nogo;
ok(21);
##############################################################
$::link->unsupported();
$::link->is_unsupported || nogo;
ok(22);
$::link->is_okay && nogo;
ok(23);
$::link->is_broken && nogo;
ok(24);
##############################################################
$i=10;
$::link->failed_test while $i--;
$::link->is_okay && nogo;
ok(25);
$::link->is_broken || nogo;
ok(26);
$::link->is_unsupported && nogo;
ok(27);

#FIXME we need to test the time_want_test in each of the different
#possible link statuses.
