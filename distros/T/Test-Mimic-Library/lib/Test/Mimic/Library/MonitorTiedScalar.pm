package Test::Mimic::Library::MonitorTiedScalar;

use strict;
use warnings;

use constant {
    # Instance variables
    BACKING_VAR => 0,
    HISTORY     => 1,
};

sub TIESCALAR {
    my ( $class, $history, $backing_var ) = @_;
    
    # Initialize instance variables.
    my $self = [];
    $self->[BACKING_VAR] = $backing_var;
    $self->[HISTORY] = $history;
    
    bless( $self, $class );
}

sub FETCH {
    my ($self) = @_;
    
    my $value = $self->[BACKING_VAR]->FETCH();
    if ( ! $Test::Mimic::Recorder::Recording ) {
        push( @{ $self->[HISTORY] }, Test::Mimic::Library::monitor( $value ) );
    }
    
    return $value;
}

sub STORE {
    my ( $self, $value ) = @_;
    $self->[BACKING_VAR]->STORE($value);
}

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
