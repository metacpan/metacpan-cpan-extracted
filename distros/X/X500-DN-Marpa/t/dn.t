#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use X500::DN::Marpa ':constants';

# -----------

my($test_count)  = 0;
my($parser)      = X500::DN::Marpa -> new;
my(@text)        =
(
	[
		0,
		1,
		q||,
		q||,
		q||,
		q||,
		q||,
		q|x|, # Deliberate error.
	],
	[
		0,
		0,
		q||,
		q||,
		q||,
		q||,
		q||,
		q||,
	],
	[
		1,
		1,
		q|x=|,
		q|x=|,
		q|x|,
		q||,
		q|x=|,
		q|x=|, # No error.
	],
	[
		1,
		1,
		q|x=|,
		q|x=|,
		q|x|,
		q||,
		q|x=|,
		q|x= |, # No error.
	],
	[
		1,				# 0: rdn_number().
		1,				# 1: rdn_count(1).
		q|1.4.9=2001|,	# 2: rdn(1) aka type 1 = value 1.
		q|1.4.9=2001|,	# 3: openssl_dn().
		q|1.4.9|,		# 4: rdn_types(1).
		q|2001|,		# 5: rdn_values(?).
		q|1.4.9=2001|,	# 6: dn().
		q|1.4.9=2001|,	# 7: DN aka test data.
	],
	[
		2,
		1,
		q|cn=Nemo|,
		q|cn=Nemo+c=US|,
		q|cn|,
		q|US|,
		q|c=US,cn=Nemo|,
		q|cn=Nemo,c=US|,
	],
	[
		2,
		1,
		q|cn=Nemo|,
		q|cn=Nemo+c=US|,
		q|cn|,
		q|US|,
		q|c=US,cn=Nemo|,
		q|cn=Nemo, c=US|,
	],
	[
		2,
		1,
		q|cn=Nemo|,
		q|cn=Nemo+c=US|,
		q|cn|,
		q|US|,
		q|c=US,cn=Nemo|,
		q|cn = Nemo, c = US|,
	],
	[
		3,
		1,
		q|cn=John Doe|,
		q|cn=John Doe+o=Acme+c=US|,
		q|cn|,
		q|US|,
		q|c=US,o=Acme,cn=John Doe|,
		q|cn=John Doe, o=Acme, c=US|,
	],
	[
		3,
		1,
		q|cn=John Doe|,
		q|cn=John Doe+o=Acme\, Inc.+c=US|,
		q|cn|,
		q|US|,
		q|c=US,o=Acme\, Inc.,cn=John Doe|,
		q|cn=John Doe, o=Acme\, Inc., c=US|,
	],
	[
		1,
		1,
		q|x=\ |,
		q|x=\ |,
		q|x|,
		q|\ |,
		q|x=\ |,
		q|x=\ |,
	],
	[
		1,
		1,
		q|x=\ |,
		q|x=\ |,
		q|x|,
		q|\ |,
		q|x=\ |,
		q|x = \ |,
	],
	[
		1,
		1,
		q|x=\ \ |,
		q|x=\ \ |,
		q|x|,
		q|\ \ |,
		q|x=\ \ |,
		q|x=\ \ |,
	],
	[
		1,
		1,
		q|x=\#\"\41|,
		q|x=\#\"\41|,
		q|x|,
		q|\#\"\41|,
		q|x=\#\"\41|,
		q|x=\#\"\41|,
	],
	[
		1,
		1,
		q|x=abc|,
		q|x=abc|,
		q|x|,
		q|abc|,
		q|x=abc|,
		q|x=#616263|,
	],
	[
		1,
		1,
		q|sn=Lu\C4\8Di\C4\87|,
		q|sn=Lu\C4\8Di\C4\87|,
		q|sn|,
		q|Lu\C4\8Di\C4\87|,
		q|sn=Lu\C4\8Di\C4\87|,
		q|SN=Lu\C4\8Di\C4\87|, # 'Lučić'.
	],
	[
		2,
		3,
		q|foo=FOO+bar=BAR+frob=FROB|,
		q|foo=FOO+bar=BAR+frob=FROB+baz=BAZ|,
		q|foo bar frob|,
		q|BAZ|,
		q|baz=BAZ,foo=FOO+bar=BAR+frob=FROB|,
		q|foo=FOO + bar=BAR + frob=FROB, baz=BAZ|,
	],
	[
		3,
		1,
		q|uid=jsmith|,
		q|uid=jsmith+dc=example+dc=net|,
		q|uid|,
		q|example net|,
		q|dc=net,dc=example,uid=jsmith|,
		q|UID=jsmith,DC=example,DC=net|
	],
	[
		3,
		2,
		q|ou=Sales+cn=J. Smith|,
		q|ou=Sales+cn=J. Smith+dc=example+dc=net|,
		q|ou cn|,
		q|example net|,
		q|dc=net,dc=example,ou=Sales+cn=J. Smith|,
		q|OU=Sales+CN=J. Smith,DC=example,DC=net|,
	],
	[
		3,
		1,
		q|cn=James \"Jim\" Smith\, III|,
		q|cn=James \"Jim\" Smith\, III+dc=example+dc=net|,
		q|cn|,
		q|example net|,
		q|dc=net,dc=example,cn=James \"Jim\" Smith\, III|,
		q|CN=James \"Jim\" Smith\, III,DC=example,DC=net|,
	],
	[
		3,
		1,
		q|cn=Before\0dAfter|,
		q|cn=Before\0dAfter+dc=example+dc=net|,
		q|cn|,
		q|example net|,
		q|dc=net,dc=example,cn=Before\0dAfter|,
		q|CN=Before\0dAfter,DC=example,DC=net|,
	],
	[
		3,
		1,
		q|uid=nobody@example.com|,
		q|uid=nobody@example.com+dc=example+dc=com|,
		q|uid|,
		q|example com|,
		q|dc=com,dc=example,uid=nobody@example.com|,
		q|UID=nobody@example.com,DC=example,DC=com|,
	],
	[
		6,
		1,
		q|cn=John Smith|,
		q|cn=John Smith+ou=Sales+o=ACME Limited+l=Moab+st=Utah+c=US|,
		q|cn|,
		q|US|,
		q|c=US,st=Utah,l=Moab,o=ACME Limited,ou=Sales,cn=John Smith|,
		q|CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US|,
	],
);

$parser -> options(return_hex_as_chars);

my($dn);
my($get_dn, $get_count, $get_number, $get_rdn, $get_type, $get_types, $get_value, $get_values, $get_openssl_dn);
my($openssl_dn);
my($result, $rdn, $rdn_count, $rdn_number);
my($text, $type, $types, @temp);
my($value, $values);

for my $item (@text)
{
	$test_count++;

	$rdn_number     = $$item[0];
	$rdn_count      = $$item[1];
	$rdn            = $$item[2];
	($type, $value) = split(/=/, $rdn, 2);
	$type           = '' if (! defined $type);
	$value          = '' if (! defined $value);
	$openssl_dn     = $$item[3];
	$types          = $$item[4];
	$values         = $$item[5];
	$dn             = $$item[6];
	$text           = $$item[7];
	$result         = $parser -> parse($text);

	# We have to determine what parameter to pass to get_values($type).
	# Let's break up the OpenSSL DN and use the last RDN's type.
	# We end up with the wanted $type in $temp[0].

	@temp = split(/\+/, $openssl_dn);
	@temp = $#temp >= 0 ? split(/=/, $temp[$#temp]) : (''); # Special code for very 1st test case.

	if ($test_count == 1)
	{
		ok($result == 1, "Failed deliberate error: |$text|");
	}
	else
	{
		ok($result == 0, "Parsed: |$text|");
	}

	if ($result == 0)
	{
		$get_dn         = $parser -> dn;
		$get_openssl_dn = $parser -> openssl_dn;
		$get_rdn        = $parser -> rdn(1);
		$get_count      = $parser -> rdn_count(1);
		$get_number     = $parser -> rdn_number;
		$get_type       = $parser -> rdn_type(1);
		$get_types      = join(' ', $parser -> rdn_types(1) );
		$get_value      = $parser -> rdn_value(1);
		$get_values     = join(' ', $parser -> rdn_values($temp[0]) );

		ok($dn         eq $get_dn,         'dn() works');          $test_count++;
		ok($openssl_dn eq $get_openssl_dn, 'openssl_dn() works');  $test_count++;
		ok($rdn        eq $get_rdn,        'rdn(1) works');        $test_count++;
		ok($rdn_count  == $get_count,      'rdn_count(1) works');  $test_count++;
		ok($rdn_number == $get_number,     'rdn_number() works');  $test_count++;
		ok($type       eq $get_type,       'rdn_type(1) works');   $test_count++;
		ok($types      eq $get_types,      'rdn_types(1) works');  $test_count++;
		ok($value      eq $get_value,      'rdn_value(1) works');  $test_count++;
		ok($values     eq $get_values,     'rdn_values(x) works'); $test_count++;
	}
}

$text    = 'CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US';
$result  = $parser -> parse($text);
my(@rdn) = split(/,/, $text);

my(@values);

for my $rdn (@rdn)
{
	($type, $value) = split(/=/, $rdn);
	@values         = $parser -> rdn_values($type);

	ok($value eq $values[0], "rdn_value($type) works"); $test_count++;
}

$text   = 'UID=nobody@example.com,DC=example,DC=com';
$result = $parser -> parse($text);
@rdn    = $parser -> rdn_values('DC');

ok($rdn[0] eq 'example', 'rdn_values(DC) works'); $test_count++;
ok($rdn[1] eq 'com',     'rdn_values(DC) works'); $test_count++;

print "# Internal test count: $test_count\n";

done_testing($test_count);
