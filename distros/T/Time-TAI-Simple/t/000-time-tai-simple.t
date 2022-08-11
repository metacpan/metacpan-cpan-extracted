#!/bin/env perl

use strict;
use warnings;
use Test::Most;
use Time::HiRes;

use lib "./lib";
use Time::TAI::Simple;

my $CUR_DELTA = 37;  # zzapp -- update this when the list changes
   $CUR_DELTA-- if (time() <= 1483257600);  # 2017-01-01

my $success = 0;
my $tai_or = undef;
# eval { $tai_or = Time::TAI::Simple->new();  $success = 1; };
$tai_or = Time::TAI::Simple->new();  $success = 1;
ok $success, 'new: no parameters';
die("no further tests possible\n") unless ($success);

my $tai35 = tai35();
my $del35 = Time::HiRes::time() - $tai35;
my $tai10 = tai10();
my $del10 = Time::HiRes::time() - $tai10;
my $tai00 = tai();
my $del00 = Time::HiRes::time() - $tai00;
# print "System clock is $tm0\n";

my $del35del = $CUR_DELTA - 35;
my $del10del = $CUR_DELTA - 10;
my $del00del = $CUR_DELTA;

ok near(abs($del35), $del35del), "tai35 is $tai35 = system clock - $del35";
ok near(abs($del10), $del10del), "tai10 is $tai10 = system clock - $del10";
ok near(abs($del00), $del00del), "tai   is $tai00 = system clock - $del00";

printf("## tai35 error is %0.010f seconds\n", abs(abs($del35) - $del35del));
printf("## tai10 error is %0.010f seconds\n", abs(abs($del10) - $del10del));
printf("## tai   error is %0.010f seconds\n", abs(abs($del00) - $del00del));

my $ua_pick = $tai_or->{ua_str};
my $ua_rand = $tai_or->_pick_user_agent();
my $ua_edge = $tai_or->{ua_ar}->[0];
print "## picked user agent [$ua_pick]\n";
print "## random user agent [$ua_rand]\n";
print "## MSEdge user agent [$ua_edge]\n";

done_testing();
exit(0);

sub near {
    my ($t1, $t2) = @_;
    my $dt = abs($t1 - $t2);
    return 0 if ($dt > 0.02);
    return 1;
}
