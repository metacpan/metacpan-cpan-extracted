package Test::Mimic::Library::PlayScalar;

use strict;
use warnings;

use constant {
    # Instance variable indices
    HISTORY => 0,
};

sub TIESCALAR {
    my ( $class, $history ) = @_;

    # Initialize instance variables.
    my $self = [];
    $self->[HISTORY] = $history;

    return bless( $self, $class );
}

sub FETCH {
    my ( $self ) = @_;

    return Test::Mimic::Library::play( shift( @{ $self->[HISTORY] } ) );
}

sub STORE {
    # not a read, do nothing
}

# optional methods
sub UNTIE {
    
}

sub DESTROY {
    
}

1;
