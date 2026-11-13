package Twilio::Exceptions::TwilioServiceException;

use 5.016;
use warnings;

# twilio-python and twilio-node have this class beside RestException. Here it inherits, as
# RestExceptionV1 does, so that code catching a RestException works with every API.
use parent 'Twilio::Exceptions::RestException';

use Scalar::Util qw(looks_like_number);

our $VERSION = '2.001';

my @REQUIRED_TEXT    = qw(type title);
my @REQUIRED_NUMBERS = qw(status code);

# The rule of twilio-node, stricter than twilio-python's: all four members, two of them numbers.
sub is_problem {
  my ($class, $content) = @_;
  return 0 if ref $content ne 'HASH';
  return 0
    if grep { !defined $content->{$_} || ref $content->{$_} } @REQUIRED_TEXT, @REQUIRED_NUMBERS;
  return 0 if grep { !looks_like_number($content->{$_}) } @REQUIRED_NUMBERS;
  return 1;
}

sub new {
  my ($class, $message, $problem, $status_code) = @_;
  $problem //= {};
  my $errors = ref $problem->{errors} eq 'ARRAY' ? $problem->{errors} : [];

  my $self = $class->SUPER::new(
    _full_message($message, $problem, $errors), $problem->{code},
    $status_code // $problem->{status},         $problem->{type}
  );
  $self->{$_} = $problem->{$_} for qw(type title detail instance);
  $self->{errors} = $errors;
  return $self;
}

sub get_type     { return $_[0]{type} }
sub get_title    { return $_[0]{title} }
sub get_detail   { return $_[0]{detail} }
sub get_instance { return $_[0]{instance} }
sub get_errors   { return $_[0]{errors} }

sub _full_message {
  my ($message, $problem, $errors) = @_;

  my $text = join ' - ', grep { defined && length } $problem->{title}, $problem->{detail};
  $message = join ': ', grep { defined && length } $message, $text;

  my @fields = grep { length } map {
    join ': ',
      grep { defined && length }
      @{$_}{qw(pointer detail)}
    }
    grep { ref eq 'HASH' } @{$errors};
  $message .= ' (' . join('; ', @fields) . ')' if @fields;
  return $message;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Exceptions::TwilioServiceException - Twilio answered with an RFC 9457 problem document

=head1 SYNOPSIS

  use Scalar::Util qw(blessed);

  my $ok = eval { $client->numbers->v3->hosted_number_orders->create($number, 1); 1 };
  if (!$ok) {
    my $error = $@;
    die $error unless blessed($error) && $error->isa('Twilio::Exceptions::TwilioServiceException');
    warn $error->get_title, "\n";
    warn "  $_->{pointer}: $_->{detail}\n" for @{ $error->get_errors };
  }

=head1 DESCRIPTION

Some Twilio APIs describe errors as Problem Details for HTTP APIs
(L<RFC 9457|https://www.rfc-editor.org/rfc/rfc9457.html>), with C<type>,
C<title>, C<status> and C<code>, and often C<detail>, C<instance> and a list of
field C<errors>. Any API can answer this way, so every error answer that has
those four members gives this class, and anything else gives
L<Twilio::Exceptions::RestException> or L<Twilio::Exceptions::RestExceptionV1>
as before.

This class inherits from L<Twilio::Exceptions::RestException>, so code that
catches that class catches this one too, and C<get_code>, C<get_status_code> and
C<get_more_info> work as they do there.

The message holds the title, the detail and the field errors, after the usual
prefix:

  [HTTP 400] Unable to create record: Invalid parameter - The 'PhoneNumber' parameter is required. (#/age: must be a positive integer)

=head1 METHODS

=head2 is_problem

  my $yes = Twilio::Exceptions::TwilioServiceException->is_problem($decoded_body);

Returns 1 when the decoded body is a hash with C<type> and C<title>, and with
C<status> and C<code> as numbers, and 0 otherwise.

=head2 new

  my $error = Twilio::Exceptions::TwilioServiceException->new(
    '[HTTP 400] Unable to create record', \%problem, $http_status_code
  );

Builds the message from the given prefix and the problem document. Without a
status code, the document's C<status> is used.

=head2 get_type

The URL of the problem type, usually Twilio's page for the error code.
C<get_more_info> returns it too.

=head2 get_title

A short summary of the problem type.

=head2 get_detail

What went wrong in this request, or C<undef>.

=head2 get_instance

A reference to this occurrence of the problem, or C<undef>.

=head2 get_errors

An array reference of the field errors, each a hash with C<pointer> (a JSON
Pointer into the request) and C<detail>. It is empty when Twilio sent none.

=head2 get_code

Inherited. Twilio's error code, such as 20001.

=head2 get_status_code

Inherited. The HTTP status of the answer.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
