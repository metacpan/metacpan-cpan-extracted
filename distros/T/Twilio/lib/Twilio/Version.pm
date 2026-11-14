package Twilio::Version;

use 5.016;
use warnings;

use Twilio::Exceptions::RestException;
use Twilio::Exceptions::TwilioServiceException;
use Twilio::Stream;

our $VERSION = '2.002';

my $MAX_PAGE_SIZE = 1000;

my $FIRST_SUCCESS_STATUS = 200;
my $FIRST_ERROR_STATUS   = 400;

sub new {
  my ($class, $domain) = @_;
  return bless { domain => $domain, version => undef }, $class;
}

sub absolute_url {
  my ($self, $uri) = @_;
  return $self->get_domain->absolute_url($self->relative_uri($uri));
}

sub relative_uri {
  my ($self, $uri) = @_;
  return join q{/}, map { s{\A/+|/+\z}{}gr } $self->{version} // q{}, $uri;
}

sub request {
  my ($self, $method, $uri, $options) = @_;
  return $self->get_domain->request($method, $self->relative_uri($uri), $options);
}

sub exception {
  my ($self, $response, $header) = @_;

  my $status  = $response->get_status_code;
  my $message = "[HTTP $status] $header";
  my $content = $response->get_content;
  if (ref $content ne 'HASH') {
    return Twilio::Exceptions::RestException->new($message, $status, $status);
  }

  # As in twilio-python and twilio-node, the shape of the body decides, whatever the API.
  if (Twilio::Exceptions::TwilioServiceException->is_problem($content)) {
    return Twilio::Exceptions::TwilioServiceException->new($message, $content, $status);
  }

  $message .= ": $content->{message}" if defined $content->{message};
  return Twilio::Exceptions::RestException->new($message, $content->{code} // $status,
    $status, $content->{more_info}, $content->{details});
}

sub read_limits {
  my ($self, $limit, $page_size) = @_;

  $page_size //= $limit       if $limit;
  $page_size = $MAX_PAGE_SIZE if ($page_size // 0) > $MAX_PAGE_SIZE;

  return { limit => $limit || undef, page_size => $page_size || undef, page_limit => undef };
}

sub page {
  my ($self, $method, $uri, $options) = @_;
  return $self->request($method, $uri, $options);
}

sub stream {
  my ($self, $page, $limit, $page_limit) = @_;
  return Twilio::Stream->new($page, $limit, $page_limit);
}

sub handle_request {
  my ($self, $method, $uri, $operation, $options) = @_;

  my $response = $self->request($method, $uri, $options);
  my $status   = $response->get_status_code;
  if ($status < $FIRST_SUCCESS_STATUS || $status >= $FIRST_ERROR_STATUS) {
    die $self->exception($response, "Unable to $operation record");    ## no critic (ErrorHandling::RequireCarping)
  }

  return $response;
}

sub get_domain  { return $_[0]{domain} }
sub get_version { return $_[0]{version} }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Version - Base class for one version of a Twilio API

=head1 SYNOPSIS

  package Twilio::Rest::Api::V2010;
  use parent 'Twilio::Version';

  sub new {
    my ($class, $domain) = @_;
    my $self = $class->SUPER::new($domain);
    $self->{version} = '2010-04-01';
    return $self;
  }

=head1 DESCRIPTION

A version adds its path to the URLs of a L<Twilio::Domain>, and turns error
responses into exceptions. Subclasses set C<version> in their constructor.
Applications reach versions through L<Twilio::Rest::Client> and do not use this
class directly.

=head1 METHODS

=head2 new

  my $version = Twilio::Version->new($domain);

=head2 absolute_url

  my $url = $version->absolute_url('/Accounts.json');

Returns the URL for a path in this version.

=head2 relative_uri

  my $uri = $version->relative_uri('/Accounts.json');

Returns the path with the version added, such as C<2010-04-01/Accounts.json>.

=head2 request

  my $response = $version->request($method, $uri, \%options);

Sends a request for a path in this version. The options are those of
L<Twilio::Http::Client/request>.

=head2 handle_request

  my $response = $version->handle_request($method, $uri, 'create', \%options);

Sends a request like L</request> and throws L<Twilio::Exceptions::RestException>
on a status below 200 or from 400 up. The third argument names the operation in
the message, as in C<[HTTP 404] Unable to fetch record: Not found>.

=head2 exception

  my $error = $version->exception($response, 'Unable to fetch record');

Returns a L<Twilio::Exceptions::RestException> for an error response, without
throwing it. It uses Twilio's code, message, more_info and details when the
body has them, and the HTTP status code otherwise. A body in the RFC 9457 form
gives a L<Twilio::Exceptions::TwilioServiceException> instead.

=head2 read_limits

  my $limits = $version->read_limits($limit, $page_size);

Returns a hash reference with C<limit>, C<page_size> and C<page_limit>. Without a
page size, a limit is also used as the page size, so that a small limit does not
download a full page. The page size is capped at 1000, the largest Twilio
returns. Values of zero mean no limit, and are returned as C<undef>.

=head2 page

  my $response = $version->page($method, $uri, \%options);

Sends the request for a page of results, and returns the response.

=head2 stream

  my $stream = $version->stream($page, $limit, $page_limit);

Returns a L<Twilio::Stream> that starts at C<$page>.

=head2 get_domain

Returns the L<Twilio::Domain>.

=head2 get_version

Returns the version path, such as C<2010-04-01>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
