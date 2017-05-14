=pod

=head1 NAME

Test::Mockify::Verify - To verify mock interactions

=head1 DESCRIPTION

Sometimes you will need to verify that a specific method was called a certain amount of times, each time with specific parameters.
Mockify provides the following methods to access this data.

=head1 METHODS

=cut
package Test::Mockify::Verify;

use Test::Mockify::Tools qw ( Error IsValid );
use Test::Mockify::TypeTests qw ( IsInteger );
use Scalar::Util qw( blessed );

use base qw ( Exporter );

use strict;
use warnings;

our @EXPORT_OK = qw (
    GetParametersFromMockifyCall
    WasCalled
    GetCallCount
);

#----------------------------------------------------------------------------------------=
=pod

=head2 GetParametersFromMockifyCall

  my $aParameters = GetParametersFromMockifyCall($MockifiedObject, 'nameOfMethod', $OptionalPosition);

This function returns all the parameters after the I<mockified> module was used. If the test calls the method multiple times, the "$OptionalPosition" can be used to get the specific call. The default is "0".
Returns an array ref with the parameters of the specific method call.
I<(Note: The calls are counted starting from zero. You will get the parameters from the first call with 0, the ones from the second call with 1, and so on.)>

=cut
sub GetParametersFromMockifyCall {
    my ( $MockifiedMockedObject, $MethodName, $Position ) = @_;

    if( not blessed $MockifiedMockedObject){
        Error('The first argument must be blessed');
    }
    my $PackageName = ref($MockifiedMockedObject);
    if( not IsValid( $MethodName )){
        Error('Method name must be specified', {'Position'=>$Position, 'Package' => $PackageName});
    }
    if ( not $MockifiedMockedObject->can('__getParametersFromMockifyCall') ){
        Error("$PackageName was not mockified", { 'Position'=>$Position, 'Method' => $MethodName});
    }
    if( !( $Position ) || !(IsInteger( $Position ))){
        $Position = 0;
    }

    return $MockifiedMockedObject->__getParametersFromMockifyCall( $MethodName, $Position );
}

#----------------------------------------------------------------------------------------=
=pod

=head2 WasCalled

  my $WasCalled = WasCalled($MockifiedObject, 'nameOfMethod');

This function returns the information if the method was called on the I<mockified> module.

=cut
sub WasCalled {
    my ( $MockifiedMockedObject, $MethodName ) = @_;

    my $WasCalled;
    my $AmountOfCalles = GetCallCount( $MockifiedMockedObject, $MethodName );
    if($AmountOfCalles > 0){
        $WasCalled = 1;
    }else{
        $WasCalled = 0;
    }

    return $WasCalled;
}
#----------------------------------------------------------------------------------------=
=pod

=head2 GetCallCount

  my $AmountOfCalls = GetCallCount($MockifiedObject, 'nameOfMethod');

This function returns the information on how often the method was called on the I<mockified> module. If the method was not called it will return "0".

=cut
sub GetCallCount {
    my ( $MockifiedMockedObject, $MethodName ) = @_;

    _TestMockifyObject( $MockifiedMockedObject );
    return $MockifiedMockedObject->{'__MethodCallCounter'}->getAmountOfCalls( $MethodName );
}

#----------------------------------------------------------------------------------------
sub _TestMockifyObject {
    my ( $MockifiedMockedObject ) = @_;

    my $ObjectPath = ref( $MockifiedMockedObject );
    if( not IsValid( $ObjectPath ) ){
        Error( 'Object is not defined' );
    }
    if ( $MockifiedMockedObject->{'__isMockified'} != 1){
        Error( "The Object: '$ObjectPath' is not mockified" );
    }

    return;
}

1;
__END__

=head1 LICENSE

Copyright (C) 2017 ePages GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Christian Breitkreutz E<lt>christianbreitkreutz@gmx.deE<gt>

=cut