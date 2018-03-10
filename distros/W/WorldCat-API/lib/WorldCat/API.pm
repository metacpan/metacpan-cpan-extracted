use strict;
use warnings;
package WorldCat::API;
$WorldCat::API::VERSION = '1.002';
# ABSTRACT: Moo bindings for the OCLC WorldCat API


use feature qw(say);

use Moo;
use Carp qw(croak);
use Digest::SHA qw(hmac_sha256_base64);
use HTTP::Request;
use HTTP::Status qw(:constants);
use LWP::UserAgent;
use MARC::Record;
use Math::Random::Secure qw(irand);
use Readonly;
use WorldCat::MARC::Record::Monkeypatch;
use XML::Simple qw(XMLin);

Readonly my $DEFAULT_RETRIES => 5;

sub _from_env {
  my ($attr) = @_;
  return $ENV{uc "WORLDCAT_API_$attr"} // die "Attribute $attr is required";
}

has institution_id => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('institution_id') },
);

has principle_id => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('principle_id') },
);

has principle_id_namespace => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('principle_id_namespace') },
);

has secret => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('secret') },
);

has wskey => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('wskey') },
);

sub _query_param {
  return "$_[0]=\"$_[1]\"";
}

# OCLC returns encoding=UTF-8, format=MARC21+xml.
sub find_by_oclc_number {
  my ($self, $oclc_number, %opts) = @_;

  my $retries = $opts{retries} // $DEFAULT_RETRIES;

  # Fetch the record with retries and exponential backoff
  my $res;
  my $ua = $self->_new_ua;
  for my $try (0..($retries - 1)) {
    $res = $ua->get("https://worldcat.org/bib/data/$oclc_number");
    say "Got HTTP Response Code: @{[$res->code]}";

    last if not $res->is_server_error; # only retry 5xx errors
    sleep 2 ** $try;
  }

  # Return MARC::Record on success
  if ($res->is_success) {
    my $xml = XMLin($res->decoded_content)->{entry}{content}{record};
    return MARC::Record->new_from_marc21xml($xml);
  }

  # Return nil if record not found
  return if $res->code eq HTTP_NOT_FOUND;

  # An error occurred, throw the response
  croak $res;
}

# Generate the authorization header. It's complicated; see the docs:
#
#   https://www.oclc.org/developer/develop/authentication/hmac-signature.en.html
#   https://github.com/geocolumbus/hmac-language-examples/blob/master/perl/hmacAuthenticationExample.pl
sub _create_auth_header {
  my ($self) = @_;

  my $signature = $self->_create_signature;

  return 'http://www.worldcat.org/wskey/v2/hmac/v1 ' . join(q{,},
    _query_param(clientId      => $self->wskey),
    _query_param(principalID   => $self->principle_id),
    _query_param(principalIDNS => $self->principle_id_namespace),
    _query_param(nonce         => $signature->{nonce}),
    _query_param(signature     => $signature->{value}),
    _query_param(timestamp     => $signature->{timestamp}),
  );
}

sub _create_signature {
  my ($self, %opts) = @_;

  my $nonce = $opts{nonce} || sprintf q{%x}, irand;
  my $timestamp = $opts{timestamp} || time;

  my $signature = hmac_sha256_base64(join(qq{\n},
    $self->wskey,
    $timestamp,
    $nonce,
    q{}, # Hash of the body; empty because we're just GET-ing
    "GET", # all-caps HTTP request method
    "www.oclc.org",
    "443",
    "/wskey",
    q{}, # query params
  ), $self->secret) . q{=};

  return {
    value     => $signature,
    nonce     => $nonce,
    timestamp => $timestamp,
  };
}

sub _new_ua {
  my ($self) = @_;

  my $ua = LWP::UserAgent->new;
  $ua->default_header(Accept => q{application/atom+xml;content="application/vnd.oclc.marc21+xml"});
  $ua->default_header(Authorization => $self->_create_auth_header);
  return $ua;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WorldCat::API - Moo bindings for the OCLC WorldCat API

=head1 VERSION

version 1.002

=head1 SYNOPSIS

  my $api = WorldCat::API->new(
    institution_id => "...",
    principle_id => "...",
    principle_id_namespace => "...",
    secret => "...",
    wskey => "...",
  );

  my $marc_record = $api->find_by_oclc_number("123") or die "Not Found!";

=head2 CONFIGURATION

Defaults are set via envrionment variables of the form "WORLDCAT_API_${ALL_CAPS_ATTR_NAME}". An easy way to set defaults (e.g. for testing) is to add them to a .env at the root of the project:

  $ cat <<EOF > .env
  WORLDCAT_API_INSTITUTION_ID="..."
  WORLDCAT_API_PRINCIPLE_ID="..."
  WORLDCAT_API_PRINCIPLE_ID_NAMESPACE="..."
  WORLDCAT_API_SECRET="..."
  WORLDCAT_API_WSKEY="..."
  EOF

=head2 DOCKER

The included Dockerfile makes it easy to develop, test, and release using Dist::Zilla. Just build the container:

  $ docker build -t worldcatapi .

dzil functions as the container's entrypoint, which makes it easy to build the project:

  $ docker run --volume="$PWD:/app" --env-file=.env worldcatapi build
  $ docker run --volume="$PWD:/app" --env-file=.env worldcatapi test
  $ docker run --volume="$PWD:/app" --env-file=.env worldcatapi clean

Release and development are interactive processes. You can use Docker for that, too, by opening a persistent shell in the container:

  $ docker run -it --volume="$PWD:/app" --entrypoint=/bin/bash worldcatapi

=head1 AUTHOR

Daniel Schmidt <danschmidt5189@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Daniel Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
