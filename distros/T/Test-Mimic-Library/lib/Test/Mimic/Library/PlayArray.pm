package Test::Mimic::Library::PlayArray;

use strict;
use warnings;

use base qw<Tie::Array>;

use constant {
    # Instance variable indices
    HISTORY => 0,
    
    # History fields
    FETCH_F     => 0,
    FETCHSIZE_F => 1,
    EXISTS_F    => 2,
};

# basic methods
sub TIEARRAY {
    my ( $class, $history ) = @_;

    #Initialize instance variables.
    my $self = [];

    $self->[HISTORY] = $history;

    return bless( $self, $class );
}

sub FETCH {
    my ( $self, $index ) = @_;

    return Test::Mimic::Library::play( shift( @{ $self->[HISTORY]->[FETCH_F]->[$index] } ) );
}

sub STORE {
    # not a read, do nothing
}

sub FETCHSIZE {
    my ($self) = @_;

    return shift( @{ $self->[HISTORY]->[FETCHSIZE_F] } );    
}

sub STORESIZE {
    # not a read, do nothing
}

# other methods
sub DELETE {
    # not a read, do nothing
}

sub EXISTS {
    my ( $self, $index ) = @_;
    
    return shift( @{ $self->[HISTORY]->[EXISTS_F]->[$index] } );
}

#POP, SHIFT, and SPLICE will be inherited from Tie::Array

#NOTE: We always consider SPLICE to be a read.

sub CLEAR {
    # not a read, do nothing
}

sub PUSH {
    # not a read, do nothing
}

sub UNSHIFT {
    # not a read, do nothing
}

# optional methods
sub UNTIE {
    
}

sub DESTROY {
    
}

1;
