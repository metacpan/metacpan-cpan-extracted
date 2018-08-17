package cPanel::TaskQueue::Task;
$cPanel::TaskQueue::Task::VERSION = '0.900';
use strict;

#use warnings;

# Namespace for the ids created by this class.
my $task_uuid = 'TaskQueue-Task';

my @fields = qw/_command _argstring _args _timestamp _uuid _child_timeout _started _pid _retries _userdata/;

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

    foreach my $field (@fields) {
        $class->_throw("Missing '$field' field in supplied hash") unless exists $hash->{$field};
        next if $field eq '_pid' or $field eq '_started';
        $class->_throw("Field '$field' has no value") unless defined $hash->{$field};
    }
    $class->_throw(q{The '_args' field must be an array}) unless ref [] eq ref $hash->{_args};

    my %object;
    foreach my $field (@fields) {
        if ( ref [] eq ref $hash->{$field} ) {
            $object{$field} = [ @{ $hash->{$field} } ];
        }
        else {
            $object{$field} = $hash->{$field};
        }
    }

    return bless \%object, $class;
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

Copyright (c) 2010, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

