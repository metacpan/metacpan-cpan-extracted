package Mockify_Verify;
use strict;

## no critic (ProhibitComplexRegexes ProhibitNoWarnings)
use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use Test::Mockify;
use Test::Mockify::Verify qw (GetParametersFromMockifyCall WasCalled GetCallCount);
use Test::Mockify::Matcher qw ( String Number HashRef ArrayRef Object Function Undef Any);
use Test::More;
use Test::Exception;
use warnings;
no warnings 'deprecated';
sub testPlan {
    my $self = shift;

    $self->test_MockModule_GetParametersFromMockifyCall();
    $self->test_MockModule_GetParametersFromMockifyCall_WithoutCallingTheMethod();
    $self->test_MockModule_GetParametersFromMockifyCall_ForNotMockifyObject();

    $self->test_MockModule_GetParametersFromMockifyCall_MultiParams();
    $self->test_MockModule_GetParametersFromMockifyCall_Multicalls_MultiParams();
    $self->test_MockModule_GetParametersFromMockifyCall_Multicalls_PositionBiggerThenRealCalls();
    $self->test_MockModule_GetParametersFromMockifyCall_Multicalls_PositionNotInteger();
    $self->test_MockModule_GetParametersFromMockifyCall_ForNotblessedObject();
    $self->test_MockModule_GetParametersFromMockifyCall_NoMethodName();

    $self->test_MockModule_CallCounter_GetCallCount_addMock_positive();
    $self->test_MockModule_CallCounter_GetCallCount_addMock_MultipleCalles();
    $self->test_MockModule_CallCounter_GetCallCount_addMock_negative();
    $self->test_MockModule_CallCounter_GetCallCount_addMock_negative_unMockedMethods();
    $self->test_MockModule_CallCounter_GetCallCount_addMockWithReturnValue();
    $self->test_MockModule_CallCounter_GetCallCount_addMockWithReturnValueAndParameterCheck();

    $self->test_MockModule_CallCounter_WasCalled_addMock_positive();
    $self->test_MockModule_CallCounter_WasCalled_addMock_negative();

    $self->test_MockModule_CallCounter_addMethodSpy();
    $self->test_MockModule_CallCounter_addMethodSpy_WithParameters();
    $self->test_MockModule_CallCounter_addMethodSpyWithParameterCheck();
    $self->test_MockModule_CallCounter_addMethodSpyWithParameterCheck_negativ();
# verify for static and imported

}

#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMock_positive {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when()->thenCall(sub { return 'This is a return value'; });
    my $MockedFakeModule = $MockObject->getMockObject();
    my $Result = $MockedFakeModule->DummyMethodForTestOverriding();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummyMethodForTestOverriding' );

    is($Result, 'This is a return value', "$SubTestName - tests if the return value is correct");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummyMethodForTestOverriding was called one time" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMock_negative {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when()->thenCall(sub { return 'This iParameter[0] is not a HashRef:s a return value'; });
    my $MockedFakeModule = $MockObject->getMockObject();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummyMethodForTestOverriding' );

    my $ExpectedCalles = 0;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummyMethodForTestOverriding was called one time" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMock_negative_unMockedMethods {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $MockedFakeModule = $MockObject->getMockObject();

    throws_ok( sub { GetCallCount( $MockedFakeModule, 'DummyMethodForTestOverriding' ) },
       qr/The Method: 'DummyMethodForTestOverriding' was not added to Mockify/sm,
       "$SubTestName - test the Error if a not mockified method name was used"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMock_MultipleCalles {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when()->thenCall(sub { return 'This is a return value'; });
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummyMethodForTestOverriding();
    $MockedFakeModule->secondDummyMethodForTestOverriding(); #Call something else in the middle
    $MockedFakeModule->DummyMethodForTestOverriding();
    $MockedFakeModule->DummyMethodForTestOverriding();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummyMethodForTestOverriding' );

    my $ExpectedCalles = 3;
    is ( $AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummyMethodForTestOverriding was called three times" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMockWithReturnValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when()->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    my $Result = $MockedFakeModule->DummyMethodForTestOverriding();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummyMethodForTestOverriding' );

    is($Result, 'This is a return value', "$SubTestName - tests if the return value is correct");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummyMethodForTestOverriding was called one time" );
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMockWithReturnValueAndParameterCheck {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();

    my $Result = $MockedFakeModule->DummyMethodForTestOverriding('TestString');
    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummyMethodForTestOverriding' );

    is($Result, 'This is a return value', "$SubTestName - tests if the return value is correct");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummyMethodForTestOverriding was called one time" );
}

#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_WasCalled_addMock_positive {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when()->thenCall(sub { return 'This is a return value'; });
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummyMethodForTestOverriding();

    my $WasCalled = WasCalled( $MockedFakeModule, 'DummyMethodForTestOverriding' );

    ok( $WasCalled, "$SubTestName - check if the method was called" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_WasCalled_addMock_negative {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when()->thenCall(sub { return 'This is a return value'; });
    my $MockedFakeModule = $MockObject->getMockObject();

    my $WasCalled = WasCalled( $MockedFakeModule, 'DummyMethodForTestOverriding' );

    is( $WasCalled, 0, "$SubTestName - check if the method was not called" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_addMethodSpy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = ['ATestValue'];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->spy('returnParameterListNew')->when();
    my $MockedFakeModule = $MockObject->getMockObject();

    my $Result = $MockedFakeModule->returnParameterListNew();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'returnParameterListNew' );

    my $FirstParameter = $Result->[0];
    is($FirstParameter, 'ATestValue', "$SubTestName - tests if the return value is the original Method so the self context is working");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if returnParameterListNew was called one time" );
    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_addMethodSpy_WithParameters {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = ['ATestValue'];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->spy('dummyMethodWithParameterReturn')->when(String());
    my $MockedFakeModule = $MockObject->getMockObject();

    my $Result = $MockedFakeModule->dummyMethodWithParameterReturn('TestParameter');

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'dummyMethodWithParameterReturn' );

    is( $Result, 'TestParameter', "$SubTestName - tests if the return value is the original Method so the self context is working");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if dummyMethodWithParameterReturn was called one time" );
    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_addMethodSpyWithParameterCheck {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = ['TestParameter'];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->spy('returnParameterListNew')->when(String('StringParameter'));
    my $MockedFakeModule = $MockObject->getMockObject();

    my $Result = $MockedFakeModule->returnParameterListNew('StringParameter');
    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'returnParameterListNew' );

    my $FirstParameter = $Result->[0];
    is($FirstParameter, 'TestParameter', "$SubTestName - tests if the return value is the original Method");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if returnParameterListNew was called one time" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_addMethodSpyWithParameterCheck_negativ {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->spy('dummyMethodWithParameterReturn')->when(HashRef({'key'=>'value'}));
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->dummyMethodWithParameterReturn('NotAHashRef') }
        ,
        qr/Error when calling method 'dummyMethodWithParameterReturn'.*No matching found for signatur type 'string'.*NotAHashRef/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}

#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String('InputValueToBeCheckAfterwords'))->thenReturnUndef();
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummyMethodForTestOverriding('InputValueToBeCheckAfterwords');
    my ($Parameter_DummyMethodForTestOverriding) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding')};
    is(
        $Parameter_DummyMethodForTestOverriding,
        'InputValueToBeCheckAfterwords',
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_Multicalls_PositionBiggerThenRealCalls {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String('InputValueToBeCheckAfterwords'))->thenReturnUndef();
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummyMethodForTestOverriding('InputValueToBeCheckAfterwords');
    throws_ok(
        sub { GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding', 3) },
        qr/DummyMethodForTestOverriding was not called 4 times/sm,
        "$SubTestName - test the Error if function was call and we didn't use the mocked method before"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_Multicalls_PositionNotInteger {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String('InputValueToBeCheckAfterwords'))->thenReturnUndef();
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummyMethodForTestOverriding('InputValueToBeCheckAfterwords');
    my $ExpectedParameterList = ['InputValueToBeCheckAfterwords'];
    is_deeply(
        GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding', 'NotANumber'),
        $ExpectedParameterList,
        "$SubTestName - tests if a not integer will become positon 0"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_MultiParams {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String(),Undef(),Object('Test::Object'))->thenReturnUndef();
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({},'Test::Object');
    $MockedFakeModule->DummyMethodForTestOverriding('FirstInput', undef, $TestObject);
    my ($Parameter_String, $Parameter_Undef, $Parameter_Object, $Parameter_NotDefined) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding')};
    is(
        $Parameter_String,
        'FirstInput',
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params (first element)"
    );
    is(
        $Parameter_Undef,
        undef,
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params (second element)"
    );
    is(
        $Parameter_Object,
        $TestObject,
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params (third element)"
    );
    is(
        $Parameter_NotDefined,
        undef,
        "$SubTestName - test the if the GetParametersFromMockifyCall does not return a 4th param (fourth element)"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_Multicalls_MultiParams {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String(),Undef(),Object('Test::Object'))->thenReturnUndef();
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({},'Test::Object');
    $MockedFakeModule->DummyMethodForTestOverriding('FirstInput', undef, $TestObject);
    my $TestObjectSecondCall = bless({'Something' => 'Inside'},'Test::Object');
    $MockedFakeModule->DummyMethodForTestOverriding('SecondCall_FirstInput', undef, $TestObjectSecondCall);
    my ($Parameter_String, $Parameter_Undef, $Parameter_Object) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding', 0)};
    is(
        $Parameter_String,
        'FirstInput',
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params (first element)"
    );
    is(
        $Parameter_Undef,
        undef,
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params (second element)"
    );
    is(
        $Parameter_Object,
        $TestObject,
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params (third element)"
    );
    my ($Parameter_String_Second, $Parameter_Undef_Second, $Parameter_Object_Second) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding',1)};
    is(
        $Parameter_String_Second,
        'SecondCall_FirstInput',
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params for second call (first element)"
    );
    is(
        $Parameter_Undef_Second,
        undef,
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params for second call (second element)"
    );
    is_deeply(
        $Parameter_Object_Second,
        $TestObjectSecondCall,
        "$SubTestName - test the if the GetParametersFromMockifyCall return the right params for second call (third element)"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_WithoutCallingTheMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String())->thenReturnUndef();
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding') },
        qr/DummyMethodForTestOverriding was not called/sm,
        "$SubTestName - test the Error if function was call and we didn't use the mocked method before"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_ForNotblessedObject {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $NotObject = 'NotBlessed';
    throws_ok(
        sub { GetParametersFromMockifyCall($NotObject,'DummyMethodForTestOverriding') },
        qr/The first argument must be blessed:/sm,
        "$SubTestName - test the Error if function was call and the first argument is not blessed"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_ForNotMockifyObject {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $NotMockifyObject = TestDummies::FakeModuleForMockifyTest->new();
    throws_ok(
        sub { GetParametersFromMockifyCall($NotMockifyObject,'DummyMethodForTestOverriding') },
        qr/FakeModuleForMockifyTest was not mockified:/sm,
        "$SubTestName - test the Error if function was call and we didn't use the mocked method before"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_NoMethodName {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $NotMockifyObject = TestDummies::FakeModuleForMockifyTest->new();
    throws_ok(
        sub { GetParametersFromMockifyCall( $NotMockifyObject ) },
        qr/Method name must be specified:/sm,
        "$SubTestName - test the Error if function was call and we didn't use the mocked method before"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub _createMockObject {
    my $self = shift;
    my ($aParameterList) = @_;

    my $MockObject = Test::Mockify->new( 'TestDummies::FakeModuleForMockifyTest', $aParameterList );

    return $MockObject;
}

__PACKAGE__->RunTest();