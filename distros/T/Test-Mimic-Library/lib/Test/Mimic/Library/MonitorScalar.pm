package Test::Mimic::Library::MonitorScalar;

use strict;
use warnings;

use constant {
    # Instance variables
    VALUE   => 0,
    HISTORY => 1,
};

sub TIESCALAR {
    my ( $class, $history, $val ) = @_;
    
    # Initialize instance variables.
    my $self = [];
    $self->[VALUE] = ${$val};
    $self->[HISTORY] = $history;
    
    bless( $self, $class );
}

sub FETCH {
    my ( $self ) = @_;
    
    my $value = $self->[VALUE];
    if ( ! $Test::Mimic::Recorder::Recording ) {
        push( @{ $self->[HISTORY] }, Test::Mimic::Library::monitor( $value ) );
    }
    
    return $value;
}

sub STORE {
    my ( $self, $value ) = @_;
    $self->[VALUE] = $value;
}

# optional methods
sub UNTIE {
    
}

sub DESTROY {
    
}

1;
