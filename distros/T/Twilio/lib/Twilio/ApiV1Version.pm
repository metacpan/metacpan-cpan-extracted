package Twilio::ApiV1Version;

use 5.016;
use warnings;

use parent 'Twilio::Version';

use Twilio::Exceptions::RestException;
use Twilio::Exceptions::RestExceptionV1;

our $VERSION = '2.001';

sub new {
  my ($class, $domain, $version) = @_;
  my $self = $class->SUPER::new($domain);
  $self->{version} = $version;
  return $self;
}

sub exception {
  my ($self, $response, $header) = @_;

  my $status  = $response->get_status_code;
  my $message = "[HTTP $status] $header";
  my $content = $response->get_content;
  if (ref $content ne 'HASH') {
    return Twilio::Exceptions::RestExceptionV1->new($status, $message, $status);
  }

  # Older services behind these APIs still answer in the classic shape, and newer ones in the RFC
  # 9457 shape, which has a status too; the parent class tells those two apart.
  return $self->SUPER::exception($response, $header)
    if defined $content->{more_info} || defined $content->{status};

  $message .= ": $content->{message}" if defined $content->{message};
  return Twilio::Exceptions::RestExceptionV1->new(
    $content->{code} // $status,
    $message, $content->{httpStatusCode} // $status,
    $content->{params}, $content->{userError},
  );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::ApiV1Version - A version of an API that follows Twilio's API Standards V1

=head1 SYNOPSIS

  package Twilio::Rest::Example::V3;

  use parent 'Twilio::ApiV1Version';

  sub new {
    my ($class, $domain) = @_;
    return $class->SUPER::new($domain, 'v3');
  }

=head1 DESCRIPTION

Works like L<Twilio::Version>, except for the error format. Generated versions of
the newer APIs inherit from it.

=head1 METHODS

=head2 new

  my $version = Twilio::ApiV1Version->new($domain, $version_name);

=head2 exception

  my $error = $version->exception($response, 'Unable to fetch record');

Returns a L<Twilio::Exceptions::RestExceptionV1> built from C<httpStatusCode>,
C<params> and C<userError>. A response in the classic shape, with C<more_info> or
C<status>, gives a L<Twilio::Exceptions::RestException>, and one in the RFC 9457
shape gives a L<Twilio::Exceptions::TwilioServiceException>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
