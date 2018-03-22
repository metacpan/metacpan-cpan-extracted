package Mockify_Matcher;
use strict;
## no critic (ProhibitComplexRegexes ProhibitNoWarnings ProhibitMagicNumbers ProhibitEmptyQuotes)
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
    $self->test_All();
    $self->test_ExpectedString();
    $self->test_ExpectedInteger();
    $self->test_ExpectedFloat();
    $self->test_ExpectedHash();
    $self->test_ExpectedArray();
    $self->test_ExpectedObject();
    $self->test_EmptyString();
    $self->test_Any_MixedParameterList();
    $self->test_Any_AllTypes();
    $self->test_WrongAmountOfParameters();
    $self->test_WrongDataTypeFor_Int();
    $self->test_WrongDataTypeFor_Float();
    $self->test_WrongDataTypeFor_String();
    $self->test_WrongDataTypeFor_HashRef();
    $self->test_WrongDataTypeFor_ArrayRef();
    $self->test_WrongDataTypeFor_Object();
    $self->test_WrongDataTypeFor_Undef();
    $self->test_WrongDataTypeFor_Function();

}
#----------------------------------------------------------------------------------------
sub test_All {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String(), Number(), Undef(), HashRef(), ArrayRef(), Object(), Function(), Any())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({}, 'Test::Object');
    my $Sub = sub {};
    my @Parameters = ('Hello', 12389, undef, {}, [], $TestObject, $Sub, 'Any'); ## no critic (ProhibitMagicNumbers RequireNumberSeparators)
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( @Parameters ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    is_deeply(
        GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding'),
        \@Parameters,
        "$SubTestName - tests if the parameter is stored correct in the mock object"
    );

    return;
}

#----------------------------------------------------------------------------------------
sub test_ExpectedString {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String('ABC123'))->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( 'ABC123' ),
        'This is a return value',"$SubTestName - tests if the parameter list check for string is working"
    );
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding( 'wrong String' ) },
        qr/'wrong String'/sm,
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_ExpectedInteger {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(Number(666))->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( 666 ),
        'This is a return value',"$SubTestName - tests if the parameter list check for integer is working"
    );
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding( 123_456 ) },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'number'.*123456/sm,
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_ExpectedFloat {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(Number(1.23))->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( 1.23 ),
        'This is a return value',"$SubTestName - tests if the parameter list check for float is working"
    );
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding(6.66) },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'number'.*'6.66'/sm,
        "$SubTestName - test if a wrong float value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_ExpectedHash {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(HashRef({'eins'=>'value'}))->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    my $hCorrectParameter = {'eins'=>'value'};
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( $hCorrectParameter ),
        'This is a return value',"$SubTestName - tests if the parameter list check for hash is working"
    );
    my $hWrongParameter = {'zwei'=>'value'};
    throws_ok(
        sub {
            $MockedFakeModule->DummyMethodForTestOverriding($hWrongParameter);
        },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'hashref'.*'zwei' => 'value'/sm,
        "$SubTestName - test if a wrong value will be found."
    );
    return;
}

#----------------------------------------------------------------------------------------
sub test_ExpectedArray {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'arrayref'=>['eins','zwei']}];
    $MockObject->mock('DummyMethodForTestOverriding')->when(ArrayRef(['eins','zwei']))->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    my $aCorrectParameter = ['eins','zwei'];
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( $aCorrectParameter ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working");
    my $aWrongParameter = ['eins'];
    throws_ok(
        sub {
            $MockedFakeModule->DummyMethodForTestOverriding($aWrongParameter);
        },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'arrayref'.*eins/sm,
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_ExpectedObject {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = [{'object'=>'Test::Object'}];
    $MockObject->mock('DummyMethodForTestOverriding')->when(Object('Test::Object'))->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({},'Test::Object');
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( $TestObject ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    my $WrongTestObject = bless({},'Wrong::Test::Object');
    throws_ok(
        sub {
            $MockedFakeModule->DummyMethodForTestOverriding($WrongTestObject);
        },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'object'.*bless\( \{\}, 'Wrong::Test::Object' \)/sm, ## no critic (ProhibitEscapedMetacharacters)
        "$SubTestName - test if a wrong value will be found."
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_EmptyString {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( '' ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    my ( $FirstParam ) = @{GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding')};
    is( $FirstParam, '', "$SubTestName - tests if a empty string is an allowed value");

    return;
}
#----------------------------------------------------------------------------------------
sub test_Any_MixedParameterList {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(Any(),String('abc'),Any())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( sub {}, 'abc', [undef, 1] ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_Any_AllTypes{
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(Any(), Any(), Any(), Any(), Any(), Any(), Any())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    my $TestObject = bless({}, 'Test::Object');
    my $Sub = sub {};
    my @Parameters = ('Hello', 12389, undef, {}, [], $TestObject, $Sub); ## no critic (ProhibitMagicNumbers RequireNumberSeparators)
    is(
        $MockedFakeModule->DummyMethodForTestOverriding( @Parameters ),
        'This is a return value',"$SubTestName - tests if the parameter list check is working"
    );
    is_deeply(
        GetParametersFromMockifyCall($MockedFakeModule,'DummyMethodForTestOverriding'),
        \@Parameters,
        "$SubTestName - tests if the parameter is stored correct in the mock object"
    );

    return;
}

#----------------------------------------------------------------------------------------
sub test_WrongAmountOfParameters {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['string','string'];
    $MockObject->mock('DummyMethodForTestOverriding')->when(String(),String())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding('Hello') },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*Hello/sm,
"$SubTestName - test the Error if the Dummy Method don't get enough parameters"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_Int {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);

    $MockObject->mock('DummyMethodForTestOverriding')->when(Number())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub {
            $MockedFakeModule->DummyMethodForTestOverriding('123NotANumber321');
        },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*123NotANumber321/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_Float {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    my $ParameterCheckList = ['float'];
    $MockObject->mock('DummyMethodForTestOverriding')->when(Number())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub {
            $MockedFakeModule->DummyMethodForTestOverriding(
                '1.23NotAFloat3.21');
        },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*1.23NotAFloat3.21/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_String {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(String())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub {
            $MockedFakeModule->DummyMethodForTestOverriding(
                [ 'Not', 'aString' ] );
        },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'arrayref'.*Not.*aString/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_HashRef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(HashRef())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding('NotAHashRef') },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*NotAHashRef/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_ArrayRef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(ArrayRef())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding('NotAnArrayRef') }
        ,
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*NotAnArrayRef/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_Object {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(Object())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding('NotAObject') },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*NotAObject/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_Undef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(Undef())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding('NotUndef') },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*NotUndef/sm,
        "$SubTestName - test the Error if method is called with wrong type"
    );

    return;
}
#----------------------------------------------------------------------------------------
sub test_WrongDataTypeFor_Function {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $aParameterList = [];
    my $MockObject = $self->_createMockObject($aParameterList);
    $MockObject->mock('DummyMethodForTestOverriding')->when(Function())->thenReturn('This is a return value');
    my $MockedFakeModule = $MockObject->getMockObject();
    throws_ok(
        sub { $MockedFakeModule->DummyMethodForTestOverriding('NotaFunction') },
        qr/Error when calling method 'DummyMethodForTestOverriding'.*No matching found for signatur type 'string'.*NotaFunction/sm,
        "$SubTestName - test the Error if method is called with wrong type"
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