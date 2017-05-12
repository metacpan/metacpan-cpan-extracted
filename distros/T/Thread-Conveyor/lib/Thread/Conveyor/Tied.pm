package Thread::Conveyor::Tied;

# Make sure we have version info for this module
# Make sure we are a belt
# Make sure we do everything by the book from now on

$VERSION = '0.19';
@ISA = qw(Thread::Conveyor);
use strict;

# Make sure we only load stuff when we actually need it

use load;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# The following subroutines are loaded only on demand

__END__

#---------------------------------------------------------------------------

# Class methods

#---------------------------------------------------------------------------
#  IN: 1 class with which to bless the object
# OUT: 1 instantiated object

sub new {

# Create the tied conveyor belt
# And bless reference to belt + its semaphore as an object and return it

    tie my @array,'Thread::Tie';
    bless [\@array,(tied @array)->semaphore],shift;
} #new

#---------------------------------------------------------------------------

# object methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 shared item on which you can lock

sub semaphore { shift->[1] } # semaphore

#---------------------------------------------------------------------------

# Object methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed as a box onto the belt

sub put {

# Obtain the object
# Return now if nothing to do

    my ($array,$semaphore) = @{shift()};
    return unless @_;

# Make sure we're the only one putting things on the belt
# Freeze the parameters and put it in a box on the belt
# Signal the other worker threads that there is a new box on the belt

    lock( $semaphore );
    push( @$array,Thread::Serialize::freeze( @_ ) );
    threads::shared::cond_signal( $semaphore );
} #put

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a box on the belt

sub take {

# Obtain the belt and semaphore
# Create an empty box

    my ($array,$semaphore) = @{shift()};
    my $box;

# Make sure we're the only one working on the belt
# Wait until someone else puts something on the belt
# Take the box off the belt
# Wake up other worker threads if there are still boxes now

    {lock( $semaphore );
     threads::shared::cond_wait( $semaphore ) until @$array;
     $box = shift( @$array );
     threads::shared::cond_signal( $semaphore ) if @$array;
    } #$semaphore

# Thaw the contents of the box and return the result

    Thread::Serialize::thaw( $box );
} #take

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a box on the belt

sub take_dontwait {

# Obtain the object
# Obtain belt and semaphore
# Make sure we're the only one handling the belt
# Return the result of taking of a box if there is one, or an empty list

    my $self = shift;
    my ($array,$semaphore) = @{$self};
    lock( $semaphore );
    return @$array ? $self->take : ();
} #take_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N references to data-structures in boxes

sub clean {

# Obtain the object
# Return now after cleaning if we're not interested in the result
# Clean the belt and turn the boxes into references

    my $self = shift;
    return $self->_clean unless wantarray;
    map {[Thread::Serialize::thaw( $_ )]} $self->_clean;
} #clean

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N references to data-structures in boxes

sub clean_dontwait {

# Obtain the object
# Obtain the belt and semaphore
# Make sure we're the only one handling the belt
# Return the result of cleaning the belt if there are boxes, or an empty list

    my $self = shift;
    my ($array,$semaphore) = @{$self};
    lock( $semaphore );
    return @$array ? $self->clean : ();
} #clean_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 ordinal number in array to return (default: 0)
# OUT: 1..N parameters returned from a box on the belt

sub peek {

# Obtain the belt and the semaphore
# Create an empty box

    my ($array,$semaphore) = @{shift()};
    my $box;

# Make sure we're the only one working on the belt
# Wait until someone else puts something on the belt
# Copy the box off the belt
# Wake up other worker threads again

    {lock( $semaphore );
     threads::shared::cond_wait( $semaphore ) until @$array;
     $box = $array->[shift || 0];
     threads::shared::cond_signal( $semaphore );
    } #$semaphore

# Thaw the contents of the box and return the result

    Thread::Serialize::thaw( $box );
} #peek

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 ordinal number in array to return (default: 0)
# OUT: 1..N parameters returned from a box on the belt

sub peek_dontwait {

# Obtain the object
# Obtain the belt and the semaphore
# Make sure we're the only one handling the belt
# Return the result of taking of a box if there is one, or an empty list

    my $self = shift;
    my ($array,$semaphore) = @{$self};
    lock( $semaphore );
    return @$array ? $self->peek( @_ ) : ();
} #peek_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 number of boxes still on the belt

sub onbelt { scalar(@{$_[0]->[0]}) } #onbelt

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub maxboxes {
    die "Cannot change throttling on a belt that was created unthrottled";
} #maxboxes

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub minboxes {
    die "Cannot change throttling on a belt that was created unthrottled";
} #minboxes

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub shutdown { undef } #shutdown

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 thread object associated with belt (always undef)

sub thread { undef } #thread

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 thread id of thread object associated with belt (always undef)

sub tid { undef } #tid

#---------------------------------------------------------------------------

# Internal subroutines

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N all frozen boxes on the belt

sub _clean {

# Obtain the belt
# Initialize the list of frozen boxes

    my ($array,$semaphore) = @{shift()};
    my @frozen;

# Make sure we're the only one accessing the belt
# Wait until there is something on the belt
# Obtain the entire contents of the belt of we want it
# Clean the belt
# Notify the world again

    {lock( $semaphore );
     threads::shared::cond_wait( $semaphore ) until @$array;
     @frozen = @$array if wantarray;
     @$array = ();
     threads::shared::cond_broadcast( $semaphore );
    } #$semaphore

# Return the frozen goods

    @frozen;
} #_clean

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Conveyor::Tied - tied array implementation of Thread::Conveyor

=head1 DESCRIPTION

This class should not be called by itself, but only with a call to
L<Thread::Conveyor>.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2004, 2007, 2010 Elizabeth Mattijsen <liz@dijkmat.nl>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Thread::Conveyor>.

=cut
