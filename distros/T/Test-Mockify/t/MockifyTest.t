package MockifyTest;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify;
use Test::Mockify::Verify qw (GetParametersFromMockifyCall WasCalled GetCallCount);
use Test::More;
use Test::Exception;

sub testPlan {
    my $self = shift;
    $self->test_MockModule();
    $self->test_MockModule_withParameter();
    $self->test_MockModule_addMock();
    $self->test_MockModule_addMock_overrideNotExistingMethod();
    $self->test_MockModule_AddMockWithReturnValue();
    $self->test_MockModule_AddMockWithReturnValue_UnexpectedParameterInCall();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedString();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedInteger();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedFloat();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedHash();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedArray();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedObject();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_EmptyString();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongAmountOfParameters();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Int();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Float();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_String();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_HashRef();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_ArrayRef();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Object();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Undef();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_withoutParameterTypes();
    $self->test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongParameterName();

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

    $self->test_MockModule_ShortCut_addmock();
    $self->test_MockModule_ShortCut_AddMockWithReturnValue();
    $self->test_MockModule_ShortCut_AddMockWithReturnValueAndParameterCheck();

}
#----------------------------------------------------------------------------------------
sub test_MockModule {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    
    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $MockedFakeModule = $MockObject->getMockObject();
    is($MockedFakeModule->DummmyMethodForTestOverriding(),'A dummmy method',"$SubTestName - test if the loaded module still have the unmocked methods");

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_withParameter {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = ['one', 'two'];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $MockedFakeModule = $MockObject->getMockObject();
    is_deeply($MockedFakeModule->returnParameterListNew(), $aParameterList, "$SubTestName - test if the parameter for the constuctor are handover correctly");

    return;    
}
#----------------------------------------------------------------------------------------
sub test_MockModule_addMock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $TestMethodPointer = sub {
        return 'return value of overridden Method';
    };
    $MockObject->addMock('DummmyMethodForTestOverriding', $TestMethodPointer );
    my $MockedFakeModule = $MockObject->getMockObject();
    is($MockedFakeModule->DummmyMethodForTestOverriding(),'return value of overridden Method',"$SubTestName - test if the loaded module can be overridden and the return value will be returned");

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMock_positive {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMock('DummmyMethodForTestOverriding', sub { return 'This is a return value'; } );
    my $MockedFakeModule = $MockObject->getMockObject();
    my $Result = $MockedFakeModule->DummmyMethodForTestOverriding();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummmyMethodForTestOverriding' );

    is($Result, 'This is a return value', "$SubTestName - tests if the return value is correct");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummmyMethodForTestOverriding was called one time" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMock_negative {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMock('DummmyMethodForTestOverriding', sub { return 'This iParameter[0] is not a HashRef:s a return value'; } );
    my $MockedFakeModule = $MockObject->getMockObject();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummmyMethodForTestOverriding' );

    my $ExpectedCalles = 0;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummmyMethodForTestOverriding was called one time" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMock_negative_unMockedMethods {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $MockedFakeModule = $MockObject->getMockObject();

    throws_ok( sub { GetCallCount( $MockedFakeModule, 'DummmyMethodForTestOverriding' ) },
       qr/The Method: 'DummmyMethodForTestOverriding' was not added to Mockify/,
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
    $MockObject->addMock('DummmyMethodForTestOverriding', sub { return 'This is a return value'; } );
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummmyMethodForTestOverriding();
    $MockedFakeModule->secondDummmyMethodForTestOverriding(); #Call something else in the middle
    $MockedFakeModule->DummmyMethodForTestOverriding();
    $MockedFakeModule->DummmyMethodForTestOverriding();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummmyMethodForTestOverriding' );

    my $ExpectedCalles = 3;
    is ( $AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummmyMethodForTestOverriding was called three times" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMockWithReturnValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMockWithReturnValue('DummmyMethodForTestOverriding', 'This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    my $Result = $MockedFakeModule->DummmyMethodForTestOverriding();

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummmyMethodForTestOverriding' );

    is($Result, 'This is a return value', "$SubTestName - tests if the return value is correct");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummmyMethodForTestOverriding was called one time" );
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_GetCallCount_addMockWithReturnValueAndParameterCheck {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', ['string'] );
    my $MockedFakeModule = $MockObject->getMockObject();

    my $Result = $MockedFakeModule->DummmyMethodForTestOverriding('TestString');
    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'DummmyMethodForTestOverriding' );

    is($Result, 'This is a return value', "$SubTestName - tests if the return value is correct");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if DummmyMethodForTestOverriding was called one time" );
}

#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_WasCalled_addMock_positive {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMock('DummmyMethodForTestOverriding', sub { return 'This is a return value'; } );
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummmyMethodForTestOverriding();

    my $WasCalled = WasCalled( $MockedFakeModule, 'DummmyMethodForTestOverriding' );

    ok( $WasCalled, "$SubTestName - check if the method was called" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_WasCalled_addMock_negative {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMock('DummmyMethodForTestOverriding', sub { return 'This is a return value'; } );
    my $MockedFakeModule = $MockObject->getMockObject();

    my $WasCalled = WasCalled( $MockedFakeModule, 'DummmyMethodForTestOverriding' );

    is( $WasCalled, 0, "$SubTestName - check if the method was not called" );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_addMethodSpy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = ['ATestValue'];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMethodSpy('returnParameterListNew');
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
    $MockObject->addMethodSpy('dummmyMethodWithParameterReturn');
    my $MockedFakeModule = $MockObject->getMockObject();

    my $Result = $MockedFakeModule->dummmyMethodWithParameterReturn('TestParameter');

    my $AmountOfCalls = GetCallCount( $MockedFakeModule, 'dummmyMethodWithParameterReturn' );

    is( $Result, 'TestParameter', "$SubTestName - tests if the return value is the original Method so the self context is working");
    my $ExpectedCalles = 1;
    is ($AmountOfCalls, $ExpectedCalles, "$SubTestName - tests if dummmyMethodWithParameterReturn was called one time" );
    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_CallCounter_addMethodSpyWithParameterCheck {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = ['TestParameter'];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMethodSpyWithParameterCheck('returnParameterListNew', [{'string'=>'StringParameter'}] );
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
    $MockObject->addMethodSpyWithParameterCheck('dummmyMethodWithParameterReturn',[{'hashref'=>{'key'=>'value'}}]);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok( sub { $MockedFakeModule->dummmyMethodWithParameterReturn('NotAHashRef') },
               qr/Parameter\[0\] is not a HashRef:/,
               "$SubTestName - test the Error if method is called with wrong type"
     );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_ShortCut_addmock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $TestMethodPointer = sub {
        return 'return value of overridden Method';
    };
    $MockObject->mock('DummmyMethodForTestOverriding', $TestMethodPointer );
    my $MockedFakeModule = $MockObject->getMockObject();
    is($MockedFakeModule->DummmyMethodForTestOverriding(),'return value of overridden Method',"$SubTestName - test if the loaded module can be overridden and the return value will be returned");

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_addMock_overrideNotExistingMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    throws_ok(
        sub { $MockObject->addMockWithReturnValue('aNotExistingMethod', sub {}); },
        qr/FakeModuleForMockifyTest donsn't have a method like: aNotExistingMethod/,
        "$SubTestName - test if the mocked method throw an Error if the method don't exists in the module"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMockWithReturnValue('DummmyMethodForTestOverriding', 'This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    is($MockedFakeModule->DummmyMethodForTestOverriding(),'This is a return value',"$SubTestName - test if the loaded module can be overridden and the return value will be returned");

    return
}
#----------------------------------------------------------------------------------------
sub test_MockModule_ShortCut_AddMockWithReturnValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummmyMethodForTestOverriding', 'This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    is($MockedFakeModule->DummmyMethodForTestOverriding(),'This is a return value',"$SubTestName - test if the loaded module can be overridden and the return value will be returned");

    return
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValue_UnexpectedParameterInCall {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->addMockWithReturnValue('DummmyMethodForTestOverriding', 'SomeReturnValue');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('anUnexpectedParameter') },
        qr/UnexpectedParameter:/,
        "$SubTestName - test if the mocked method was called with the wrong amount of parameters"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $aParameterCheckList = ['string','int','undef','hashref', 'arrayref', 'object',];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $aParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({}, 'Test::Object');
    my @Parameters = ('Hello', 12389, undef, {}, [], $TestObject); ## no critic (ProhibitMagicNumbers RequireNumberSeparators)
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( @Parameters ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    is_deeply(
        GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding'),
        \@Parameters,
        "$SubTestName - tests if the parameter is stored correct in the mock object"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_ShortCut_AddMockWithReturnValueAndParameterCheck {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $aParameterCheckList = ['string','int','undef','hashref', 'arrayref', 'object',];
    $MockObject->mock('DummmyMethodForTestOverriding', 'This is a return value', $aParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({}, 'Test::Object');
    my @Parameters = ('Hello', 12389, undef, {}, [], $TestObject); ## no critic (ProhibitMagicNumbers RequireNumberSeparators)
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( @Parameters ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    is_deeply(
        GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding'),
        \@Parameters,
        "$SubTestName - tests if the parameter is stored correct in the mock object"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedString {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'string'=>'ABC123'}];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( 'ABC123' ),
        'This is a return value',"$SubTestName - tests if the parameter list check for string is working"
    );
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding( 'wrong String' ) },
        qr/ActualValue='wrong String'/,
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedInteger {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'int'=>666}];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( 666 ),
        'This is a return value',"$SubTestName - tests if the parameter list check for integer is working"
    );
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding( 123456 ) },
        qr/Parameter\[0\] unexpected value:/,
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedFloat {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'float'=>1.23}];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( 1.23 ),
        'This is a return value',"$SubTestName - tests if the parameter list check for float is working"
    );
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding( 6.66 ) },
        qr/ActualValue='6.66'/sm,
        "$SubTestName - test if a wrong float value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedHash {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'hashref'=>{'eins'=>'value'}}];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    my $hCorrectParameter = {'eins'=>'value'};
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( $hCorrectParameter ),
        'This is a return value',"$SubTestName - tests if the parameter list check for hash is working"
    );
    my $hWrongParameter = {'zwei'=>'value'};
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding( $hWrongParameter ) },
        qr/Parameter\[0\] unexpected value:/,
        "$SubTestName - test if a wrong value will be found."
    );
    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedArray {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'arrayref'=>['eins','zwei']}];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    my $aCorrectParameter = ['eins','zwei'];
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( $aCorrectParameter ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working");
    my $aWrongParameter = ['eins'];
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding( $aWrongParameter ) },
        qr/Parameter\[0\] unexpected value:/,
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_ExpectedObject {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'object'=>'Test::Object'}];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({},'Test::Object');
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( $TestObject ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    my $WrongTestObject = bless({},'Wrong::Test::Object');
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding( $WrongTestObject ) },
        qr/ActualObjectType='Wrong::Test::Object'/,
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_EmptyString {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['string'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummmyMethodForTestOverriding( '' ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    my ( $FirstParam ) = @{GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding')};
    is( $FirstParam, '', "$SubTestName - tests if a empty string is an allowed value");

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongAmountOfParameters {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['string','string'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('Hello') },
        qr/WrongAmountOfParameters:/,
        "$SubTestName - test the Error if the Dummy Method don't get enough parameters"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Int {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['int'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('123NotANumber321') },
        qr/Parameter\[0\] is not an Integer:/,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Float {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['float'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('1.23NotAFloat3.21') },
        qr/Parameter\[0\] is not an Float:/,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_String {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['string'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding(['Not','aString']) },
        qr/Parameter\[0\] is not a String:/,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_HashRef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['hashref'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('NotAHashRef') },
        qr/Parameter\[0\] is not a HashRef:/,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_ArrayRef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['arrayref'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('NotAnArrayRef') },
        qr/Parameter\[0\] is not an ArrayRef:/,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Object {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['object'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('NotAObject') },
        qr/Parameter\[0\] is not a Object:/,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongDataTypeFor_Undef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['undef'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('NotUndef') },
        qr/Parameter\[0\] is not undefined:/,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_withoutParameterTypes {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    throws_ok( sub {
        $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value'); },
        qr/ParameterTypesNotProvided:/,
        "$SubTestName - test if the mocked method was called with the wrong amount of parameters"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_AddMockWithReturnValueAndParameterCheck_WrongParameterName {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['string','WrongType'];
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', 'This is a return value', $ParameterCheckList);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummmyMethodForTestOverriding('some','value') },
        qr/UnknownParametertype/,
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
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', undef, [{'string' => 'InputValueToBeCheckAfterwords'}]);
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummmyMethodForTestOverriding('InputValueToBeCheckAfterwords');
    my ($Parameter_DummmyMethodForTestOverriding) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding')};
    is(
        $Parameter_DummmyMethodForTestOverriding,
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
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', undef, [{'string' => 'InputValueToBeCheckAfterwords'}]);
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummmyMethodForTestOverriding('InputValueToBeCheckAfterwords');
    throws_ok(
        sub { GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding', 3) },
        qr/DummmyMethodForTestOverriding was not called 4 times/,
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
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', undef, [{'string' => 'InputValueToBeCheckAfterwords'}]);
    my $MockedFakeModule = $MockObject->getMockObject();
    $MockedFakeModule->DummmyMethodForTestOverriding('InputValueToBeCheckAfterwords');
    my $ExpectedParameterList = ['InputValueToBeCheckAfterwords'];
    is_deeply(
        GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding', 'NotANumber'),
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
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', undef, ['string','undef',{'object' => 'Test::Object'}]);
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({},'Test::Object');
    $MockedFakeModule->DummmyMethodForTestOverriding('FirstInput', undef, $TestObject);
    my ($Parameter_String, $Parameter_Undef, $Parameter_Object, $Parameter_NotDefined) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding')};
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
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', undef, ['string','undef',{'object' => 'Test::Object'}]);
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({},'Test::Object');
    $MockedFakeModule->DummmyMethodForTestOverriding('FirstInput', undef, $TestObject);
    my $TestObjectSecondCall = bless({'Something' => 'Inside'},'Test::Object');
    $MockedFakeModule->DummmyMethodForTestOverriding('SecondCall_FirstInput', undef, $TestObjectSecondCall);
    my ($Parameter_String, $Parameter_Undef, $Parameter_Object) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding', 0)};
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
    my ($Parameter_String_Second, $Parameter_Undef_Second, $Parameter_Object_Second) = @ {GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding',1)};
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
    $MockObject->addMockWithReturnValueAndParameterCheck('DummmyMethodForTestOverriding', undef, ['string']);
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { GetParametersFromMockifyCall($MockedFakeModule,'DummmyMethodForTestOverriding') },
        qr/DummmyMethodForTestOverriding was not called/,
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
        sub { GetParametersFromMockifyCall($NotObject,'DummmyMethodForTestOverriding') },
        qr/The first argument must be blessed:/,
        "$SubTestName - test the Error if function was call and the first argument is not blessed"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_ForNotMockifyObject {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $NotMockifyObject = FakeModuleForMockifyTest->new();
    throws_ok(
        sub { GetParametersFromMockifyCall($NotMockifyObject,'DummmyMethodForTestOverriding') },
        qr/FakeModuleForMockifyTest was not mockified:/,
        "$SubTestName - test the Error if function was call and we didn't use the mocked method before"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_MockModule_GetParametersFromMockifyCall_NoMethodName {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $NotMockifyObject = FakeModuleForMockifyTest->new();
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

    my $MockObject = Test::Mockify->new( 'FakeModuleForMockifyTest', $aParameterList );

    return $MockObject;
}
__PACKAGE__->RunTest();