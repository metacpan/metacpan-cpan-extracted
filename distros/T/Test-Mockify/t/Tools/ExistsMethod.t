package ExistsMethod;
use strict;
## no critic (ProhibitComplexRegexes)
use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use strict;
use Test::Mockify::Tools qw (ExistsMethod);
use Test::More;
use Test::Exception;
use TestDummies::FakeModuleForMockifyTest;

#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->ExistsMethod_WithObject_positiv();
    $self->ExistsMethod_WithPath_positiv();
    $self->ExistsMethod_negativ();
    return;
}
#------------------------------------------------------------------------
sub ExistsMethod_WithObject_positiv {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $FakeModuleForMockifyTest = TestDummies::FakeModuleForMockifyTest->new();
    ok( ExistsMethod($FakeModuleForMockifyTest, 'DummyMethodForTestOverriding'),
        "$SubTestName - tests if ExistsMethod works with an object"
    );
    throws_ok( sub{ExistsMethod($FakeModuleForMockifyTest,'NotExistingMethod')},
        qr/FakeModuleForMockifyTest doesn't have a method like: NotExistingMethod/sm,
        "$SubTestName - tests if ExistsMethod throws error if method not exists with an object"
    );

    return;
}
#------------------------------------------------------------------------
sub ExistsMethod_WithPath_positiv {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok( ExistsMethod('TestDummies::FakeModuleForMockifyTest', 'DummyMethodForTestOverriding'),
        "$SubTestName - tests if ExistsMethod works with the object path"
    );
    throws_ok( sub{ExistsMethod('TestDummies::FakeModuleForMockifyTest','NotExistingMethod')},
        qr/FakeModuleForMockifyTest doesn't have a method like: NotExistingMethod/sm,
        "$SubTestName - tests if ExistsMethod throws error if method not exists with the object path"
    );

    return;
}

#------------------------------------------------------------------------
sub ExistsMethod_negativ {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    throws_ok( sub{ExistsMethod()},
        qr/Path or Object is needed/sm,
        "$SubTestName - tests if ExistsMethod throws error if there no parameters"
    );
    throws_ok( sub{ExistsMethod('TestDummies::FakeModuleForMockifyTest')},
        qr/Method name is needed/sm,
        "$SubTestName - tests if ExistsMethod throws error if there is only a path"
    );

    return;
}

__PACKAGE__->RunTest();

1;