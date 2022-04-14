package cPanel::TaskQueue::Processor;
$cPanel::TaskQueue::Processor::VERSION = '0.903';
use strict;

#use warnings;

{

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub get_timeout {
        my ($self) = @_;
        return;
    }

    sub is_dupe {
        my ( $self, $a, $b ) = @_;

        return unless $a->command() eq $b->command();
        my @a_args = $a->args();
        my @b_args = $b->args();
        return unless @a_args == @b_args;

        foreach my $i ( 0 .. $#a_args ) {
            return unless $a_args[$i] eq $b_args[$i];
        }

        return 1;
    }

    sub overrides {
        my ( $self, $new, $old ) = @_;

        return;
    }

    sub is_valid_args {
        my ( $self, $task ) = @_;

        return 1;
    }

    sub process_task {
        my ( $self, $task, $logger ) = @_;

        if ($logger) {
            $logger->throw("No processing has been specified for this task.\n");
        }
        else {
            die "No processing has been specified for this task.\n";
        }
    }

    sub deferral_tags {
        my ( $self, $task ) = @_;
        return;
    }

    sub is_task_deferred {
        my ( $self, $task, $defer_hash ) = @_;
        return unless $defer_hash && keys %{$defer_hash};

        foreach my $tag ( $self->deferral_tags($task) ) {
            return 1 if exists $defer_hash->{$tag};
        }

        return;
    }

    # Utility functions
    sub checked_system {
        my ( $self, $args ) = @_;
        die "Argument must be a hashref."         unless ref $args eq 'HASH';
        die "Missing required 'logger' argument." unless $args->{'logger'};
        $args->{'logger'}->throw("Missing required 'cmd' argument.")
          unless defined $args->{'cmd'} && length $args->{'cmd'};
        $args->{'logger'}->throw("Missing required 'name' argument.")
          unless defined $args->{'name'} && length $args->{'name'};
        $args->{'args'} ||= [];

        my $rc = system $args->{'cmd'}, @{ $args->{'args'} };
        return 0 unless $rc;

        my $message;
        if ( $rc == -1 ) {
            $message = "Failed to run $args->{'name'}";
        }
        elsif ( $rc & 127 ) {
            $message = "$args->{'name'} dies with signal: " . ( $rc & 127 );
        }
        else {
            $message = "$args->{'name'} exited with value " . ( $rc >> 8 );
        }
        $args->{'logger'}->warn($message);

        return $rc;
    }
}

# To simplify use, here is a simple module that turns a code ref into a valid
# TaskQueue::Processor.
{

    package cPanel::TaskQueue::Processor::CodeRef;
$cPanel::TaskQueue::Processor::CodeRef::VERSION = '0.903';
use parent -norequire, 'cPanel::TaskQueue::Processor';

    {

        sub new {
            my ( $class, $args_ref ) = @_;
            die "Args must be a hash ref.\n" unless 'HASH' eq ref $args_ref;

            unless ( exists $args_ref->{code} and 'CODE' eq ref $args_ref->{code} ) {
                die "Missing required code parameter.\n";
            }
            return bless { proc => $args_ref->{code} }, $class;
        }

        # Override the default behavior to call the stored coderef with the
        # arguments supplied in the task. Return whatever the coderef returns.
        sub process_task {
            my ( $self, $task, $logger ) = @_;

            eval {
                $self->{proc}->( $task->args() );
                1;
            } or do {
                $logger->throw($@);
            };

            return 0;
        }
    }
}

1;

__END__


=head1  NAME

cPanel::TaskQueue::Processor - Processes an individual task from the cPanel::TaskQueue.

=head1 SYNOPSIS

    package NewTask;

    use base 'cPanel::TaskQueue::Processor';

    sub process_task {
        my ($self, $task) = @_;

        # do something exciting.

        return;
    }

    sub is_valid_args {
        my ($self, $task) = @_;
        # all args must be numeric
        return !grep { /[^-\d]/ } $task->args();
    }

=head1  DESCRIPTION

This module provides an abstraction for commands to be executed from/by the
TaskQueue. It is used as a base class to provide default behavior for every
method except C<process_task> that is used by the C<cPanel::TaskQueue>.

=head1 PUBLIC METHODS

=over 4

=item cPanel::TaskQueue::Processor->new

Create a new C<cPanel::TaskQueue::Processor> object.

=item $proc->is_dupe( $task_a, $task_b )

Return true if the two supplied C<cPanel::TaskQueue::Task> objects are equivalent.
The parameters are guaranteed not to be C<undef>.

The method should return a true value if the parameters are duplicates and a
false value if they are not. If the method fails for some reason, throw an
exception.

A subclass might want to override this to give more specific processing. The
default definition is to check if the arguments for the two supplied task
descriptors is the same. If so, return true, else return C<undef>.

=item $proc->overrides( $new_task, $old_task )

Return true if the I<new_task> C<cPanel::TaskQueue::Task> object should override
the I<old_task> object. The parameters are guaranteed not to be C<undef>.

The method should return a true value if there is no need to execute the I<old_task>
since the I<new_task> results will override whatever I<old_task> was going to
do. For example, if the old task changes a user's password, and the new task
deletes that user, there is no need to run the first task. Otherwise the method
should return a false value. If the method fails for some reason, throw an
exception.

A subclass might want to override this to give more specific processing. The
default definition is aways return C<undef>.

=item $proc->is_valid_args( $task )

Return true if the arguments in the supplied cPanel::TaskQueue::Task are valid
for this task. The parameter is guaranteed not to be C<undef>.

The method should return a true value if the supplied task has valid arguments
for the command, otherwise it should return false. If the method fails for some
reason, the method should throw an exception.

A subclass will probably want to override this method for more specific processing.
The default definition is to return true regardless of the state of the supplied
task descriptor.

=item $proc->process_task( $task, $logger )

Perform the task that is described by the supplied cPanel::TaskQueue::Task. The
parameter is guaranteed not to be C<undef>. The C<$logger> parameter is an object
providing logging facilities for the system. See L<cPanel::TaskQueue/#LOGGER OBJECT>
for the interface of this object.

This method should return a 0 if the code processing is complete. If the processing
spawns a child to handle the work, the method should return the pid of the child.
If the processing fails, it should throw an exception.

A subclass must override this method to get any processing. The default throws
an exception if called.

=item $proc->get_timeout()

Return the number of seconds before the task should be considered I<timed out>.
The default method returns C<undef>. Any false value uses whatever the default
value for the TaskQueue defines. A subclass may override this method to provide
a longer time out value for cases where the processing is known to take some
time.

=item $proc->deferral_tags( $task )

Return a list of tags that that the supplied C<$task> defers.

=item $proc->is_task_deferred( $task, $defer_hash )

Check the supplied C<$task> against the C<$defer_hash> to decide if the task
should be deferred. Return a C<true> value if the task should be deferred,
false otherwise.

=back

=head1 UTILITY METHODS

This section describes convenience methods that may be useful to classes
derived from the C<Processor> class.

=over 4

=item $proc->checked_system( $hashref )

In many cases, the task to be processed depends on running another program.
Since handling the return code from C<system> is annoying, it often gets
ignored.  This method calls the core system routine, and checks the return
code. It logs an appropriate message for error conditions and is quiet on
success.  C<checked_system> returns the same return code as C<system>.

The method expects a C<hash ref> describing the request. The parameters in the
hash ref are:

=over 4

=item logger

This required parameter should provide an object following the logging
interface described in L<cPanel::TaskQueue/#LOGGER OBJECT>. If this parameter
is missing, the method throws an exception.

=item name

This required parameter provides a name used in any error messages. If this
parameter is missing, the method throws an exception.

=item cmd

This required parameter provides the command that system is to execute. If this
parameter is missing, the method throws an exception.

=item args

This optional parameter is an array reference containing the parameters to pass
with the command to the C<system> call. If this parameter is missing, an empty
list is assumed.

=back

=back

=head1 DIAGNOSTICS

=over

=item C<< No processing has been specified for this task. >>

Either this base class has been used directly as a processor for a command or
the C<process_task> method was not overridden in a derived class.

In either case, the default behavior for C<process_task> is to throw an exception.

=back

=head1 CONFIGURATION AND ENVIRONMENT

cPanel::TaskQueue::Processor requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.

=head1 SEE ALSO

cPanel::TaskQueue, cPanel::TaskQueue::Task

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< wade@cpanel.net >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
