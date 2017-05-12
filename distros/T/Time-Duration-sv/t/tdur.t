# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;

my @them;
BEGIN { plan('tests' => 135) };
BEGIN { print "# Perl version $] under $^O\n" }
#BEGIN {require 'sv.pm';
#Time::Duration::sv->import();
#}
use Time::Duration::sv;
ok 1;
print "# Time::Duration version $Time::Duration::sv::VERSION\n";

use constant MINUTE =>   60;
use constant HOUR   => 3600;
use constant DAY    =>   24 * HOUR;
use constant YEAR   =>  365 * DAY;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print "# Basic tests...\n";

ok( sub{duration(   0)}, '0 sekunder');
ok( sub{duration(   1)}, '1 sekund');
ok( sub{duration(  -1)}, '1 sekund');
ok( sub{duration(   2)}, '2 sekunder');
ok( sub{duration(  -2)}, '2 sekunder');
ok( sub{later(   0)}, 'just då');
ok( sub{later(   2)}, '2 sekunder senare');
ok( sub{later(  -2)}, '2 sekunder tidigare');
ok( sub{earlier( 0)}, 'just då');
ok( sub{earlier( 2)}, '2 sekunder tidigare');
ok( sub{earlier(-2)}, '2 sekunder senare');
  
ok( sub{ago(      0)}, 'just nu');
ok( sub{ago(      2)}, 'för 2 sekunder sen');
ok( sub{ago(     -2)}, 'om 2 sekunder');
ok( sub{from_now( 0)}, 'just nu');
ok( sub{from_now( 2)}, 'om 2 sekunder');
ok( sub{from_now(-2)}, 'för 2 sekunder sen');

 
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print "# Advanced tests...\n";

my $v;  #scratch var

$v = 0;
ok(sub {later(       $v   )}, 'just då');
ok(sub {later(       $v, 3)}, 'just då');
ok(sub {later_exact( $v   )}, 'just då');

$v = 1;
ok(sub {later(       $v   )}, '1 sekund senare');
ok(sub {later(       $v, 3)}, '1 sekund senare');
ok(sub {later_exact( $v   )}, '1 sekund senare');

$v = 30;
ok(sub {later(       $v   )}, '30 sekunder senare');
ok(sub {later(       $v, 3)}, '30 sekunder senare');
ok(sub {later_exact( $v   )}, '30 sekunder senare');

$v = 46;
ok(sub {later(       $v   )}, '46 sekunder senare');
ok(sub {later(       $v, 3)}, '46 sekunder senare');
ok(sub {later_exact( $v   )}, '46 sekunder senare');

$v = 59;
ok(sub {later(       $v   )}, '59 sekunder senare');
ok(sub {later(       $v, 3)}, '59 sekunder senare');
ok(sub {later_exact( $v   )}, '59 sekunder senare');

$v = 61;
ok(sub {later(       $v   )}, '1 minut och 1 sekund senare');
ok(sub {later(       $v, 3)}, '1 minut och 1 sekund senare');
ok(sub {later_exact( $v   )}, '1 minut och 1 sekund senare');

$v = 3599;
ok(sub {later(       $v   )}, '59 minuter och 59 sekunder senare');
ok(sub {later(       $v, 3)}, '59 minuter och 59 sekunder senare');
ok(sub {later_exact( $v   )}, '59 minuter och 59 sekunder senare');

$v = 3600;
ok(sub {later(       $v   )}, '1 timme senare');
ok(sub {later(       $v, 3)}, '1 timme senare');
ok(sub {later_exact( $v   )}, '1 timme senare');

$v = 3601;
ok(sub {later(       $v   )}, '1 timme och 1 sekund senare');
ok(sub {later(       $v, 3)}, '1 timme och 1 sekund senare');
ok(sub {later_exact( $v   )}, '1 timme och 1 sekund senare');

$v = 3630;
ok(sub {later(       $v   )}, '1 timme och 30 sekunder senare');
ok(sub {later(       $v, 3)}, '1 timme och 30 sekunder senare');
ok(sub {later_exact( $v   )}, '1 timme och 30 sekunder senare');

$v = 3800;
ok(sub {later(       $v   )}, '1 timme och 3 minuter senare');
ok(sub {later(       $v, 3)}, '1 timme, 3 minuter, och 20 sekunder senare');
ok(sub {later_exact( $v   )}, '1 timme, 3 minuter, och 20 sekunder senare');

$v = 3820;
ok(sub {later(       $v   )}, '1 timme och 4 minuter senare');
ok(sub {later(       $v, 3)}, '1 timme, 3 minuter, och 40 sekunder senare');
ok(sub {later_exact( $v   )}, '1 timme, 3 minuter, och 40 sekunder senare');

$v = DAY + - HOUR + -28;
ok(sub {later(       $v   )}, '23 timmar senare');
ok(sub {later(       $v, 3)}, '22 timmar, 59 minuter, och 32 sekunder senare');
ok(sub {later_exact( $v   )}, '22 timmar, 59 minuter, och 32 sekunder senare');

$v = DAY + - HOUR + MINUTE;
ok(sub {later(       $v   )}, '23 timmar och 1 minut senare');
ok(sub {later(       $v, 3)}, '23 timmar och 1 minut senare');
ok(sub {later_exact( $v   )}, '23 timmar och 1 minut senare');

$v = DAY + - HOUR + 29 * MINUTE + 1;
ok(sub {later(       $v   )}, '23 timmar och 29 minuter senare');
ok(sub {later(       $v, 3)}, '23 timmar, 29 minuter, och 1 sekund senare');
ok(sub {later_exact( $v   )}, '23 timmar, 29 minuter, och 1 sekund senare');

$v = DAY + - HOUR + 29 * MINUTE + 31;
ok(sub {later(       $v   )}, '23 timmar och 30 minuter senare');
ok(sub {later(       $v, 3)}, '23 timmar, 29 minuter, och 31 sekunder senare');
ok(sub {later_exact( $v   )}, '23 timmar, 29 minuter, och 31 sekunder senare');

$v = DAY + - HOUR + 30 * MINUTE + 31;
ok(sub {later(       $v   )}, '23 timmar och 31 minuter senare');
ok(sub {later(       $v, 3)}, '23 timmar, 30 minuter, och 31 sekunder senare');
ok(sub {later_exact( $v   )}, '23 timmar, 30 minuter, och 31 sekunder senare');

$v = DAY + - HOUR + -28 + YEAR;
ok(sub {later(       $v   )}, '1 år och 23 timmar senare');
ok(sub {later(       $v, 3)}, '1 år och 23 timmar senare');
ok(sub {later_exact( $v   )}, '1 år, 22 timmar, 59 minuter, och 32 sekunder senare');

$v = DAY + - HOUR + MINUTE + YEAR;
ok(sub {later(       $v   )}, '1 år och 23 timmar senare');
ok(sub {later(       $v, 3)}, '1 år, 23 timmar, och 1 minut senare');
ok(sub {later_exact( $v   )}, '1 år, 23 timmar, och 1 minut senare');

$v = DAY + - HOUR + 29 * MINUTE + 1 + YEAR;
ok(sub {later(       $v   )}, '1 år och 23 timmar senare');
ok(sub {later(       $v, 3)}, '1 år, 23 timmar, och 29 minuter senare');
ok(sub {later_exact( $v   )}, '1 år, 23 timmar, 29 minuter, och 1 sekund senare');

$v = DAY + - HOUR + 29 * MINUTE + 31 + YEAR;
ok(sub {later(       $v   )}, '1 år och 23 timmar senare');
ok(sub {later(       $v, 3)}, '1 år, 23 timmar, och 30 minuter senare');
ok(sub {later_exact( $v   )}, '1 år, 23 timmar, 29 minuter, och 31 sekunder senare');

$v = YEAR + 2 * HOUR + -1;
ok(sub {later(       $v   )}, '1 år och 2 timmar senare');
ok(sub {later(       $v, 3)}, '1 år och 2 timmar senare');
ok(sub {later_exact( $v   )}, '1 år, 1 timme, 59 minuter, och 59 sekunder senare');

$v = YEAR + 2 * HOUR + 59;
ok(sub {later(       $v   )}, '1 år och 2 timmar senare');
ok(sub {later(       $v, 3)}, '1 år, 2 timmar, och 59 sekunder senare');
ok(sub {later_exact( $v   )}, '1 år, 2 timmar, och 59 sekunder senare');

$v = YEAR + DAY + 2 * HOUR + -1;
ok(sub {later(       $v   )}, '1 år och 1 dag senare');
ok(sub {later(       $v, 3)}, '1 år, 1 dag, och 2 timmar senare');
ok(sub {later_exact( $v   )}, '1 år, 1 dag, 1 timme, 59 minuter, och 59 sekunder senare');

$v = YEAR + DAY + 2 * HOUR + 59;
ok(sub {later(       $v   )}, '1 år och 1 dag senare');
ok(sub {later(       $v, 3)}, '1 år, 1 dag, och 2 timmar senare');
ok(sub {later_exact( $v   )}, '1 år, 1 dag, 2 timmar, och 59 sekunder senare');

$v = YEAR + - DAY + - 1;
ok(sub {later(       $v   )}, '364 dagar senare');
ok(sub {later(       $v, 3)}, '364 dagar senare');
ok(sub {later_exact( $v   )}, '363 dagar, 23 timmar, 59 minuter, och 59 sekunder senare');

$v = YEAR + - 1;
ok(sub {later(       $v   )}, '1 år senare');
ok(sub {later(       $v, 3)}, '1 år senare');
ok(sub {later_exact( $v   )}, '364 dagar, 23 timmar, 59 minuter, och 59 sekunder senare');




print "# och an advanced one to put duration thru its paces...\n";
$v = YEAR + DAY + 2 * HOUR + 59;
ok(sub {duration(       $v   )}, '1 år och 1 dag');

ok(sub {duration(       $v, 3)}, '1 år, 1 dag, och 2 timmar');
ok(sub {duration_exact( $v   )}, '1 år, 1 dag, 2 timmar, och 59 sekunder');

ok(sub {duration(      -$v   )}, '1 år och 1 dag');
ok(sub {duration(      -$v, 3)}, '1 år, 1 dag, och 2 timmar');
ok(sub {duration_exact(-$v   )}, '1 år, 1 dag, 2 timmar, och 59 sekunder');


#~~~~~~~~

print "# Some tests of concise() ...\n";

ok( sub{concise duration(   0)}, '0s');
ok( sub{concise duration(   1)}, '1s');
ok( sub{concise duration(  -1)}, '1s');
ok( sub{concise duration(   2)}, '2s');
ok( sub{concise duration(  -2)}, '2s');

ok( sub{concise later(   0)}, 'just då');
ok( sub{concise later(   2)}, '2s senare');
ok( sub{concise later(  -2)}, '2s tidigare');
ok( sub{concise earlier( 0)}, 'just då');
ok( sub{concise earlier( 2)}, '2s tidigare');
ok( sub{concise earlier(-2)}, '2s senare');

ok( sub{concise ago(      0)}, 'just nu');
ok( sub{concise ago(      2)}, 'för 2s sen');
ok( sub{concise ago(     -2)}, 'om 2s');
ok( sub{concise from_now( 0)}, 'just nu');
ok( sub{concise from_now( 2)}, 'om 2s');
ok( sub{concise from_now(-2)}, 'för 2s sen');

  


$v = YEAR + DAY + 2 * HOUR + -1;
ok(sub {concise later(       $v   )}, '1å1d senare');
ok(sub {concise later(       $v, 3)}, '1å1d2t senare');
ok(sub {concise later_exact( $v   )}, '1å1d1t59m59s senare');



$v = YEAR + DAY + 2 * HOUR + 59;
ok(sub {concise later(       $v   )}, '1å1d senare');
ok(sub {concise later(       $v, 3)}, '1å1d2t senare');
ok(sub {concise later_exact( $v   )}, '1å1d2t59s senare');

$v = YEAR + - DAY + - 1;
ok(sub {concise later(       $v   )}, '364d senare');
ok(sub {concise later(       $v, 3)}, '364d senare');
ok(sub {concise later_exact( $v   )}, '363d23t59m59s senare');

$v = YEAR + - 1;
ok(sub {concise later(       $v   )}, '1å senare');
ok(sub {concise later(       $v, 3)}, '1å senare');
ok(sub {concise later_exact( $v   )}, '364d23t59m59s senare');



# That's it.
print "# och one for the road.\n";
ok 1;
print "# Done with of ", __FILE__, "\n";

