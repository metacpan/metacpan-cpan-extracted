package Mockify_Method;
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
    $self->integrationTest_WhenAny();
    $self->integrationTest_thenCall();
    $self->integrationTest_thenReturnArray();
    $self->integrationTest_thenReturnHash();
    $self->integrationTest_thenReturnUndef();
    $self->integrationTest_Verify();
    $self->integrationTest_thenThrowError();
    return;
}
#------------------------------------------------------------------------
sub integrationTest_AnyTypes {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String(), Number(), HashRef(), ArrayRef(), Object(), Function(), Undef(), Any())->thenReturn('Its matched');
    my $FakeModule = $Mockify->getMockObject();
    is($FakeModule->DummyMethodForTestOverriding('a', 1, {}, [], bless({},'a'), sub{}, undef, 'a'),'Its matched' , 'proves that all parameter types are working');
}
#------------------------------------------------------------------------
sub integrationTest_ExpectedTypes {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('a'))->thenReturn('string');
    $Mockify->mock('DummyMethodForTestOverriding')->when(Number(123))->thenReturn('number');
    $Mockify->mock('DummyMethodForTestOverriding')->when(HashRef({1=>23}))->thenReturn('hashref');
    $Mockify->mock('DummyMethodForTestOverriding')->when(ArrayRef([1, 23]))->thenReturn('arrayref');
    $Mockify->mock('DummyMethodForTestOverriding')->when(Object('Hello::World'))->thenReturn('object');
    my $FakeModule = $Mockify->getMockObject();

    is($FakeModule->DummyMethodForTestOverriding('a'),'string' , 'proves that the expected string matcher is working.');
    is($FakeModule->DummyMethodForTestOverriding(123),'number' , 'proves that the expected number matcher is working.');
    is($FakeModule->DummyMethodForTestOverriding({1=>23}),'hashref' , 'proves that the expected hashref matcher is working.');
    is($FakeModule->DummyMethodForTestOverriding([1=>23]),'arrayref' , 'proves that the expected arrayref matcher is working.');
    is($FakeModule->DummyMethodForTestOverriding(bless({},'Hello::World')),'object' , 'proves that the expected object matcher is working.');
}
#------------------------------------------------------------------------
sub integrationTest_WhenAny {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->whenAny()->thenReturn('Its called');
    my $FakeModule = $Mockify->getMockObject();
    is($FakeModule->DummyMethodForTestOverriding('a', 1, {}),'Its called' , 'proves that any is working');
}
#------------------------------------------------------------------------
sub integrationTest_thenCall {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('Parameter'))->thenCall(sub{return $_[0].'_test';});
    my $FakeModule = $Mockify->getMockObject();

    is($FakeModule->DummyMethodForTestOverriding('Parameter'),'Parameter_test' , 'proves than thenCall is working.');
}
#------------------------------------------------------------------------
sub integrationTest_thenReturnArray {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('Parameter'))->thenReturnArray(['a', 'b']);
    my $FakeModule = $Mockify->getMockObject();

    my @ReturnValue = $FakeModule->DummyMethodForTestOverriding('Parameter');
    is_deeply(\@ReturnValue, ['a', 'b'], 'proves that an Array was returned.');
}
#------------------------------------------------------------------------
sub integrationTest_thenReturnHash {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('Parameter'))->thenReturnHash({'a'=> 'b'});
    my $FakeModule = $Mockify->getMockObject();

    my %ReturnValue = $FakeModule->DummyMethodForTestOverriding('Parameter');
    is_deeply(\%ReturnValue, {'a'=> 'b'}, 'proves that a hash was returned.');
}
#------------------------------------------------------------------------
sub integrationTest_thenReturnUndef {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('Parameter'))->thenReturnUndef();
    my $FakeModule = $Mockify->getMockObject();

    is($FakeModule->DummyMethodForTestOverriding('Parameter'), undef, 'proves that a hash was returned.');
}
#------------------------------------------------------------------------
sub integrationTest_thenThrowError {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('Parameter'))->thenThrowError('HelloError');
    my $FakeModule = $Mockify->getMockObject();

    throws_ok( sub { $FakeModule->DummyMethodForTestOverriding('Parameter') },
        qr/HelloError/,
        'proves that the "HelloError" Error was thrown.'
    );
}
#------------------------------------------------------------------------
sub integrationTest_Verify {
    my $self = shift;

    my $Mockify = Test::Mockify->new('FakeModuleForMockifyTest', []);
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('Parameter'))->thenReturn('ReturnValue');
    $Mockify->mock('DummyMethodForTestOverriding')->when(String('SomeParameter'))->thenReturn('SomeReturnValue');
    $Mockify->mock('secondDummyMethodForTestOverriding')->when(String('SomeParameter'))->thenReturn('SecondReturnValue');
    my $FakeModule = $Mockify->getMockObject();

    is($FakeModule->DummyMethodForTestOverriding('Parameter'),'ReturnValue' , 'proves that the parameters will be passed');
    is($FakeModule->DummyMethodForTestOverriding('SomeParameter'),'SomeReturnValue' , 'proves that defining mulitiple return types are supported');
    is($FakeModule->secondDummyMethodForTestOverriding('SomeParameter'),'SecondReturnValue' , 'proves that defining an other method with the same parameter works fine');

    is(GetCallCount($FakeModule,'DummyMethodForTestOverriding'),2 , 'proves that the get call count works fine');
    is(WasCalled($FakeModule,'secondDummyMethodForTestOverriding'),1 , 'proves that the verifyer for wasCalled works fine');
    is(GetParametersFromMockifyCall($FakeModule,'secondDummyMethodForTestOverriding')->[0],'SomeParameter' , 'proves that the verifyer for getparams. works fine');
}
__PACKAGE__->RunTest();
1;