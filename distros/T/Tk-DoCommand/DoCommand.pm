#=============================================================================
#
# Do a command asynchronously, for Perl/Tk
#
#-----------------------------------------------------------------------------

package Tk::DoCommand;
use vars qw/$VERSION/;
$VERSION = '0.1';

use Tk::widgets qw/ROText/;
use base qw/Tk::Derived Tk::ROText/;
use strict;
use warnings;

use Carp;
use IO::Handle;
use Proc::Killfam;

Construct Tk::Widget 'DoCommand';

sub ClassInit {
    my ($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($w, $args) = @_;
    $w->SUPER::Populate($args);
    $w->{-finish} = 0;
    $w->{-pid} = undef;
    $w->OnDestroy( sub { $w->kill_command } );
    $w->ConfigSpecs(
        -command  => [qw/PASSIVE command Command/, 'ls; sleep 3; pwd'],
        'DEFAULT' => ['SELF']
    );
    return $w;
}

# Convienence method to get result text
sub get_output {
    my ($self) = @_;
    return $self->get('1.0' => 'end -1 chars');
}

# Return the pid of the process running the command
sub get_pid {
    my ($self) = @_;
    return $self->{-pid};
}

# Return a 2 element array of $? and $! from last command execution.
# Returns undef if the command is not done
sub get_status {
    my ($self) = @_;
    my $stat = $self->{-status};
    return (defined $stat ? @$stat : undef);

}

# Is the command done?
sub is_done {
    my ($self) = @_;
    return $self->{-finish};
}

# Nuke the command
sub kill_command {
    my ($self) = @_;

    $self->{-finish} = 1;
    my $h = $self->{-handle};
    if (defined $h) {
        $self->fileevent($h, 'readable' => '');
        killfam 'TERM', $self->{-pid} if defined $self->{-pid};
        close $h;
        $self->{-status} = [$?, $!];
        $self->{-handle} = undef;
    }
}

# Run the command in a background pipe; returns immediately
sub start_command {
    my ($self) = @_;
    my $command = $self->cget('-command');
    return 0 if !length($command);

    $self->{-finish} = 0;
    $self->{-handle} = undef;
    $self->{-pid}    = undef;

    my $h = IO::Handle->new;
    croak "IO::Handle->new failed." unless defined $h;
    $self->{-handle} = $h;

    $self->{-pid} = open $h, $command . ' 2>&1 |';
    if (not defined $self->{-pid}) {
        $self->insert('end', "'" . $command . "' : $!\n");  # Show the error
        $self->kill_command;
        return;
    }
    $h->autoflush(1);
    $self->fileevent($h, 'readable' => [\&_read_stdout, $self]);
    return 1;
}

# Block (wait) until the command is done
sub wait {
    my ($self) = @_;
    $self->waitVariable(\$self->{-finish});
    $self->kill_command;
}

# Internal function
sub _read_stdout {
    my ($self) = @_;

    if ($self->{-finish}) {
        $self->kill_command;
    }
    else {
        my $h = $self->{-handle};
        croak "Tk::DoCommand ($self) handle is undefined\n" if !defined $h;
        my $stat;
        if ($stat = sysread $h, $_, 4096) {
            $self->insert('end', $_);
            $self->yview('end');
        }
        elsif ($stat == 0) {
            $self->{-finish} = 1;
        }
        else {
            die "Tk::DoCommand ($self) sysread error: $!";
        }
    }
}

__END__

=head1 NAME

Tk::DoCommand - Asynchronously Do a Command

=head1 SYNOPSIS

    use Tk;
    use Tk::DoCommand;

    my $mw = new MainWindow;
    my $dc = $mw->DoCommand(-command => "ls -al")->pack;
    $dc->start_command;     # Run the command, returns immediately
        .
        .
        .
    if ($dc->is_done) { ... }       # Test if command is finished
    my $pid = $dc->get_pid;         # Get the pid of the command's process
    my @status = $dc->get_status;   # Returns ($?, $!) from command
    my $text = $dc_>get_output;     # Result text from command
    $dc->kill_command;              # Rudely terminate the command
    $dc->wait;                      # Wait for command to finish (blocks)

=head1 DESCRIPTION

Execute a command asynchronously, and display the output within
this widget.  Both stdout and stderr are captured.

This I<is-a> Tk::ROText widget.

This is similar to Tk::ExecuteCommand.  
But Tk::ExecuteCommand is not fully asynchronous, it that 
its execute_command() function is blocking.
Also, Tk::ExecuteCommand has "fluff" around it (buttons, text).
This widget is bare-bones; it's just an ROText widget.

The following options/value pairs are supported:

=over 4

=item B<-command>

Command to execute.

=back

=head1 METHODS

=head2 start_command

Execute the command.  The command is run in a background pipe; this
function returns immediately.

=head2 get_status

Returns a 2 element array of $? and $! from last command execution.

=head2 get_output

A convienence method to return the result text from the command.
This is the same as calling ->get('1.0' => 'end -1 chars'),
since this widget is derived from an ROText widget.

=head2 is_done

Tests if the command has finished executing.

=head2 kill_command

Terminates the command.  This is called automatically via an
OnDestroy handler when the DoCommand widget goes away.

=head2 pid

Returns the process id of the process that's executing the command.

=head2 wait

Wait for the command to complete.  Obviously, this is a blocking call.

=head1 ADVERTISED SUBWIDGETS

None.

=head1 AUTHOR

Steve Roscio  C<< <roscio@cpan.org> >>

Copyright (c) 2010, Steve Roscio C<< <roscio@cpan.org> >>. All rights reserved.

Code liberally mooched from Tk::ExecuteCommand by Stephen O. Lidie.  Thanx Steve!

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law.  Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose.  The
entire risk as to the quality and performance of the software is with
you.  Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=head1 KEYWORDS

DoCommand

=cut
