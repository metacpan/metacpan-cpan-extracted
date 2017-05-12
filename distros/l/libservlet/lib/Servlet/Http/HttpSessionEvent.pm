# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpSessionEvent;

use base qw(Servlet::Util::Event);
use strict;
use warnings;

sub getSession {
    my $self = shift;

    return $self->getSource();
}

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpSessionEvent - session event base class

=head1 SYNOPSIS

  my $event = Servlet::Http::HttpSessionEvent->new($session);

  my $session = $event->getSession();
  # or
  my $session = $event->getSource();

=head1 DESCRIPTION

This class represents event notifications for changes to sessions
within a web application.

=head1 CONSTRUCTOR

=over

=item new($session)

Construct a session event from the given source.

B<Parameters:>

=over

=item I<$session>

the B<Servlet::Http::HttpSession> instance that is the source of the
event

=back

=back

=head1 METHODS

=over

=item getSession()

Returns the B<Servlet::Http::HttpSession> that is the source of this event.

=item getSource()

Returns the B<Servlet::Http::HttpSession> that is the source of this event.

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Servlet::Http::HttpSessionListener>,
L<Servlet::Util::Event>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
