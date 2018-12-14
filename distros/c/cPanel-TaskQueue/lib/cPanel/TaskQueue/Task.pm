package cPanel::TaskQueue::Task;
$cPanel::TaskQueue::Task::VERSION = '0.902';
use strict;

#use warnings;

# Namespace for the ids created by this class.
my $task_uuid = 'TaskQueue-Task';

my @fields = qw/_command _argstring _args _timestamp _uuid _child_timeout _started _pid _retries _userdata/;
my @must_be_defined_fields = grep { $_ ne '_pid' && $_ ne '_started' } @fields;

# These methods are intended to help document the importance of the message and to supply 'seam' that
#   could be used to modify the logging behavior of the TaskQueue.
sub _throw {
    my $class = shift;
    die @_;
}

# Not using _warn or _info, so don't define them.

sub new {
    my ( $class, $args ) = @_;

    $class->_throw('Missing arguments')                  unless defined $args;
    $class->_throw('Args parameter must be a hash ref.') unless 'HASH' eq ref $args;
    $class->_throw('Missing command string.')            unless exists $args->{cmd} and $args->{cmd} =~ /\S/;
    $class->_throw('Invalid Namespace UUID.') if exists $args->{nsid} and !_is_valid_ns( $args->{nsid} );
    $class->_throw('Invalid id.') unless _is_pos_int( $args->{id} );

    my $uuid = _make_name_based_uuid(
        exists $args->{nsid} ? $args->{nsid} : $task_uuid,
        $args->{id}
    );

    my $timeout = -1;
    if ( exists $args->{timeout} ) {
        $timeout = $args->{timeout};
        $class->_throw('Invalid child timeout.') unless _is_pos_int($timeout);
    }
    my $retries = 1;
    if ( exists $args->{retries} ) {
        $retries = $args->{retries};
        $class->_throw('Invalid value for retries.') unless _is_pos_int($retries);
    }
    my $userdata = {};
    if ( exists $args->{userdata} ) {
        $class->_verify_userdata_arg( $args->{userdata} );
        $userdata = { %{ $args->{userdata} } };
    }

    my ( $command, $argstring ) = split( /\s+/, $args->{cmd}, 2 );
    $argstring = '' unless defined $argstring;

    # recognizes simple args, quoted args, and quoted args with escaped quotes.
    my @args = ( $argstring =~ m/('(?: \\' | [^'] )*' | "(?: \\" | [^"] )*" | \S+ )/xg );
    foreach my $arg (@args) {

        # remove quotes and escapes.
        $arg =~ s/^['"]//;
        $arg =~ s/["']$//;
        $arg =~ s/\\(['"])/$1/g;
    }

    return bless {
        _command       => $command,
        _argstring     => $argstring,
        _args          => \@args,
        _timestamp     => time,
        _uuid          => $uuid,
        _child_timeout => $timeout,
        _started       => undef,
        _pid           => undef,
        _retries       => $retries,
        _userdata      => $userdata,
    }, $class;
}

# Validate supplied hash bless into class if valid
sub reconstitute {
    my ( $class, $hash ) = @_;

    return unless defined $hash;
    return $hash if ref $hash eq $class;

    $class->_throw('Argument is not a hash reference.') unless ref {} eq ref $hash;
    if ( my $field = ( grep { !defined $hash->{$_} } @must_be_defined_fields )[0] ) {

        # We only care about the the first one since we throw
        $class->_throw("Missing '$field' field in supplied hash") unless exists $hash->{$field};
        $class->_throw("Field '$field' has no value");
    }
    $class->_throw("Missing '_pid' field in supplied hash")     unless exists $hash->{_pid};
    $class->_throw("Missing '_started' field in supplied hash") unless exists $hash->{_started};
    $class->_throw(q{The '_args' field must be an array}) unless ref [] eq ref $hash->{_args};

    return bless {
        %$hash,

        # _args needs a bit more do do a clone
        '_args' => [ @{ $hash->{'_args'} } ]
    }, $class;
}

# Make a copy of the task description.
# Makes a one-level deep copy of the hash. If this structure is ever extended
# to support more complex attributes, this method will need to change.
#
# Returns the clone.
sub clone {
    my $self = shift;

    my $new = bless { %{$self} }, __PACKAGE__;

    # Don't add lexical in for, changing in place.
    foreach ( grep { ref $_ } values %{$new} ) {
        if ( ref [] eq ref $_ ) {
            $_ = [ @{$_} ];
        }
    }
    return $new;
}

# Make a copy of the task description with changes.
# Makes a one-level deep copy of the hash. If this structure is ever extended
# to support more complex attributes, this method will need to change.
#
# Returns the modified clone.
sub mutate {
    my $self  = shift;
    my %parms = %{ shift() };

    my $new = $self->clone();

    if ( exists $parms{timeout} ) {
        $self->_throw('Invalid child timeout.') unless _is_pos_int( $parms{timeout} );
        $new->{_child_timeout} = $parms{timeout};
    }
    if ( exists $parms{retries} ) {
        $self->_throw('Invalid value for retries.') unless _is_pos_int( $parms{retries} );
        $new->{_retries} = $parms{retries};
    }
    if ( exists $parms{userdata} ) {
        $self->_verify_userdata_arg( $parms{userdata} );
        while ( my ( $k, $v ) = each %{ $parms{userdata} } ) {
            $new->{_userdata}->{$k} = $v;
        }
    }

    return $new;
}

# Accessors
sub command           { return $_[0]->{_command}; }
sub full_command      { return "$_[0]->{_command} $_[0]->{_argstring}"; }
sub argstring         { return $_[0]->{_argstring}; }
sub args              { return @{ $_[0]->{_args} }; }
sub timestamp         { return $_[0]->{_timestamp}; }
sub uuid              { return $_[0]->{_uuid}; }
sub child_timeout     { return $_[0]->{_child_timeout}; }
sub started           { return $_[0]->{_started}; }
sub pid               { return $_[0]->{_pid}; }
sub retries_remaining { return $_[0]->{_retries}; }

sub get_userdata {
    my $self = shift;
    my $key  = shift;
    $self->_throw('No userdata key specified') unless defined $key;
    return unless exists $self->{_userdata}->{$key};
    return $self->{_userdata}->{$key};
}

sub get_arg {
    my ( $self, $index ) = @_;
    return $self->{_args}->[$index];
}

sub set_pid { $_[0]->{_pid}     = $_[1]; return; }
sub begin   { $_[0]->{_started} = time;  return; }

sub decrement_retries {
    my $self = shift;
    return unless $self->{_retries};
    $self->{_retries}--;
    return;
}

# Utility methods

# Create a UUID from the supplied namespace and name.
# Based on code in RFC 4122, verified against Data::UUID
sub _make_name_based_uuid {
    my ( $nsid, $name ) = @_;

    return sprintf( 'TQ:%s:%s', $nsid, $name );
}

#
# Returns true if the supplied parameter is a positive integer.
sub _is_pos_int {
    my $val = shift;
    return unless defined $val;
    return unless $val =~ /^\d+$/;
    return $val > 0;
}

sub _is_valid_ns {
    my $val = shift;
    return defined $val && length $val && $val !~ /:/;
}

sub is_valid_taskid {
    my $val = shift;
    return defined $val && $val =~ /^TQ:[^:]+:\d+$/;
}

sub _verify_userdata_arg {
    my $class = shift;
    my $arg   = shift;
    $class->_throw('Expected a hash reference for userdata value.') unless 'HASH' eq ref $arg;
    my @bad_keys;
    while ( my ( $k, $v ) = each %{$arg} ) {
        push @bad_keys, $k if ref $v;
    }
    if (@bad_keys) {
        @bad_keys = sort @bad_keys;
        $class->_throw("Reference values not allowed as userdata. Keys containing references: @bad_keys");
    }
    return;
}

1;

__END__


=head1  NAME

cPanel::TaskQueue::Task - Objects representing the task concept.

=head1 SYNOPSIS

    use cPanel::TaskQueue;

    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => "/home/$user/.cpanel/state" } );

    $queue->queue_task( "init_quota" );
    $queue->queue_task( "edit_quota fred 0" );

=head1  DESCRIPTION

This module provides an abstraction for the tasks we insert into the
C<cPanel::TaskQueue>.  They should not be instantiated directly, the TaskQueue
object will handle that.

=head1 PUBLIC METHODS

=over 4

=item cPanel::TaskQueue::Task->new( $args_ref )

Creates a new Task object based on the parameters supplied in the hashref.

=over 4

=item I<cmd>

The command string that we will turn into a task. The string consists of a command
name and an optional whitespace-separated set of arguments. If an argument must
contain spaces, surround it with quotes.

=item I<nsid>

A namespace string used to generate a unique identifier for the Task. Must be a
non-empty string containing no ':' characters. Defaults to an internal UUID.

=item I<id>

A sequence number combined with the I<nsid> to create a unique Task ID.

=item I<timeout>

This is a number of seconds after which a child task should be timed out.

=item I<retries>

The initial value for the retry counter. Must be a positive integer.

=item I<userdata>

The value of this parameter is a hash containing data that the Task will maintain
on behalf of the user. This may be used to pass data from the scheduling process
to the running process that is inconvenient to store in the Processor. For
example, the data used to drive the retry code uses the I<userdata> structure.

None of the values in the I<userdata> hash may be references (or objects). This
limitation reduces the possibility of Tasks that cannot be restored correctly
from disk.

=back

=item cPanel::TaskQueue::Task->reconstitute( $task_hash )

Given a hash that represents the core of a C<Cpanel::TaskQueue::Task> object,
rebuild a task object to match this state. This class method supports
rebuilding the C<Task> objects after a serialize/deserialize round-trip that
strips the type from the objects.

The method dies if any parameter is the wrong type or or if any parameters are
missing. Extra parameters are discarded. The data is cloned to remove the
chance that someone will mess with the object through the original hash.

=item $q->clone()

Create a deep copy of the C<cPanel::TaskQueue::Task> object.

=item $q->mutate( $hashref )

Clone the C<cPanel::TaskQueue::Task> object and modify some of its properties.

The C<mutate> method supports hashref argument that contains small number of
named parameters for changing the associated properties.

=over 4

=item I<timeout>

=item I<retries>

=item I<userdata>

=back

These parameters act in much the same way as their counterparts in the C<new>
method above. The one difference is the I<userdata> parameter. This parameter
does not replace the user data from the original Task. Instead, the old user
data is merged with the data supplied by this parameter. Any data without a key
in the new hash is kept as it was, otherwise it is replaced by the new value.

=back

=head2 ACCESSORS

There are accessors for each of the properties of the Task object.

=over 4

=item $t->command()

Returns the name of the task, without arguments

=item $t->full_command()

Returns the C<command> and C<argstring> values joined by a single space.

=item $t->argstring()

Returns the unparsed argument string.

=item $t->args()

Returns the list of parsed arguments.

=item $t->get_arg( $index )

Returns the argument at the supplied I<index>, C<undef> if there is no argument
at that index.

=item $t->timestamp()

Return the time the item was added to the queue in epoch seconds.

=item $t->uuid()

Return the unique ID of this queue item.

=item $t->child_timeout()

Return timeout for a child process in seconds

=item $t->started()

Return the timestamp of the point in time the task started in epoch seconds.

=item $t->pid()

Return pid of the child process executing this command

=item $t->retries_remaining()

Return the current value of the remaining retries counter.

=item $t->get_userdata( $key )

Return the userdata associated with the supplied I<key> if any exists, otherwise return C<undef>.

=back

=head2 MUTATORS

These method modify the data in the C<Task>.

=over 4

=item $t->set_pid( $pid )

Set the pid of the Task to the child process executing the Task.

=item $t->begin()

Set the I<started> time of the process to the current time in epoch seconds.

=item $t->decrement_retries()

If the retry count is greater than 0, decrement it by one.

=back

=head2 CLASS METHODS

=over

=item cPanel::TaskQueue::Task::is_valid_taskid( $taskid )

Returns true if the supplied C<$taskid> is of the right form to be a Task id.

=back

=head1 DIAGNOSTICS

The following messages can be reported by this module:

=over 4

=item C<< Missing arguments. >>

The C<new> method was called with no hash ref to initialize the object state.

=item C<< Args parameter must be a hash ref. >>

Incorrect parameter type for C<new> method. Probably called the method with either positional arguments
or with named arguments outside an anonymous hash.

=item C<< Missing command string. >>

The I<new> method was called without a I<cmd> parameter that lists the command to execute.

=item C<< Invalid Namespace UUID. >>

The method was called with something other than a 16-byte binary UUID as the I<nsid> parameter.

=item C<< Invalid id. >>

The method was called with something other than a positive integer as the I<id> parameter.

=item C<< Invalid child timeout. >>

The method was called with something other than a positive integer as the I<timeout> parameter.

=item C<< Invalid value for retries. >>

The method was called with something other than a positive integer as the I<retries> parameter.

=item C<< Expected a hash reference for userdata value. >>

The method was called with something other than a hash as the value of the I<userdata> parameter.

=item C<< Reference values not allowed as userdata. Keys containing references: %s. >>

The hash passed as the I<userdata> value contained values that are references. This is currently not allowed.
The keys with the inappropriate data are listed at the end of the message.

=item C<< No userdata key specified. >>

No key name was passed to the C<get_userdata> method.

=back

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

none reported.

=head1 SEE ALSO

cPanel::TaskProcessor

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
