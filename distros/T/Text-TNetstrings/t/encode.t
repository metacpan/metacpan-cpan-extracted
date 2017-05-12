#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 32;

BEGIN {
	use_ok("Text::TNetstrings", qw(:all))
		or BAIL_OUT("unable to import Text::TNetstrings");
};

if(defined($INC{'Text/TNetstrings/XS.pm'})) {
	diag("Using XS version of Text::TNetstrings");
} else {
	diag("Using pure-Perl version of Text::TNetstrings");
}

{
	my $null = undef;
	my $encoded = encode_tnetstrings($null);
	my $given = "Given a null value, when the null value is encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, 0, $given .
		"then the length should be zero");
	is($data, '', $given .
		"then the data field should be empty");
	is($type, '~', $given .
		"then the type indicator should be '~'");
}

SKIP: {
	eval {require boolean};
	skip "boolean is not installed", 4 if $@;

	my $boolean = boolean::true();
	my $encoded = encode_tnetstrings($boolean);
	my $given = "Given a boolean value, when the boolean value is true and encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, 4, $given .
		"then the length should be 4");
	is($data, 'true', $given .
		"then the data field should be \"true\"");
	is($type, '!', $given .
		"then the type indicator should be '!'");
}

{
	my $string = "hello";
	my $encoded = encode_tnetstrings($string);
	my $given = qq(Given a string "$string", when the string is encoded, );
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, length($string), $given .
		"then the length should be " . length($string));
	is($data, $string, $given .
		"then the data field should be the same as the string");
	is($type, ',', $given .
		"then the type indicator should be ','");
}

{
	my $string = "hel\0lo";
	my $encoded = encode_tnetstrings($string);
	my $given = qq(Given a string "$string", ) .
		"when the string is encoded, " .
		"and the string contains a NULL byte, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, length($string), $given .
		"then the length should be " . length($string));
	is($data, $string, $given .
		"then the data field should be the same as the string");
}

{
	my $number = 42;
	my $encoded = encode_tnetstrings($number);
	my $given = qq(Given an integer $number, when the integer is encoded, );
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, length($number), $given .
		"then the length should be " . length("$number"));
	is($data, $number, $given .
		"then the data field should be the same as the number");
	is($type, '#', $given .
		"then the type indicator should be '#'");
}

{
	my $float = 3.14159265;
	my $encoded = encode_tnetstrings($float);
	my $given = qq(Given a float $float, when the float is encoded, );
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	is($length, length($float), $given .
		"then the length should be " . length("$float"));
	is($data, $float, $given .
		"then the data field should be the same as the float");
	is($type, '^', $given .
		"then the type indicator should be '^'");
}

{
	my $array = ["hello", 42];
	my $encoded = encode_tnetstrings($array);
	my $given = "Given a flat array [" . join(', ', @$array) . "], when the array is encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $encoded_elements = join('', map {encode_tnetstrings($_)} @$array);
	is($length, length($encoded_elements), $given .
		"then the length should be equal to the length of its elements");
	is($data, $encoded_elements, $given .
		"then the data field should contain the encoded elements of the array");
	is($type, ']', $given .
		"then the type indicator should be ']'");
}

{
	my $hash = {"hello" => 42};
	my $encoded = encode_tnetstrings($hash);
	my $hash_str = join(', ', map {"$_: " . $hash->{$_}} keys(%$hash));
	my $given = "Given a flat hash [$hash_str], when the hash is encoded, ";
	isnt($encoded, undef, $given .
		"then the result should be defined");
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $encoded_elements = '';
	while(my ($key, $value) = each(%$hash)) {
		$encoded_elements .= encode_tnetstrings($key);
		$encoded_elements .= encode_tnetstrings($value);
	}
	is($length, length($encoded_elements), $given .
		"then the length should be equal to the length of its elements");
	is($data, $encoded_elements, $given .
		"then the data field should contain the encoded pairs of the hash");
	is($type, '}', $given .
		"then the type indicator should be '}'");
}

