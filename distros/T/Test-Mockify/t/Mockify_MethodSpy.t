package Mockify_MethodSpy;
use strict;
use FindBin;
use lib ($FindBin::Bin);
use parent 'TestBase';
use Test::More;
use Test::Exception;
use Test::Mockify;
use Test::Mockify::Matcher qw (
        String
        Number
        HashRef
        ArrayRef
        Object
        Function
        Undef
        Any
    );
use Test::Mockify::Verify qw (GetParametersFromMockifyCall WasCalled GetCallCount);
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->integrationTest_AnyTypes();
    $self->integrationTest_ExpectedTypes();
    $self->integrationTest_whenAny();
    $self->integrationTest_Verify();
    $self->integrationTest_MixSpyAndMock();
    return;
}
#------------------------------------------------------------------------
sub integrationTest_AnyTypes {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', ['one','two']);
    $Mockify->spy('returnParameterListNew')->when(String(), Number(), HashRef(), ArrayRef(), Object(), Function(), Undef(), Any());
    my $FakeModule = $Mockify->getMockObject();
    is_deeply($FakeModule->returnParameterListNew('a', 1, {}, [], bless({},'a'), sub{}, undef, 'a'),['one','two'] , 'proves that all parameter types are working for spy.');
}
#------------------------------------------------------------------------
sub integrationTest_ExpectedTypes {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', ['one','two']);
    $Mockify->spy('returnParameterListNew')->when(String('a'));
    $Mockify->spy('returnParameterListNew')->when(Number(123));
    $Mockify->spy('returnParameterListNew')->when(HashRef({1=>23}));
    $Mockify->spy('returnParameterListNew')->when(ArrayRef([1, 23]));
    $Mockify->spy('returnParameterListNew')->when(Object('Hello::World'));
    my $FakeModule = $Mockify->getMockObject();

    is_deeply($FakeModule->returnParameterListNew('a'),['one','two'] , 'proves that the expected string matcher is working for spy.');
    is_deeply($FakeModule->returnParameterListNew(123),['one','two'] , 'proves that the expected number matcher is working for spy.');
    is_deeply($FakeModule->returnParameterListNew({1=>23}),['one','two'] , 'proves that the expected hashref matcher is working for spy.');
    is_deeply($FakeModule->returnParameterListNew([1=>23]),['one','two'] , 'proves that the expected arrayref matcher is working for spy.');
    is_deeply($FakeModule->returnParameterListNew(bless({},'Hello::World')),['one','two'] , 'proves that the expected object matcher is working for spy.');
}
#------------------------------------------------------------------------
sub integrationTest_whenAny {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', ['one','two']);
    $Mockify->spy('returnParameterListNew')->whenAny();
    my $FakeModule = $Mockify->getMockObject();
    is_deeply($FakeModule->returnParameterListNew('a', 1, {}),['one','two'] , 'proves that any is working with multiple random parameters');
    is_deeply($FakeModule->returnParameterListNew(),['one','two'] , 'proves that any is working without parameters');
}

#------------------------------------------------------------------------
sub integrationTest_Verify {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', ['one','two']);
    $Mockify->spy('returnParameterListNew')->when(String('Parameter'));
    $Mockify->spy('returnParameterListNew')->when(String('SomeParameter'));
    $Mockify->spy('DummmyMethodForTestOverriding')->when(String('SomeParameter'));
    my $FakeModule = $Mockify->getMockObject();

    is_deeply($FakeModule->returnParameterListNew('Parameter'),['one','two'] , 'proves that the parameters will be passed');
    is_deeply($FakeModule->returnParameterListNew('SomeParameter'),['one','two'] , 'proves that defining multiple return types are supported');
    is($FakeModule->DummmyMethodForTestOverriding('SomeParameter'),'A dummmy method' , 'proves that defining an other method with the same parameter works fine');
    throws_ok( sub { $FakeModule->DummmyMethodForTestOverriding('WrongValue') },
        qr/No matching found for string/,
        'proves that an unexpected value will throw an Error.'
    );

    is(GetCallCount($FakeModule,'returnParameterListNew'),2 , 'proves that the get call count works fine');
    is(WasCalled($FakeModule,'DummmyMethodForTestOverriding'),1 , 'proves that the verifyer for wasCalled works fine');
    is(GetParametersFromMockifyCall($FakeModule,'DummmyMethodForTestOverriding')->[0],'SomeParameter' , 'proves that the verifyer for getparams. works fine');
}

#------------------------------------------------------------------------
sub integrationTest_MixSpyAndMock {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', ['one','two']);
    $Mockify->spy('returnParameterListNew')->when(String('Parameter'));
    throws_ok( sub { $Mockify->mock('returnParameterListNew') },
        qr/It is not possible to mix spy and mock/,
        'proves that it is not possible to use first spy and than mock for the same method'
    );

    $Mockify->mock('DummmyMethodForTestOverriding')->whenAny()->thenReturn('hello');
    throws_ok( sub { $Mockify->spy('DummmyMethodForTestOverriding') },
        qr/It is not possible to mix spy and mock/,
        'proves that it is not possible to use first mock and than spy for the same method'
    );

    my $FakeModule = $Mockify->getMockObject();

    is_deeply($FakeModule->returnParameterListNew('Parameter'),['one','two'] , 'proves that the parameters will be passed');
    is($FakeModule->DummmyMethodForTestOverriding(),'hello' , 'proves that the mock was called');
}
__PACKAGE__->RunTest();
1;