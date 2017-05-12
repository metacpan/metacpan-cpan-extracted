package Thread::Conveyor::Throttled;

# Make sure we have version info for this module
# Make sure we're a conveyor belt
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
#      2 parameter hash reference
# OUT: 1 instantiated object

sub new {

# Obtain the class
# Obtain the parameter hash
# Create a conveyor belt of the right type and save its object
# Create local copy of it's semaphore (save one indirection later on)
# Return with a blessed object

    my $class = shift;
    my $self = shift;
    my $belt = $self->{'belt'} = $class->SUPER::_new(
     'Thread::Conveyor::'.(qw(Tied Array)[($self->{'optimize'}||'') eq 'cpu']),
     @_
    );
    $self->{'semaphore'} = $belt->semaphore;
    bless $self,$class;
} #new

#---------------------------------------------------------------------------

# object methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed as a box onto the belt

sub put {

# Obtain the object
# De-activate box putting if too many now
# Go perform the ordinary method

    my $self = shift;
    $self->_red;
    $self->{'belt'}->put( @_ );
} #put

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a box on the belt

sub take {

# Obtain the object
# Activate box putting again if so allowed
# Go perform the ordinary method

    my $self = shift;
    $self->_green;
    $self->{'belt'}->take( @_ );
} #take

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a box on the belt

sub take_dontwait {

# Obtain the object
# Activate box putting again if so allowed
# Go perform the ordinary method

    my $self = shift;
    $self->_green;
    $self->{'belt'}->take_dontwait( @_ );
} #take_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N references to contents of boxes

sub clean { shift->{'belt'}->clean } #clean

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N references to contents of boxes

sub clean_dontwait { shift->{'belt'}->clean_dontwait } #clean_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 index into array at which to peek (default: 0)
# OUT: 1..N parameters returned from a box on the belt

sub peek { shift->{'belt'}->peek( @_ ) } #peek

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 index into array at which to peek (default: 0)
# OUT: 1..N parameters returned from a box on the belt

sub peek_dontwait { shift->{'belt'}->peek_dontwait( @_ ) } #peek_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 number of boxes on the belt

sub onbelt { shift->{'belt'}->onbelt } #onbelt

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new maxboxes value (default: no change)
# OUT: 1 current maxboxes value

sub maxboxes {

# Obtain the object
# Set the new maxboxes and minboxes value if new value specified
# Return current value

    my $self = shift;
    $self->{'minboxes'} = ($self->{'maxboxes'} = shift) >> 1 if @_;
    $self->{'maxboxes'};
} #maxboxes

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new minboxes value (default: no change)
# OUT: 1 current minboxes value

sub minboxes {

# Obtain the object
# Set the new minboxes value if new value specified
# Return current value

    my $self = shift;
    $self->{'minboxes'} = shift if @_;
    $self->{'minboxes'};
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

# internal methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub _red { 

# Obtain the object
# Return now if there is no throttling anymore
# Obtain local copy of the belt

    my $self = shift;
    return unless $self->{'maxboxes'};
    my ($belt,$semaphore,$halted) = @$self{qw(belt semaphore halted)};

# Lock the belt
# If were halted
#  Wait until the halt flag is reset
#  Notify the rest of the world again

    lock( $semaphore );
    return unless $$halted;
    if ($$halted) {
        threads::shared::cond_wait( $semaphore ) while $$halted;
        threads::shared::cond_broadcast( $semaphore );

# Elseif there are now too many boxes in the belt
#  Set the box putting halted flag
#  Wake up any threads that are waiting for boxes to be handled
#  Wait until the halt flag is reset
#  Notify the rest of the world again

    } elsif ($belt->onbelt > $self->{'maxboxes'}) {
        $$halted = 1;
        threads::shared::cond_broadcast( $semaphore );
        threads::shared::cond_wait( $semaphore ) while $$halted;
        threads::shared::cond_broadcast( $semaphore );
    }
} #_red

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub _green {

# Obtain the object
# Return now if we don't have throttling anymore
# Get local copies of the stuff we need

    my $self = shift;
    return unless $self->{'maxboxes'};
    my ($belt,$semaphore,$halted) = @$self{qw(belt semaphore halted)};

# Lock access to the belt
# Return now if box putting is not halted
# Return if current number boxes of is still more than minimum number of boxes

    lock( $semaphore );
    return unless $$halted;
    return if $belt->onbelt > $belt->{'minboxes'};

# Reset the halted flag, allow box putting again
# Wake up all of the other threads to allow them to submit again

    $$halted = 0;
    threads::shared::cond_broadcast( $semaphore );
} #_green

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N references to frozen contents of boxes

sub _clean { shift->{'belt'}->_clean } #_clean

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Conveyor::Throttled - helper class of Thread::Conveyor

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
