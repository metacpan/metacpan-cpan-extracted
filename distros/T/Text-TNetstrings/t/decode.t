#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 25;

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
	my $encoded = "0:~";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	is($decoded, undef,
		"Given an encoded TNetstring, " .
		"and the TNetstring contains a null value, " .
		"when the null value is decoded, " .
		"then the decoded value should be undefined");
}

{
	my $encoded = "5:hello,";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the string \"hello\", " .
		"when the string is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, "hello", $given .
		"then the decoded value should be the string \"hello\"");
}

{
	my $encoded = "6:he\0llo,";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the string, " .
		"and the string contains a null byte, " .
		"when the string is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, $data, $given .
		"then the null byte should not be processed in any special way");
}

{
	my $encoded = "2:42#";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the integer 42, " .
		"when the integer is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, 42, $given .
		"then the decoded value should be the integer 42");
}

{
	my $encoded = "3:-42#";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the negative integer -42, " .
		"when the integer is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, -42, $given .
		"then the decoded value should be the negative integer -42");
}

{
	my $encoded = "10:3.14159265^";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the float 3.14159265, " .
		"when the float is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is("$decoded", "3.14159265", $given .
		"then the decoded value should be the float 3.14159265");
}

{
	my $encoded = "11:-3.14159265^";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the negative float -3.14159265, " .
		"when the float is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is("$decoded", "-3.14159265", $given .
		"then the decoded value should be the negative float -3.14159265");
}

{
	my $encoded = "4:true!";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the boolean true, " .
		"when the boolean is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	ok($decoded, $given .
		"then the decoded value should be boolean true");
}

{
	my $encoded = "5:false!";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the boolean false, " .
		"when the boolean is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	ok(!$decoded, $given .
		"then the decoded value should be boolean false");
}

{
	my $encoded = "18:2:32#2:84#5:hello,]";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the array [32, 84, \"hello\"], " .
		"when the array is decoded, ";
	is(ref($decoded), 'ARRAY', $given .
		"then the decoded value should be an array");
	is_deeply($decoded, [32, 84, "hello"], $given .
		"then the decoded value should be the array [32, 84, \"hello\"]");
}

{
	my $encoded = "16:1:a,1:1#1:b,1:2#}";
	$encoded =~ m/^(\d+):(.*)(.)$/;
	my ($length, $data, $type) = ($1, $2, $3);
	my $decoded = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the hash {a => 1, b => 2}, " .
		"when the hash is decoded, ";
	is(ref($decoded), 'HASH', $given .
		"then the decoded value should be a hash");
	is_deeply($decoded, {"a" => 1, "b" => 2}, $given .
		"then the decoded value should be the hash {a => 1, b => 2}");
}

{
	my $encoded = "5:hello,other irrelevant text";
	my ($decoded, $rest) = decode_tnetstrings($encoded);
	my $given = "Given an encoded TNetstring, " .
		"and the TNetstring contains the string \"hello\", " .
		"and other data follows the TNetstring, " .
		"when the string is decoded, ";
	is(ref($decoded), '', $given .
		"then the decoded value should be a scalar");
	is($decoded, "hello", $given .
		"then the decoded value should be the string \"hello\"");
	is($rest, "other irrelevant text", $given .
		"then the remaining data should be returned");
}

