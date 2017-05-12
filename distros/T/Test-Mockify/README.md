[![Build Status](https://travis-ci.org/ePages-de/Mockify.svg?branch=master)](https://travis-ci.org/ePages-de/Mockify)
# NAME

Test::Mockify - minimal mocking framework for perl

# SYNOPSIS

    use Test::Mockify;
    use Test::Mockify::Verify qw ( WasCalled );

    # build a new mocked object
    my $MockObjectBuilder = Test::Mockify->new('SampleLogger', []);
    my $returnValue = undef;
    my $expectedParameterTypes = ['string'];
    $MockObjectBuilder->mock('log', $returnValue, $expectedParameterTypes);
    my $MockedLogger = $MockLoggerBuilder->getMockObject();
    
    # inject mocked object into the code you want to test
    my $App = SampleApp->new('logger'=> $MockedLogger);
    $App->do_something();
    
    # verify that the mock object was called
    ok(WasCalled($MockedLogger, 'log'), 'log was called');
    done_testing();

# DESCRIPTION

Use [Test::Mockify](https://metacpan.org/pod/Test::Mockify) to create and configure mock objects. Use [Test::Mockify::Verify](https://metacpan.org/pod/Test::Mockify::Verify) to
verify the interactions with your mocks.

# METHODS

## new

    my $MockObjectBuilder = Test::Mockify->new('Module::To::Mock', ['Constructor Parameters']);

### Options

The `new` method creates a new mock object builder. Use `getMockObject` to obtain the final
mock object.

## getMockObject

Provides the actual mock object, which you can use in the test.

    my $aParameterList = ['SomeValueForConstructor'];
    my $MockObjectBuilder = Test::Mockify->new( 'My::Module', $aParameterList );
    my $MyModuleObject = $MockObjectBuilder->getMockObject();

## mock

This is a short cut for \*addMock\*, \*addMockWithReturnValue\* and \*addMockWithReturnValueAndParameterCheck\*. \*mock\* detects the required method with given parameters.

| Parameter in \*mock\*  | actually used method |
| ------------- | ------------- |
| mock('MethodName', sub{})  | \*addMock\*  |
| mock('MethodName', 'someValue')  | \*addMockWithReturnValue\*  |
| mock('MethodName', 'someValue', \['string',{'string' => 'abcd'}\])  | \*addMockWithReturnValueAndParameterCheck\*  |

## addMethodSpy

With this method it is possible to observe a method. That means, you keep the original functionality, but you can get meta data from the mockify- framework.

    $MockObjectBuilder->addMethodSpy('myMethodName');

## addMethodSpyWithParameterCheck

With this method it is possible to observe a method and check the parameters. That means, you keep the original functionality, but you can get meta data from the mockify- framework and use the parameter check, like \*addMockWithReturnValueAndParameterCheck\*.

    my $aParameterTypes = ['string',{'string' => 'abcd'}];
    $MockObjectBuilder->addMethodSpyWithParameterCheck('myMethodName', $aParameterTypes);

### Options

Pure types

    ['string', 'int', 'hashref', 'float', 'arrayref', 'object', 'undef', 'any']

or types with expected values

    [{'string'=>'abcdef'}, {'int' => 123}, {'float' => 1.23}, {'hashref' => {'key'=>'value'}}, {'arrayref'=>['one', 'two']}, {'object'=> 'PAth::to:Obejct}]

If you use \*any\*, you have to verify this value explicitly in the test, see \*\*GetParametersFromMockifyCall\*\* in [Test::Mockify::Verify](https://metacpan.org/pod/Test::Mockify::Verify).

## addMock

This is the simplest case. It works like the mock-method from Test::MockObject.

Only handover the \*\*name\*\* and a \*\*method pointer\*\*. Mockify will automatically check if the method exists in the original object.

    $MockObjectBuilder->addMock('myMethodName', sub {
                                      # Your implementation
                                   }
    );

## addMockWithReturnValue

Does the same as `addMock`, but here you can handover a \*\*value\*\* which will be returned if you call the mocked method.

    $MockObjectBuilder->addMockWithReturnValue('myMethodName','the return value');

## addMockWithReturnValueAndParameterCheck

This method is an extension of \*addMockWithReturnValue\*. Here you can also check the parameters which will be passed.

You can check if they have a specific \*\*data type\*\* or even check if they have a given \*\*value\*\*.

In the following example two strings will be expected, and the second one has to have the value "abcd".

    my $aParameterTypes = ['string',{'string' => 'abcd'}];
    $MockObjectBuilder->addMockWithReturnValueAndParameterCheck('myMethodName','the return value',$aParameterTypes);

### Options

Pure types

    ['string', 'int', 'float', 'hashref', 'arrayref', 'object', 'undef', 'any']

or types with expected values

    [{'string'=>'abcdef'}, {'int' => 123}, {'float' => 1.23}, {'hashref' => {'key'=>'value'}}, {'arrayref'=>['one', 'two']}, {'object'=> 'PAth::to:Obejct}]

If you use \*\*any\*\*, you have to verify this value explicitly in the test, see +\*GetParametersFromMockifyCall\*\* in [Test::Mockify::Verify](https://metacpan.org/pod/Test::Mockify::Verify).

# LICENSE

Copyright (C) 2017 ePages GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Christian Breitkreutz <cbreitkreutz@epages.com>
