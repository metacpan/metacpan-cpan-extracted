package Mockify_StaticInjection;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Exception;
use Test::Mockify;
use Test::Mockify::Verify qw (WasCalled GetCallCount GetParametersFromMockifyCall);
use Test::More;
use Test::Mockify::Matcher qw (String Number);
use warnings;
use Data::Dumper;


use strict;
no warnings 'deprecated';

use FakeModuleForMockifyTest;
use FakeModuleWithoutNew;

sub testPlan {
    my $self = shift;

    $self->test_mockStatic();
    $self->test_verify_with_mockAndSpy();
    $self->test_functionNameFormatingErrorHandling();
    $self->test_MethodAndImportedFunctionHaveTheSameName();
    $self->test_someSelectedMockifyFeatures();

}
#----------------------------------------------------------------------------------------
sub test_mockStatic {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $SUT;
    {
        my $Mockify = Test::Mockify->new('FakeModulStaticInjection',[]);
        $Mockify->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('German'))->thenReturn('Hallo Welt');
        $Mockify->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('Spanish'))->thenReturn('Hola Mundo');
        $Mockify->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('Esperanto'))->thenReturn('Saluton mondon');
        $SUT = $Mockify->getMockObject();

        is($SUT->useStaticFunction('German'), 'German: Hallo Welt',"$SubTestName - prove full path call- german");
        is($SUT->useImportedStaticFunction('German'), 'German: Hallo Welt',"$SubTestName - prove that the same mock can handle also the imported call - german");
        is($SUT->useStaticFunction('Spanish'), 'Spanish: Hola Mundo',"$SubTestName - prove full path call - spanish");
        is($SUT->useImportedStaticFunction('Spanish'), 'Spanish: Hola Mundo',"$SubTestName - prove imported call - spanish");
    }
    # With this approach it also is not binded anymore to the scope. The Override stays with the mocked object
    is($SUT->useStaticFunction('Esperanto'), 'Esperanto: Saluton mondon',"$SubTestName - prove full path call, scope independent- german");
    is($SUT->useImportedStaticFunction('Esperanto'), 'Esperanto: Saluton mondon',"$SubTestName - prove that the same mock can handle also the imported call, scope independent - german");

}
#----------------------------------------------------------------------------------------
sub test_verify_with_mockAndSpy{
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('FakeModulStaticInjection',[]);
    $Mockify->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('German'))->thenReturn('Hallo Welt');
    $Mockify->spyStatic('FakeStaticTools::HelloSpy')->when(String('And you are?'));
    my $SUT = $Mockify->getMockObject();

    is($SUT->useStaticFunction('German'), 'German: Hallo Welt',"$SubTestName - prove full path call- german");
    is($SUT->useImportedStaticFunction('German'), 'German: Hallo Welt',"$SubTestName - prove that the same mock can handle also the imported call - german");
    is($SUT->useStaticFunctionSpy('And you are?'), 'And you are?: Bond, James Bond!', "$SubTestName - prove static spy Works");
    is($SUT->useImportedStaticFunctionSpy('And you are?'), 'And you are?: Bond, James Bond!', "$SubTestName - prove static spy Works.");

    ok( WasCalled($SUT, 'FakeStaticTools::ReturnHelloWorld'), "$SubTestName - prove verify, independent of scope and call type");
    is( GetCallCount($SUT, 'FakeStaticTools::ReturnHelloWorld'),  2,"$SubTestName - prove that 'ReturnHelloWorld' was called 2 times, independent of call type");

    my $aParamsCall1 = GetParametersFromMockifyCall($SUT, 'FakeStaticTools::ReturnHelloWorld', 0);
    is(scalar @{$aParamsCall1}, 1 , "$SubTestName - prove amount of parameters");
    is($aParamsCall1->[0], 'German' , "$SubTestName - prove that the value of parameter 1 is 'German'");

    ok( WasCalled($SUT, 'FakeStaticTools::HelloSpy'), "$SubTestName - prove verify, independent of scope and call type");
    is(GetCallCount($SUT,'FakeStaticTools::HelloSpy'), 2,"$SubTestName - prove verify works for spy");
    my $aParamsCallHelloSpy = GetParametersFromMockifyCall($SUT, 'FakeStaticTools::HelloSpy', 0);
    is(scalar @{$aParamsCallHelloSpy}, 1 , "$SubTestName - prove amount of parameters for 'HelloSpy'");
    is($aParamsCallHelloSpy->[0], 'And you are?' , "$SubTestName - prove that the value of parameter 1 of helloSpy is 'And you are?'");
}
#----------------------------------------------------------------------------------------
sub test_MethodAndImportedFunctionHaveTheSameName {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('FakeModulStaticInjection',[]);
    my $SUT = $Mockify->getMockObject();

    # Perl can't differ between imported and actual methods of a package.
    # Since this package implements a method which is also imported as static function,
    #    the implemented method will override the imported one since the own implementaion is loaded later in time.
    #    (the perl interpreter complains too)
    is($SUT->methodImportedHappyOverride(), 'original in FakeModulStaticInjection', "$SubTestName - prove return value before mocking!! it is not 'original in FakeStaticTools' as you would expect.");
    is($SUT->methodStaticHappyOverride(), 'original in FakeStaticTools', "$SubTestName - Prove the static call behaves normal");
    
    $Mockify->mockStatic('FakeStaticTools::HappyOverride')->whenAny()->thenReturn('i am mocked'); # This will override the method and the imported Function

    is($SUT->methodImportedHappyOverride(), 'i am mocked', "$SubTestName - prove now it returns always the mock and will hide the perl 'Bug'");
    is($SUT->methodStaticHappyOverride(), 'i am mocked', "$SubTestName - Prove will be mocked as expected");
}
#----------------------------------------------------------------------------------------
sub test_functionNameFormatingErrorHandling {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify->new('FakeModulStaticInjection',[]);
    throws_ok( sub { $Mockify->mockStatic() },
                   qr/The Parameter needs to be defined and a String. e.g. Path::To::Your::Function/,
                   "$SubTestName - prove the an undefined will fail"
    );
    throws_ok( sub { $Mockify->mockStatic('OnlyFunctionName') },
                   qr/The function name needs to be with full path. e.g. 'Path::To::Your::OnlyFunctionName' instead of only 'OnlyFunctionName'/,
                   "$SubTestName - prove the an incomplete name will fail"
    );
}
#----------------------------------------------------------------------------------------
sub test_someSelectedMockifyFeatures {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify->new('FakeModulStaticInjection',[]);
    $Mockify->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('Error'))->thenThrowError('TestError');
    $Mockify->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('caller'))->thenCall(sub{return 'returnValue'});
    $Mockify->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('undef'), String('abc'))->thenReturnUndef();
    
    $Mockify->mock('overrideMethod')->when(String('override'))->thenReturn('overridden Value');
    $Mockify->spy('overrideMethod_spy')->when(String('spyme'));
    my $SUT = $Mockify->getMockObject();

    #Error
    throws_ok( sub{$SUT->useStaticFunction('Error') },
                   qr/TestError/,
                   "$SubTestName - prove if thenThrowError will fail"
    );
    # anonymous function pointer mock
    is($SUT->useStaticFunction('caller'), 'caller: returnValue',"$SubTestName - prove thenCall");
    # undef
    is($SUT->useStaticFunction('undef', 'abc'), 'undef: ',"$SubTestName - prove thenReturnUndef");
    # normal mock
    is($SUT->overrideMethod('override'), 'overridden Value',"$SubTestName - prove mock Works");
    # normal spy
    $SUT->overrideMethod_spy('spyme'); #1
    $SUT->overrideMethod_spy('spyme'); #2
    is(GetCallCount($SUT,'overrideMethod_spy'), 2,"$SubTestName - prove verify works for override");
}

__PACKAGE__->RunTest();