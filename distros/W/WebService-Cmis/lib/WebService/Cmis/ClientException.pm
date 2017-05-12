package WebService::Cmis::ClientException;

=head1 NAME

WebService::Cmis::ClientException

=head1 DESCRIPTION

This exception is raised by L<WebService::Cmis::Client> when 
an HTTP error >= 400, < 500 ocurred.

See L<WebService::Cmis::Client/processErrors>.

Parent class: Error

=cut

use strict;
use warnings;
use Error ();
our @ISA = qw(Error);

=head1 METHODS

=over 4

=item new($client)

$client is the L<WebService::Cmis::Client> been used.

=cut

sub new {
  my ($class, $client, $reason) = @_;

  my $url = $client->responseBase;
  $reason = $client->responseStatusLine unless defined $reason;

  return $class->SUPER::new(-text=>"$reason at $url");
}

=back

=head1 AUTHOR

Michael Daum C<< <daum@michaeldaumconsulting.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
