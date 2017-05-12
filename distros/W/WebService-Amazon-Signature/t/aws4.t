use strict;
use warnings;

=pod

Uses the AWS4 testsuite (from L<http://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html>)
to verify that all steps in the signature generation process are correct.

=cut

use Test::More;
use Test::Fatal;
use Encode;
use Path::Tiny qw(path);
use Dir::Self;
use WebService::Amazon::Signature;

my $credential_scope = 'AKIDEXAMPLE/20110909/us-east-1/host/aws4_request';
my $secret_key = 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY';
my $test_path = __DIR__ . '/aws4_testsuite/';

my %tests;
{ # Extract the names of all tests
	opendir my $dir, $test_path or die $!;
	while(my $entry = readdir $dir) {
		$tests{$1} = 1 if $entry =~ /^([\w-]+)\./ && -f "$test_path/$entry";
	}
	closedir $dir or die $!;
}

plan tests => scalar keys %tests;

for my $test_name (sort keys %tests) {
	subtest $test_name => sub {
		# Test suite includes various stages of the signing process,
		# but components vary between tests. We need at least the
		# basic request, the rest are all optional.
		my %paths = map {;
			$_ => $test_path . '/' . $test_name . '.' . $_
		} qw(req creq sts authz sreq);

		die "No request" unless -r $paths{req};
		my %content = map {;
			$_ => path($paths{$_})->slurp_utf8,
		} grep -r $paths{$_}, keys %paths;

		my $amz = new_ok('WebService::Amazon::Signature', [
			version    => 4,
			algorithm  => 'AWS4-HMAC-SHA256',
			access_key => 'AKIDEXAMPLE',
			scope      => '20110909/us-east-1/host/aws4_request',
			secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
		]);
		is(exception {
			$amz->parse_request($content{req})
		}, undef, 'can parse request without exceptions');
		if(exists $content{creq}) {
			my $creq = $amz->canonical_request;
			$content{creq} =~ s{\r+}{}g;
			is($creq, $content{creq}, 'creq matches');
		}
		if(exists $content{sts}) {
			my $sts = $amz->string_to_sign;
			$content{sts} =~ s{\r+}{}g;
			is($sts, $content{sts}, 'string to sign matches');
		}
		if(exists $content{authz}) {
			my $authz = $amz->calculate_signature;
			$content{authz} =~ s{\r+}{}g;
			is($authz, $content{authz}, 'authentication matches');
		}
		# Always do the signing step even if we don't have anything to check against
		ok(my $sreq = $amz->signed_request($content{req}), 'can sign the request');
		if(exists $content{sreq}) {
			is($sreq, $content{sreq}, 'signed request matches');
		}
		done_testing;
	}
}
done_testing;

