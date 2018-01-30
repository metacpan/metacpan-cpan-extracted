=pod

=head1 NAME

Test::Mockify - minimal mocking framework for perl

=head1 SYNOPSIS

  use Test::Mockify;
  use Test::Mockify::Verify qw ( WasCalled );
  use Test::Mockify::Matcher qw ( String );

  # build a new mocked object
  my $MockObjectBuilder = Test::Mockify->new('SampleLogger', []);
  $MockObjectBuilder->mock('log')->when(String())->thenReturnUndef();
  my $MockedLogger = $MockLoggerBuilder->getMockObject();

  # inject mocked object into the code you want to test
  my $App = SampleApp->new('logger'=> $MockedLogger);
  $App->do_something();

  # verify that the mocked method was called
  ok(WasCalled($MockedLogger, 'log'), 'log was called');
  done_testing();

=head1 DESCRIPTION

Use L<Test::Mockify> to create and configure mock objects. Use L<Test::Mockify::Verify> to
verify the interactions with your mocks.

=head1 METHODS

=cut

package Test::Mockify;
use Test::Mockify::Tools qw ( Error ExistsMethod LoadPackage );
use Test::Mockify::TypeTests qw ( IsString IsArrayReference);
use Test::Mockify::MethodCallCounter;
use Test::Mockify::Method;
use Test::Mockify::MethodSpy;
use Test::MockObject::Extends;
use Test::Mockify::CompatibilityTools qw (MigrateOldMatchers);
use Scalar::Util qw( blessed );
use Sub::Override;

use strict;

our $VERSION = '1.3';

sub new {
    my $class = shift;
    my ( $FakeModulePath, $aFakeParams ) = @_;

    my $self = bless {}, $class;

    LoadPackage( $FakeModulePath );
    my $FakeClass = $FakeModulePath->can('new') ? $FakeModulePath->new( @{$aFakeParams} ) : $FakeModulePath;
    $self->_mockedModulePath($FakeModulePath);
    $self->_mockedSelf(Test::MockObject::Extends->new( $FakeClass ));
    $self->_initMockedModule();

    return $self;

}
#----------------------------------------------------------------------------------------
sub _mockedModulePath {
    my $self = shift;
    my ($ModulePath) = @_;
    return $self->{'MockedModulePath'} unless ($ModulePath);
    $self->{'MockedModulePath'} = $ModulePath;
}
#----------------------------------------------------------------------------------------
sub _mockedSelf {
    my $self = shift;
    my ($MockedSelf) = @_;
    return $self->{'MockedModule'} unless ($MockedSelf);
    $self->{'MockedModule'} = $MockedSelf;
}
#----------------------------------------------------------------------------------------
sub _initMockedModule {
    my $self = shift;

    $self->_mockedSelf()->{'__MethodCallCounter'} = Test::Mockify::MethodCallCounter->new();
    $self->_mockedSelf()->{'__isMockified'} = 1;
    $self->_addGetParameterFromMockifyCall();

    $self->{'override'} = Sub::Override->new();
    $self->{'IsStaticMockStore'} = undef;
    return;
}

#----------------------------------------------------------------------------------------
=pod

=head2 getMockObject

Provides the actual mock object, which you can use in the test.

  my $aParameterList = ['SomeValueForConstructor'];
  my $MockObjectBuilder = Test::Mockify->new( 'My::Module', $aParameterList );
  my $MyModuleObject = $MockObjectBuilder->getMockObject();

=cut
sub getMockObject {
    my $self = shift;
    return $self->_mockedSelf();
}

#----------------------------------------------------------------------------------------=
=pod

=head2 mock

This is the place where the mocked methods are defined. The method also proves that the method you like to mock actually exists.

=head3 synopsis

This method takes one parameter, which is the name of the method you like to mock.
Because you need to specify more detailed the behaviour of this mock you have to chain the method signature (when) and the expected return value (then...). 

For example, the next line will create a mocked version of the method log, but only if this method is called with any string and the number 123. In this case it will return the String 'Hello World'. Mockify will throw an error if this method is called somehow else.

  my $MockObjectBuilder = Test::Mockify->new( 'Sample::Logger', [] );
  $MockObjectBuilder->mock('log')->when(String(), Number(123))->thenReturn('Hello World');
  my $SampleLogger = $MockObjectBuilder->getMockObject();
  is($SampleLogger->log('abc',123), 'Hello World');


=head4 when

To define the signature in the needed structure you must use the L<< Test::Mockify::Matcher >>.

=head4 whenAny

If you don't want to specify the method signature at all, you can use whenAny.
It is not possible to mix C<whenAny> and C<when> for the same method.

=head4 then ...

For possible return types please look in L<Test::Mockify::ReturnValue>

=cut
sub mock {
    my $self = shift;
    my @Parameters = @_;

    my $ParameterAmount = scalar @Parameters;
    if($ParameterAmount == 1 && IsString($Parameters[0]) ){
        return $self->_addMockWithMethod($Parameters[0]);
    }
    if($ParameterAmount == 2){
        my ( $MethodName, $ReturnValueOrFunctionPointer ) = @Parameters;
        if( ref($ReturnValueOrFunctionPointer) eq 'CODE' ){
            $self->addMock($MethodName, $ReturnValueOrFunctionPointer);
        }else{
            $self->addMockWithReturnValue($MethodName, $ReturnValueOrFunctionPointer);
        }
    }
    if($ParameterAmount == 3){
        my ( $MethodName, $ReturnValue, $aParameterTypes ) = @_;
        $self->addMockWithReturnValueAndParameterCheck($MethodName, $ReturnValue, $aParameterTypes);
    }
    return;
}
#----------------------------------------------------------------------------------------
=pod

=head2 mockStatic

Sometimes it is not possible to inject the dependencies from the outside. This is especially the case when the package uses imports of static functions.
C<mockStatic> provides the possibility to mock static functions inside the mock/sut.

  package SUT;
  use Magic::Tools qw ( Rabbit ); # Rabbit could use a webservice
  sub pullCylinder {
      shift;
      if(Rabbit('white') && not Magic::Tools::Rabbit('black')){ # imported && full path
          return 1;
      }else{
          return 0;
      }
  }
  1;


In the Test it can be mocked

  package Test_SUT;
  my $MockObjectBuilder = Test::Mockify->new( 'SUT', [] );
  $MockObjectBuilder->mockStatic('Magic::Tools::Rabbit')->when(String('white'))->thenReturn(1);
  $MockObjectBuilder->mockStatic('Magic::Tools::Rabbit')->when(String('black'))->thenReturn(0);

  my $SUT = $MockObjectBuilder->getMockObject();
  is($SUT->pullCylinder(), 1);
  1;


It can be mixed with normal C<spy> and C<mock>

=head4 Thx
to @dbucky for this amazing idea

=cut
sub mockStatic {
    my $self = shift;
    my @Parameters = @_;

    my $ParameterAmount = scalar @Parameters;
    if($ParameterAmount == 1 && IsString($Parameters[0])){
        if( $Parameters[0] =~ /.*::.*/x ){
            $self->{'IsStaticMockStore'}{$Parameters[0]} = 1;
            return $self->_addMockWithMethod($Parameters[0]);
        }else{
            Error("The function name needs to be with full path. e.g. 'Path::To::Your::$Parameters[0]' instead of only '$Parameters[0]'");
        }
    }else{
        Error('The Parameter needs to be defined and a String. e.g. Path::To::Your::Function');
    }

}
=pod


=head2 spy

Use spy if you want to observe a method. You can use the L<Test::Mockify::Verify> to ensure that the method was called with the expected parameters.

=head3 synopsis

This method takes one parameter, which is the name of the method you like to spy.
Because you need to specify more detailed the behaviour of this spy you have to define the method signature with C<when>

For example, the next line will create a method spy of the method log, but only if this method is called with any string and the number 123. Mockify will throw an error if this method is called in another way.

  my $MockObjectBuilder = Test::Mockify->new( 'Sample::Logger', [] );
  $MockObjectBuilder->spy('log')->when(String(), Number(123));
  my $SampleLogger = $MockObjectBuilder->getMockObject();

  # call spied method
  $SampleLogger->log('abc', 123);

  # verify that the spied method was called
  is_deeply(GetParametersFromMockifyCall($MockedLogger, 'log'),['abc', 123], 'Check parameters of first call');

=head4 when

To define the signature in the needed structure you must use the L<< Test::Mockify::Matcher >>.

=head4 whenAny

If you don't want to specify the method signature at all, you can use whenAny.
It is not possible to mix C<whenAny> and C<when> for the same method.

=cut
sub spy {
    my $self = shift;
    my ($MethodName) = @_;
    my $PointerOriginalMethod = \&{$self->_mockedModulePath().'::'.$MethodName};
    #In order to have the current object available in the parameter list, it has to be injected here.
    return $self->_addMockWithMethodSpy($MethodName, sub {
        return $PointerOriginalMethod->($self->_mockedSelf(), @_);
    });
}
#----------------------------------------------------------------------------------------
=pod

=head2 spyStatic

Provides the possibility to spy static functions inside the mock/sut.

  package SUT;
  use Magic::Tools qw ( Rabbit ); # Rabbit could use a webservice
  sub pullCylinder {
      shift;
      if(Rabbit('white') && not Magic::Tools::Rabbit('black')){ # imported && full path
          return 1;
      }else{
          return 0;
      }
  }
  1;

In the Test it can be mocked

  package Test_SUT;
  my $MockObjectBuilder = Test::Mockify->new( 'SUT', [] );
  $MockObjectBuilder->spyStatic('Magic::Tools::Rabbit')->whenAny();
  my $SUT = $MockObjectBuilder->getMockObject();

  $SUT->pullCylinder();
  is(GetCallCount($SUT, 'pullCylinder), 1);

  1;

It can be mixed with normal C<spy> and C<mock>. For more options see, C<mockStatic>

=cut
sub spyStatic {
    my $self = shift;
    my ($MethodName) = @_;
    if( $MethodName =~ /.*::.*/x ){
        $self->{'IsStaticMockStore'}{$MethodName} = 1;
            my $PointerOriginalMethod = \&{$MethodName};
            #In order to have the current object available in the parameter list, it has to be injected here.
            return $self->_addMockWithMethodSpy($MethodName, sub {
                return $PointerOriginalMethod->($self->_mockedSelf(), @_);
            });
    }else{
        Error("The function name needs to be with full path. e.g. 'Path::To::Your::$MethodName' instead of only '$MethodName'");
    }
}
#----------------------------------------------------------------------------------------
=pod

=head2 addMethodSpy I<(deprecated)>

With this method it is possible to observe a method. That means, you keep the original functionality but you can get meta data from the mockify-framework.

  $MockObjectBuilder->addMethodSpy('myMethodName');

=cut
sub addMethodSpy {
    my $self = shift;
    my ( $MethodName ) = @_;
    if (warnings::enabled("deprecated")) {
        warnings::warn('deprecated', "addMethodSpy is deprecated, use spy('name')->whenAny()");
    }
    $self->spy($MethodName)->whenAny();
    return;
}
#----------------------------------------------------------------------------------------
=pod

=head2 addMethodSpyWithParameterCheck I<(deprecated)>

With this method it is possible to observe a method and check the parameters. That means, you keep the original functionality, but you can get meta data from the mockify- framework and use the parameter check, like B<addMockWithReturnValueAndParameterCheck>.

  my $aParameterTypes = [String(),String(abcd)];
  $MockObjectBuilder->addMethodSpyWithParameterCheck('myMethodName', $aParameterTypes);

To define it in a nice way the signature you must use the L<< Test::Mockify::Matcher; >>.

=cut
sub addMethodSpyWithParameterCheck {
    my $self = shift;
    my ( $MethodName, $aParameterTypes ) = @_;
    if (warnings::enabled("deprecated")) {
        warnings::warn('deprecated', "addMethodSpyWithParameterCheck is deprecated, use spy('name')->when(String('abc'))");
    }
    my $aMigratedMatchers = MigrateOldMatchers($aParameterTypes);
    $self->spy($MethodName)->when(@{$aMigratedMatchers});
    return;
}

#----------------------------------------------------------------------------------------
=pod

=head2 addMock I<(deprecated)>

This is the simplest case. It works like the mock-method from L<Test::MockObject>.

Only handover the B<name> and a B<method pointer>. Mockify will automatically check if the method exists in the original object.

  $MockObjectBuilder->addMock('myMethodName', sub {
                                    # Your implementation
                                 }
  );

=cut
sub addMock {
    my $self = shift;
    my ( $MethodName, $rSub ) = @_;
    if (warnings::enabled("deprecated")) {
        warnings::warn('deprecated', "addMock is deprecated, use mock('name')->whenAny()->thenCall(sub{})");
    }
    $self->_addMockWithMethod($MethodName)->whenAny()->thenCall(sub {
        return $rSub->($self->_mockedSelf(), @_);
    });

    return;
}
#----------------------------------------------------------------------------------------
sub _addStaticMock {
    my $self = shift;
    my ( $MethodName, $Method) = @_;

    ExistsMethod( $self->_mockedModulePath(), $MethodName );
    $self->_mockedSelf()->{'__MethodCallCounter'}->addMethod( $MethodName );
    if(not $self->{'MethodStore'}{$MethodName}){
        $self->{'MethodStore'}{$MethodName} //= $Method;
        my $MockedMethodBody = sub {
            $self->_mockedSelf()->{'__MethodCallCounter'}->increment( $MethodName );
            my @MockedParameters = @_;
            $self->_storeParameters( $MethodName, $self->_mockedSelf(), \@MockedParameters );
            return $self->{'MethodStore'}{$MethodName}->call(@MockedParameters);
        };
        # mock with full path
        $self->{'override'}->replace($MethodName, $MockedMethodBody);
        my ($FunctionName) = $MethodName =~ /.*::([^:]+$)/x;
        # mock for imported method(it will complain if you did't imported it)
        $self->{'override'}->replace($self->_mockedModulePath().'::'.$FunctionName, $MockedMethodBody);
    }
    return $self->{'MethodStore'}{$MethodName};
}
#----------------------------------------------------------------------------------------
sub _addMockWithMethod {
    my $self = shift;
    my ( $MethodName ) = @_;
    $self->_testMockTypeUsage($MethodName);
    if($self->{'IsStaticMockStore'}{$MethodName}){
        return $self->_addStaticMock($MethodName, Test::Mockify::Method->new());
    }else{
        return $self->_addMock($MethodName, Test::Mockify::Method->new());
    }
}
#----------------------------------------------------------------------------------------
sub _addMockWithMethodSpy {
    my $self = shift;
    my ( $MethodName, $PointerOriginalMethod ) = @_;
    $self->_testMockTypeUsage($MethodName);
    if($self->{'IsStaticMockStore'}{$MethodName}){
        return $self->_addStaticMock($MethodName, Test::Mockify::MethodSpy->new($PointerOriginalMethod));
    }else{
        return $self->_addMock($MethodName, Test::Mockify::MethodSpy->new($PointerOriginalMethod));
    }
}
#-------------------------------------------------------------------------------------
sub _addMock {
    my $self = shift;
    my ( $MethodName, $Method) = @_;

    ExistsMethod( $self->_mockedModulePath(), $MethodName );
    $self->_mockedSelf()->{'__MethodCallCounter'}->addMethod( $MethodName );
    if(not $self->{'MethodStore'}{$MethodName}){
        $self->{'MethodStore'}{$MethodName} //= $Method;
        $self->_mockedSelf()->mock($MethodName, sub {
            $self->_mockedSelf()->{'__MethodCallCounter'}->increment( $MethodName );
            my $MockedSelf = shift;
            my @MockedParameters = @_;
            $self->_storeParameters( $MethodName, $MockedSelf, \@MockedParameters );
            return $self->{'MethodStore'}{$MethodName}->call(@MockedParameters);
        });
    }
    return $self->{'MethodStore'}{$MethodName};
}
#----------------------------------------------------------------------------------------
=pod

=head2 addMockWithReturnValue I<(deprecated)>

Does the same as C<addMock>, but here you can handover a B<value> which will be returned if you call the mocked method.

  $MockObjectBuilder->addMockWithReturnValue('myMethodName','the return value');

=cut
sub addMockWithReturnValue {
    my $self = shift;
    my ( $MethodName, $ReturnValue ) = @_;
    if (warnings::enabled("deprecated")) {
        warnings::warn('deprecated', "addMockWithReturnValue is deprecated, use mock('name')->when()->thenReturn('Value')");
    }
    if($ReturnValue){
        $self->_addMockWithMethod($MethodName)->when()->thenReturn($ReturnValue);
    }else {
        $self->_addMockWithMethod($MethodName)->when()->thenReturnUndef();
    }

    return;
}
#----------------------------------------------------------------------------------------
=pod

=head2 addMockWithReturnValueAndParameterCheck I<(deprecated)>

This method is an extension of B<addMockWithReturnValue>. Here you can also check the parameters which will be passed.

You can check if they have a specific B<data type> or even check if they have a given B<value>.

In the following example two strings will be expected, and the second one has to have the value "abcd".

  my $aParameterTypes = [String(),String('abcd')];
  $MockObjectBuilder->addMockWithReturnValueAndParameterCheck('myMethodName','the return value',$aParameterTypes);

To define it in a nice way the signature you must use the L<< Test::Mockify::Matcher; >>.

=cut
sub addMockWithReturnValueAndParameterCheck {
    my $self = shift;
    my ( $MethodName, $ReturnValue, $aParameterTypes ) = @_;
    if (warnings::enabled("deprecated")) {
        warnings::warn('deprecated', "addMockWithReturnValue is deprecated, use mock('name')->when(String('abc'))->thenReturn('Value')");
    }
    if ( not IsArrayReference( $aParameterTypes ) ){
        Error( 'ParameterTypesNotProvided', {
            'Method' => $self->_mockedModulePath()."->$MethodName",
            'ParameterList' => $aParameterTypes,
        } );
    }
    $aParameterTypes = MigrateOldMatchers($aParameterTypes);

    if($ReturnValue){
        $self->_addMockWithMethod($MethodName)->when(@{$aParameterTypes})->thenReturn($ReturnValue);
    }else {
        $self->_addMockWithMethod($MethodName)->when(@{$aParameterTypes})->thenReturnUndef();
    }

    return;
}
#----------------------------------------------------------------------------------------
sub _storeParameters {
    my $self = shift;
    my ( $MethodName, $MockedSelf, $aMockedParameters ) = @_;

    push( @{$MockedSelf->{$MethodName.'_MockifyParams'}}, $aMockedParameters );

    return;
}

#----------------------------------------------------------------------------------------
sub _addGetParameterFromMockifyCall {
    my $self = shift;

    $self->_mockedSelf()->mock('__getParametersFromMockifyCall',
        sub{
            my $MockedSelf = shift;
            my ( $MethodName, $Position ) = @_;

            my $aParametersFromAllCalls = $MockedSelf->{$MethodName.'_MockifyParams'};
            if( ref $aParametersFromAllCalls ne 'ARRAY' ){
                Error( "$MethodName was not called" );
            }
            if( scalar @{$aParametersFromAllCalls} < $Position ) {
                Error( "$MethodName was not called ".( $Position+1 ).' times',{
                'Method' => "$MethodName",
                'Postion' => $Position,
                } );
            }
            else {
                my $ParameterFromMockifyCall = $MockedSelf->{$MethodName.'_MockifyParams'}[$Position];
                return $ParameterFromMockifyCall;
            }
            return;
        }
    );

    return;
}
#----------------------------------------------------------------------------------------
sub _testMockTypeUsage {
    my $self = shift;
    my ($MethodName) = @_;
    my $PositionInCallerStack = 2;
    my $MethodMockType = (caller($PositionInCallerStack))[3]; # autodetect mock type (spy or mock)
    if($self->{'MethodMockType'}{$MethodName} && $self->{'MethodMockType'}{$MethodName} ne $MethodMockType){
        die('It is not possible to mix spy and mock');
    }else{
        $self->{'MethodMockType'}{$MethodName} = $MethodMockType;
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

