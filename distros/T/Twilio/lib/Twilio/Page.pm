package Twilio::Page;

use 5.016;
use warnings;

use Carp qw(croak);

use Twilio::Exceptions::DeserializeException;

our $VERSION = '2.001';

my $PAGING_END_CODE = '20006';

my %META_KEYS = map { $_ => 1 } qw(
  end first_page_uri last_page_uri next_page_uri num_pages page page_size
  previous_page_uri schemas start total totalResults uri
);

sub new {
  my ($class, $version, $response, $solution) = @_;

  my $self = bless {
    version  => $version,
    solution => $solution // {},
    records  => [],
    position => 0,
  }, $class;

  $self->{payload} = $self->process_response($response);
  $self->{records} = $self->load_page;
  return $self;
}

sub build_instance {
  my ($self) = @_;
  croak ref($self) . ' must implement build_instance';
}

# Generated pages name their list, which the single-list search in load_page can only guess.
sub records_key { return }

sub process_response {
  my ($self, $response) = @_;

  my $content = $response->get_content;
  return $content if $response->get_status_code == 200 || _is_paging_end($content);

  die $self->get_version->exception($response, 'Unable to fetch page');    ## no critic (ErrorHandling::RequireCarping)
}

sub load_page {
  my ($self) = @_;

  my $payload = $self->{payload};
  return [] if _is_paging_end($payload);

  # twilio-php requires exactly one top-level key besides its known list. Counting only
  # arrays means a new scalar or object from Twilio cannot break paging.
  my $key = $self->records_key // $self->get_meta('key');
  if (!defined $key && ref $payload eq 'HASH') {
    my @lists = grep { !$META_KEYS{$_} && ref $payload->{$_} eq 'ARRAY' } keys %{$payload};
    $key = $lists[0] if @lists == 1;
  }

  if (!defined $key || ref $payload->{$key} ne 'ARRAY') {
    Twilio::Exceptions::DeserializeException->throw('Page Records can not be deserialized');
  }
  return $payload->{$key};
}

sub has_meta {
  my ($self, $key) = @_;
  my $payload = $self->{payload};
  return ref $payload eq 'HASH' && ref $payload->{meta} eq 'HASH' && exists $payload->{meta}{$key};
}

sub get_meta {
  my ($self, $key, $default) = @_;
  return $self->has_meta($key) ? $self->{payload}{meta}{$key} : $default;
}

sub get_next_page_url {
  my ($self) = @_;
  return $self->_page_url('next');
}

sub get_previous_page_url {
  my ($self) = @_;
  return $self->_page_url('previous');
}

sub get_response {
  my ($self, $url) = @_;
  return if !$url;
  return $self->get_version->get_domain->get_client->request('GET', $url);
}

sub create_page {
  my ($self, $response) = @_;
  return ref($self)->new($self->get_version, $response, $self->{solution});
}

sub next_page {
  my ($self) = @_;
  return $self->_page_at($self->get_next_page_url);
}

sub previous_page {
  my ($self) = @_;
  return $self->_page_at($self->get_previous_page_url);
}

sub next {
  my ($self) = @_;
  return if $self->{position} >= @{ $self->{records} };
  return $self->instance_for($self->{records}[$self->{position}++]);
}

sub rewind {
  my ($self) = @_;
  $self->{position} = 0;
  return;
}

sub records {
  my ($self) = @_;
  return map { $self->instance_for($_) } @{ $self->{records} };
}

sub get_version { return $_[0]{version} }

sub instance_for {
  my ($self, $item) = @_;
  return $self->build_instance($item);
}

sub _page_url {
  my ($self, $direction) = @_;

  my $meta_key = "${direction}_page_url";
  return $self->get_meta($meta_key) if $self->has_meta($meta_key);

  my $uri = $self->{payload}{"${direction}_page_uri"};
  return if !$uri;
  return $self->get_version->get_domain->absolute_url($uri);
}

sub _page_at {
  my ($self, $url) = @_;
  my $response = $self->get_response($url) or return;
  return $self->create_page($response);
}

# Reading past the last page answers with this error code, sometimes with status 400.
sub _is_paging_end {
  my ($content) = @_;
  return ref $content eq 'HASH' && ($content->{code} // q{}) eq $PAGING_END_CODE;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Page - Base class for a page of results

=head1 SYNOPSIS

  my $page = $client->messages->page({}, 50);

  while (my $message = $page->next) {
    say $message->body;
  }

  my $next = $page->next_page;

=head1 DESCRIPTION

Reads a page of a list, in the two formats Twilio uses: C<next_page_uri> in the
2010 API, and C<meta.next_page_url> with the list named in C<meta.key> in product
APIs. Asking for a page past the end gives an empty page, not an error, and fields
this class does not know about are ignored.

Each resource has a subclass that implements L</build_instance>.

=head1 METHODS

=head2 new

  my $page = Twilio::Page->new($version, $response, \%solution);

Reads a L<Twilio::Http::Response>. It throws L<Twilio::Exceptions::RestException>
on an error response, and L<Twilio::Exceptions::DeserializeException> if the
response has no recognisable list of records. C<%solution> holds the path values
that resources on this page need, such as the account SID.

=head2 build_instance

  my $instance = $page->build_instance($payload);

Subclasses must implement this. It receives one record and returns its object.

=head2 records_key

Returns the name of the list of records in the response. Subclasses may implement
this. Otherwise the name comes from C<meta.key>, or is the only list in the response.

=head2 next

  my $record = $page->next;

Returns the next record, or nothing at the end of this page.

=head2 rewind

  $page->rewind;

Makes L</next> start again from the first record of this page.

=head2 records

  my @records = $page->records;

Returns all the records of this page.

=head2 next_page

=head2 previous_page

  my $page = $page->next_page;

Fetch and return the next or previous page, or nothing if there is none.

=head2 get_next_page_url

=head2 get_previous_page_url

Return the URL of the next or previous page, or nothing if there is none.

=head2 instance_for

  my $instance = $page->instance_for($record);

Returns the instance for one record of the list. It calls C<build_instance>, and
exists so that a subclass can prepare a record first.

=head2 has_meta

  my $found = $page->has_meta('key');

Returns true if the C<meta> object of the response has this key.

=head2 get_meta

  my $value = $page->get_meta('key', $default);

Returns a value from the C<meta> object of the response.

=head2 process_response

=head2 load_page

=head2 get_response

=head2 create_page

The steps of reading a page, which subclasses may override.
L</process_response> checks a response and returns its content, L</load_page>
returns the list of records, L</get_response> fetches a URL, and L</create_page>
builds a page of the same class from a response.

=head2 get_version

Returns the L<Twilio::Version>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
