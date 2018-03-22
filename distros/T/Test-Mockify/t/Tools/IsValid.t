package IsValid;
use strict;
## no critic (ProhibitMagicNumbers ProhibitEmptyQuotes)
use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use Test::Mockify::Tools qw ( IsValid );
use Test::More;

#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->isObjectReference_positivPath();
    $self->isObjectReference_negativPath();
    return;
}


#------------------------------------------------------------------------
sub isObjectReference_positivPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok(IsValid('abc'),"$SubTestName - tests if string is valid");
    ok(IsValid(123),"$SubTestName - tests if int is valid");
    ok(IsValid(1.23),"$SubTestName - tests if float is valid");
    ok(IsValid({'key'=> 'value'}),"$SubTestName - tests if hash pointer is valid");
    ok(IsValid(['element1','element2']),"$SubTestName - tests if array pointer is valid");
    ok(IsValid(bless({},'Class')),"$SubTestName - tests if object pointer is valid");

    return;
}

#------------------------------------------------------------------------
sub isObjectReference_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;
    is(IsValid(), $False,"$SubTestName - tests if no parameter is not valid");
    is(IsValid(''), $False,"$SubTestName - tests if empty string is not valid");
    is(IsValid(undef), $False,"$SubTestName - tests if undef is not valid");
    return;
}

__PACKAGE__->RunTest();
1;