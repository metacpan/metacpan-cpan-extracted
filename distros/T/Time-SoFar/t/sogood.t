#!/usr/bin/perl -w

BEGIN{ 
$ntest = 11;
print "1..$ntest\n";
}

use Time::SoFar qw( runtime runinterval figuretimes );

sub okay ($$$) {
  my $num = shift;
  my $ok  = shift;
  my $mess = shift;

  print 'not ' unless $ok;
  print "ok $num\n";
  print STDERR $mess."\n" unless $ok;
} # end &okay 

sub arraymatch($$) {
  my $ref1 = shift;
  my $ref2 = shift;

  return 0 if @$ref1 != @$ref2;
  for ($i = 0; $i < @$ref1; $i++) {
    return 0 unless $$ref1[$i] eq $$ref2[$i];
  }
  return 1;
} # end &arraymatch

$" = ", ";

print "ok 1\n";

$expect = q<0:00>;
$got    = scalar runinterval();
okay(2, $expect eq $got, "$expect eq $got");

sleep 5;
$expect = q<0:05>;
$got    = scalar runinterval();
okay(3, $expect eq $got, "$expect eq $got");

sleep 2;
@expect = (0, 2);
@got    = runinterval();
okay(4, arraymatch(\@expect, \@got), "arraymatch([@expect], [@got])");

$expect = q<0:07>;
$got    = scalar runtime();
okay(5, $expect eq $got, "$expect eq $got");

$expect = q<0:00>;
$got    = scalar runinterval();
okay(6, $expect eq $got, "$expect eq $got");

sleep 1;
$expect = q<0:00:00:01>;
$got    = scalar runinterval(1);
okay(7, $expect eq $got, "$expect eq $got");

$expect = q<0:00:00:08>;
$got    = scalar runtime(1);
okay(8, $expect eq $got, "$expect eq $got");

$expect = q<1:00:00:01>;
$got    = scalar figuretimes(86401);
okay(9, $expect eq $got, "$expect eq $got");

@expect = (1, 0, 2);
@got    = figuretimes(3602);
okay(10, arraymatch(\@expect, \@got), "arraymatch([@expect], [@got])");

@expect = (0, 1, 0, 2);
@got    = figuretimes(3602,1);
okay(11, arraymatch(\@expect, \@got), "arraymatch([@expect], [@got])");

