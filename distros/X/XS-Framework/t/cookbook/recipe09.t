use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

subtest "shapeA" => sub {
    my $shape = MyTest::Cookbook::ShapeA->new;
    $shape->add_point(MyTest::Cookbook::Point->new(10, 5), { direction => 'NORTH', power => 5 });
    $shape->add_point(MyTest::Cookbook::Point->new(-10, 7), 'hello');
    $shape->add_point(MyTest::Cookbook::Point->new(100, 1));

    my $pt1 = $shape->get_point(0);
    is $pt1->x, 10;
    is $pt1->y, 5;

    my ($pt11, $label1) = $shape->get_point(0);
    is $pt11->x, 10;
    is $pt11->y, 5;
    is_deeply $label1, { direction => 'NORTH', power => 5 };


    my ($pt2, $label2) = $shape->get_point(1);
    is $pt2->x, -10;
    is $pt2->y, 7;
    is $label2, 'hello';

    my $pt3 = $shape->get_point(2);
    is $pt3->x, 100;
    is $pt3->y, 1;
};

subtest "shapeA" => sub {
    my $shape = MyTest::Cookbook::ShapeB->new;
    $shape->add_point(MyTest::Cookbook::Point->new(10, 5), { direction => 'NORTH', power => 5 });
    $shape->add_point(MyTest::Cookbook::Point->new(-10, 7), 'hello');
    $shape->add_point(MyTest::Cookbook::Point->new(100, 1));

    my $pt1 = $shape->get_point(0);
    is $pt1->x, 10;
    is $pt1->y, 5;

    my ($pt11, $label1) = $shape->get_point(0);
    is $pt11->x, 10;
    is $pt11->y, 5;
    is_deeply $label1, { direction => 'NORTH', power => 5 };

    my ($pt2, $label2) = $shape->get_point(1);
    is $pt2->x, -10;
    is $pt2->y, 7;
    is $label2, 'hello';

    my $pt3 = $shape->get_point(2);
    is $pt3->x, 100;
    is $pt3->y, 1;
};

done_testing;
