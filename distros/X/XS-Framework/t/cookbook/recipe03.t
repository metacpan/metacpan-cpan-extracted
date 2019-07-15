use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

my $tz = MyTest::Cookbook::TimezoneRecipe03::get_instance();
ok $tz;
isa_ok($tz, 'MyTest::Cookbook::TimezoneRecipe03');
is $tz->get_name, 'Europe/Minsk';

done_testing;
