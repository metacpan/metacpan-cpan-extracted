package TypeTests_isInteger;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify::TypeTests qw ( IsInteger );
use Test::More;

#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->isInteger_positivPath();
    $self->isInteger_negativPath();
    return;
}
#------------------------------------------------------------------------
sub isInteger_positivPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok(IsInteger(2), "$SubTestName - tests positiv integer - true");
    ok(IsInteger(+2), "$SubTestName - tests other positiv integer - true");
    ok(IsInteger(-2), "$SubTestName - tests negativ integer - true");
    ok(IsInteger(0), "$SubTestName - tests zero - true");
    ok(IsInteger(-0), "$SubTestName - tests negativ zero - true");
    return;
}
#------------------------------------------------------------------------
sub isInteger_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;

    is(IsInteger(), $False, "$SubTestName - tests empty parameter - false");
    is(IsInteger(4.123), $False, "$SubTestName - tests positiv float - false");
    is(IsInteger(-0.123), $False, "$SubTestName - tests negativ float - false");
    is(IsInteger('a'), $False, "$SubTestName - tests string - false");
    is(IsInteger(''), $False, "$SubTestName - tests empty string - false");
    is(IsInteger({'some' => 'thing'}), $False, "$SubTestName - tests hash pointer - false");
    is(IsInteger(['some', 'thing']), $False, "$SubTestName - tests array pointer - false");
    is(IsInteger(bless({},'object')), $False, "$SubTestName - tests object pointer - false");
    is(IsInteger(sub{}), $False, "$SubTestName - tests function pointer - false");

    return;
}

__PACKAGE__->RunTest();
1;
