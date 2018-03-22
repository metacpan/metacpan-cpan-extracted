package Mockify_Sut;
use strict;
use FindBin;
## no critic (ProhibitComplexRegexes)
use lib ($FindBin::Bin.'/..'); # point to test base
use lib ($FindBin::Bin.'/../..'); # point to project base
use parent 'TestBase';
use Test::More;
use Test::Mockify::Sut;
use Test::Exception;
use Test::Mockify::Matcher qw (
        Number
    );
use t::TestDummies::DummyImportToolsUser_Static;
use Test::Mockify::Verify qw (GetParametersFromMockifyCall GetCallCount);
use t::TestDummies::DummyImportTools qw (Doubler);
#----------------------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_InjectionOfConstructor_Static();
    $self->test_InjectionOfConstructor();
    $self->test_InjectionOfConstructor_alternativConstructorName();
    $self->test_InjectionOfConstructor_Error();
    $self->test_InjectionOfImportedMethod();
    $self->test_InjectionOfStaticMethod();
    $self->test_ErrorOnMockSutMethod();
}

#----------------------------------------------------------------------------------------
sub test_InjectionOfConstructor_Static {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
        $Mockify->mockConstructor('TestDummies::FakeModuleForMockifyTest', $self->_createFakeModuleForMockifyTest());
        my $VerificationObject = $Mockify->getVerificationObject();
        is(
            t::TestDummies::DummyImportToolsUser_Static::CallAConstructor('hello'),
            'mockedValue',
            "$SubTestName - Prove that the constructor injection works out"
        );
        is(GetCallCount($VerificationObject, 'TestDummies::FakeModuleForMockifyTest::new'),1,"$SubTestName - prove the verify output");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfConstructor {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser');
        $Mockify->mockConstructor('TestDummies::FakeModuleForMockifyTest', $self->_createFakeModuleForMockifyTest());
        my $DummyImportToolsUser = $Mockify->getMockObject();
        is(
            $DummyImportToolsUser->callAConstructor('hello'),
            'mockedValue',
            "$SubTestName - Prove that the constructor injection works out"
        );
        is(GetCallCount($DummyImportToolsUser, 'TestDummies::FakeModuleForMockifyTest::new'),1,"$SubTestName - prove the verify output - new");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfConstructor_alternativConstructorName {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser');
        $Mockify->mockConstructor('TestDummies::FakeModuleForMockifyTest', $self->_createFakeModuleForMockifyTest(), 'create');
        my $DummyImportToolsUser = $Mockify->getMockObject();
        is(
            $DummyImportToolsUser->callAlternativConstructor('hello'),
            'alternativMockedValue',
            "$SubTestName - Prove that the constructor injection works out"
        );
        is(GetCallCount($DummyImportToolsUser, 'TestDummies::FakeModuleForMockifyTest::create'),1,"$SubTestName - prove the verify output - create");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfConstructor_Error {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser');
        throws_ok( sub { $Mockify->mockConstructor( ); },
                       qr/Wrong or missing parameter list. Please use it like: \$Mockify->mockConstructor\('Path::To::Package', \$Object, 'new'\)/sm, ## no critic (ProhibitEscapedMetacharacters)
                       "$SubTestName - somehow called wrong error."
             );
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfImportedMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
        $Mockify->mockImported('t::TestDummies::DummyImportTools', 'Doubler')->when(Number(2))->thenReturn('InjectedReturnValueOfDoubler');
        my $VerificationObject = $Mockify->getVerificationObject();
        is(
            t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
            'In useDummyImportTools, result Doubler call: "InjectedReturnValueOfDoubler"',
            "$SubTestName - Prove that the injection works out"
        );
        is(GetCallCount($VerificationObject, 'Doubler'),1,"$SubTestName - prove the verify output");
        is($VerificationObject, $Mockify->getMockObject(), "$SubTestName - prove that both returning the same");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
        $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');
        my $VerificationObject = $Mockify->getVerificationObject();
        is(
            t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
            'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
            "$SubTestName - Prove that the injection works out"
        );
        is(GetCallCount($VerificationObject, 't::TestDummies::DummyStaticTools::Tripler'),1,"$SubTestName - prove the verify output");
        is($VerificationObject, $Mockify->getMockObject(), "$SubTestName - prove that both returning the same");
}
#----------------------------------------------------------------------------------------
sub test_ErrorOnMockSutMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
        throws_ok( sub { $Mockify->mock('OverrideDummyFunctionUser') },
                       qr/It is not possible to mock a method of your SUT. Don't mock the code you like to test./sm,
                       "$SubTestName - Prove the error when try to mock a method of the SUT"
             );
        ;
}
#----------------------------------------------------------------------------------------
sub _createFakeModuleForMockifyTest {
    my $self = shift;

    my $aParameterList = [];
    my $Mockify = Test::Mockify->new(
                   'TestDummies::FakeModuleForMockifyTest',
                   $aParameterList
              );
    $Mockify
        ->mock('returnParameterListNew')
        ->when()
        ->thenReturn('mockedValue');
    $Mockify
        ->mock('returnParameterListCreate')
        ->when()
        ->thenReturn('alternativMockedValue');

    return $Mockify->getMockObject();
}
__PACKAGE__->RunTest();
1;