package WebService::Cmis::Agent;

=head1 NAME

WebService::Cmis::Agent - base class for all user agents

=head1 DESCRIPTION

This is the base class for all WebService::Cmis::Agents.

Parent class: L<LWP::UserAgent>

=cut

use strict;
use warnings;

use LWP::UserAgent ();
our @ISA = qw(LWP::UserAgent);

=head1 METHODS

=over 4

=cut 

=item login(%params) 

to be implemented by a sub class as required. 

=cut

sub login {
  # nop
}

=item logout() 

to be implemented by a sub class as required. 

=cut

sub logout {
  # nop
}

=back


=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

