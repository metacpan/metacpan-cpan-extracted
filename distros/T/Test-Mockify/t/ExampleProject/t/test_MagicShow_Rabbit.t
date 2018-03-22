package test_MagicShow_Rabbit;
use strict;
use FindBin;
use lib ("$FindBin::Bin/../.."); #Path to test base
use lib ("$FindBin::Bin/../../.."); #Path to example project
use parent 'TestBase';
use Test::More;
use t::ExampleProject::MagicShow::Rabbit;
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;

    my $Rabbit = t::ExampleProject::MagicShow::Rabbit->new();
    my $IsSnappy = $Rabbit->isSnappyToday();
    if($IsSnappy == 0 || $IsSnappy == 1){
        ok(1, 'Snappy returns a number between 0 and 1');
    }
    return;
}

__PACKAGE__->RunTest();
1;