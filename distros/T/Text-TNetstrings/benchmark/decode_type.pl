#!/usr/bin/perl

use strict;
use warnings;
use Text::TNetstrings::PP;
use Benchmark qw(cmpthese);

my %benchmarks = (
	#'TNetstrings::PP int' => sub {Text::TNetstrings::PP::decode_tnetstrings("4:9627^")},
);

eval {
	require Text::TNetstrings::XS;
	Text::TNetstrings::XS->import('encode_tnetstrings');
	my $array = encode_tnetstrings(["hello", 9627]);
	my $bool = "7:4:true!]";
	my $float = encode_tnetstrings([3.14]);
	my $hash = encode_tnetstrings({"hello" => 9627});
	my $int = encode_tnetstrings([9627]);
	my $null = encode_tnetstrings([undef]);
	my $string = encode_tnetstrings(["hello"]);
	$benchmarks{'TNetstrings::XS int'} = sub {Text::TNetstrings::XS::decode_tnetstrings($int)};
	$benchmarks{'TNetstrings::XS bool'} = sub {Text::TNetstrings::XS::decode_tnetstrings($bool)};
	$benchmarks{'TNetstrings::XS float'} = sub {Text::TNetstrings::XS::decode_tnetstrings($float)};
	$benchmarks{'TNetstrings::XS string'} = sub {Text::TNetstrings::XS::decode_tnetstrings($string)};
	$benchmarks{'TNetstrings::XS hash'} = sub {Text::TNetstrings::XS::decode_tnetstrings($hash)};
	$benchmarks{'TNetstrings::XS array'} = sub {Text::TNetstrings::XS::decode_tnetstrings($array)};
	$benchmarks{'TNetstrings::XS null'} = sub {Text::TNetstrings::XS::decode_tnetstrings($null)};
} or warn "Unable to require Text::TNetstrings::XS";

#eval {
#	require JSON::PP;
#	$benchmarks{'JSON::PP int'} = sub{JSON::PP::encode_json("9627")};
#} or warn "Unable to require JSON::PP";

eval {
	require JSON::XS;
	JSON::XS->import('encode_json');
	my $array = encode_json(["hello", 9627]);
	my $bool = "[true]";
	my $float = encode_json([3.14]);
	my $hash = encode_json({"hello" => 9627});
	my $int = encode_json([9627]);
	my $null = encode_json([undef]);
	my $string = encode_json(["hello"]);
	$benchmarks{'JSON::XS int'} = sub {JSON::XS::decode_json($int)};
	$benchmarks{'JSON::XS bool'} = sub {JSON::XS::decode_json($bool)};
	$benchmarks{'JSON::XS float'} = sub {JSON::XS::decode_json($float)};
	$benchmarks{'JSON::XS string'} = sub {JSON::XS::decode_json($string)};
	$benchmarks{'JSON::XS hash'} = sub {JSON::XS::decode_json($hash)};
	$benchmarks{'JSON::XS array'} = sub {JSON::XS::decode_json($array)};
	$benchmarks{'JSON::XS null'} = sub {JSON::XS::decode_json($null)};
} or warn "Unable to require JSON::XS";

cmpthese(-5, \%benchmarks);


