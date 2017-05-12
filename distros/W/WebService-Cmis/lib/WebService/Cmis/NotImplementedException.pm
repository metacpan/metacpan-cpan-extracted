package WebService::Cmis::NotImplementedException;

=head1 NAME

WebService::Cmis::NotImplementedException

=head1 DESCRIPTION

This exception is raised when calling services not implemented
by the client library.

Parent class: Error

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
  my $class = shift;

  my ($package, $filename, $line, $subroutine) = caller(1);

  return $class->SUPER::new(-text=>($subroutine||'')." not implemented yet.\n");
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;



