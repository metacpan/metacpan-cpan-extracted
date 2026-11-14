package Twilio::InstanceContext;

use 5.016;
use warnings;

our $VERSION = '2.002';

sub new {
  my ($class, $version) = @_;
  return bless { version => $version, solution => {}, uri => undef }, $class;
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

Twilio::InstanceContext - Base class for the operations on one record

=head1 DESCRIPTION

A context points at one record by its identifiers and offers its operations,
without having fetched it, as in C<< $client->messages($sid)->fetch >>. Each
resource has a subclass that sets C<uri> and C<solution> in its constructor.

=head1 METHODS

=head2 new

  my $context = Twilio::InstanceContext->new($version);

=head2 with_metadata

  my $answer = $client->messages($sid)->with_metadata('fetch');
  my $status = $client->messages($sid)->with_metadata('delete')->get_status_code;

Runs one of the record's operations, such as C<fetch>, C<update> or C<delete>,
with the arguments that follow its name. Returns a L<Twilio::Metadata> with what
the operation returns, and the status code and headers of Twilio's answer. It
dies when the record has no such operation.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
