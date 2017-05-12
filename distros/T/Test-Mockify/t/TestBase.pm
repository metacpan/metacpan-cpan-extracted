# Copy&Paste template for yourTest.t
=head1
package yourTest;
use base TestBase;
use strict;
use TypeTests;
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

    ok(1,"$SubTestName - tests if ...");

    return;
}

#------------------------------------------------------------------------
sub isObjectReference_negativPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    ok(1,"$SubTestName - tests if ...");

    return;
}

__PACKAGE__->RunTest();
1;
=cut
package TestBase;
use strict;
use Test::More;

#------------------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = bless({},$class);
    return $self;
}

#------------------------------------------------------------------------
sub RunTest {
    my $Package = shift;
    note("Unit test for: $Package ######");
    my $UnitTest = $Package->new();
    
    $UnitTest->testPlan();
    done_testing();
}

1;
