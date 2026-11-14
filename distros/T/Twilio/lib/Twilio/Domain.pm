package Twilio::Domain;

use 5.016;
use warnings;

our $VERSION = '2.002';

sub new {
  my ($class, $client) = @_;
  return bless { client => $client, base_url => q{} }, $class;
}

sub absolute_url {
  my ($self, $uri) = @_;
  return join q{/}, map { s{\A/+|/+\z}{}gr } $self->{base_url}, $uri;
}

sub request {
  my ($self, $method, $uri, $options) = @_;
  return $self->get_client->request($method, $self->absolute_url($uri), $options);
}

sub get_client { return $_[0]{client} }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Domain - Base class for a Twilio API host

=head1 SYNOPSIS

  package Twilio::Rest::Api;
  use parent 'Twilio::Domain';

  sub new {
    my ($class, $client) = @_;
    my $self = $class->SUPER::new($client);
    $self->{base_url} = 'https://api.twilio.com';
    return $self;
  }

=head1 DESCRIPTION

A domain is one Twilio product host, such as C<api.twilio.com>. Subclasses set
C<base_url> in their constructor. Applications reach domains through
L<Twilio::Rest::Client> and do not use this class directly.

=head1 METHODS

=head2 new

  my $domain = Twilio::Domain->new($client);

=head2 absolute_url

  my $url = $domain->absolute_url('/2010-04-01/Accounts.json');

Returns the URL for a path on this host.

=head2 request

  my $response = $domain->request($method, $uri, \%options);

Sends a request for a path on this host through the client. The options are
those of L<Twilio::Http::Client/request>.

=head2 get_client

Returns the client.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
