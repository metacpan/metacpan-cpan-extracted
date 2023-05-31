use Test::More tests => 7;

use strict;
use warnings;
use VisualCrossing::API;
use Test::Exception;
use Test::More;
use Test::MockModule;

my $key = "K1234";
my $location = "L1234";
my $date = "";

{
    dies_ok {
        VisualCrossing::API->new(
            location => $location,
            date     => $date
        );
    } "dies: Invalid key required";
}

{
    dies_ok {
        VisualCrossing::API->new(
            key      => $key,
            latitude => $location,
            date     => $date
        );
    } "dies: Invalid latitude only";
}

{
    dies_ok {
        VisualCrossing::API->new(
            key      => $key,
            longitude => $location,
            date     => $date
        );
    } "dies: Invalid longitude only";
}

{
    dies_ok {
        VisualCrossing::API->new(
            key      => $key,
            date     => $date
        );
    } "dies: Invalid location required";
}

{
    dies_ok {
        VisualCrossing::API->new(
            key      => $key,
            location => $location,
            include     => "blah"
        );
    } "dies: Invalid include specified";
}

{
    dies_ok {
        VisualCrossing::API->new(
            key      => $key,
            location => $location,
            unitGroup     => "blah"
        );
    } "dies: Invalid unitGroup specified";
}

{
    dies_ok {
        VisualCrossing::API->new(
            key      => $key,
            location => $location,
            date2     => "blah"
        );
    } "dies: Invalid date2 only";
}