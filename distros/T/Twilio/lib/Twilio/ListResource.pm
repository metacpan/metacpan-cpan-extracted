package Twilio::ListResource;

use 5.016;
use warnings;

our $VERSION = '2.001';

sub new {
  my ($class, $version) = @_;
  return bless { version => $version, solution => {}, uri => undef }, $class;
}

sub read_records {
  my ($self, $options, $limit, $page_size) = @_;

  my $stream = $self->stream_records($options, $limit, $page_size);
  my @records;
  while (my $item = $stream->next) {
    push @records, $item;
  }
  return @records;
}

sub stream_records {
  my ($self, $options, $limit, $page_size) = @_;

  my $version = $self->{version};
  my $limits  = $version->read_limits($limit, $page_size);
  my $page    = $self->page($options, $limits->{page_size});
  return $version->stream($page, $limits->{limit}, $limits->{page_limit});
}

sub with_metadata {
  my ($self, $operation, @arguments) = @_;
  require Twilio::Metadata;
  return Twilio::Metadata->capture($self, $operation, @arguments);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::ListResource - Base class for a collection of records

=head1 DESCRIPTION

A list is the collection endpoint of a resource, such as the messages of an
account. Each resource has a subclass that sets C<uri> and C<solution> in its
constructor, and only the operations Twilio offers for it. This is why C<read>
and C<stream> are not defined here: a list without them must not respond to them.

=head1 METHODS

=head2 new

  my $list = Twilio::ListResource->new($version);

=head2 read_records

  my @records = $list->read_records(\%options, $limit, $page_size);

Returns the records as a list, fetching as many pages as it needs. The C<read>
method of a subclass calls this.

=head2 stream_records

  my $stream = $list->stream_records(\%options, $limit, $page_size);

Fetches the first page and returns a L<Twilio::Stream> that starts there. It calls
the C<page> method of the subclass, with the options and page size. The C<stream>
method of a subclass calls this.

=head2 with_metadata

  my $answer = $client->messages->with_metadata(create => $to, { body => 'Hi' });
  my $listed = $client->messages->with_metadata(read => {}, 20);

Runs one of the list's operations, such as C<create>, C<read>, C<stream> or
C<page>, with the arguments that follow its name. Returns a L<Twilio::Metadata>
with what the operation returns, and the status code and headers of Twilio's
answer. It dies when the list has no such operation.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
