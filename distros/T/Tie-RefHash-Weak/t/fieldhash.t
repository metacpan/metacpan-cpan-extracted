#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok("Tie::RefHash::Weak", ':all') };

my $thing = fieldhash my %fieldmouse;

isa_ok(tied %fieldmouse, "Tie::RefHash::Weak", 'tied(%hash)');
is $thing, \%fieldmouse, 'return val of fieldhash';

$thing = fieldhashes \my %hash1, \my %hash2;

isa_ok(tied %hash1, "Tie::RefHash::Weak", '%hash1 tied by fieldhashes()');
isa_ok(tied %hash2, "Tie::RefHash::Weak", '%hash2 tied by fieldhashes()');
is $thing, 2, 'return val of fieldhashes (scalar)';

my(%foo, %bar);

is_deeply [map "$_", fieldhashes\(%foo, %bar)],
          [map "$_",            \(%foo, %bar)],
	'return val of fieldhashes (list)';

