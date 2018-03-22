package IsObjectReference;
## no critic (ProhibitMagicNumbers ProhibitEmptyQuotes)
use strict;

use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use Test::Mockify::TypeTests qw (IsObjectReference);
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

    my $TestObject = bless({},'Object::Test');
    ok(IsObjectReference($TestObject), "$SubTestName - tests if object will be detected");

    return;
}
#------------------------------------------------------------------------
sub isObjectReference_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;

    is(IsObjectReference(), $False, "$SubTestName - tests empty parameter - false");
    is(IsObjectReference(123), $False, "$SubTestName - tests with integer - false");
    is(IsObjectReference(12.3), $False, "$SubTestName - tests with float - false");
    is(IsObjectReference('string'), $False, "$SubTestName - tests with string - false");
    is(IsObjectReference(['some', 'thing']), $False, "$SubTestName - tests with array ref - false");
    is(IsObjectReference({'some'=> 'thing'}), $False, "$SubTestName - tests with hash ref - false");
    is(IsObjectReference(sub{}), $False, "$SubTestName - tests with function ref - false");

    return;
}

__PACKAGE__->RunTest();
1;
