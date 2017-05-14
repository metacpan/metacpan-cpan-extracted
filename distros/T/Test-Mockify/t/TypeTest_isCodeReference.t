package TypeTests_isCodeReference;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify::TypeTests qw (IsCodeReference);
use Test::More;

#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->IsCodeReference_positivPath();
    $self->IsCodeReference_negativPath();
    return;
}

#------------------------------------------------------------------------
sub IsCodeReference_positivPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok(IsCodeReference(sub{}), "$SubTestName - proves that this reconize a code reference.");

    return;
}

#------------------------------------------------------------------------
sub IsCodeReference_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $False = 0;

    is(IsCodeReference(), 0,"$SubTestName - tests empty parameter");
    is(IsCodeReference({'some' => 'thing'}), $False,"$SubTestName - tests hash pointer");
    is(IsCodeReference(['some' , 'thing']), $False,"$SubTestName - tests array pointer");
    is(IsCodeReference(bless({},'object')), $False, "$SubTestName - tests object");

    return;
}

__PACKAGE__->RunTest();
