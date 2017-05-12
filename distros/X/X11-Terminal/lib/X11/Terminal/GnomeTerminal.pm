package X11::Terminal::GnomeTerminal;

use Moose;
extends 'X11::Terminal';

our $VERSION = 1.0.0;

=head1 NAME

X11::Terminal::GnomeTerminal - Create customised gnome-terminal windows

=head1 SYNOPSIS

This module provides an object interface to launching gnome-terminal windows.

	use X11::Terminal::GnomeTerminal;

	my $t1 = X11::Terminal::GnomeTerminal->new();
	my $t2 = X11::Terminal::GnomeTerminal->new(host => "remoteserver");
	my $t3 = X11::Terminal::GnomeTerminal->new(profile => "special");

	for ( $t1, $t2, $t3 ) {
	  $_->launch();
	}


=head1 CONSTRUCTOR

=over 4

=item X11::Terminal::GnomeTerminal->new(%attr);

Create a new GnomeTerminal object, optionally with the specified attributes
(see below).

=back


=head1 ATTRIBUTES

Each of the following attributes provide an accessor method, but they can
also be set in the constructor.

=over 4
 
=item host

Specifies the remote host to log in to (using ssh).

=item agentforward

If the host has been specified, and agentforward is true, the login to that
host will use SSH Agent Forwarding.

=item xforward

If the host has been specified, and xforward is true, the login to that host
will use SSH X Forwarding.

=item profile

Set the GnomeTerminal window profile name

=item geometry

Set the preferred size and position of the GnomeTerminal window

=back


=head1 OTHER METHODS

=over 4

=item launch($debug);

Calculates (and returns) the command that will launch your gnome-terminal.
It also runs that command in a child process - unless $debug is specified.

=item terminalArgs();

Return the arguments that will be passed to the gnome-terminal.  This will
provide the customisations.  There should be no reason to call this method
directly.
=cut

sub terminalArgs {
    my ($self) = @_;

    my $args = "";
    if ( my $name = $self->profile() ) {
        $args .= " --window-with-profile=$name";
    }
    if ( my $geo = $self->geometry() ) {
        $args .= " -geometry $geo";
    }
    return "$args";
}

=item terminalName();

Returns the name of the executable program that we want to run.  There
should be no reason to call this method directly.
=cut

sub terminalName {
    return "gnome-terminal";
}

=back

=head1 SEE ALSO

L<X11::Terminal>

=head1 COPYRIGHT

Copyright 2010-2011 Evan Giles.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
=cut

1;    # End of X11::Terminal::GnomeTerminal
