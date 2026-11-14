package Twilio::Exceptions::RestException;

use 5.016;
use warnings;

use parent 'Twilio::Exceptions::TwilioException';

our $VERSION = '2.002';

sub new {
  my ($class, $message, $code, $status_code, $more_info, $details) = @_;
  my $self = $class->SUPER::new($message, $code);
  $self->{status_code} = $status_code;
  $self->{more_info}   = $more_info // q{};
  $self->{details}     = $details   // {};
  return $self;
}

sub get_status_code { return $_[0]{status_code} }
sub get_more_info   { return $_[0]{more_info} }
sub get_details     { return $_[0]{details} }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Exceptions::RestException - Twilio answered a request with an error

=head1 SYNOPSIS

  use Scalar::Util qw(blessed);

  my $ok = eval { $client->messages->create($to, { from => $from, body => $body }); 1 };
  if (!$ok) {
    my $error = $@;
    die $error unless blessed($error) && $error->isa('Twilio::Exceptions::RestException');
    warn sprintf("HTTP %d, Twilio error %d: %s\nSee %s\n",
      $error->get_status_code, $error->get_code, $error->get_message, $error->get_more_info);
  }

=head1 DESCRIPTION

Thrown when the Twilio API returns an error response. It adds the HTTP status
and Twilio's error details to L<Twilio::Exceptions::TwilioException>.

=head1 METHODS

=head2 new

  my $error = Twilio::Exceptions::RestException->new(
    $message, $code, $status_code, $more_info, $details);

Creates an exception without throwing it.

=head2 get_code

Inherited. Returns the Twilio error code, such as 21211, or the HTTP status
when the response carried no code.

=head2 get_status_code

Returns the HTTP status code.

=head2 get_more_info

Returns the URL of the documentation page for this error, or an empty string.

=head2 get_details

Returns a hash reference of additional error details.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
