package IsArrayReference;
## no critic (ProhibitMagicNumbers)
use strict;

use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use Test::Mockify::TypeTests qw ( IsArrayReference );
use Test::More;
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->isArrayReference_positivPath();
    $self->isArrayReference_negativPath();
    return;
}
#------------------------------------------------------------------------
sub isArrayReference_positivPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok(IsArrayReference([]),"$SubTestName - tests with empty array ref - true");
    ok(IsArrayReference(['some', 'elments']),"$SubTestName - tests array ref with some elments - true");
    my @TestArray = qw (one two);
    ok(IsArrayReference(\@TestArray),"$SubTestName - tests direct de-referencing of array - true");
    return;
}
#------------------------------------------------------------------------
sub isArrayReference_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;

    is(IsArrayReference(), $False, "$SubTestName - tests empty parameter - false");
    is(IsArrayReference(123), $False, "$SubTestName - tests with integer - false");
    is(IsArrayReference(12.3), $False, "$SubTestName - tests with float - false");
    is(IsArrayReference('string'), $False, "$SubTestName - tests with string - false");
    is(IsArrayReference({'some' => 'thing'}), $False, "$SubTestName - tests with hash ref - false");
    is(IsArrayReference(bless({},'object')), $False, "$SubTestName - tests with object ref - false");
    is(IsArrayReference(sub{}), $False, "$SubTestName - tests with function ref - false");
    my @TestArray = qw (one two);
    is(IsArrayReference(@TestArray), $False, "$SubTestName - tests with direct array - false");

    return;
}

__PACKAGE__->RunTest();
1;
