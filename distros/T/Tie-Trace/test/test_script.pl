#!/usr/bin/perl

package TestPackage;

$| = 1;

use lib qw(../lib);
use Tie::Trace qw/watch/;
use Data::Dumper;
use strict;

local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 0;

my $test = 1;

watch($test);

$test = 1;

print "  => ", Dumper($test), "\n\n";
undef $test;
print "  => ", Dumper($test), "\n\n";
$test = {};
print "  => ", Dumper($test), "\n\n";
$test->{a} = 1;
print "  => ", Dumper($test), "\n\n";
$test->{b} = ["a" .. "c"];
print "  => ", Dumper($test), "\n\n";
push @{$test->{b}}, 1, 2;
print "  => ", Dumper($test), "\n\n";
shift @{$test->{b}};
print "  => ", Dumper($test), "\n\n";
push @{$test->{b}}, 'a' .. 'f';
print "  => ", Dumper($test), "\n\n";
unshift @{$test->{b}}, 1 .. 5;
print "  => ", Dumper($test), "\n\n";
pop @{$test->{b}};
print "  => ", Dumper($test), "\n\n";
splice @{$test->{b}}, 0, 1, "01", "02", "03";
print "  => ", Dumper($test), "\n\n";
splice @{$test->{b}}, 0, 3, "01";
print "  => ", Dumper($test), "\n\n";
@{$test}{qw/a b/} = ();
print "  => ", Dumper($test), "\n\n";
@{$test}{qw/a b/} = ([1 .. 5], "B");
print "  => ", Dumper($test), "\n\n";
delete @{$test}{qw/a b/};
print "  => ", Dumper($test), "\n\n";
$test->{a} = sub {};
print "  => ", Dumper($test), "\n\n";

$test->{a} = sub {1,2,3};
print "  => ", Dumper($test), "\n\n";

=pod

=head1 test_script.pl for Tie::Trace

The following is result of test_script.pl
  
 TestPackage:: $test => 1 at test/test_script.pl line 19.
   => '1'
 
 TestPackage:: $test => undef at test/test_script.pl line 22.
   => undef
 
 TestPackage:: $test => {} at test/test_script.pl line 24.
   => {}
 
 TestPackage:: $test => {a} => 1 at test/test_script.pl line 26.
   => {'a' => 1}
 
 TestPackage:: $test => {b} => ['a','b','c'] at test/test_script.pl line 28.
   => {'a' => 1,'b' => ['a','b','c']}
 
 TestPackage:: $test => @{{b}} => PUSH(1,2) at lib/Tie/Trace.pm line 395.
   => {'a' => 1,'b' => ['a','b','c','1','2']}
 
 TestPackage:: $test => @{{b}} => SHIFT() at lib/Tie/Trace.pm line 410.
   => {'a' => 1,'b' => ['b','c','1','2']}
 
 TestPackage:: $test => @{{b}} => PUSH('a','b','c','d','e','f') at lib/Tie/Trace.pm line 395.
   => {'a' => 1,'b' => ['b','c','1','2','a','b','c','d','e','f']}
 
 TestPackage:: $test => @{{b}} => UNSHIFT(1,2,3,4,5) at lib/Tie/Trace.pm line 400.
   => {'a' => 1,'b' => ['1','2','3','4','5','b','c','1','2','a','b','c','d','e','f']}
 
 TestPackage:: $test => @{{b}} => POP() at lib/Tie/Trace.pm line 405.
   => {'a' => 1,'b' => ['1','2','3','4','5','b','c','1','2','a','b','c','d','e']}
 
 TestPackage:: $test => {b}[0] => ('01','02','03') at test/test_script.pl line 40.
   => {'a' => 1,'b' => ['01','02','03','2','3','4','5','b','c','1','2','a','b','c','d','e']}
 
 TestPackage:: $test => {b}[0 .. 2] => ('01') at test/test_script.pl line 42.
   => {'a' => 1,'b' => ['01','2','3','4','5','b','c','1','2','a','b','c','d','e']}
 
 TestPackage:: $test => {a} => undef at test/test_script.pl line 44.
 TestPackage:: $test => {b} => undef at test/test_script.pl line 44.
   => {'a' => undef,'b' => undef}
 
 TestPackage:: $test => {a} => [1,2,3,4,5] at test/test_script.pl line 46.
 TestPackage:: $test => {b} => 'B' at test/test_script.pl line 46.
   => {'a' => ['1','2','3','4','5'],'b' => 'B'}
 
 TestPackage:: $test => {a} => DELETED([1,2,3,4,5]) at test/test_script.pl line 48.
 TestPackage:: $test => {b} => DELETED('B') at test/test_script.pl line 48.
   => {}
 
  TestPackage:: $test => {a} => sub {        package TestPackage;        use strict 'refs';            } at test/test_script.pl line 48.
   => {'a' => sub { "DUMMY" }}
 
 TestPackage:: $test => {a} => sub {        package TestPackage;        use strict 'refs';        1, 2, 3;    } at test/test_script.pl line 51.
   => {'a' => sub { "DUMMY" }}


=cut
