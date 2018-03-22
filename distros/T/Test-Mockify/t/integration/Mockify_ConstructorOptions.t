package Mockify_ConstructorOptions;
use strict;

use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use Test::Mockify;
use Test::More;
use warnings;
use Test::Exception;
## no critic (ProhibitComplexRegexes ProhibitNoWarnings)
no warnings 'deprecated';
sub testPlan {
    my $self = shift;

    $self->test_ModulWithConstructor();
    $self->test_ModulWithConstructor_emptyParameterList();
    $self->test_ModulWithConstructor_butIgnore();

    $self->test_ModulWithoutConstructor();
    $self->test_ModulWithoutConstructor_ParameterListError();
}
#----------------------------------------------------------------------------------------
sub test_ModulWithConstructor {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('TestDummies::FakeModuleForMockifyTest',['Hello' => 'World']);
    my $FakeModuleForMockifyTest = $Mockify->getMockObject();
    is_deeply($FakeModuleForMockifyTest->returnParameterListNew(), ['Hello' => 'World'], "$SubTestName - Prove that the parameters are taken over.");

    return;
}
#----------------------------------------------------------------------------------------
sub test_ModulWithConstructor_emptyParameterList {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('TestDummies::FakeModuleForMockifyTest',[]);
    my $FakeModuleForMockifyTest = $Mockify->getMockObject();
    is_deeply($FakeModuleForMockifyTest->returnParameterListNew(), [], "$SubTestName - Prove that the parameters are taken over.");

    return;
}
#----------------------------------------------------------------------------------------
sub test_ModulWithConstructor_butIgnore {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('TestDummies::FakeModuleForMockifyTest');
    $Mockify->mock('DummyMethodForTestOverriding')->when()->thenReturn('Injected');
    my $FakeModuleForMockifyTest = $Mockify->getMockObject();
    is($FakeModuleForMockifyTest->DummyMethodForTestOverriding(), 'Injected', "$SubTestName - Prove that the mock still works");
    is($FakeModuleForMockifyTest->returnParameterListNew(), undef, "$SubTestName - Prove that the parameters was never used.");

    return;
}
#----------------------------------------------------------------------------------------
sub test_ModulWithoutConstructor {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('TestDummies::FakeModuleWithoutNew');
    my $MockedFakeModule = $Mockify->getMockObject();
    is($MockedFakeModule->secondDummyMethodForTestOverriding(),'A second dummy method',"$SubTestName - test if the loaded module still have the unmocked methods");

    return;
}
#----------------------------------------------------------------------------------------
sub test_ModulWithoutConstructor_ParameterListError {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    throws_ok( sub { Test::Mockify->new('TestDummies::FakeModuleWithoutNew', []) },
               qr/TestDummies::FakeModuleWithoutNew' have no constructor. If you like to create a mock of a package without constructor please use it without parameter list/sm,
               "$SubTestName - Prove error message when using modulesrüg without constructor"
     );

    return;
}

__PACKAGE__->RunTest();