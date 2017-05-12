#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use X500::DN::Marpa::DN;
use X500::DN::Marpa::RDN;

# -----------------------

my($test_count) = 0;
my($dn)         = X500::DN::Marpa::DN -> new;

isa_ok($dn, 'X500::DN::Marpa::DN', '$dn'); $test_count++;

# Test set 1.

my($text) = '';

diag "Parsing: $text.";

$dn -> ParseRFC2253($text);

ok($dn -> getRDNs          == 0,         'dn.getRDNs() works');          $test_count++;
ok($dn -> getRFC2253String eq $text,     'dn.getRFC2253String() works'); $test_count++;
ok($dn -> getX500String    eq "{$text}", 'dn.getX500String() works');    $test_count++;

# Test set 2.

$text = '1.4.9=2001';

diag "Parsing: $text.";

$dn -> ParseRFC2253($text);

ok($dn -> getRDNs          == 1,         'dn.getRDNs() works');          $test_count++;
ok($dn -> getRFC2253String eq $text,     'dn.getRFC2253String() works'); $test_count++;
ok($dn -> getX500String    eq "{$text}", 'dn.getX500String() works');    $test_count++;

my($rdn) = $dn -> getRDN(0);

isa_ok($rdn, 'X500::DN::Marpa::RDN', '$rdn'); $test_count++;

my $type_count = $rdn -> getAttributeTypes;
my(@types)     = $rdn -> getAttributeTypes;

ok($type_count == 1,       'rdn.getAttributeTypes() works');  $test_count++;
ok($types[0]   eq '1.4.9', 'rdn.getAttributeTypes() works');  $test_count++;

my $value   = $rdn -> getAttributeValue('1.4.9');
my(@values) = $rdn -> getAttributeValue('1.4.9');

ok($value     eq '2001', 'rdn.getAttributeValue() works');  $test_count++;
ok($values[0] eq '2001', 'rdn.getAttributeValue() works');  $test_count++;

my($has_multi) = $dn -> hasMultivaluedRDNs;

ok($has_multi == 0, 'dn.hasMultivaluedRDNs() works'); $test_count++;

# Test set 3.

$text = 'foo=FOO + bar=BAR + frob=FROB, baz=BAZ';

diag "Parsing: $text.";

$dn -> ParseRFC2253($text);

ok($dn -> getRDNs          == 2,                                     'dn.getRDNs() works');          $test_count++;
ok($dn -> getRFC2253String eq "baz=BAZ,foo=FOO+bar=BAR+frob=FROB",   'dn.getRFC2253String() works'); $test_count++;
ok($dn -> getX500String    eq "{foo=FOO+bar=BAR+frob=FROB+baz=BAZ}", 'dn.getX500String() works');    $test_count++;

$rdn = $dn -> getRDN(0);

isa_ok($rdn, 'X500::DN::Marpa::RDN', '$rdn'); $test_count++;

$type_count = $rdn -> getAttributeTypes;
@types      = $rdn -> getAttributeTypes;

ok($type_count == 3,     'rdn.getAttributeTypes() works'); $test_count++;
ok($types[0]   eq 'foo', 'rdn.getAttributeTypes() works'); $test_count++;
ok($types[1]   eq 'bar', 'rdn.getAttributeTypes() works'); $test_count++;

@values = $rdn -> getAttributeValue('foo');

ok($values[0] eq 'FOO+bar=BAR+frob=FROB', 'getAttributeValue() works'); $test_count++;

$has_multi = $dn -> hasMultivaluedRDNs;

ok($has_multi == 1, 'hasMultivaluedRDNs() works'); $test_count++;

$rdn = $dn -> getRDN(1);

isa_ok($rdn, 'X500::DN::Marpa::RDN', '$rdn'); $test_count++;

@values = $rdn -> getAttributeValue('baz');

ok($values[0] eq 'BAZ', 'getAttributeValue() works'); $test_count++;

print "# Internal test count: $test_count\n";

done_testing($test_count);
