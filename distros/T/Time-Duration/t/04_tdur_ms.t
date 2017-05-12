use strict;
use Test;

my @them;
BEGIN { plan('tests' => 20) };
BEGIN { print "# Perl version $] under $^O\n" }

use Time::Duration;
ok 1;
print "# Time::Duration version $Time::Duration::VERSION\n";

use constant MINUTE =>   60;
use constant HOUR   => 3600;
use constant DAY    =>   24 * HOUR;
use constant YEAR   =>  365 * DAY;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print "# Millisecond mode disabled...\n";

ok( sub{duration(1.001)}, '1 second');

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print "# Basic millisecond tests...\n";

$Time::Duration::MILLISECOND = 1;

ok( sub{duration(1.001)}, '1 second and 1 millisecond');
ok( sub{duration(1.021)}, '1 second and 21 milliseconds');

ok( sub{later(  2.001)}, '2 seconds and 1 millisecond later');
ok( sub{later(  2.021)}, '2 seconds and 21 milliseconds later');
ok( sub{earlier(2.001)}, '2 seconds and 1 millisecond earlier');
ok( sub{earlier(2.021)}, '2 seconds and 21 milliseconds earlier');
  
ok( sub{ago(     2.001)}, '2 seconds and 1 millisecond ago');
ok( sub{ago(     2.021)}, '2 seconds and 21 milliseconds ago');
ok( sub{from_now(2.001)}, '2 seconds and 1 millisecond from now');
ok( sub{from_now(2.021)}, '2 seconds and 21 milliseconds from now');

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print "# Advanced millisecond tests...\n";

my $v;  #scratch var

$v = 61.02;
ok(sub {later(       $v   )}, '1 minute and 1 second later');
ok(sub {later(       $v, 3)}, '1 minute, 1 second, and 20 milliseconds later');
ok(sub {later_exact( $v   )}, '1 minute, 1 second, and 20 milliseconds later');

$v = DAY + - HOUR + -28.802 + YEAR;
ok(sub {later(       $v   )}, '1 year and 23 hours later');
ok(sub {later(       $v, 3)}, '1 year and 23 hours later');
ok(sub {later_exact( $v   )}, '1 year, 22 hours, 59 minutes, 31 seconds, and 198 milliseconds later');

#~~~~~~~~

print "# Some tests of concise() ...\n";

ok( sub{concise duration(   1.021)}, '1s21ms');
ok( sub{concise duration(  -1.021)}, '1s21ms');
  
print "# Done with all of ", __FILE__, "\n";

