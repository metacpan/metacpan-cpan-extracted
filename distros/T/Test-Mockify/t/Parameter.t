package Parameter;
use strict;
## no critic (ProhibitMagicNumbers)
use FindBin;
use lib ($FindBin::Bin);
use parent 'TestBase';
use Test::More;
use Test::Exception;
use Test::Mockify::Parameter;
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
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_call_and_buildReturn();
    $self->test_compareExpectedParameters();
    $self->matchWithExpectedParameters();
    return;
}

#------------------------------------------------------------------------
sub test_call_and_buildReturn {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Parameter = Test::Mockify::Parameter->new();
    $Parameter->buildReturn()->thenCall(sub{return join('-', @_);}); ## no critic (ProhibitNoisyQuotes) # wrong critic match
    is($Parameter->call('a','b'),'a-b', 'proves that the parameter has passed');

    $Parameter = Test::Mockify::Parameter->new();
    throws_ok( sub { $Parameter->call() },
       qr/NoReturnValueDefined/sm,
       'proves that mockify throws an error if the return is nott defined.'
    );

    return;
}

#------------------------------------------------------------------------
sub test_compareExpectedParameters {
    my $self = shift;

    my $Parameter = Test::Mockify::Parameter->new(['abc','def']);
    is($Parameter->compareExpectedParameters(['abc']), 0, 'proves that wrong amount of parameters will return false');

    $Parameter = Test::Mockify::Parameter->new(['def']);
    is($Parameter->compareExpectedParameters(['abc']), 0, 'proves that to less parameter will return false');

    $Parameter = Test::Mockify::Parameter->new(['abc']);
    is($Parameter->compareExpectedParameters(['abc','def','xyz']), 0, 'proves that to many parameter will return false');

    $Parameter = Test::Mockify::Parameter->new();
    is($Parameter->compareExpectedParameters(), 1, 'proves that an undefined parameter list will be checked positiv');

    $Parameter = Test::Mockify::Parameter->new();
    is($Parameter->compareExpectedParameters([]), 1, 'proves that an empty parameter list will be checked positiv');

    $Parameter = Test::Mockify::Parameter->new();
    is($Parameter->compareExpectedParameters(['abc']), 0, 'proves that an empty parameter list will be checked negativ');

    $Parameter = Test::Mockify::Parameter->new(['abc', 123]);
    is($Parameter->compareExpectedParameters(['abc', 123]), 1, 'proves that muiltple parameter of type scalar are supported');

    $Parameter = Test::Mockify::Parameter->new([{'hash'=>'value'},['one',{'two'=>'zwei'}]]);
    is($Parameter->compareExpectedParameters([{'hash'=>'value'},['one',{'two'=>'zwei'}]]), 1, 'proves that muiltple parameter of depply nested arrays and hashs are supported -  matches');
    is($Parameter->compareExpectedParameters([{'hash'=>'value'},['one','else']]), 0, 'proves that muiltple parameter of depply nested arrays and hashs are supported - matches not');

}
#------------------------------------------------------------------------
sub matchWithExpectedParameters {
    my $self = shift;
    # no expected parameter
    my $Parameter = Test::Mockify::Parameter->new([String('expectedValue'),String(),String()]);
    is($Parameter->matchWithExpectedParameters('expectedValue','somevalue',123_456),1, 'proves that expected and not checked values are checked. matches.');
    is($Parameter->matchWithExpectedParameters('unexpectedValue','somevalue',123_456),0, 'proves that expected and not checked values are checked. matches not.');
    # check parameter amount
    $Parameter = Test::Mockify::Parameter->new([String('somevalue'),String('othervalue')]);
    is($Parameter->matchWithExpectedParameters('somevalue','othervalue' ), 1, 'proves that the correct amount is matches.');
    is($Parameter->matchWithExpectedParameters('somevalue','othervalue',123_456), 0, 'proves that too many values are not matching');
    is($Parameter->matchWithExpectedParameters('somevalue'), 0, 'proves that too less values are not matching');
    is($Parameter->matchWithExpectedParameters(), 0, , 'proves that no values are not matching');
    # check package name
    $Parameter = Test::Mockify::Parameter->new([String('abc'), Object('Package::One'),Object('Package::Two')]);
    is($Parameter->matchWithExpectedParameters('abc',bless({},'Package::One'),bless({},'Package::Two')), 1, 'proves that the package check is working well. matches.');
    is($Parameter->matchWithExpectedParameters('abc',bless({},'Package::One')), 0, 'proves that the package check is working well. matches not');

    $Parameter = Test::Mockify::Parameter->new();
    is($Parameter->matchWithExpectedParameters(), 1, 'proves that an empty parameter list will be checked positiv');

    $Parameter = Test::Mockify::Parameter->new();
    is($Parameter->matchWithExpectedParameters('abc'), 0, 'proves that an empty parameter list will not be matched');

    $Parameter = Test::Mockify::Parameter->new([String('abc'), Number(123)]);
    is($Parameter->matchWithExpectedParameters('abc', 123), 1, 'proves that muiltple parameter of type scalar are supported');

    $Parameter = Test::Mockify::Parameter->new([HashRef({'hash'=>'value'}), ArrayRef(['one',{'two'=>'zwei'}])]);
    is($Parameter->matchWithExpectedParameters({'hash'=>'value'},['one',{'two'=>'zwei'}]), 1, 'proves that muiltple parameter of depply nested arrays and hashs are supported -  matches');
    is($Parameter->matchWithExpectedParameters({'hash'=>'value'},['one','else']), 0, 'proves that muiltple parameter of depply nested arrays and hashs are supported - matches not');
}

__PACKAGE__->RunTest();
1;