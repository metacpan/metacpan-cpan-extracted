[![Build Status](https://travis-ci.org/ChristianBreitkreutz/Mockify.svg?branch=master)](https://travis-ci.org/ChristianBreitkreutz/Mockify) [![MetaCPAN Release](https://badge.fury.io/pl/Test-Mockify.svg)](https://metacpan.org/release/Test-Mockify)
# NAME

Test::Mockify - minimal mocking framework for perl

# SYNOPSIS

    use Test::Mockify;
    use Test::Mockify::Verify qw ( WasCalled );
    use Test::Mockify::Matcher qw ( String );

    # build a new mocked object
    my $MockObjectBuilder = Test::Mockify->new('SampleLogger', []);
    $MockObjectBuilder->mock('log')->when(String())->thenReturnUndef();
    my $MockedLogger = $MockLoggerBuilder->getMockObject();

    # inject mocked object into the code you want to test
    my $App = SampleApp->new('logger'=> $MockedLogger);
    $App->do_something();

    # verify that the mocked method was called
    ok(WasCalled($MockedLogger, 'log'), 'log was called');
    done_testing();

# DESCRIPTION

Use [Test::Mockify](https://metacpan.org/pod/Test::Mockify) to create and configure mock objects. Use [Test::Mockify::Verify](https://metacpan.org/pod/Test::Mockify::Verify) to
verify the interactions with your mocks. Use [Test::Mockify::Sut](https://metacpan.org/pod/Test::Mockify::Sut) to inject dependencies into your Sut.

You can find a Example Project in [ExampleProject](https://github.com/ChristianBreitkreutz/Mockify/tree/master/t/ExampleProject)

# METHODS

## getMockObject

Provides the actual mock object, which you can use in the test.

    my $aParameterList = ['SomeValueForConstructor'];
    my $MockObjectBuilder = Test::Mockify->new( 'My::Module', $aParameterList );
    my $MyModuleObject = $MockObjectBuilder->getMockObject();

## mock

This is the place where the mocked methods are defined. The method also proves that the method you like to mock actually exists.

### synopsis

This method takes one parameter, which is the name of the method you like to mock.
Because you need to specify more detailed the behaviour of this mock you have to chain the method signature (when) and the expected return value (then...). 

For example, the next line will create a mocked version of the method log, but only if this method is called with any string and the number 123. In this case it will return the String 'Hello World'. Mockify will throw an error if this method is called somehow else.

    my $MockObjectBuilder = Test::Mockify->new( 'Sample::Logger', [] );
    $MockObjectBuilder->mock('log')->when(String(), Number(123))->thenReturn('Hello World');
    my $SampleLogger = $MockObjectBuilder->getMockObject();
    is($SampleLogger->log('abc',123), 'Hello World');

#### when

To define the signature in the needed structure you must use the [Test::Mockify::Matcher](https://metacpan.org/pod/Test::Mockify::Matcher).

#### whenAny

If you don't want to specify the method signature at all, you can use whenAny.
It is not possible to mix `whenAny` and `when` for the same method.

#### then ...

For possible return types please look in [Test::Mockify::ReturnValue](https://metacpan.org/pod/Test::Mockify::ReturnValue)

## spy

Use spy if you want to observe a method. You can use the [Test::Mockify::Verify](https://metacpan.org/pod/Test::Mockify::Verify) to ensure that the method was called with the expected parameters.

### synopsis

This method takes one parameter, which is the name of the method you like to spy.
Because you need to specify more detailed the behaviour of this spy you have to define the method signature with `when`

For example, the next line will create a method spy of the method log, but only if this method is called with any string and the number 123. Mockify will throw an error if this method is called in another way.

    my $MockObjectBuilder = Test::Mockify->new( 'Sample::Logger', [] );
    $MockObjectBuilder->spy('log')->when(String(), Number(123));
    my $SampleLogger = $MockObjectBuilder->getMockObject();

    # call spied method
    $SampleLogger->log('abc', 123);

    # verify that the spied method was called
    is_deeply(GetParametersFromMockifyCall($MockedLogger, 'log'),['abc', 123], 'Check parameters of first call');

#### when

To define the signature in the needed structure you must use the [Test::Mockify::Matcher](https://metacpan.org/pod/Test::Mockify::Matcher).

#### whenAny

If you don't want to specify the method signature at all, you can use whenAny.
It is not possible to mix `whenAny` and `when` for the same method.

# LICENSE

Copyright (C) 2017 ePages GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Christian Breitkreutz <christianbreitkreutz@gmx.de>

# ACKNOWLEDGEMENTS

Thanks to Dustin Buckenmeyer <dustin.buckenmeyer@gmail.com> and [ECS Tuning](https://www.ecstuning.com/) for giving Dustin the opportunity to pursue this idea and ultimately give it back to the community!
