use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

my $tz;

subtest "date is alive" => sub {
    my $date = MyTest::Cookbook::DateRecipe11->new('Europe/Minsk');
    $tz = $date->get_timezone;
    is $tz->get_name, 'Europe/Minsk';
};

is $tz->get_name, 'Europe/Minsk';

done_testing;
