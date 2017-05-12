#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Config;
use Data::Dumper;

$loaded = 1;
print "ok 1\n";

tie %hash, 'Tie::Config', "t/foo.txt", O_RDWR;

print Data::Dumper->Dump([\%hash],[qw(*hash)]);

print "not " if $hash{new} eq 'rdonly';
print "ok 2\n";

undef %hash;

$hash{anykey} = 'anyval';


untie %hash;


tie %hash, 'Tie::Config', "t/foo.txt";

print Data::Dumper->Dump([\%hash],[qw(*hash)]);

print "not " unless ( $hash{anykey} eq 'anyval' );
print "ok 3\n";

print "not " unless unlink("t/foo.txt");
print "ok 4\n";
