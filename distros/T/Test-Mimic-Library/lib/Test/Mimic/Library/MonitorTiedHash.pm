package Test::Mimic::Library::MonitorTiedHash;

use strict;
use warnings;

use base qw<Tie::Hash>;

use constant {
    # Instance variables
    BACKING_VAR => 0,
    HISTORY => 1,
    
    # History fields
    FETCH_F     => 0,
    KEYS_F      => 1,
    EXISTS_F    => 2,
    SCALAR_F    => 3,
};

sub TIEHASH {
    my ( $class, $history, $backing_var ) = @_;
    
    # Initialize instance variables.
    my $self = [];
    $self->[BACKING_VAR] = $backing_var;
    for my $field ( FETCH_F, EXISTS_F ) {
        $history->[$field] = {};
    }
    for my $field ( KEYS_F, SCALAR_F ) {
        $history->[$field] = [];
    }
    $self->[HISTORY] = $history;

    bless( $self, $class );
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    
    $self->[BACKING_VAR]->STORE( $key, $value );
}

sub FETCH {
    my ( $self, $key ) = @_;
    
    my $value = $self->[BACKING_VAR]->FETCH($key);
    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        my $key_history = ( $self->[HISTORY]->[FETCH_F]->{$key} ||= [] ); 
        push( @{$key_history}, Test::Mimic::Library::monitor( $value ) );
    }
    
    return $value;
}

sub FIRSTKEY {
    my ($self) = @_;

    my $key = $self->[BACKING_VAR]->FIRSTKEY();

    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        push( @{ $self->[HISTORY]->[KEYS_F] }, $key ); 
    }
    
    return $key;
}

sub NEXTKEY {
    my ( $self, $last_key ) = @_;
    
    my $key = $self->[BACKING_VAR]->NEXTKEY($last_key);

    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        push( @{ $self->[HISTORY]->[KEYS_F] }, $key ); 
    }
    
    return $key;
}

sub EXISTS {
    my ( $self, $key ) = @_;
    
    my $result = $self->[BACKING_VAR]->EXISTS($key);
    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        my $exists_history = ( $self->[HISTORY]->[EXISTS_F]->{$key} ||= [] );
        push( @{$exists_history}, $result );
    }
    
    return $result;
}

sub DELETE {
    my ( $self, $key ) = @_;
    
    $self->[BACKING_VAR]->DELETE($key);
}

# Any non-read inherited operation should not alter the history.
sub CLEAR {
    my $self = shift(@_);
    local $Test::Mimic::Recorder::SuspendRecording = 1;
    $self->SUPER::CLEAR(@_);
}

sub SCALAR {
    my ( $self ) = @_;
    
    my $result = $self->[BACKING_VAR]->SCALAR();
    if ( ! $Test::Mimic::Recorder::SuspendRecording ) {
        push( @{ $self->[HISTORY]->[SCALAR_F] }, $result );
    }
    
    return $result;
}

1;
