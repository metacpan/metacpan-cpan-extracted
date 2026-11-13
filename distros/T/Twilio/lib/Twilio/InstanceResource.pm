package Twilio::InstanceResource;

use 5.016;
use warnings;

our $VERSION = '2.001';

sub new {
  my ($class, $version, $payload, $solution) = @_;
  return bless {
    version    => $version,
    properties => ref $payload eq 'HASH' ? { %{$payload} } : {},
    solution   => $solution // {},
  }, $class;
}

sub to_hash {
  my ($self) = @_;
  return { %{ $self->{properties} } };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::InstanceResource - Base class for one record

=head1 SYNOPSIS

  my $message = $client->messages->create($to, { from => $from, body => $body });

  say $message->sid;

  my $fields = $message->to_hash;

=head1 DESCRIPTION

An instance holds a record as Twilio returned it. Each resource has a subclass
with one accessor per documented field. Every field is kept, including those newer
than this library, which have no accessor but are returned by L</to_hash>.

=head1 METHODS

=head2 new

  my $instance = Twilio::InstanceResource->new($version, $payload, \%solution);

C<$payload> is the record, and C<%solution> holds the identifiers needed to reach
it, such as the account SID.

=head2 to_hash

  my $fields = $instance->to_hash;

Returns a hash reference with the record's fields, as Twilio named them. This is
C<toArray> in PHP.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
