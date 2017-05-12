#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use WebService::Ooyala;
use JSON::MaybeXS;
use Data::Dumper;
use Test::Deep;

#Test some of the api methods, before allowing a release to happen

if (not $ENV{RELEASE_TESTING}) {
	plan skip_all => 'Set $ENV{RELEASE_TESTING} to run release tests.';
}

my $api_key;
my $secret_key;

my $credentials_file = "$ENV{HOME}/.webservice-ooyala-credentials";

if (-e $credentials_file) {
	open(my $fh, "<", $credentials_file);

	while (my $line = <$fh>) {
		chomp $line;
		my($key, $value) = split(/=/, $line);
		if ($key eq 'api_key') {
			$api_key = $value;
		} elsif ($key eq 'secret_key') {
			$secret_key = $value;
		}
	}

	close $credentials_file;
}

if ($ENV{'WEBSERVICE_OOYALA_API_KEY'}) {
	$api_key = $ENV{'WEBSERVICE_OOYALA_API_KEY'};
}
if ($ENV{'WEBSERVICE_OOYALA_SECRET_KEY'}) {
	$secret_key = $ENV{'WEBSERVICE_OOYALA_SECRET_KEY'};
}

if (not $api_key || not $secret_key) {
	plan skip_all => "Missing either api_key or secret_key";
}

my $ooyala =
	WebService::Ooyala->new({api_key => $api_key, secret_key => $secret_key});

my $assets = $ooyala->get("assets");

my $cases = {
	first_asset => {
		embed_code => re('^[a-zA-Z0-9]+$'),
		asset_type => re('^[a-z]+$'),
		name       => re('[a-zA-Z0-9 ]')
	}
};

isa_ok($assets->{items}, 'ARRAY', "Got an array of items on assets request");
cmp_deeply($assets->{items}[0],
	superhashof($cases->{first_asset}), "Check first asset in assets list");
done_testing;
