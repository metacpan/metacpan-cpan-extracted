package X11::Terminal;

use Moose;

our $VERSION = 1.0.0;

=head1 NAME

X11::Terminal - Create customised X11 terminal windows

=head1 SYNOPSIS

This module provides a baseclass for launching terminal windows on your
desktop.  You would normally instantiate subclass rather than using this
class directly.

For example:

	use X11::Terminal::XTerm;
	
	# Create an xterm window, logged in to a remote server
	my $term = X11::Terminal::XTerm->new(host => "remotehost");
	$term->launch();
=cut

=head1 ATTRIBUTES

Each of the following attributes provide an accessor method, but they
can also be set in the constructor.

The following attributes define the shell command to be run within the
terminal window.

=over

=item host 

If set, the terminal window will ssh to that host.  Otherwise, it will
just run a bash shell.
=cut

has 'host' => (
    is  => 'rw',
    isa => 'Str',
);

=item xforward 

If set, the ssh command will enable X11 forwarding.  Requires L</host>.
=cut

has 'xforward' => (
    is  => 'rw',
    isa => 'Bool',
);

=item agentforward 

If set, the ssh command will enable agent forwarding.  Requires L</host>.
=cut

has 'agentforward' => (
    is  => 'rw',
    isa => 'Bool',
);

=back

The following attributes are implemented in the various subclasses and
depending on the subclass involved they may have no effect.  For example,
a C<GnomeTerminal> subclass can't set the font as gnome-terminals
utilise a profile setting for that bahaviour.

=over

=item profile
=cut

has 'profile' => (
    is  => 'rw',
    isa => 'Str',
);

=item geometry
=cut

has 'geometry' => (
    is  => 'rw',
    isa => 'Str',
);

=item font
=cut

has 'font' => (
    is  => 'rw',
    isa => 'Str',
);

=item foreground
=cut

has 'foreground' => (
    is  => 'rw',
    isa => 'Str',
);

=item background
=cut

has 'background' => (
    is  => 'rw',
    isa => 'Str',
);

=item scrollback
=cut

has 'scrollback' => (
    is  => 'rw',
    isa => 'Int',
);

=back

=head1 OTHER METHODS

=over

=item launch($debug);

Calculates (and returns) the command that will launch your terminal program.
The exact content of the command will depend on which subclass is calling
the command, and the attributes that have been specified.

It also runs that command in a child process - unless $debug is specified.
=cut

sub launch {
    my ( $self, $debug ) = @_;

    my $shell   = $self->shellCommand();
    my $term    = $self->terminalName();
    my $args    = $self->terminalArgs();
    my $command = "$term $args -e '$shell'";

    if ( !$debug ) {
        if ( fork() == 0 ) {
            exec($command);
        }
    }
    return $command;
}

=item shellCommand();

Returns the shell command that should be run within the terminal window.  
There should be no need to call this method directly.
=cut

sub shellCommand {
    my ($self) = @_;

    if ( my $host = $self->host() ) {
        my $sshForward   = $self->xforward()     ? "-X" : "";
        my $agentForward = $self->agentforward() ? "-A" : "";
        return "ssh $sshForward $agentForward $host";
    }
    return "bash";
}

=item terminalName();

Returns the name of the program that will be run to provide the terminal
window.  There should be no need to call this method directly.
=cut

sub terminalName {
    my ($self) = @_;

    my ($className) = ref($self) =~ m/([\w|-]+)$/;
    return lc($className);
}

=back

=head1 COPYRIGHT

Copyright 2010-2011 Evan Giles.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
=cut

1;    # End of X11::Terminal
