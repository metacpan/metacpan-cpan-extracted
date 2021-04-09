package UV::Process;

our $VERSION = '1.907';

use strict;
use warnings;
use Carp ();
use parent 'UV::Handle';

sub spawn {
    my $self = shift;
    ref $self or $self = $self->new(@_);

    $self->_spawn();

    return $self;
}

sub _set_stdin  { shift->_set_stdio_h(0 => @_); }
sub _set_stdout { shift->_set_stdio_h(1 => @_); }
sub _set_stderr { shift->_set_stdio_h(2 => @_); }

1;

__END__

=encoding utf8

=head1 NAME

UV::Process - Process handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  my $process = UV::Process->spawn(...)

=head1 DESCRIPTION

This module provides an interface to
L<libuv's process|http://docs.libuv.org/en/v1.x/process.html> handle.

=head1 EVENTS

=head2 exit

    $process->on("exit", sub {
        my ($invocant, $exit_status, $term_signal) = @_;
        say "The process exited with status $exit_status" unless $term_signal;
        say "The process terminated with signal $term_signal" if $term_signal;
    });

When the process terminates (either by C<exit> or a signal), this event will
be fired.

=head1 METHODS

L<UV::Signal> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 spawn (class method)

    my $process = UV::Process->spawn(file => $file, args => \@args);

This constructor method creates a new L<UV::Process> object with the given
configuration, and
L<spawns|http://docs.libuv.org/en/v1.x/process.html#c.uv_spawn> the actual
process to begin running. If no L<UV::Loop> is provided then the
L<UV::Loop/"default loop"> is assumed.

The following named options are supported:

=over 4

=item

C<file>: a string giving the command name or path to it.

=item

C<args>: a reference to an array of addtional argument values to invoke the
command with.

=item

C<env>: an optional reference to a hash containing the environment variables
for the new process.

=item

C<stdin>, C<stdout>, C<stderr>: optional argument to set up a file descriptor
in the child process.

Pass a plain integer, or filehandle reference to inherit that FD from the
parent.

=item

C<setuid>, C<setgid>: optional integer arguments to attempt to change the
user and group ID of the newly-spawned process.

Not supported on Windows.

=back

=head2 kill

    $process->kill($signal);

Sends the specified signal to the process.

=head2 pid

    my $pid = $process->pid;

Returns the PID number.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
