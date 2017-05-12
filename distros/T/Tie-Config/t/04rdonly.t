#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Config;
use Data::Dumper;

$loaded = 1;
print "ok 1\n";

### default read only access
tie %hash, 'Tie::Config', "t/foo.txt";

$hash{new} = 'rdonly';

print "not " if $hash{new} eq 'rdonly';
print "ok 2\n";
