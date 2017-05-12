package TypeTests_isHashReference;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify::TypeTests qw (IsHashReference);
use Test::More;

#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->isHashReference_positivPath();
    $self->isHashReference_negativPath();
    return;
}

#------------------------------------------------------------------------
sub isHashReference_positivPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok(IsHashReference({}),"$SubTestName - tests with empty hash ref - true");
    ok(IsHashReference({'some' => 'elments'}),"$SubTestName - tests hash ref with some elments - true");
    my %TestHash = ('key1' => 'value1', 'key2' => 'value2');
    ok(IsHashReference(\%TestHash),"$SubTestName - tests direct de-referencing of hash - true");
    return;
}

#------------------------------------------------------------------------
sub isHashReference_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;

    is(IsHashReference(), $False, "$SubTestName - tests empty parameter - false");
    is(IsHashReference(123), $False, "$SubTestName - tests with integer - false");
    is(IsHashReference(12.3), $False, "$SubTestName - tests with float - false");
    is(IsHashReference('string'), $False, "$SubTestName - tests with string - false");
    is(IsHashReference(['some', 'thing']), $False, "$SubTestName - tests with array ref - false");
    is(IsHashReference(bless({},'object')), $False, "$SubTestName - tests with object ref - false");
    is(IsHashReference(sub{}), $False, "$SubTestName - tests with function ref - false");
    my %TestHash = ('key1' => 'value1', 'key2' => 'value2');
    is(IsHashReference(%TestHash), $False, "$SubTestName - tests with direct hash - false");

    return;
}

__PACKAGE__->RunTest();
1;
