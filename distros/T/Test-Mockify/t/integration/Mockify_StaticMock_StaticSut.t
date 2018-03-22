package Mockify_StaticMock_StaticSut;
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
use t::TestDummies::DummyStaticToolsUser_Static;
use Test::Mockify::Verify qw (GetParametersFromMockifyCall GetCallCount);
#----------------------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_InjectionOfStaticedMethod_scopes();
    $self->test_InjectionOfStaticMethod_CreatorMethod();
    $self->test_InjectionOfStaticedMethod_scopes_spy();
    $self->test_InjectionOfStaticedMethod_SetMockifyToUndef();
    $self->test_InjectionOfStaticedMethod_Verify();
    $self->test_InjectionOfStaticedMethod_Verify_spy();
    $self->test_functionNameFormatingErrorHandling_mock ();
    $self->test_functionNameFormatingErrorHandling_spy ();
}

#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_scopes {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    {#beginn scope
        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
        $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');
        is(
            t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
            'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
            "$SubTestName - Prove that the injection works out"
        );
        is(t::TestDummies::DummyStaticTools::Tripler(2), 'InjectedReturnValueOfTripler', "$SubTestName - Prove injected mock result (direct call)");
    } # end scope
    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    is(t::TestDummies::DummyStaticTools::Tripler(2), 6, "$SubTestName - Prove released original method result (direct call)");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticMethod_CreatorMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

        my $DummyStaticToolsUser = $self->_createDummyStaticToolsUser();
        is(
            t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
            'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
            "$SubTestName - Prove that the injection works out"
        );
        is(t::TestDummies::DummyStaticTools::Tripler(2), 'InjectedReturnValueOfTripler', "$SubTestName - Prove injected mock result (direct call)");
}
#----------------------------------------------------------------------------------------
sub _createDummyStaticToolsUser {
    my $self = shift;

    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
    $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');

   return $Mockify->getMockObject();
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_scopes_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    {#beginn scope
        my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
        $Mockify->spyStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2));
        is(
            t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
            'In useDummyStaticTools, result Tripler call: "6"',
            "$SubTestName - Prove that the injection works out"
        );
    } # end scope
    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_SetMockifyToUndef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
    $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');
    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
        "$SubTestName - Prove that the injection works out"
    );
    is(t::TestDummies::DummyStaticTools::Tripler(2), 'InjectedReturnValueOfTripler', "$SubTestName - Prove injected mock result (direct call)");
    $Mockify = undef;
    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    is(t::TestDummies::DummyStaticTools::Tripler(2), 6, "$SubTestName - Prove released original method result (direct call)");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_Verify {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
    $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');
    my $DummyStaticToolsUser = $Mockify->getMockObject();
    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
        "$SubTestName - Prove that the injection works out"
    );
    is(
        t::TestDummies::DummyStaticTools::Tripler(2),
        'InjectedReturnValueOfTripler',
        "$SubTestName - Prove injected mock result will increase the counter (direct call) "
    );
    my $aParams =  GetParametersFromMockifyCall($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler');
    is(scalar @{$aParams} ,1 , "$SubTestName - prove amount of parameters");
    is($aParams->[0] ,2 , "$SubTestName - get parameter of first call");
    is(  GetCallCount($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler'), 2, "$SubTestName - prove that the the Tripler only get called twice.");

}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_Verify_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
    $Mockify->spyStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2));
    my $DummyStaticToolsUser = $Mockify->getMockObject();
    is(
        t::TestDummies::DummyStaticToolsUser_Static::useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - Prove that the spy works out"
    );
    is(
        t::TestDummies::DummyStaticTools::Tripler(2),
        6,
        "$SubTestName - Prove injected spy result will increase the counter (direct call) "
    );
    my $aParams =  GetParametersFromMockifyCall($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler');
    is(scalar @{$aParams} ,1 , "$SubTestName - prove amount of parameters");
    is($aParams->[0] ,2 , "$SubTestName - get parameter of first call");
    is(  GetCallCount($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler'), 2, "$SubTestName - prove that the the Tripler only get called twice.");

}

#----------------------------------------------------------------------------------------
sub test_functionNameFormatingErrorHandling_mock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
    throws_ok( sub { $Mockify->mockStatic() },
                   qr/"mockStatic" Needs to be called with one Parameter which need to be a fully qualified path as String. e.g. "Path::To::Your::Function"/sm,
                   "$SubTestName - prove the an undefined will fail"
    );
    throws_ok( sub { $Mockify->mockStatic('OnlyFunctionName') },
                   qr/The function you like to mock needs to be defined with a fully qualified path. e.g. 'Path::To::Your::OnlyFunctionName' instead of only 'OnlyFunctionName'/sm,
                   "$SubTestName - prove the an incomplete name will fail"
    );
}
#----------------------------------------------------------------------------------------
sub test_functionNameFormatingErrorHandling_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify::Sut->new('t::TestDummies::DummyStaticToolsUser_Static');
    throws_ok( sub { $Mockify->spyStatic() },
                   qr/"spyStatic" Needs to be called with one Parameter which need to be a fully qualified path as String. e.g. "Path::To::Your::Function"/sm,
                   "$SubTestName - prove the an undefined will fail"
    );
    throws_ok( sub { $Mockify->spyStatic('OnlyFunctionName') },
                   qr/The function you like to spy needs to be defined with a fully qualified path. e.g. 'Path::To::Your::OnlyFunctionName' instead of only 'OnlyFunctionName'/sm,
                   "$SubTestName - prove the an incomplete name will fail"
    );
}
__PACKAGE__->RunTest();
1;