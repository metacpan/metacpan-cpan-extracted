#!/usr/bin/perl

use lib '../blib/lib';
use Tie::HashHistory;
use Tie::Hash;

my $o =
tie %h => Tie::HashHistory, Tie::StdHash, '/tmp/testfile', O_CREAT|O_RDWR, 0666
    or die "Couldn't tie file: $!";

print "1..3\n";

$h{a} = 'a1';
$h{a} = 'a2';
$h{b} = 'b1';
$h{a} = 'a3';
$h{b} = 'b2';

$n=1;

@ha = $o->history('a');
print +(("@ha" eq "a3 a2 a1") ? "" : "not "), "ok $n\n";
$n++;

@hb = $o->history('b');
print +(("@hb" eq "b2 b1") ? "" : "not "), "ok $n\n";
$n++;

@k = @k = keys %h;
print +(("@k" eq "a b" || "@k" eq "b a") ? "" : "not "), "ok $n\n";
$n++;

untie %h;

