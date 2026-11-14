package Twilio::Jwt::Validation::ClientValidationJwt;

use 5.016;
use warnings;

use Digest::SHA qw(sha256_hex);

use Twilio::Exceptions::ConfigurationException;
use Twilio::Jwt::JWT;

our $VERSION = '2.002';

my $CONTENT_TYPE = 'twilio-pkrv;v=1';
my $ALGORITHM    = 'RS256';
my $TTL          = 300;

sub new {
  my ($class, $account_sid, $api_key_sid, $credential_sid, $private_key, $validation_payload) = @_;

  my %given = (
    account_sid    => $account_sid,
    api_key_sid    => $api_key_sid,
    credential_sid => $credential_sid,
    private_key    => $private_key,
  );
  for my $name (qw(account_sid api_key_sid credential_sid private_key)) {
    next if length($given{$name} // q{});
    Twilio::Exceptions::ConfigurationException->throw("$name is required for client validation");
  }
  if (ref $validation_payload ne 'HASH') {
    Twilio::Exceptions::ConfigurationException->throw(
      'Client validation needs the request to sign, as a hash reference');
  }

  return bless { %given, validation_payload => $validation_payload }, $class;
}

sub to_jwt {
  my ($self) = @_;
  return Twilio::Jwt::JWT->encode($self->get_payload, $self->{private_key}, $ALGORITHM,
    { cty => $CONTENT_TYPE, kid => $self->{credential_sid} });
}

sub get_payload {
  my ($self, $now) = @_;
  $now //= time;

  return {
    iss => $self->{api_key_sid},
    sub => $self->{account_sid},
    nbf => $now,
    exp => $now + $TTL,
    hrh => join(q{;}, $self->_signed_headers),
    rqh => sha256_hex(_bytes($self->canonical_request)),
  };
}

# The request in the fixed form Twilio rebuilds on its side, as in twilio-python: method, path,
# sorted query, the signed headers it has, a blank line, their names, and the body's hash.
sub canonical_request {
  my ($self) = @_;
  my $payload = $self->{validation_payload};

  my %headers = _lowercase_headers($payload->{all_headers});
  my @signed  = $self->_signed_headers;
  my @header_lines =
    map { "$_:$headers{$_}" } grep { exists $headers{$_} } @signed;

  my $body = _bytes($payload->{body} // q{});
  return join "\n",
    $payload->{method} // q{},
    $payload->{path}   // q{},
    join(q{&}, sort split /&/, $payload->{query_string} // q{}),
    (@header_lines ? join("\n", @header_lines) : ()),
    q{},
    join(q{;}, @signed),
    length $body ? sha256_hex($body) : q{};
}

sub _signed_headers {
  my ($self) = @_;
  my @signed = sort @{ $self->{validation_payload}{signed_headers} // [qw(authorization host)] };
  return @signed;
}

# A header given as a list is sorted and joined with commas, as twilio-python does.
sub _lowercase_headers {
  my ($headers) = @_;
  my %lowercase;
  for my $name (keys %{ $headers // {} }) {
    my $value = $headers->{$name};
    $lowercase{ lc $name } = ref $value eq 'ARRAY' ? join(q{,}, sort @{$value}) : $value // q{};
  }
  return %lowercase;
}

sub _bytes {
  my ($text) = @_;
  my $bytes = "$text";
  utf8::encode($bytes) if utf8::is_utf8($bytes);
  return $bytes;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Validation::ClientValidationJwt - The token that signs a request for client validation

=head1 SYNOPSIS

  use Twilio::Jwt::Validation::ClientValidationJwt;

  my $jwt = Twilio::Jwt::Validation::ClientValidationJwt->new(
    $account_sid, $api_key_sid, $credential_sid, $private_key_pem,
    {
      method       => 'POST',
      path         => '/2010-04-01/Accounts/ACxxx/Messages.json',
      query_string => q{},
      all_headers  => { Authorization => 'Basic ...', Host => 'api.twilio.com' },
      body         => 'Body=Hi&To=%2B15558675309',
    }
  );
  my $token = $jwt->to_jwt;    # the value of the Twilio-Client-Validation header

=head1 DESCRIPTION

With Public Key Client Validation, every request to Twilio carries a JWT signed
with the account's private key, and Twilio checks it with the public key it
holds as a credential (C<CR...>). The token covers the method, the path, the
query, the C<Authorization> and C<Host> headers and the body, and lasts five
minutes.

L<Twilio::Http::ValidationClient> builds one for each request, so most code
does not use this class directly. It follows C<ClientValidationJwt> in
twilio-python, and signs with C<RS256>, which needs L<Crypt::OpenSSL::RSA>.

=head1 METHODS

=head2 new

  my $jwt = Twilio::Jwt::Validation::ClientValidationJwt->new(
    $account_sid, $api_key_sid, $credential_sid, $private_key, \%validation_payload
  );

The private key is in PEM form. The payload describes the request with
C<method>, C<path>, C<query_string> (without the C<?>), C<all_headers>, C<body>,
and optionally C<signed_headers>, which defaults to C<authorization> and
C<host>. It throws L<Twilio::Exceptions::ConfigurationException> when a value is
missing.

=head2 to_jwt

Returns the signed token. Its header has C<cty> C<twilio-pkrv;v=1> and C<kid>,
the credential SID.

=head2 get_payload

  my $claims = $jwt->get_payload($now);

Returns the claims: C<iss> (the API key), C<sub> (the account), C<nbf>, C<exp>,
C<hrh> (the names of the signed headers) and C<rqh> (the SHA-256 of the
canonical request). C<$now> defaults to the current time.

=head2 canonical_request

Returns the request in the form that is hashed into C<rqh>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
