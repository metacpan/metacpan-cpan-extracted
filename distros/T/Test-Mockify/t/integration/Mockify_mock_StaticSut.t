package Mockify_StaticMock_StaticSut;
use strict;
use FindBin;
use lib ($FindBin::Bin.'/..'); # point to test base
use lib ($FindBin::Bin.'/../..'); # point to project base
use parent 'TestBase';
use Test::More;
use Test::Mockify::Sut;
use Test::Exception;
use Test::Mockify::Matcher qw (
        String
        Number
    );
use t::TestDummies::DummyStaticToolsUser_Static;
use t::TestDummies::DummyImportToolsUser_Static;
use t::TestDummies::DummyImportTools qw (Doubler);
use Test::Mockify::Verify qw (GetParametersFromMockifyCall GetCallCount);
#----------------------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_InjectionOfStaticedMethod_scopes();
    $self->test_InjectionOfStaticedMethod_scopes_spy();

    $self->test_InjectionOfImportedMethod_scopes();
    $self->test_InjectionOfImportedMethod_scopes_spy();

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
__PACKAGE__->RunTest();
1;