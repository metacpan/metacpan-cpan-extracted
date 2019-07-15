use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

my $stats;

{
    $stats = MyTest::Cookbook::StatisticsRecipe12->new(
        MyTest::Cookbook::PointRecipe12->new(0.5, 0.5),
        [
            MyTest::Cookbook::PointRecipe12->new(1, 1),
            MyTest::Cookbook::PointRecipe12->new(2, 1),
            MyTest::Cookbook::PointRecipe12->new(5, 3),
        ],
    );
};

subtest 'nearest point' => sub {
    my $p = $stats->nearest;
    is $p->x, 1;
    is $p->y, 1;
};

subtest 'farest point' => sub {
    my $p = $stats->farest;
    is $p->x, 5;
    is $p->y, 3;
};

done_testing;
