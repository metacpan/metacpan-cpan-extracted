#!/usr/bin/env perl

use strict;
use warnings;

use X500::DN::Marpa::DN;
use X500::DN::Marpa::RDN;

# -----------------------

print "Part 1:\n";

my($dn)   = X500::DN::Marpa::DN -> new;
my($text) = 'foo=FOO + bar=BAR + frob=FROB, baz=BAZ';

$dn -> ParseRFC2253($text);

print "Parsing:     $text\n";
print 'RDN count:   ', $dn -> getRDNs, " (Expected: 2)\n";
print 'DN:          ', $dn -> getRFC2253String, " (Expected: baz=BAZ,foo=FOO+bar=BAR+frob=FROB)\n";
print 'X500 string: ', $dn -> getX500String, " (Expected: {foo=FOO+bar=BAR+frob=FROB+baz=BAZ})\n";
print '-' x 50, "\n";
print "Part 2:\n";

my($rdn)       = $dn -> getRDN(0);
my $type_count = $rdn -> getAttributeTypes;
my(@types)     = $rdn -> getAttributeTypes;

print 'RDN(0):      ', $rdn -> dn, "\n";
print "Type count:  $type_count (Expected: 3)\n";
print "Type [0]:    $types[0] (Expected: foo)\n";
print "Type [1]:    $types[1] (Expected: bar)\n";

my(@values) = $rdn -> getAttributeValue('foo');

print "Value [0]:   $values[0] (Expected: FOO+bar=BAR+frob=FROB)\n";

my($has_multi) = $dn -> hasMultivaluedRDNs;

print "hasMulti:    $has_multi (Expected: 1)\n";
print '-' x 50, "\n";
print "Part 3:\n";

$rdn = $dn -> getRDN(1);

@values = $rdn -> getAttributeValue('baz');

print 'RDN(1):      ', $rdn -> dn, "\n";
print "Value [0]:   $values[0] (Expected: BAZ)\n";
print '-' x 50, "\n";
