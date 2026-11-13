package Twilio::Metadata;

use 5.016;
use warnings;

use Carp qw(croak);

our $VERSION = '2.001';

# read returns a list, so its records are kept in an array reference.
my %RETURNS_LIST = (read => 1);

sub capture {
  my ($class, $resource, $operation, @arguments) = @_;

  if (!defined $operation || !length $operation) {
    croak 'with_metadata needs the name of an operation, such as fetch, create or read';
  }
  if ($operation =~ /\A_/ || $operation eq 'with_metadata' || !$resource->can($operation)) {
    croak 'with_metadata cannot call ' . ref($resource) . "->$operation";
  }

  my $client = $resource->{version}->get_domain->get_client;
  my ($data, @responses) = $client->capture_responses(
    sub {
      return $RETURNS_LIST{$operation}
        ? [$resource->$operation(@arguments)]
        : scalar $resource->$operation(@arguments);
    }
  );

  # The first answer, as in twilio-php: a read's first page, or the one answer of the others.
  my ($response) = @responses;
  croak "$operation made no request to Twilio, so there is no answer to describe" if !$response;
  return $class->new($data, $response->get_status_code, $response->get_headers);
}

sub new {
  my ($class, $data, $status_code, $headers) = @_;
  return bless { data => $data, status_code => $status_code, headers => $headers // {} }, $class;
}

sub get_data        { return $_[0]{data} }
sub get_status_code { return $_[0]{status_code} }
sub get_headers     { return $_[0]{headers} }

sub get_header {
  my ($self, $name) = @_;
  my $wanted = lc($name // q{});
  my ($key) = grep { lc eq $wanted } sort keys %{ $self->{headers} };
  return if !defined $key;

  # A header sent more than once comes as a list; RFC 9110 joins those with commas.
  my $value = $self->{headers}{$key};
  return ref $value eq 'ARRAY' ? join(', ', @{$value}) : $value;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Metadata - The status code and headers of Twilio's answer, with the result

=head1 SYNOPSIS

  my $answer = $client->messages->with_metadata(create => $to, { from => $from, body => 'Hi' });

  my $message = $answer->get_data;
  say $answer->get_status_code;                  # 201
  say $answer->get_header('Twilio-Request-Id');

  my $listed = $client->messages->with_metadata(read => {}, 20);
  say scalar @{ $listed->get_data }, ' messages';

  my $fetched = $client->messages($sid)->with_metadata('fetch');

=head1 DESCRIPTION

Every list and context has C<with_metadata>, which runs one of its operations
and returns an object of this class. It holds what the operation returns, and
the status code and headers of Twilio's answer to it. twilio-php has the same
with a C<WithMetadata> twin of each operation, twilio-python with
C<_with_http_info> and twilio-node with C<WithHttpInfo>.

When an operation makes more than one request, the first answer counts: for a
read that goes through several pages, the first page's. A request repeated
after HTTP 429 counts once, with its last answer.

An error answer still throws, as it does without C<with_metadata>; the
exception has the status code.

=head1 METHODS

=head2 capture

  my $answer = Twilio::Metadata->capture($list_or_context, $operation, @arguments);

What C<with_metadata> calls. It runs C<< $list_or_context->$operation(@arguments) >>
and records the answers the client gets meanwhile. It dies when there is no
such operation, or when the operation makes no request.

=head2 new

  my $answer = Twilio::Metadata->new($data, $status_code, \%headers);

=head2 get_data

What the operation returns:

=over

=item * for C<create>, C<fetch>, C<update> and C<patch>, the instance;

=item * for C<delete>, 1;

=item * for C<read>, an array reference of the records;

=item * for C<stream>, the L<Twilio::Stream>, and for C<page>, the page.

=back

=head2 get_status_code

The HTTP status of the answer, such as 200 or 201.

=head2 get_headers

A hash reference of the answer's headers, as the HTTP client gave them. With
the default client their names are in lower case.

=head2 get_header

  my $value = $answer->get_header('Twilio-Request-Id');

One header, whatever the case of its name, or C<undef> when the answer does not
have it. A header sent more than once comes as one value, joined with commas.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
