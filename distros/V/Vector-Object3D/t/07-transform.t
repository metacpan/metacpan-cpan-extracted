########################################
use strict;
use warnings;
use Readonly;
use Test::More tests => 10;
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
    my %args = (x => 3, y => -2);
    my $point = $class->new(%args);
    my $point_transformed = $point->translate(shift_x => -1, shift_y => -2);
    my @xy = (2, -4);
    cmp_deeply([ $point_transformed->get_xy ], \@xy, 'Translate point object on a 2D plane');
}
########################################
{
    my %args = (x => 3, y => -2, z => 1);
    my $point = $class->new(%args);
    my $point_transformed = $point->translate(shift_x => -1, shift_y => -2, shift_z => 1);
    my @xyz = (2, -4, 2);
    cmp_deeply([ $point_transformed->get_xyz ], \@xyz, 'Translate point object in a 3D space');
}
########################################
{
    my %args = (x => 3, y => -2, z => 1);
    my $point = $class->new(%args);
    my $point_transformed = $point->translate(shift_x => 1, shift_y => 2, shift_z => -1);
    my @xyz = (4, 0, 0);
    cmp_deeply([ $point_transformed->get_xyz ], \@xyz, 'Translate point object in a 3D space');
}
########################################
{
    my %args = (x => 1, y => -2);
    my $point = $class->new(%args);
    my $point_transformed = $point->scale(scale_x => 2, scale_y => 0.5);
    my @xy = (2, -1);
    cmp_deeply([ $point_transformed->get_xy ], \@xy, 'Scale point object on a 2D plane');
}
########################################
{
    my %args = (x => 1, y => -2, z => -1);
    my $point = $class->new(%args);
    my $point_transformed = $point->scale(scale_x => 2, scale_y => 0.5, scale_z => 1);
    my @xyz = (2, -1, -1);
    cmp_deeply([ $point_transformed->get_xyz ], \@xyz, 'Scale point object in a 3D space');
}
########################################
{
    my %args = (x => 1, y => -2, z => -1);
    my $point = $class->new(%args);
    my $point_transformed = $point->scale(scale_x => 1, scale_y => 2, scale_z => 3);
    my @xyz = (1, -4, -3);
    cmp_deeply([ $point_transformed->get_xyz ], \@xyz, 'Scale point object in a 3D space');
}
########################################
{
    my %args = (x => 2, y => -3);
    my $point = $class->new(%args);
    my $point_transformed = $point->rotate(rotate_xy => (45 * $pi / 180));
    $point_transformed->set(parameter => 'precision', value => 3);
    my @xy = (-0.707, -3.536);
    my $point_expected = $class->new(coord => \@xy);
    ok($point_transformed == $point_expected, 'Rotate point object on a 2D plane');
}
########################################
{
    my %args = (x => 2, y => -3, z => 1);
    my $point = $class->new(%args);
    my $point_transformed = $point->rotate(rotate_xy => (30 * $pi / 180), rotate_yz => -30 * ($pi / 180), rotate_xz => 15 * ($pi / 180));
    $point_transformed->set(parameter => 'precision', value => 3);
    my @xyz = (0.432, -2.750, 1.819);
    my $point_expected = $class->new(coord => \@xyz);
    ok($point_transformed == $point_expected, 'Rotate point object in a 3D space');
}
########################################
{
    my %args = (x => 2, y => -3, z => 1);
    my $point = $class->new(%args);
    my $point_transformed = $point->rotate(rotate_xy => (-15 * $pi / 180), rotate_yz => 15 * ($pi / 180), rotate_xz => 30 * ($pi / 180));
    $point_transformed->set(parameter => 'precision', value => 3);
    my @xyz = (2.949, -2.540, -0.940);
    my $point_expected = $class->new(coord => \@xyz);
    ok($point_transformed == $point_expected, 'Rotate point object in a 3D space');
}
########################################
