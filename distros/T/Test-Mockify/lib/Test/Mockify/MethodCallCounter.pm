package Test::Mockify::MethodCallCounter;
use Test::Mockify::Tools qw ( Error );
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}

sub addMethod {
    my $self = shift;
    my ( $MethodName ) = @_;

    $self->{$MethodName} = 0;

    return;
}

sub increment {
    my $self = shift;
    my ( $MethodName ) = @_;

    $self->_testIfMethodWasAdded( $MethodName );
    $self->{$MethodName} += 1;

    return;
}

sub getAmountOfCalls {
    my $self = shift;
    my ( $MethodName ) = @_;

    $self->_testIfMethodWasAdded( $MethodName );
    my $AmountOfCalls = $self->{ $MethodName };

    return $AmountOfCalls;
}

sub _testIfMethodWasAdded {
    my $self = shift;
    my ( $MethodName ) = @_;

    if( not exists $self->{ $MethodName } ){
        Error( "The Method: '$MethodName' was not added to Mockify" );
    }
}
1;