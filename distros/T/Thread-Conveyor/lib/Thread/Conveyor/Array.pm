package Thread::Conveyor::Array;

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

# Obtain the class
# Create the conveyor belt
# And bless it as an object

    my $class = shift;
    my @belt : shared;
    bless \@belt,$class;
} #new

#---------------------------------------------------------------------------

# object methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 shared item on which you can lock

sub semaphore { shift } # semaphore

#---------------------------------------------------------------------------

# Object methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed as a box onto the belt

sub put {

# Obtain the object
# Return now if nothing to do

    my $belt = shift;
    return unless @_;

# Make sure we're the only one putting things on the belt
# Freeze the parameters and put it in a box on the belt
# Signal the other worker threads that there is a new box on the belt

    lock( @$belt );
    push( @$belt,Thread::Serialize::freeze( @_ ) );
    threads::shared::cond_signal( @$belt );
} #put

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a box on the belt

sub take {

# Obtain the object
# Create an empty box

    my $belt = shift;
    my $box;

# Make sure we're the only one working on the belt
# Wait until someone else puts something on the belt
# Take the box off the belt
# Wake up other worker threads if there are still boxes now

    {lock( @$belt );
     threads::shared::cond_wait( @$belt ) until @$belt;
     $box = shift( @$belt );
     threads::shared::cond_signal( @$belt ) if @$belt;
    } #@$belt

# Thaw the contents of the box and return the result

    Thread::Serialize::thaw( $box );
} #take

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a box on the belt

sub take_dontwait {

# Obtain the object
# Make sure we're the only one handling the belt
# Return the result of taking of a box if there is one, or an empty list

    my $belt = shift;
    lock( @$belt );
    return @$belt ? $belt->take : ();
} #take_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N references to data-structures in boxes

sub clean {

# Obtain the belt
# Return now after cleaning if we're not interested in the result
# Clean the belt and turn the boxes into references

    my $belt = shift;
    return $belt->_clean unless wantarray;
    map {[Thread::Serialize::thaw( $_ )]} $belt->_clean;
} #clean

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N references to data-structures in boxes

sub clean_dontwait {

# Obtain the belt
# Make sure we're the only one handling the belt
# Return the result of cleaning the belt if there are boxes, or an empty list

    my $belt = shift;
    lock( @$belt );
    return @$belt ? $belt->clean : ();
} #clean_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 ordinal number in array to return (default: 0)
# OUT: 1..N parameters returned from a box on the belt

sub peek {

# Obtain the object
# Create an empty box

    my $belt = shift;
    my $box;

# Make sure we're the only one working on the belt
# Wait until someone else puts something on the belt
# Copy the box off the belt
# Wake up other worker threads again

    {lock( @$belt );
     threads::shared::cond_wait( @$belt ) until @$belt;
     $box = $belt->[shift || 0];
     threads::shared::cond_signal( @$belt );
    } #@$belt

# Thaw the contents of the box and return the result

    Thread::Serialize::thaw( $box );
} #peek

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 ordinal number in array to return (default: 0)
# OUT: 1..N parameters returned from a box on the belt

sub peek_dontwait {

# Obtain the object
# Make sure we're the only one handling the belt
# Return the result of taking of a box if there is one, or an empty list

    my $belt = shift;
    lock( @$belt );
    return @$belt ? $belt->peek( @_ ) : ();
} #peek_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 number of boxes still on the belt

sub onbelt { scalar(@{$_[0]}) } #onbelt

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

    my $belt = shift;
    my @frozen;

# Make sure we're the only one accessing the belt
# Wait until there is something on the belt
# Obtain the entire contents of the belt of we want it
# Clean the belt
# Notify the world again

    {lock( @$belt );
     threads::shared::cond_wait( @$belt ) until @$belt;
     @frozen = @$belt if wantarray;
     @$belt = ();
     threads::shared::cond_broadcast( @$belt );
    } #@$belt

# Return the frozen goods

    @frozen;
} #_clean

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Conveyor::Array - array implementation of Thread::Conveyor

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
