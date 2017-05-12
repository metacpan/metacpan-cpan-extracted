########################################
use strict;
use warnings;
use Readonly;
use Test::More tests => 5;
use Test::Deep;
########################################
Readonly our $pi => 3.14159;
our $class;
BEGIN {
    $class = 'Vector::Object3D::Point';
    use_ok($class);
}
########################################
{
    my %args = (x => 2, y => -1, z => 3);
    my $point = $class->new(%args);
    my $point_casted = $point->cast(type => 'parallel');
    my @xy = (2, -1);
    my $point_expected = $class->new(coord => \@xy);
    ok($point_casted == $point_expected, 'Cast point onto 2D surface area using an orthographic projection');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my $point_casted = $point->cast(type => 'parallel');
    my @xy = (-2, 2);
    my $point_expected = $class->new(coord => \@xy);
    ok($point_casted == $point_expected, 'Cast point onto 2D surface area using an orthographic projection');
}
########################################
{
    my %args = (x => -1, y => -3, z => 2);
    my $point = $class->new(%args);
    my $point_casted = $point->cast(type => 'perspective', distance => 5);
    my @xy = (-2.5, -7.5);
    my $point_expected = $class->new(coord => \@xy);
    ok($point_casted == $point_expected, 'Cast point onto 2D surface area using a perspective projection');
}
########################################
{
    my %args = (x => -3, y => 1, z => 1);
    my $point = $class->new(%args);
    my $point_casted = $point->cast(type => 'perspective', distance => 2);
    my @xy = (-6, 2);
    my $point_expected = $class->new(coord => \@xy);
    ok($point_casted == $point_expected, 'Cast point onto 2D surface area using a perspective projection');
}
########################################
