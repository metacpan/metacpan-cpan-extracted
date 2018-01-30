package Mockify_OptionalNew;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify;
use Test::More;
use warnings;
no warnings 'deprecated';
sub testPlan {
    my $self = shift;
    $self->test_MockModule();
}
#----------------------------------------------------------------------------------------
sub test_MockModule {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $MockObject = Test::Mockify->new('FakeModuleWithoutNew');
    my $MockedFakeModule = $MockObject->getMockObject();
    is($MockedFakeModule->secondDummyMethodForTestOverriding(),'A second dummy method',"$SubTestName - test if the loaded module still have the unmocked methods");

    return;
}

__PACKAGE__->RunTest();