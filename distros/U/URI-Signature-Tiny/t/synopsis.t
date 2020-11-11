use strict; use warnings;

use Test::More tests => 4;

my $secret = 'hmac_placeholder_synopsis';

########################################################################

use URI;
use URI::Signature::Tiny;

my $notary = URI::Signature::Tiny->new(
  secret     => $secret,
  after_sign => sub {
    my ( $uri, $sig ) = @_;
    $uri->query_form({ $uri->query_form, s => $sig });
    $uri;
  },
  before_verify => sub {
    my ( $uri ) = @_;
    my %f = $uri->query_form;
    my $sig = delete $f{'s'};
    $uri = $uri->clone; # important
    $uri->query_form( \%f );
    ( $uri, ref $sig ? '' : $sig );
  },
);

my $signed_uri = $notary->sign( URI->new( 'http://example.com/foo?bar=baz#pagetop' ) );

my $ok = $notary->verify( $signed_uri );

########################################################################

isa_ok $notary, 'URI::Signature::Tiny', '$notary';

like $signed_uri, qr/[&;?]s=/, 'Signature is present in signed URI';

is ${{ $signed_uri->query_form }}{'s'}, 'DvVWTw5co-LIQCUCGVuQ6kzM95NzsDcq5QFhHqOs98E',
  '... with the expected value';

ok $ok, '... and it verifies';

# vim: et sw=2 ts=2 sts=2
