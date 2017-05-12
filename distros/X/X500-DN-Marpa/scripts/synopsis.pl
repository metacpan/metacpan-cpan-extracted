#!/usr/bin/env perl

use strict;
use warnings;

use X500::DN::Marpa ':constants';

# -----------

my(%count)  = (fail => 0, success => 0, total => 0);
my($parser) = X500::DN::Marpa -> new;
my(@text)   =
(
	q|x=#616263|,
	q|foo=FOO + bar=BAR + frob=FROB, baz=BAZ|,
	q|CN=James \"Jim\" Smith\, III,DC=example,DC=net|,
);

$parser -> options(return_hex_as_chars);

my(%expected) =
(
	1 =>
		{
			dn         => 'x=abc',
			rdn        => 'x=abc',
			rdn_count  => 1, # For RDN(1).
			rdn_number => 1,
			rdn_type   => 'x',
			rdn_types  => 'x',
			rdn_value  => 'abc',
			rdn_values => 'abc',
			values_for => 'x',
		},
	2 =>
		{
			dn         => 'baz=BAZ,foo=FOO+bar=BAR+frob=FROB',
			rdn        => 'foo=FOO+bar=BAR+frob=FROB',
			rdn_count  => 3, # For RDN(1).
			rdn_number => 2,
			rdn_type   => 'foo',
			rdn_types  => 'foo bar frob',
			rdn_value  => 'FOO+bar=BAR+frob=FROB',
			rdn_values => 'FOO+bar=BAR+frob=FROB',
			values_for => 'foo',
		},
	3 =>
		{
			dn         => 'dc=net,dc=example,cn=James \"Jim\" Smith\, III',
			rdn        => 'cn=James \"Jim\" Smith\, III',
			rdn_count  => 1, # For RDN(1).
			rdn_number => 3,
			rdn_type   => 'cn',
			rdn_types  => 'cn',
			rdn_value  => 'James \"Jim\" Smith\, III',
			rdn_values => 'example & net',
			values_for => 'dc',
		},
);

my($dn);
my($get_count, $get_number, $get_rdn, $get_type, $get_types, $get_value, @get_values, $get_openssl_dn);
my($result);
my($text);

for my $text (@text)
{
	$count{total}++;

	print "# $count{total}. Parsing: $text\n";

	$result = $parser -> parse($text);

	if ($result == 0)
	{
		$count{success}++;

		$dn             = $parser -> dn;
		$get_openssl_dn = $parser -> openssl_dn;
		$get_rdn        = $parser -> rdn(1);
		$get_count      = $parser -> rdn_count(1);
		$get_number     = $parser -> rdn_number;
		$get_type       = $parser -> rdn_type(1);
		$get_types      = join(' ', $parser -> rdn_types(1) );
		$get_value      = $parser -> rdn_value(1);
		@get_values     = $parser -> rdn_values($expected{$count{total} }{values_for});

		print "dn():         $dn (Expected: $expected{$count{total} }{dn})\n";
		print "rdn(1):       $get_rdn (Expected: $expected{$count{total} }{rdn})\n";
		print "rdn_count(1): $get_count (Expected: $expected{$count{total} }{rdn_count})\n";
		print "rdn_number(): $get_number (Expected: $expected{$count{total} }{rdn_number})\n";
		print "rdn_type(1):  $get_type (Expected: $expected{$count{total} }{rdn_type})\n";
		print "rdn_types(1): $get_types (Expected: $expected{$count{total} }{rdn_types})\n";
		print "rdn_value(1): $get_value (Expected: $expected{$count{total} }{rdn_value})\n";
		print "rdn_values($expected{$count{total} }{values_for}): ", join(' & ', @get_values), " (Expected: $expected{$count{total} }{rdn_values})\n";
	}

	print '-' x 50, "\n";
}

$count{fail} = $count{total} - $count{success};

print "\n";
print 'Statistics: ', join(', ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
