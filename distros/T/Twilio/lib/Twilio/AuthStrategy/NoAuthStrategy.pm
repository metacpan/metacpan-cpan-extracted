package Twilio::AuthStrategy::NoAuthStrategy;

use 5.016;
use warnings;

use parent 'Twilio::AuthStrategy::AuthStrategy';

our $VERSION = '2.002';

sub new {
  my ($class) = @_;
  return $class->SUPER::new('noauth');
}

sub get_auth_string         { return q{} }
sub requires_authentication { return 0 }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::AuthStrategy::NoAuthStrategy - Requests with no credentials

=head1 DESCRIPTION

Returned by L<Twilio::CredentialProvider::NoAuthCredentialProvider>. Requests
are sent with no C<Authorization> header, as the request for an OAuth token is.

=head1 METHODS

=head2 new

  my $strategy = Twilio::AuthStrategy::NoAuthStrategy->new;

=head2 get_auth_string

Returns an empty string.

=head2 requires_authentication

Returns false.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
