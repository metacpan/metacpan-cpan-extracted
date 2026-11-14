package Twilio::Exceptions::RestExceptionV1;

use 5.016;
use warnings;

# twilio-php has these two as siblings. Here this one inherits, so that code catching a
# RestException works with every API, and get_status_code answers on both.
use parent 'Twilio::Exceptions::RestException';

our $VERSION = '2.002';

sub new {
  my ($class, $code, $message, $http_status_code, $params, $user_error) = @_;
  my $self = $class->SUPER::new($message, $code, $http_status_code);
  $self->{params}     = $params // {};
  $self->{user_error} = $user_error ? 1 : 0;
  return $self;
}

sub get_http_status_code { return $_[0]{status_code} }
sub get_params           { return $_[0]{params} }
sub get_user_error       { return $_[0]{user_error} }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Exceptions::RestExceptionV1 - An error from an API that follows API Standards V1

=head1 SYNOPSIS

  use Scalar::Util qw(blessed);

  my $ok = eval { $list->create($name); 1 };
  if (!$ok) {
    my $error = $@;
    die $error unless blessed($error) && $error->isa('Twilio::Exceptions::RestExceptionV1');
    warn 'Check the request' if $error->get_user_error;
  }

=head1 DESCRIPTION

The newer Twilio APIs describe errors with C<httpStatusCode>, C<params> and
C<userError>. This class inherits from L<Twilio::Exceptions::RestException>, so
code that catches that class catches this one too.

=head1 METHODS

=head2 new

  my $error = Twilio::Exceptions::RestExceptionV1->new(
    $code, $message, $http_status_code, \%params, $user_error
  );

=head2 get_http_status_code

Returns the HTTP status, as C<get_status_code> does.

=head2 get_params

Returns a hash reference with the details Twilio gave.

=head2 get_user_error

Returns 1 when Twilio says the caller made the mistake, and 0 otherwise.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
