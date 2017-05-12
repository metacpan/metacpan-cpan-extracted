#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Config;
use Data::Dumper;

$loaded = 1;
print "ok 1\n";

tie %hash, 'Tie::Config', "t/foo.txt", O_RDWR;

print Data::Dumper->Dump([\%hash],[qw(*hash)]);

print $hash{numeric} == 1 ? '' : 'not ', "ok 2\n";
print $hash{second} eq 'param' ? '' : 'not ', "ok 3\n";
print $hash{nula} == 0 ? '' : 'not ', "ok 4\n";

$hash{new} = 'write';
