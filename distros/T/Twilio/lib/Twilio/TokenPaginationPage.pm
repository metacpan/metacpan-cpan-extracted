package Twilio::TokenPaginationPage;

use 5.016;
use warnings;

use parent 'Twilio::Page';

use Twilio::Exceptions::TwilioException;

our $VERSION = '2.002';

sub new {
  my ($class, @arguments) = @_;
  my $self = $class->SUPER::new(@arguments);
  $self->_read_last_request;
  $self->{page_size} = int($self->get_meta('pageSize') // 0);

  my $current = $self->_current_token;
  $self->{next_token}     = _usable_token($self->get_meta('nextToken'),     $current);
  $self->{previous_token} = _usable_token($self->get_meta('previousToken'), $current);
  return $self;
}

sub get_next_page_url {
  my ($self) = @_;
  return $self->_url_with_token($self->{next_token});
}

sub get_previous_page_url {
  my ($self) = @_;
  return $self->_url_with_token($self->{previous_token});
}

# These APIs can list plain values, and instances are always built from a hash.
sub instance_for {
  my ($self, $item) = @_;
  return $self->build_instance(ref $item eq 'HASH' ? $item : { id => $item });
}

# A token only says where to go, so the next URL is this page's URL with the token replaced.
sub _read_last_request {
  my ($self) = @_;

  my $request = $self->_http_client->last_request // {};
  my ($url, $query) = split /[?]/, $request->{url} // q{}, 2;
  $self->{url}         = $url;
  $self->{query_pairs} = [split /&/, $query // q{}];
  return;
}

sub _http_client {
  my ($self) = @_;
  return $self->get_version->get_domain->get_client->get_http_client;
}

sub _current_token {
  my ($self) = @_;

  my ($pair) = grep { /\ApageToken=/ } @{ $self->{query_pairs} };
  return if !defined $pair;

  my $token = $pair =~ s/\ApageToken=//r;
  $token =~ tr/+/ /;
  $token =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  return $token;
}

# A server that answers with the token just used would otherwise keep a stream reading forever.
sub _usable_token {
  my ($token, $current) = @_;

  return if !defined $token || !length $token;
  return if defined $current && $token eq $current;
  return $token;
}

sub _url_with_token {
  my ($self, $token) = @_;
  return if !defined $token;

  # Without a URL the token cannot be used, and returning nothing would end the list early.
  if (!length($self->{url} // q{})) {
    Twilio::Exceptions::TwilioException->throw('The HTTP client did not record the last request');
  }

  my %params = (pageToken => $token);
  $params{pageSize} = $self->{page_size} if $self->{page_size};

  my @kept = grep { my ($name) = /\A([^=]*)/; !exists $params{$name} } @{ $self->{query_pairs} };
  return "$self->{url}?" . join q{&}, @kept, $self->_http_client->build_query(\%params);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::TokenPaginationPage - A page of records from an API that pages by token

=head1 SYNOPSIS

  my $page = $list->page({}, 50);

  while ($page) {
    say $_->sid for $page->records;
    $page = $page->next_page;
  }

=head1 DESCRIPTION

The newer Twilio APIs answer with C<meta.nextToken> and C<meta.previousToken>
instead of a URL. This class builds that URL from the last request, keeping its
other parameters, so it works like any L<Twilio::Page>. Generated pages inherit
from it, and each one implements C<build_instance>.

A record that is not a hash reference reaches C<build_instance> as
C<< { id => $record } >>.

=head1 METHODS

See L<Twilio::Page> for the inherited methods.

=head2 new

  my $page = $class->new($version, $response, \%solution);

=head2 instance_for

  my $instance = $page->instance_for($record);

Returns the instance for one record, as described above.

=head2 get_next_page_url

=head2 get_previous_page_url

Return the URL of that page, or nothing when there is none. A token equal to the
one that fetched this page counts as none, because a server that repeats itself
would otherwise keep a L<Twilio::Stream> reading forever.

They throw L<Twilio::Exceptions::TwilioException> when the HTTP client did not
record the last request, as L<Twilio::Http::Client> does, because ending the list
there would hide records.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
