use strict;
use warnings;

use Test::More tests => 5;

my ( $api_key, $secret ) = ( $ENV{TRIGGERMAIL_KEY}, $ENV{TRIGGERMAIL_SECRET} );

use lib 'lib';

use_ok('Triggermail');

# create the Triggermail object
my $fake_tm = Triggermail->new( 'api_key', 'secret' );

# signature hash generation invalid key response
my %vars = ( var1 => 'var_content', );
my $signature = $fake_tm->_getSignatureHash( \%vars );
is( $signature, '27a0c810cdd561a69de9ca9bae1f3d82', 'Testing signature hash generation' );

my $tm;
my %invalid_key;

# testing invalid email
SKIP: {
	skip 'requires an API key and secret.', 1 if not defined $api_key and not defined $secret;
	my $tm = Triggermail->new( $api_key, $secret );
	my %invalid_key = %{ $tm->getEmail('not_an_email') };
	is( $invalid_key{error}, 11, 'Testing error code on invalid email' );
}

# testing invalid authorization
SKIP: {
	skip 'requires an API key.', 1 if not defined $api_key;
	my $tm = Triggermail->new( $api_key, 'invalid_secret' );
	%invalid_key = %{ $tm->getEmail('not_an_email') };
	is( $invalid_key{error}, 5, 'Testing authentication failing error code' );
}

# testing invalid key response
%invalid_key = %{ $fake_tm->getEmail('not_an_email') };
is( $invalid_key{error}, 3, 'Testing error code on invalid key' );
