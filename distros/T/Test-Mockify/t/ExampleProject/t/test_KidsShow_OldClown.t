package test_KidsShow_OldClown;
## no critic (ProhibitMagicNumbers)
use strict;
use FindBin;
use lib ("$FindBin::Bin/../.."); #Path to test base
use lib ("$FindBin::Bin/../../.."); #Path to example project
use parent 'TestBase';
use Test::More;
use t::ExampleProject::MagicShow::Rabbit;
use t::ExampleProject::KidsShow::OldClown;
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;

    my $KilocaloriesForBreakfast = 30_000;
    is(t::ExampleProject::KidsShow::OldClown::BeHeavy($KilocaloriesForBreakfast), 30, 'Prove old clown weight calculation');
}

__PACKAGE__->RunTest();
1;