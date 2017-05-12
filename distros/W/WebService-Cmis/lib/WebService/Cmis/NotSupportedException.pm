package WebService::Cmis::NotSupportedException;

=head1 NAME

WebService::Cmis::NotSupportedException

=head1 DESCRIPTION

This exception is raised when a service is called that
the repository is not capable of.

See L<WebService::Cmis::Repository/getCapabilities>.

=cut

use strict;
use warnings;
use Error ();
our @ISA = qw(Error);

=head1 METHODS

=over 4

=item new()

=cut

sub new {
  my ($class, $text) = @_;

  return $class->SUPER::new(-text=>"$text");
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
