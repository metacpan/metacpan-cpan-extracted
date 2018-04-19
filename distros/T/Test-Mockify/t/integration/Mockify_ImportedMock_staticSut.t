package Mockify_ImportedMock_StaticSut;
use strict;
use FindBin;
## no critic (ProhibitComplexRegexes)
use lib ($FindBin::Bin.'/..'); # point to test base
use lib ($FindBin::Bin.'/../..'); # point to project base
use parent 'TestBase';
use Test::More;
use Test::Mockify::Sut;
use Test::Exception;
use Test::Warn;
use Test::Mockify::Matcher qw (
        Number
    );
use t::TestDummies::DummyImportToolsUser_Static;
use Test::Mockify::Verify qw (GetParametersFromMockifyCall GetCallCount);
use t::TestDummies::DummyImportTools qw (Doubler);
#----------------------------------------------------------------------------------------
sub testPlan{
    my $self = shift;

    $self->test_InjectionOfImportedMethod_scopes();
    $self->test_InjectionOfImportedMethod_CreatorMethod();
    $self->test_InjectionOfImportedMethod_scopes_spy();
    $self->test_InjectionOfImportedMethod_Verify();
    $self->test_InjectionOfImportedMethod_Verify_spy();
    $self->test_functionNameFormatingErrorHandling_mock();
    $self->test_EmpthyPrototype();
    $self->test_functionNameFormatingErrorHandling_spy();
}

#----------------------------------------------------------------------------------------
sub test_InjectionOfImportedMethod_scopes {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
        'In useDummyImportTools, result Doubler call: "4"',
        "$SubTestName - prove the unmocked Result"
    );
    {#beginn scope
        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
        $Mockify->mockImported('t::TestDummies::DummyImportTools', 'Doubler')->when(Number(2))->thenReturn('InjectedReturnValueOfDoubler');
        my $DummyImportToolsUser = $Mockify->getMockObject();
        is(
            t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
            'In useDummyImportTools, result Doubler call: "InjectedReturnValueOfDoubler"',
            "$SubTestName - Prove that the injection works out"
        );
        is(Doubler(2), 4, "$SubTestName - Prove that the mock is only injected in the mock (inside scope of \$Mockify)");
    } # end scope
    is(Doubler(2), 4, "$SubTestName - Prove that the mock is only injected in the mock (left scope of \$Mockify)");
    is(
        t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
        'In useDummyImportTools, result Doubler call: "4"',
        "$SubTestName - prove the unmocked Result"
    );
}
#----------------------------------------------------------------------------------------
sub test_EmpthyPrototype {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    warning_is (sub {
        {# start lexical scope
            my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportTools');
            $Mockify->mockImported('t::TestDummies::DummyImportTools', 'EmptyProtoType')->when()->thenReturnUndef();
            my $Sut = $Mockify->getMockObject();
        }# close lexial scope
    }, '', "$SubTestName - Prove make sure that no warn is throw on mock");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfImportedMethod_scopes_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
        'In useDummyImportTools, result Doubler call: "4"',
        "$SubTestName - prove the unmocked Result"
    );
    {#beginn scope
        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
        $Mockify->spyImported('t::TestDummies::DummyImportTools', 'Doubler')->when(Number(2));
        my $DummyImportToolsUser = $Mockify->getMockObject();
        is(
            t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
            'In useDummyImportTools, result Doubler call: "4"',
            "$SubTestName - Prove that the injection works out"
        );
    } # end scope
    is(
        t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
        'In useDummyImportTools, result Doubler call: "4"',
        "$SubTestName - prove the unmocked Result"
    );
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfImportedMethod_CreatorMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $DummyImportToolsUser = $self->_createDummyImportToolsUser();
        is(
        t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
        'In useDummyImportTools, result Doubler call: "InjectedReturnValueOfDoubler"',
        "$SubTestName - Prove that the injection works out"
    );
    is(Doubler(2), 4, "$SubTestName - Prove that the mock is only injected in the mock (inside scope of \$Mockify)");
}
#----------------------------------------------------------------------------------------
sub _createDummyImportToolsUser {
    my $self = shift;

    my $Mockify = Test::Mockify::Sut->new(
                   't::TestDummies::DummyImportToolsUser_Static'
              );
    $Mockify->mockImported('t::TestDummies::DummyImportTools', 'Doubler')->when(Number(2))->thenReturn('InjectedReturnValueOfDoubler');

    return $Mockify->getMockObject();
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfImportedMethod_Verify {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
    $Mockify->mockImported('t::TestDummies::DummyImportTools', 'Doubler')->when(Number(2))->thenReturn('InjectedReturnValueOfDoubler');
    my $DummyImportToolsUser = $Mockify->getMockObject();
    is(
        t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
        'In useDummyImportTools, result Doubler call: "InjectedReturnValueOfDoubler"',
        "$SubTestName - Prove that the injection works out"
    );
    is(Doubler(2), 4, "$SubTestName - Prove that the mock is only injected in the mock. The counter should not increase ");
    my $aParams =  GetParametersFromMockifyCall($DummyImportToolsUser, 'Doubler');
    is(scalar @{$aParams} ,1 , "$SubTestName - prove amount of parameters");
    is($aParams->[0] ,2 , "$SubTestName - get parameter of first call");
    is(  GetCallCount($DummyImportToolsUser, 'Doubler'), 1, "$SubTestName - prove that the the Doubler only get called once.");

}
#----------------------------------------------------------------------------------------
sub test_InjectionOfImportedMethod_Verify_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
    $Mockify->spyImported('t::TestDummies::DummyImportTools', 'Doubler')->when(Number(2));
    my $DummyImportToolsUser = $Mockify->getMockObject();
    is(
        t::TestDummies::DummyImportToolsUser_Static::useDummyImportTools(2),
        'In useDummyImportTools, result Doubler call: "4"',
        "$SubTestName - Prove that the injection works out"
    );
    is(Doubler(2), 4, "$SubTestName - Prove that the mock is only injected in the mock. The counter should not increase ");
    my $aParams =  GetParametersFromMockifyCall($DummyImportToolsUser, 'Doubler');
    is(scalar @{$aParams} ,1 , "$SubTestName - prove amount of parameters");
    is($aParams->[0] ,2 , "$SubTestName - get parameter of first call");
    is(  GetCallCount($DummyImportToolsUser, 'Doubler'), 1, "$SubTestName - prove that the the Doubler only get called once.");

}
#----------------------------------------------------------------------------------------
sub test_functionNameFormatingErrorHandling_mock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
    throws_ok( sub { $Mockify->mockImported() },
                   qr/"mockImported" Needs to be called with two Parameters which need to be a fully qualified path as String and the Function name. e.g. "Path::To::Your", "Function"/sm,
                   "$SubTestName - prove no parameters in mockImported error handling"
    );
    throws_ok( sub { $Mockify->mockImported('OnlyFunctionName') },
                   qr/"mockImported" Needs to be called with two Parameters which need to be a fully qualified path as String and the Function name. e.g. "Path::To::Your", "Function"/sm,
                   "$SubTestName - prove not enought parameters in spyImported error handling"
    );
}
#----------------------------------------------------------------------------------------
sub test_functionNameFormatingErrorHandling_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyImportToolsUser_Static');
    throws_ok( sub { $Mockify->spyImported() },
                   qr/"spyImported" Needs to be called with two Parameters which need to be a fully qualified path as String and the Function name. e.g. "Path::To::Your", "Function"/sm,
                   "$SubTestName - prove no parameters in spyImported error handling"
    );
    throws_ok( sub { $Mockify->spyImported('OnlyFunctionName') },
                   qr/"spyImported" Needs to be called with two Parameters which need to be a fully qualified path as String and the Function name. e.g. "Path::To::Your", "Function"/sm,
                   "$SubTestName - prove not enought parameters in spyImported error handling"
    );
}
__PACKAGE__->RunTest();
1;