#!/usr/bin/env perl

use strict;
use warnings;

use X500::DN::Marpa ':constants';

# -----------

my(%count)  = (fail => 0, success => 0, total => 0);
my($parser) = X500::DN::Marpa -> new;
my(@text)   =
(
	q|cn=Nemo, c=US|,
	q|cn=Nemo, c=US|,
	q|x=#616263|,
	q|x=#616263|,
	q|foo=FOO + bar=BAR + frob=FROB, baz=BAZ|,
	q|UID=12345, OU=Engineering, CN=Kurt Zeilenga+L=Redwood Shores|,
	q|x=\#\"\41|,
);

my($result);

for my $text (@text)
{
	$count{total}++;

	print sprintf('(# %3d) | ', $count{total});
	printf '%10d', $_ for (1 .. 9);
	print "\n";
	print '        |';
	print '0123456789' for (0 .. 8);
	print "0\n";
	print "Parsing |$text|. \n";

	$result = $parser -> parse($text);

	print "Parse result: $result (0 is success)\n";

	if ($result == 0)
	{
		$count{success}++;

		for my $item ($parser -> stack -> print)
		{
			print "RDN:        $$item{type}=$$item{value}. count = $$item{count}. \n";
		}

		print 'DN:         ', $parser -> dn, ". \n";
		print 'OpenSSL DN: ', $parser -> openssl_dn, ". \n";
	}

	# Change the options after the 1st parse...

	$parser -> options(long_descriptors);
	$parser -> options(return_hex_as_chars) if ($count{total} == 3);
}

$count{fail} = $count{total} - $count{success};

print "\n";
print 'Statistics: ', join(', ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
