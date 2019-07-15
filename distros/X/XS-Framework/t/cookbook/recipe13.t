use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

package MyTest::Cookbook::CustomPointRecipe13 {
use base qw/MyTest::Cookbook::PointRecipe13/;

sub new {
    my ($class, $x, $y, $meta) = @_;
    my $obj = $class->SUPER::new($x, $y);
    XS::Framework::obj2hv($obj);
    $obj->{meta} = $meta;
    return $obj;
}

sub meta { return shift->{meta}; }

}

my $shape = MyTest::Cookbook::Shape13->new;
my $pt1 = MyTest::Cookbook::PointRecipe13->new(5, 10);
$shape->add_point($pt1);
my $pt1_back = $shape->get_point(0);
is $pt1_back->x, $pt1->x;
is $pt1_back->y, $pt1->y;
is $pt1, $pt1_back;

my $pt2 = MyTest::Cookbook::CustomPointRecipe13->new(6, 11, { direction => 'north'});
$shape->add_point($pt2);
my $pt2_back = $shape->get_point(1);
is $pt2_back->x, $pt2->x;
is $pt2_back->y, $pt2->y;
isa_ok($pt2_back, 'MyTest::Cookbook::CustomPointRecipe13');
is $pt2, $shape->get_point(1);

done_testing;
