use 5.10.1;
use strict;
use warnings;

use Test::More;

BEGIN {
	eval {
		require JSON;
		plan tests=>10;
		1;
	} or so {
		plan skip_all => "JSON not installed";
	};
}

BEGIN { use_ok( 'Zeek::Log::Parse' ); }

my $parse = Zeek::Log::Parse->new('logs/x509.json');

is(join(",", sort @{$parse->{fields}}), "basic_constraints.ca,certificate.exponent,certificate.issuer,certificate.key_alg,certificate.key_length,certificate.key_type,certificate.not_valid_after,certificate.not_valid_before,certificate.serial,certificate.sig_alg,certificate.subject,certificate.version,id,san.dns,ts", "read fields");
is(scalar @{$parse->{headerlines}}, 0, "no headers");
is(scalar keys %{$parse->{headers}}, 0, "no headers");

my $line = $parse->getLine();
is(join(",", sort @{$parse->{fields}}), "basic_constraints.ca,certificate.exponent,certificate.issuer,certificate.key_alg,certificate.key_length,certificate.key_type,certificate.not_valid_after,certificate.not_valid_before,certificate.serial,certificate.sig_alg,certificate.subject,certificate.version,id,san.dns,ts", "read fields");
is(scalar keys %$line, 15, "Number of entries");
is($line->{ts}, '1398362902.71211', "ts");
is($line->{id}, 'Fcrbf41pfftsHhnUv9', "id");
is($parse->{line}."\n", <<LINE, "line");
{"ts":1398362902.712109,"id":"Fcrbf41pfftsHhnUv9","certificate.version":3,"certificate.serial":"5F16E91E8E863F49","certificate.subject":"CN=*.google.de,O=Google Inc,L=Mountain View,ST=California,C=US","certificate.issuer":"CN=Google Internet Authority G2,O=Google Inc,C=US","certificate.not_valid_before":1397070465.0,"certificate.not_valid_after":1404802800.0,"certificate.key_alg":"rsaEncryption","certificate.sig_alg":"sha1WithRSAEncryption","certificate.key_type":"rsa","certificate.key_length":2048,"certificate.exponent":"65537","san.dns":["*.google.de","google.de"],"basic_constraints.ca":false}
LINE

$line = $parse->getLine();
$line = $parse->getLine();
$line = $parse->getLine();
is($line, undef, 'EOF');
