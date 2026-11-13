package Twilio::Stream;

use 5.016;
use warnings;

our $VERSION = '2.001';

sub new {
  my ($class, $page, $limit, $page_limit) = @_;
  return bless {
    page         => $page,
    first_page   => $page,
    limit        => $limit,
    page_limit   => $page_limit,
    records_read => 0,
    pages_read   => 1,
  }, $class;
}

sub next {
  my ($self) = @_;
  return if $self->_over_limit;

  while (my $page = $self->{page}) {
    my $item = $page->next;
    if ($item) {
      $self->{records_read}++;
      return $item;
    }

    return if $self->_over_page_limit;

    # An empty page is not the end: only the lack of a next page is.
    $self->{page} = $page->next_page;
    $self->{pages_read}++;
  }

  return;
}

sub rewind {
  my ($self) = @_;
  $self->{page} = $self->{first_page};
  $self->{page}->rewind;
  $self->{records_read} = 0;
  $self->{pages_read}   = 1;
  return;
}

# Both checks run before any fetch, so stopping at a limit never costs an extra request.
sub _over_limit {
  my ($self) = @_;
  return $self->{limit} && $self->{records_read} >= $self->{limit};
}

sub _over_page_limit {
  my ($self) = @_;
  return $self->{page_limit} && $self->{pages_read} >= $self->{page_limit};
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Stream - Iterator over the records of several pages

=head1 SYNOPSIS

  my $stream = $client->messages->stream({}, 100, 50);

  while (my $message = $stream->next) {
    say $message->body;
  }

=head1 DESCRIPTION

Returns records one at a time and fetches each page only when it is needed, so
it can walk long lists without holding them in memory. Where PHP uses C<foreach>
over a stream, Perl uses C<while> over L</next>.

=head1 METHODS

=head2 new

  my $stream = Twilio::Stream->new($page, $limit, $page_limit);

Starts at the L<Twilio::Page> C<$page>. It stops after C<$limit> records or
C<$page_limit> pages. Without them, or with zero, it reads until the last page.

=head2 next

  my $record = $stream->next;

Returns the next record, or nothing when there are no more.

=head2 rewind

  $stream->rewind;

Starts again from the first page. Later pages are fetched again.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
