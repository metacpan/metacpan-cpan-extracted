#========================================================================================
# §package      MethodCallCounter
# §state        public
#----------------------------------------------------------------------------------------
# §description  encapsulate the Call Counter for Mockify
#========================================================================================
package Test::Mockify::MethodCallCounter;

use Test::Mockify::Tools qw ( Error );

use strict;
#========================================================================================
# §function     new
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       new( );
#----------------------------------------------------------------------------------------
# §description  constructor
#----------------------------------------------------------------------------------------
# §return       $self | self | MethodCallCounter
#========================================================================================
sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}
#========================================================================================
# §function     addMethod
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       addMethod( $MethodName );
#----------------------------------------------------------------------------------------
# §description  add the Method '$MethodName' to the counter
#----------------------------------------------------------------------------------------
# §input        $MethodName | name of method | string
#========================================================================================
sub addMethod {
    my $self = shift;
    my ( $MethodName ) = @_;

    $self->{$MethodName} = 0;

    return;
}
#========================================================================================
# §function     increment
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       increment( $MethodName );
#----------------------------------------------------------------------------------------
# §description  increment the the counter for the Method '$MethodName'
#----------------------------------------------------------------------------------------
# §input        $MethodName | name of method | string
#========================================================================================
sub increment {
    my $self = shift;
    my ( $MethodName ) = @_;

    $self->_testIfMethodWasAdded( $MethodName );
    $self->{$MethodName} += 1;

    return;
}
#========================================================================================
# §function     getAmountOfCalls
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       getAmountOfCalls( $MethodName );
#----------------------------------------------------------------------------------------
# §description  returns the amount of calls for the method '$MethodName'
#               throws error if the method was not added to Mockify
#----------------------------------------------------------------------------------------
# §input        $MethodName | name of method | string
# §return       $AmountOfCalls | Amount of calles | integer
#========================================================================================
sub getAmountOfCalls {
    my $self = shift;
    my ( $MethodName ) = @_;

    $self->_testIfMethodWasAdded( $MethodName );
    my $AmountOfCalls = $self->{ $MethodName };

    return $AmountOfCalls;
}
#----------------------------------------------------------------------------------------
sub _testIfMethodWasAdded {
    my $self = shift;
    my ( $MethodName ) = @_;

    if( not exists $self->{ $MethodName } ){
        Error( "The Method: '$MethodName' was not added to Mockify" );
    }
}
1;