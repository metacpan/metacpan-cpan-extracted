#!/usr/local/bin/perl

use strict;
use warnings;

use constant cte_flag => 0;

sub cte_test0 {
  if (cte_flag) { print "hello\n" };
}

sub cte_test1 {
  my $a=0;
  for my $i (1..100) {
    if (cte_flag) { print "hello\n" };
    $a+=$i;
  }
}

sub cte_test2 {
  my $a=0;
  for my $i (1..10000) {
    if (cte_flag) { print "hello\n" };
    $a+=$i;
  }
}

our $our_flag=0;

sub our_test0 {
  if ($our_flag) { print "hello\n" };
}

sub our_test1 {
  my $a=0;
  for my $i (1..100) {
    if ($our_flag) { print "hello\n" };
    $a+=$i;
  }
}

sub our_test2 {
  my $a=0;
  for my $i (1..10000) {
    if ($our_flag) { print "hello\n" };
    $a+=$i;
  }
}


my $my_flag=0;

sub my_test0 {
  if ($my_flag) { print "hello\n" };
}

sub my_test1 {
  my $a=0;
  for my $i (1..100) {
    if ($my_flag) { print "hello\n" };
    $a+=$i;
  }
}

sub my_test2 {
  my $a=0;
  for my $i (1..10000) {
    if ($my_flag) { print "hello\n" };
    $a+=$i;
  }
}

sub stacked0 () {
  if (cte_flag) {
    print "hello";
  }
}

sub stacked1 () {
  stacked0;
}

sub stacked2 () {
  stacked1;
}

use Benchmark qw(:all);

disablecache();

print "Test 0\n";
cmpthese (10_000_000,
	  { Constant => \&cte_test0,
	    Our      => \&our_test0,
	    My       => \&my_test0 });

print "\nTest 1\n";
cmpthese (-10,
	  { Constant => \&cte_test1,
	    Our      => \&our_test1,
	    My       => \&my_test1 });

print "\nTest 2\n";
cmpthese (-10,
	  { Constant => \&cte_test2,
	    Our      => \&our_test2,
	    My       => \&my_test2 });
