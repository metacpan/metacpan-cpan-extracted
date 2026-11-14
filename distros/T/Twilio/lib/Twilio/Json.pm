package Twilio::Json;

use 5.016;
use warnings;

our $VERSION = '2.002';

my $codec = _new_codec();

sub encode {
  my ($value) = @_;
  return $codec->encode($value);
}

sub decode {
  my ($text) = @_;
  return $codec->decode($text);
}

sub _new_codec {
  my $backend =
    eval { require Cpanel::JSON::XS; 'Cpanel::JSON::XS' } // do { require JSON::PP; 'JSON::PP' };

  # Canonical key order keeps request bodies reproducible in tests and logs.
  return $backend->new->utf8->canonical->allow_nonref;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Json - JSON encoding for this library

=head1 DESCRIPTION

Uses L<Cpanel::JSON::XS> when it is installed, and the core module L<JSON::PP>
otherwise. Encoded text is UTF-8 bytes.

=head1 FUNCTIONS

=head2 encode

  my $bytes = Twilio::Json::encode($data);

=head2 decode

  my $data = Twilio::Json::decode($bytes);

Dies when the text is not valid JSON.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
