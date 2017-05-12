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

my %benchmarks;

{
	my $encoded = Text::TNetstrings::PP::encode_tnetstrings($structure);
	$benchmarks{'TNetstrings::PP'} = sub {Text::TNetstrings::PP::decode_tnetstrings($encoded)},
}

eval {
	require Text::TNetstrings::XS;
	my $encoded = Text::TNetstrings::XS::encode_tnetstrings($structure);
	$benchmarks{'TNetstrings::XS'} = sub{Text::TNetstrings::XS::decode_tnetstrings($encoded)};
} or warn "Unable to require Text::TNetstrings::XS";

eval {
	require JSON::PP;
	my $encoded = JSON::PP::encode_json($structure);
	$benchmarks{'JSON::PP'} = sub{JSON::PP::decode_json($encoded)};
} or warn "Unable to require JSON::PP";

eval {
	require JSON::XS;
	my $encoded = JSON::XS::encode_json($structure);
	$benchmarks{'JSON::XS'} = sub{JSON::XS::decode_json($encoded)};
} or warn "Unable to require JSON::XS";

eval {
	require Convert::Bencode;
	my $encoded = Convert::Bencode::bencode($structure);
	$benchmarks{'Convert::Bencode'} = sub{Convert::Bencode::bdecode($encoded)};
} or warn "Unable to require Convert::Bencode";

eval {
	require Convert::Bencode_XS;
	my $encoded = Convert::Bencode_XS::bencode($structure);
	$benchmarks{'Convert::Bencode_XS'} = sub{Convert::Bencode_XS::bdecode($encoded)};
} or warn "Unable to require Convert::Bencode_XS";

cmpthese(-5, \%benchmarks);

