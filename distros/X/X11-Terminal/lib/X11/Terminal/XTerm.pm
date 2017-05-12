package X11::Terminal::XTerm;

use Moose;
extends 'X11::Terminal';

our $VERSION = 1.0.0;

=head1 NAME

X11::Terminal::XTerm - Create customised xterm windows

=head1 SYNOPSIS

This module provides an object interface to launching xterm windows.

	use X11::Terminal::XTerm;

	my $t1 = X11::Terminal::XTerm->new();
	my $t2 = X11::Terminal::XTerm->new(host => "remoteserver");
	my $t3 = X11::Terminal::XTerm->new(foreground => "green");

	for ( $t1, $t2, $t3 ) {
	  $_->launch();
	}


=head1 CONSTRUCTOR

=over 4

=item X11::Terminal::XTerm->new(%attr);

Create a new XTerm object, optionally with the specified attributes
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

=item foreground

Set the forground colour to be used in the XTerm window

=item background

Set the background colour to be used in the XTerm window

=item scrollback

Set the number of lines that should be stored made accessible via the xterm
scrollback buffer

=item font

Set the font used in the XTerm window

=item profile

Set the X11 resource name used by the XTerm window

=item geometry

Set the preferred size and position of the XTerm window

=back


=head1 OTHER METHODS

=over 4

=item launch($debug);

Calculates (and returns) the command that will launch your xterm.  It also
runs that command in a child process - unless $debug is specified.

=item terminalArgs();

Return the arguments that will be passed to the xterm.  This will provide
the customisations.  There should be no reason to call this method directly.
=cut

sub terminalArgs {
    my ($self) = @_;

    my $args = "";
    if ( my $font = $self->font() ) {
        $args .= " -fn $font";
    }
    if ( my $name = $self->profile() ) {
        $args .= " -name $name";
    }
    if ( my $colour = $self->foreground() ) {
        $args .= " -fg $colour";
    }
    if ( my $geo = $self->geometry() ) {
        $args .= " -geometry $geo";
    }
    if ( my $colour = $self->background() ) {
        $args .= " -bg $colour";
    }
    if ( my $lines = $self->scrollback() ) {
        $args .= " -sl $lines";
    }
    return "$args";
}

=back

=head1 SEE ALSO

L<X11::Terminal>

=head1 COPYRIGHT

Copyright 2010-2011 Evan Giles.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
=cut

1;    # End of X11::Terminal::XTerm
