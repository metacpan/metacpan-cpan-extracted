#!/usr/bin/perl

use strict;
use warnings;
use Text::TNetstrings::PP;
use Benchmark qw(cmpthese);

my $structure = {
	'hello' => 'world',
	'array' => [40,'two'],
	'hash' => {
		'eggs' => 'spam',
	},
	'light' => 299792458,
	'pi' => 3.14,
	'null' => undef,
};

my %benchmarks = (
	'TNetstrings::PP' => sub {Text::TNetstrings::PP::encode_tnetstrings($structure)},
);

eval {
	require Text::TNetstrings::XS;
	$benchmarks{'TNetstrings::XS'} = sub{Text::TNetstrings::XS::encode_tnetstrings($structure)};
} or warn "Unable to require Text::TNetstrings::XS";

eval {
	require JSON::PP;
	$benchmarks{'JSON::PP'} = sub{JSON::PP::encode_json($structure)};
} or warn "Unable to require JSON::PP";

eval {
	require JSON::XS;
	$benchmarks{'JSON::XS'} = sub{JSON::XS::encode_json($structure)};
} or warn "Unable to require JSON::XS";

eval {
	require Convert::Bencode;
	$benchmarks{'Convert::Bencode'} = sub{Convert::Bencode::bencode($structure)};
} or warn "Unable to require Convert::Bencode";

eval {
	require Convert::Bencode_XS;
	$benchmarks{'Convert::Bencode_XS'} = sub{Convert::Bencode_XS::bencode($structure)};
} or warn "Unable to require Convert::Bencode_XS";

cmpthese(-5, \%benchmarks);

