#!/usr/bin/perl 
use strict;
use warnings;

print "Please type in your name\n";
my $name = <STDIN>;
chomp $name;
print "Hello $name\n";

warn "Some warning\n";
