package test_MagicShow_Magician;
use strict;
use FindBin;
use lib ("$FindBin::Bin/../.."); #Path to test base
use lib ("$FindBin::Bin/../../.."); #Path to example project
use parent 'TestBase';
use Test::More;
use Test::Mockify;
use t::ExampleProject::MagicShow::Magician;
use Test::Mockify::Verify qw (WasCalled);
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_HappyPath();
    $self->test_DisasterPath();
}

#----------------------------------------------------------------------------------------
sub test_HappyPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    # It is very practical to put this mock creation into a method
    my $Mockify = Test::Mockify->new( 't::ExampleProject::MagicShow::Rabbit');
    my $RabitIsSnappy = 0;
    $Mockify->mock('isSnappyToday')->when()->thenReturn($RabitIsSnappy);
    my $Rabbit = $Mockify->getMockObject();

    my $Magician = t::ExampleProject::MagicShow::Magician->new($Rabbit);

    is($Magician->pullRabbit(), 'Tada!' ,"$SubTestName - Prove that a rabit could be pulled.");
    ok(WasCalled($Rabbit, 'isSnappyToday'),"$SubTestName - Prove that isSnappyToday was triggerd");
}
#----------------------------------------------------------------------------------------
sub test_DisasterPath {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new( 't::ExampleProject::MagicShow::Rabbit', [] );
    my $RabitIsSnappy = 1;
    $Mockify->mock('isSnappyToday')->when()->thenReturn($RabitIsSnappy);
    my $Rabbit = $Mockify->getMockObject();

    my $Magician = t::ExampleProject::MagicShow::Magician->new($Rabbit);

    is($Magician->pullRabbit(), 'Tada! ouch' ,"$SubTestName - Prove that a rabit couldn't be pulled.");
    ok(WasCalled($Rabbit, 'isSnappyToday'),"$SubTestName - Prove that isSnappyToday was triggerd");
}

__PACKAGE__->RunTest();
1;