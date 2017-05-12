package TypeTests_isString;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify::TypeTests qw (IsString);
use Test::More;

#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->isString_positivPath();
    $self->isString_negativPath();
    return;
}

#------------------------------------------------------------------------
sub isString_positivPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok(IsString('abc'), "$SubTestName - tests string - true");
    ok(IsString("a\tbc\n"), "$SubTestName - tests string with tabulator and return - true");
    ok(IsString('123abc'), "$SubTestName - tests string with leading numbers - true");
    ok(IsString('abc12.3'), "$SubTestName - tests string with float in the end- true");
    ok(IsString('123 abc'), "$SubTestName - tests string with space and with leading numbers - true");
    ok(IsString('abc 123'), "$SubTestName - tests string with space and numbers in the end- true");
    ok(IsString(''),"$SubTestName - tests empty string - true");
    ok(IsString(' '), "$SubTestName - tests white space - true");
    ok(IsString('  '), "$SubTestName - tests multiple white spaces - true");

    return;
}

#------------------------------------------------------------------------
sub isString_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;

    is(IsString(), $False,"$SubTestName - tests empty parameter - false");
    is(IsString({'some' => 'thing'}), $False,"$SubTestName - tests hash pointer - false");
    is(IsString(['some' , 'thing']), $False,"$SubTestName - tests array pointer - false");
    is(IsString(bless({},'object')), $False, "$SubTestName - tests object pointer - false");
    is(IsString(sub{}), $False, "$SubTestName - tests object pointer - false");

    return;
}

__PACKAGE__->RunTest();
