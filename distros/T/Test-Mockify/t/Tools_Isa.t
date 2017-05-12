package Tools_Isa;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify::Tools qw ( Isa );
use Test::More;
use FakeModuleForMockifyTest;
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_Isa_positiv();
    $self->test_Isa_negativ();
    return;
}
#------------------------------------------------------------------------
sub test_Isa_positiv {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $FakeModuleForMockifyTest = FakeModuleForMockifyTest->new();
    is(Isa($FakeModuleForMockifyTest, 'FakeModuleForMockifyTest'),
        1,
        "$SubTestName - tests if the Isa works fine with existing name"
    );
    is(Isa($FakeModuleForMockifyTest, 'Wrong::Path'),
        0,
        "$SubTestName - tests if the Isa works fine with not existing name"
    );

    return;
}
#------------------------------------------------------------------------
sub test_Isa_negativ {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(Isa(),
        0,
        "$SubTestName - tests if the Isa returns 0 if there no parameters"
    );
    is(Isa('NotAnBlessedObject'),
        0,
        "$SubTestName - tests if the Isa returns 0 if object is not blessed"
    );
    my $FakeModuleForMockifyTest = FakeModuleForMockifyTest->new();
    is(Isa($FakeModuleForMockifyTest),
        0,
        "$SubTestName - tests if the Isa returns 0 if object is blessed but the method name is not defind"
    );

    return;
}

__PACKAGE__->RunTest();
1;