package UID2::Client;
use strict;
use warnings;

our $VERSION = '0.02';

use Class::Accessor::Lite (
    rw => [qw(endpoint auth_key secret_key identity_scope http keys)],
);

use Carp;
use HTTP::Tiny;
use JSON;
use Crypt::PRNG qw(random_bytes);
use Crypt::Misc qw(encode_b64 decode_b64);

use UID2::Client::Encryption;
use UID2::Client::Key;
use UID2::Client::KeyContainer;
use UID2::Client::Timestamp;
use UID2::Client::IdentityScope;

sub new {
    my ($class, $options) = @_;
    my $secret_key = $options->{secret_key} // croak 'secret_key required';
    $secret_key = decode_b64($secret_key);
    my $http = do {
        if ($options->{http_options} && $options->{http}) {
            croak 'only one of http_options or http can be specified';
        } elsif ($options->{http_options}) {
            HTTP::Tiny->new(%{$options->{http_options}});
        } elsif ($options->{http}) {
            $options->{http};
        } else {
            HTTP::Tiny->new;
        }
    };
    bless {
        endpoint       => $options->{endpoint} // croak('endpoint required'),
        auth_key       => $options->{auth_key} // croak('auth_key required'),
        secret_key     => $secret_key,
        identity_scope => $options->{identity_scope} // UID2::Client::IdentityScope::UID2,
        http           => $http,
        keys           => undef,
    }, $class;
}

sub new_euid {
    my ($class, $options) = @_;
    $class->new({ %$options, identity_scope => UID2::Client::IdentityScope::EUID });
}

sub refresh {
    my $self = shift;
    eval {
        $self->keys(_parse_json($self->get_latest_keys));
    }; if ($@) {
        return { is_success => undef, reason => $@ };
    }
    +{ is_success => 1 };
}

sub refresh_json {
    my ($self, $json) = @_;
    eval {
        $self->keys(_parse_json($json));
    }; if ($@) {
        return { is_success => undef, reason => $@ };
    }
    +{ is_success => 1 };
}

my $V2_NONCE_LEN = 8;

sub get_latest_keys {
    my $self = shift;
    my $nonce = random_bytes($V2_NONCE_LEN);
    my $res = $self->http->post($self->endpoint . '/v2/key/latest', {
        headers => {
            'Authorization' => 'Bearer ' . $self->auth_key,
            'Content-Type' => 'text/plain',
        },
        content => $self->_make_v2_request($nonce),
    });
    unless ($res->{success}) {
        if ($res->{status} == 599) {
            chomp(my $content = $res->{content});
            croak $content;
        } else {
            croak "$res->{status} $res->{reason}";
        }
    }
    $self->_parse_v2_response($res->{content}, $nonce);
}

sub _make_v2_request {
    my ($self, $nonce, $now) = @_;
    $now //= UID2::Client::Timestamp->now;
    my $data = pack 'q> a*', $now->get_epoch_milli, $nonce;
    my $payload = UID2::Client::Encryption::encrypt_gcm($data, $self->secret_key),
    my $version = 1;
    my $envelope = pack 'C a*', $version, $payload;
    encode_b64($envelope);
}

sub _parse_v2_response {
    my ($self, $envelope, $nonce) = @_;
    my $envelope_bytes = decode_b64($envelope);
    my $payload = UID2::Client::Encryption::decrypt_gcm($envelope_bytes, $self->secret_key);
    if (length($payload) < 16) {
        croak 'invalid payload';
    }
    my ($res_nonce, $data) = unpack "x8 a${V2_NONCE_LEN} a*", $payload;
    if ($res_nonce ne $nonce) {
        croak 'nonce mismatch';
    }
    $data;
}

sub _parse_json {
    my $content = shift;
    my $obj = decode_json($content);
    my @keys;
    for my $entry (@{$obj->{body}}) {
        $entry->{secret} = decode_b64($entry->{secret});
        push @keys, UID2::Client::Key->new($entry);
    }
    UID2::Client::KeyContainer->new(@keys);
}

sub decrypt {
    my ($self, $token, $now) = @_;
    UID2::Client::Encryption::decrypt_token($token, $now, $self->keys, $self->identity_scope);
}

sub encrypt_data {
    my ($self, $data, $request) = @_;
    $request->{identity_scope} = $self->identity_scope;
    $request->{keys} = $self->keys unless $request->{key};
    UID2::Client::Encryption::encrypt_data($data, $request);
}

sub decrypt_data {
    my ($self, $data) = @_;
    UID2::Client::Encryption::decrypt_data($data, $self->keys, $self->identity_scope);
}

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client - Unified ID 2.0 Perl Client

=head1 SYNOPSIS

  use UID2::Client;

  my $client = UID2::Client->new({
      endpoint => 'https://prod.uidapi.com',
      auth_key => 'your_auth_key',
      secret_key => 'your_secret_key',
  });
  my $result = $client->refresh;
  die $result->{reason} unless $result->{is_success};
  my $decrypted = $client->decrypt($uid2_token);
  if ($decrypted->{is_success}) {
      say $result->{uid};
  }

=head1 DESCRIPTION

This module provides an interface to Unified ID 2.0 API.

=head1 CONSTRUCTOR METHODS

=head2 new

  my $client = UID2::Client->new(\%options);

Creates and returns a new UID2 client with a hashref of options.

Valid options are:

=over

=item endpoint

The UID2 Endpoint (required).

=item auth_key

A bearer token in the request's authorization header (required).

=item secret_key

A secret key for encrypting/decrypting the request/response body (required).

=item identity_scope

UID2 or EUID. Defaults to UID2.

=item http_options

Options to pass to the L<HTTP::Tiny> constructor.

=item http

The L<HTTP::Tiny> instance.

Only one of I<http_options> or I<http> can be specified.

=back

=head2 new_euid

  my $client = UID2::Client->new_euid(\%options);

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

  $client->refresh_json($json);

Updates keys with the JSON string and returns a hashref containing the response. The hashref will have same keys of I<refresh()>.

=head2 get_latest_keys

  my $json = $client->get_latest_keys();

Gets latest keys from UID2 API and returns the JSON string.

Dies on errors, e.g. HTTP errors.

=head2 decrypt

  my $result = $client->decrypt($uid2_token);
  # or
  my $result = $client->decrypt($uid2_token, $timestamp);

Decrypts an advertising token and returns a hashref containing the response. The hashref will have the following keys:

=over

=item is_success

Boolean indicating whether the operation succeeded.

=item status

Returns failed status if is_success is false.

See L<UID2::Client::DecryptionStatus> for more details.

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

=item key

=back

One of I<advertising_token> or I<site_id> must be passed.

Returns a hashref containing the response. The hashref will have the following keys:

=over

=item is_success

Boolean indicating whether the operation succeeded.

=item status

Returns failed status if is_success is false.

See L<UID2::Client::EncryptionStatus> for more details.

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

L<https://github.com/UnifiedID2/uid2docs>

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
