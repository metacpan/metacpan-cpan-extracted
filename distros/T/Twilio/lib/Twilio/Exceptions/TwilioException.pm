package Twilio::Exceptions::TwilioException;

use 5.016;
use warnings;

use overload
  q{""}    => sub { $_[0]->get_message },
  bool     => sub { 1 },
  fallback => 1;

our $VERSION = '2.002';

sub new {
  my ($class, $message, $code) = @_;
  return bless { message => $message // q{}, code => $code // 0 }, $class;
}

sub throw {
  my ($class, @args) = @_;
  die $class->new(@args);    ## no critic (ErrorHandling::RequireCarping)
}

sub get_message { return $_[0]{message} }
sub get_code    { return $_[0]{code} }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Exceptions::TwilioException - Base class of every exception in this library

=head1 SYNOPSIS

  use Scalar::Util qw(blessed);

  my $ok = eval { $client->request('GET', $url); 1 };
  if (!$ok) {
    my $error = $@;
    die $error unless blessed($error) && $error->isa('Twilio::Exceptions::TwilioException');
    warn 'Twilio failed: ' . $error->get_message;
  }

=head1 DESCRIPTION

All errors raised by this library are objects of this class or of a subclass,
thrown with C<die>. An exception stringifies to its message, so code that
prints C<$@> still shows something useful.

=head1 METHODS

=head2 new

  my $error = Twilio::Exceptions::TwilioException->new($message, $code);

Creates an exception without throwing it.

=head2 throw

  Twilio::Exceptions::TwilioException->throw($message, $code);

Creates an exception and dies with it.

=head2 get_message

Returns the error message.

=head2 get_code

Returns the error code, or 0 when there is none.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
