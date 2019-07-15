use 5.012;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

my $date_a = MyTest::Cookbook::DateRecipe01a->new();
say "date = ", $date_a, ", epoch = ", $date_a->get_epoch();
$date_a->update;
say "date = ", $date_a, ", epoch = ", $date_a->get_epoch();

my $date_b = MyTest::Cookbook::DateRecipe01b->new();
say "date = ", $date_b, ", epoch = ", $date_b->get_epoch();
$date_b->update;
say "date = ", $date_b, ", epoch = ", $date_b->get_epoch();

pass();
done_testing;
