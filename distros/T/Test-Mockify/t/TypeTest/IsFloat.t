package IsFloat;
## no critic (ProhibitMagicNumbers)
use strict;

use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use Test::Mockify::TypeTests qw (IsFloat);
use Test::More;

#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->_isFloat_positivPath();
    $self->_isFloat_negativPath();
    return;
}


#------------------------------------------------------------------------
sub _isFloat_positivPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    #brute force testing ON
    ok(IsFloat(-1.12E-34),"$SubTestName - tests if -1.12E-34 is a float - true");
    ok(IsFloat(-1.12E+34),"$SubTestName - tests if -1.12E+34 is a float - true");
    ok(IsFloat(+1.12E-34),"$SubTestName - tests if +1.12E-34 is a float - true");
    ok(IsFloat(+1.12E+34),"$SubTestName - tests if +1.12E+34 is a float - true");
    ok(IsFloat(1.12E-34),"$SubTestName - tests if 1.12E-34 is a float - true");
    ok(IsFloat(1.12E+34),"$SubTestName - tests if 1.12E+34 is a float - true");

    ok(IsFloat(-.12E-34),"$SubTestName - tests if -.12E-34 is a float - true");
    ok(IsFloat(-.12E+34),"$SubTestName - tests if -.12E+34 is a float - true");
    ok(IsFloat(+.12E-34),"$SubTestName - tests if +.12E-34 is a float - true");
    ok(IsFloat(+.12E+34),"$SubTestName - tests if +.12E+34 is a float - true");
    ok(IsFloat(.12E-34),"$SubTestName - tests if .12E-34 is a float - true");
    ok(IsFloat(.12E+34),"$SubTestName - tests if .12E+34 is a float - true");

    ok(IsFloat(-1.E-34),"$SubTestName - tests if -1.E-34 is a float - true");
    ok(IsFloat(-1.E+34),"$SubTestName - tests if -1.E+34 is a float - true");
    ok(IsFloat(+1.E-34),"$SubTestName - tests if +1.E-34 is a float - true");
    ok(IsFloat(+1.E+34),"$SubTestName - tests if +1.E+34 is a float - true");
    ok(IsFloat(1.E-34),"$SubTestName - tests if 1.E-34 is a float - true");
    ok(IsFloat(1.E+34),"$SubTestName - tests if 1.E+34 is a float - true");

    ok(IsFloat(-1.12e-34),"$SubTestName - tests if -1.12e-34 is a float - true");
    ok(IsFloat(-1.12e+34),"$SubTestName - tests if -1.12e+34 is a float - true");
    ok(IsFloat(+1.12e-34),"$SubTestName - tests if +1.12e-34 is a float - true");
    ok(IsFloat(+1.12e+34),"$SubTestName - tests if +1.12e+34 is a float - true");
    ok(IsFloat(1.12e-34),"$SubTestName - tests if 1.12e-34 is a float - true");
    ok(IsFloat(1.12e+34),"$SubTestName - tests if 1.12e+34 is a float - true");

    ok(IsFloat(-.12e-34),"$SubTestName - tests if -.12e-34 is a float - true");
    ok(IsFloat(-.12e+34),"$SubTestName - tests if -.12e+34 is a float - true");
    ok(IsFloat(+.12e-34),"$SubTestName - tests if +.12e-34 is a float - true");
    ok(IsFloat(+.12e+34),"$SubTestName - tests if +.12e+34 is a float - true");
    ok(IsFloat(.12e-34),"$SubTestName - tests if .12e-34 is a float - true");
    ok(IsFloat(.12e+34),"$SubTestName - tests if .12e+34 is a float - true");

    ok(IsFloat(-1.e-34),"$SubTestName - tests if -1.e-34 is a float - true");
    ok(IsFloat(-1.e+34),"$SubTestName - tests if -1.e+34 is a float - true");
    ok(IsFloat(+1.e-34),"$SubTestName - tests if +1.e-34 is a float - true");
    ok(IsFloat(+1.e+34),"$SubTestName - tests if +1.e+34 is a float - true");
    ok(IsFloat(1.e-34),"$SubTestName - tests if 1.e-34 is a float - true");
    ok(IsFloat(1.e+34),"$SubTestName - tests if 1.e+34 is a float - true");

    ok(IsFloat(-1.12),"$SubTestName - tests if -1.12 is a float - true");
    ok(IsFloat(+1.12),"$SubTestName - tests if +1.12 is a float - true");
    ok(IsFloat(1.12),"$SubTestName - tests if 1.12 is a float - true");

    ok(IsFloat(-.12),"$SubTestName - tests if -.12 is a float - true");
    ok(IsFloat(+.12),"$SubTestName - tests if +.12 is a float - true");
    ok(IsFloat(.12),"$SubTestName - tests if .12 is a float - true");

    ok(IsFloat(-1.),"$SubTestName - tests if -1. is a float - true");
    ok(IsFloat(+1.),"$SubTestName - tests if +1. is a float - true");
    ok(IsFloat(1.),"$SubTestName - tests if 1. is a float - true");
    #brute force testing OFF ;-)

    ok(IsFloat(1),"$SubTestName - tests the integer is also a float - true");
    ok(IsFloat(-1),"$SubTestName - tests the integer is also a float - true");

    return;
}

#------------------------------------------------------------------------
sub _isFloat_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;

    is(IsFloat(), $False, "$SubTestName - tests empty parameters");
    is(IsFloat('abc'), $False, "$SubTestName - tests abc is not a float");
    is(IsFloat('123,123e-123'), $False, "$SubTestName - tests 123,123e-123 is not a float");
    is(IsFloat('12.234ae-12'), $False, "$SubTestName - tests 12.234ae-12 is not a float");
    is(IsFloat('12.234e-'), $False, "$SubTestName - tests 12.234ae-12 is not a float");
    is(IsFloat('.'), $False, "$SubTestName - tests '.' is not a float");## no critic (ProhibitNoisyQuotes) # wrong critic match
    is(IsFloat({'some' => 'thing'}), $False,"$SubTestName - tests hash pointer - false");
    is(IsFloat(['some' , 'thing']), $False,"$SubTestName - tests array pointer - false");
    is(IsFloat(bless({},'object')), $False, "$SubTestName - tests object pointer - false");

    return;
}

__PACKAGE__->RunTest();
1;
