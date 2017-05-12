#!/usr/bin/perl

# Test the Carp methods

use Test::More tests => 4;
use Throw qw(croak confess carp cluck);


eval { croak "\x1bmsg\n"; };
my $e = $@;
cmp_ok(ref $e, 'eq', 'Throw', "Throw::croak() ref check");
ok($e =~ /^\x1bmsg/, "Throw::croak()");


eval { confess "\x1bmsg\n"; };
$e = $@;
cmp_ok(ref $e, 'eq', 'Throw', "Throw::confess() ref check");
ok($e =~ /^\x1bmsg/, "Throw::confess()");
