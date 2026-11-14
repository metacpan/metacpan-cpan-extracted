package Twilio::Http::ValidationClient;

use 5.016;
use warnings;

use parent 'Twilio::Http::TinyClient';

use Twilio::Exceptions::ConfigurationException;
use Twilio::Jwt::JWT;
use Twilio::Jwt::Validation::ClientValidationJwt;

our $VERSION = '2.002';

my @REQUIRED       = qw(account_sid api_key_sid credential_sid private_key);
my @SIGNED_HEADERS = qw(authorization host);

sub new {
  my ($class, $options) = @_;
  $options //= {};

  for my $name (@REQUIRED) {
    next if length($options->{$name} // q{});
    Twilio::Exceptions::ConfigurationException->throw("$name is required for client validation");
  }

  # A key that can't sign fails here, at start-up, rather than on the first request.
  Twilio::Jwt::JWT->sign('key check', $options->{private_key}, 'RS256');

  return $class->SUPER::new($options);
}

# Signed after the parent class has added Authorization, so that header is covered too.
sub prepare_request {
  my ($self, @arguments) = @_;
  my $request = $self->SUPER::prepare_request(@arguments);
  $request->{headers}{'Twilio-Client-Validation'} = $self->validation_token($request);
  return $request;
}

sub validation_token {
  my ($self, $request) = @_;

  my ($authority, $path, $query) =
    ($request->{url} // q{}) =~ m{\A[^:/?#]+://([^/?#]*)([^?#]*)(?:[?]([^#]*))?};
  my $host = ($authority // q{}) =~ s/\A.*@//r;

  # HTTP::Tiny sends the Host of the URL, so that is the one to sign, whatever a caller set.
  my %headers = %{ $request->{headers} // {} };
  delete @headers{ grep { lc eq 'host' } keys %headers };

  my $jwt = Twilio::Jwt::Validation::ClientValidationJwt->new(
    @{$self}{@REQUIRED},
    {
      method         => $request->{method},
      path           => $path  // q{},
      query_string   => $query // q{},
      all_headers    => { %headers, host => $host },
      signed_headers => [@SIGNED_HEADERS],
      body           => $request->{content} // q{},
    }
  );
  return $jwt->to_jwt;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::ValidationClient - An HTTP client that signs each request for Public Key Client Validation

=head1 SYNOPSIS

  use Twilio;
  use Twilio::Http::ValidationClient;

  my $http = Twilio::Http::ValidationClient->new({
    account_sid    => $account_sid,       # AC...
    api_key_sid    => $api_key_sid,       # SK...
    credential_sid => $credential_sid,    # CR..., the public key you gave Twilio
    private_key    => $private_key_pem,
  });
  my $client = Twilio->new($api_key_sid, $api_key_secret,
    { account_sid => $account_sid, http_client => $http });

=head1 DESCRIPTION

When an account enforces Public Key Client Validation (a setting in the Twilio
Console), Twilio accepts only requests that carry a C<Twilio-Client-Validation>
header: a JWT signed with the account's private key. This client adds one to
every request; see L<Twilio::Jwt::Validation::ClientValidationJwt>.

To set it up, create an RSA key pair, give Twilio the public key as a
credential (C<< $client->accounts->v1->credentials->public_key->create($pem) >>,
which returns the C<CR...> SID), and use this client with an API key. It works
like L<Twilio::Http::TinyClient> otherwise, and takes its options too. It is
the C<ValidationClient> of twilio-python and twilio-node; twilio-php has none.

Use it only with an account that has the setting on. Twilio refuses a signed
request to any other account, with HTTP 401 and "Public key client validation
is not enabled for the account" (seen on 2026-11-11).

Signing needs the optional module L<Crypt::OpenSSL::RSA>, version 0.38 or
later, or one before 0.35.

=head1 METHODS

=head2 new

  my $http = Twilio::Http::ValidationClient->new(\%options);

C<account_sid>, C<api_key_sid>, C<credential_sid> and C<private_key> (in PEM
form) are required. It throws L<Twilio::Exceptions::ConfigurationException>
when one is missing, and L<Twilio::Exceptions::TwilioException> when the key
can't sign.

=head2 prepare_request

Prepares the request as the parent class does, and adds the
C<Twilio-Client-Validation> header.

=head2 validation_token

  my $token = $http->validation_token($request);

Returns the signed token for a prepared request, covering its C<Authorization>
and C<Host> headers.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
