use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

my $tz = MyTest::Cookbook::TimezoneRecipe05::create('Europe/Minsk');
ok $tz;
is $tz->get_name, 'Europe/Minsk';

my $date = MyTest::Cookbook::DateRecipe05->new;
is $date->get_timezone, undef;
$date->set_timezone($tz);
is $date->get_timezone->get_name, 'Europe/Minsk';

done_testing;
