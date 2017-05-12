package Test::Mimic::Library::MonitorTiedArray;

use strict;
use warnings;

use base qw<Tie::Array>;

use constant {
    # Instance variables
    BACKING_VAR => 0,
    HISTORY => 1,
    
    # History fields
    FETCH_F     => 0,
    FETCHSIZE_F => 1,
    EXISTS_F    => 2,
};

# basic methods
sub TIEARRAY {
    my ( $class, $history, $backing_var ) = @_;
    
    # Initialize instance variables.
    my $self = [];
    $self->[BACKING_VAR] = $backing_var;
    for my $field ( FETCH_F, FETCHSIZE_F, EXISTS_F ) {
        $history->[$field] = [];
    }
    $self->[HISTORY] = $history;
    
    bless( $self, $class );
}

sub FETCH {
    my ( $self, $index ) = @_;
    
    my $value = $self->[BACKING_VAR]->FETCH($index);
    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        my $index_history = ( $self->[HISTORY]->[FETCH_F]->[$index] ||= [] );
        push( @{$index_history}, Test::Mimic::Library::monitor( $value ) );
    }
    
    return $value;
}

sub STORE {
    my ( $self, $index, $value ) = @_;
    
    $self->[BACKING_VAR]->STORE( $index, $value );
}

sub FETCHSIZE {
    my ($self) = @_;
    
    my $size = $self->[BACKING_VAR]->FETCHSIZE();
    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        push( @{ $self->[HISTORY]->[FETCHSIZE_F] }, $size );
    }
    
    return $size;
}

sub STORESIZE {
    my ( $self, $size ) = @_;

    $self->[BACKING_VAR]->STORESIZE($size);    
}

# other methods
sub DELETE {
    my ( $self, $index ) = @_;
    
    $self->[BACKING_VAR]->DELETE($index);
}

sub EXISTS {
    my ( $self, $index ) = @_;
    
    my $result = $self->[BACKING_VAR]->EXISTS($index);
    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        my $exists_history = ( $self->[HISTORY]->[EXISTS_F]->[$index] ||= [] );
        push( @{$exists_history}, $result );
    }
    
    return $result;
}

# We need to turn off recording for any non-read inherited operations.
sub PUSH {
    my $self = shift(@_);
    local $Test::Mimic::Recorder::SuspendRecording = 1;
    $self->SUPER::PUSH(@_);
}

sub UNSHIFT {
    my $self = shift(@_);
    local $Test::Mimic::Recorder::SuspendRecording = 1;
    $self->SUPER::UNSHIFT(@_);
}

# Not truly needed for CLEAR, but if the implementation of Tie::Hash changes this will save us.
sub CLEAR {
    my $self = shift(@_);
    local $Test::Mimic::Recorder::SuspendRecording = 1;
    $self->SUPER::CLEAR();
}

#POP, SHIFT, and SPLICE will be inherited from Tie::Array

# optional methods
sub UNTIE {
    my ($self) = @_;
    $self->[BACKING_VAR]->UNTIE();
}

sub DESTROY {
    my ($self) = @_;
    $self->[BACKING_VAR]->DESTROY();
}

1;
