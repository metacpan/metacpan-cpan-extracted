#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 3 }

$ref = new Text::Scan;

ok( ! $ref->restore("testdump") );

print "States: ", $ref->states,
	"\nTransitions: ", $ref->transitions,
	"\nTerminals: ", $ref->terminals, "\n";

ok( @keys = $ref->keys );

print "KEYS:\n";
print join("\n", @keys);
print "\n";


ok( @vals = $ref->values );

print "VALUES:\n";
print join("\n", @vals);
print "\n";

exit 0;

