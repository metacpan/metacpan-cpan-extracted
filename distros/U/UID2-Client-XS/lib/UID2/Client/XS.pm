package UID2::Client::XS;
use 5.008005;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.01";

require XSLoader;
XSLoader::load('UID2::Client::XS', $VERSION);

require UID2::Client::XS::DecryptionStatus;
require UID2::Client::XS::EncryptionStatus;
require UID2::Client::XS::IdentityScope;
require UID2::Client::XS::IdentityType;
require UID2::Client::XS::Timestamp;

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::XS - Unified ID 2.0 Client for Perl (binding to the UID2 C++ library)

=head1 SYNOPSIS

  use UID2::Client::XS;

  my $client = UID2::Client::XS->new({
      endpoint => '...',
      auth_key => '...',
      secret_key => '...',
  });
  my $result = $client->refresh();
  die $result->{reason} unless $result->{is_success};
  my $decrypted = $client->decrypt($uid2_token);
  if ($result->{is_success}) {
      say $result->{uid};
  }

=head1 DESCRIPTION

This module provides an interface to Unified ID 2.0 API.

=head1 CONSTRUCTOR METHODS

=head2 new

  my $client = UID2::Client::XS->new(\%options);

Creates and returns a new UID2 client with a hashref of options.

Valid options are:

=over

=item endpoint

The UID2 Endpoint (required).

Please note that not to specify a trailing slash.

=item auth_key

A bearer token in the request's authorization header (required).

=item secret_key

A secret key for encrypting/decrypting the request/response body (required).

=item identity_scope

UID2 or EUID. Defaults to UID2.

=back

=head2 new_euid

  my $client = UID2::Client::XS->new_euid(\%options);

Calls I<new()> with EUID identity_scope.

=head1 METHODS

=head2 refresh

  my $result = $client->refresh();

Fetch the latest keys and returns a hashref containing the response. The hashref will have the following keys:

=over

=item is_success

Boolean indicating whether the operation succeeded.

=item reason

Returns reason for failure if I<is_success> is false.

=back

=head2 refresh_json

  my $result = $client->refresh_json($json);

Updates keys with the JSON string and returns a hashref containing the response. The hashref will have same keys of I<refresh>.

=head2 decrypt

  my $result = $client->decrypt($token);
  # or
  my $result = $client->decrypt($token, $timestamp);

Decrypts an advertising token and returns a hashref containing the response. The hashref will have the following keys:

=over

=item is_success

Boolean indicating whether the operation succeeded.

=item status

Returns failed status if is_success is false.

See L<UID2::Client::XS::DecryptionStatus> for more details.

=item uid

The UID2 string.

=item site_id

=item site_key_site_id

=item established

=back

=head2 encrypt_data

  my $result = $client->encrypt_data($data, \%request);

Encrypts arbitrary data with a hashref of requests.

Valid options are:

=over

=item advertising_token

Specify the UID2 Token.

=item site_id

=item initialization_vector

=item now

=back

One of I<advertising_token> or I<site_id> must be passed.

Returns a hashref containing the response. The hashref will have the following keys:

=over

=item is_success

Boolean indicating whether the operation succeeded.

=item status

Returns failed status if is_success is false.

See L<UID2::Client::XS::EncryptionStatus> for more details.

=item encrypted_data

=back

=head2 decrypt_data

  my $result = $client->decrypt_data($encrypted_data);

Decrypts data encrypted with I<encrypt_data()>. Returns a hashref containing the response. The hashref will have the following keys:

=over

=item is_success

=item status

=item decrypted_data

=item encrypted_at

=back

=head1 SEE ALSO

L<https://github.com/IABTechLab/uid2-client-cpp11>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
