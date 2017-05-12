########################################
use strict;
use warnings;
use Readonly;
use Test::More tests => 32;
use Test::Deep;
use Test::Moose;
use Test::Exception;
use Vector::Object3D::Point;
use Vector::Object3D::Polygon;
########################################
Readonly our $pi => 3.14159;
our $class;
BEGIN {
    $class = 'Vector::Object3D';
    use_ok($class);
}
########################################
{
    can_ok($class, qw(copy num_faces last_face_index get_polygon get_polygons print rotate scale translate cast _comparison _negative_comparison));
}
########################################
{
    has_attribute_ok($class, 'polygons');
}
########################################
sub get_polygons {
    my $vertexA1 = Vector::Object3D::Point->new(x => -1, y => 0, z => 0);
    my $vertexA2 = Vector::Object3D::Point->new(x => 0, y => -1, z => 0);
    my $vertexA3 = Vector::Object3D::Point->new(x => 1, y => 0, z => 0);
    my $vertexA4 = Vector::Object3D::Point->new(x => 0, y => 1, z => 0);
    my $polygonA = Vector::Object3D::Polygon->new(vertices => [$vertexA1, $vertexA2, $vertexA3, $vertexA4]);
    my $vertexB1 = Vector::Object3D::Point->new(x => -1, y => 0, z => 0);
    my $vertexB2 = Vector::Object3D::Point->new(x => 0, y => 1, z => 0);
    my $vertexB3 = Vector::Object3D::Point->new(x => 0, y => 0, z => 2);
    my $polygonB = Vector::Object3D::Polygon->new(vertices => [$vertexB1, $vertexB2, $vertexB3]);
    my $vertexC1 = Vector::Object3D::Point->new(x => 0, y => 1, z => 0);
    my $vertexC2 = Vector::Object3D::Point->new(x => 1, y => 0, z => 0);
    my $vertexC3 = Vector::Object3D::Point->new(x => 0, y => 0, z => 2);
    my $polygonC = Vector::Object3D::Polygon->new(vertices => [$vertexC1, $vertexC2, $vertexC3]);
    my $vertexD1 = Vector::Object3D::Point->new(x => 1, y => 0, z => 0);
    my $vertexD2 = Vector::Object3D::Point->new(x => 0, y => -1, z => 0);
    my $vertexD3 = Vector::Object3D::Point->new(x => 0, y => 0, z => 2);
    my $polygonD = Vector::Object3D::Polygon->new(vertices => [$vertexD1, $vertexD2, $vertexD3]);
    my $vertexE1 = Vector::Object3D::Point->new(x => 0, y => -1, z => 0);
    my $vertexE2 = Vector::Object3D::Point->new(x => -1, y => 0, z => 0);
    my $vertexE3 = Vector::Object3D::Point->new(x => 0, y => 0, z => 2);
    my $polygonE = Vector::Object3D::Polygon->new(vertices => [$vertexE1, $vertexE2, $vertexE3]);
    return [ $polygonA, $polygonB, $polygonC, $polygonD, $polygonE ];
}
########################################
sub get_object {
    return $class->new(polygons => get_polygons());
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my $vertex2 = Vector::Object3D::Point->new(x => 3, y => -1, z => -2);
    my $vertex3 = Vector::Object3D::Point->new(x => 2, y => 1, z => 1);
    my %args = (vertices => [$vertex1, $vertex2, $vertex3]);
    my $polygon = Vector::Object3D::Polygon->new(%args);
    my $object = new_ok($class => [polygons => [$polygon]]);
}
########################################
{
    my %args = (polygons => []);
    dies_ok { my $polygon = $class->new(%args); } 'Initialize object with insufficient number of polygons';
}
########################################
{
    my $polygon1 = { x => -1, y => 2, z => 3 };
    my $polygon2 = [ 3, -1, -2 ];
    my %args = (polygons => [$polygon1, $polygon2]);
    dies_ok { my $polygon = $class->new(%args); } 'Initialize object with invalid polygon object types';
}
########################################
{
    my $object = get_object();
    my $copy = $object->copy;
    my $polygons = get_polygons();
    cmp_deeply([ $copy->get_polygons ], $polygons, 'Create a new object as a copy of an existing object');
}
########################################
{
    my $object = get_object();
    my $num_faces = $object->num_faces;
    is($num_faces, 5, 'Get number of polygons that make up an object');
}
########################################
{
    my $object = get_object();
    my $last_face_index = $object->last_face_index;
    is($last_face_index, 4, 'Get index of last polygon');
}
########################################
{
    my $object = get_object();
    dies_ok { $object->get_polygon(index => 'zero') } 'Get polygon with a non-numeric index value';
}
########################################
{
    my $object = get_object();
    dies_ok { $object->get_polygon(index => -1) } 'Get polygon below acceptable index range';
}
########################################
{
    my $object = get_object();
    my $last_face_index = $object->last_face_index;
    dies_ok { $object->get_polygon(index => $last_face_index + 1) } 'Get polygon beyond acceptable index range';
}
########################################
{
    my $object = get_object();
    my $polygon1 = $object->get_polygon(index => 0);
    my $polygon = get_polygons()->[0];
    ok($polygon == $polygon1, 'Get first polygon');
}
########################################
{
    my $object = get_object();
    my $polygon1 = $object->get_polygon(index => 1);
    my $polygon = get_polygons()->[1];
    ok($polygon == $polygon1, 'Get second polygon');
}
########################################
{
    my $object = get_object();
    my $polygon1 = $object->get_polygon(index => 2);
    my $polygon = get_polygons()->[2];
    ok($polygon == $polygon1, 'Get third polygon');
}
########################################
{
    my $object = get_object();
    my $last_face_index = $object->last_face_index;
    my $polygon1 = $object->get_polygon(index => $last_face_index);
    my $polygon = get_polygons()->[$last_face_index];
    ok($polygon == $polygon1, 'Get last polygon');
}
########################################
{
    my $object = get_object();
    my $polygons = get_polygons();
    cmp_deeply([ $object->get_polygons ], $polygons, 'Get all polygons');
}
########################################
{
    my $object = get_object();
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $object->print(fh => $fh);
    close $fh;
    select $old_fh;
    my $content_expected = <<OBJECT;

Polygon 1/5:
[ -1.00  0.00  0.00 ]
[  0.00 -1.00  0.00 ]
[ 1.00 0.00 0.00 ]
[ 0.00 1.00 0.00 ]
Polygon 2/5:
[ -1.00  0.00  0.00 ]
[ 0.00 1.00 0.00 ]
[ 0.00 0.00 2.00 ]
Polygon 3/5:
[ 0.00 1.00 0.00 ]
[ 1.00 0.00 0.00 ]
[ 0.00 0.00 2.00 ]
Polygon 4/5:
[ 1.00 0.00 0.00 ]
[  0.00 -1.00  0.00 ]
[ 0.00 0.00 2.00 ]
Polygon 5/5:
[  0.00 -1.00  0.00 ]
[ -1.00  0.00  0.00 ]
[ 0.00 0.00 2.00 ]
OBJECT
    chomp $content_expected;
    is($content_got, $content_expected, 'Print out the contents of an object (default number of digits after floating point)');
}
########################################
{
    my $polygons = get_polygons();
    my @polygons1 = @{$polygons}[0..4];
    my $object1 = $class->new(polygons => \@polygons1);
    my @polygons2 = @{$polygons}[0..4];
    my $object2 = $class->new(polygons => \@polygons2);
    my $result = $object1 == $object2;
    ok($result, 'Overload comparison operator (comparing two identical objects yields true)');
}
########################################
{
    my $polygons = get_polygons();
    my @polygons1 = @{$polygons}[0..4];
    my $object1 = $class->new(polygons => \@polygons1);
    my @polygons2 = @{$polygons}[0..3];
    my $object2 = $class->new(polygons => \@polygons2);
    my $result = $object1 == $object2;
    ok(!$result, 'Overload comparison operator (comparing two different objects yields false)');
}
########################################
{
    my $polygons = get_polygons();
    my @polygons1 = @{$polygons}[0..4];
    my $object1 = $class->new(polygons => \@polygons1);
    my @polygons2 = @{$polygons}[0..3];
    my $object2 = $class->new(polygons => \@polygons2);
    my $result = $object1 != $object2;
    ok($result, 'Overload negative comparison operator (comparing two different objects yields true)');
}
########################################
{
    my $polygons = get_polygons();
    my @polygons1 = @{$polygons}[0..4];
    my $object1 = $class->new(polygons => \@polygons1);
    my @polygons2 = @{$polygons}[0..4];
    my $object2 = $class->new(polygons => \@polygons2);
    my $result = $object1 != $object2;
    ok(!$result, 'Overload negative comparison operator (comparing two identical objects yields false)');
}
########################################
{
    my $polygons = get_polygons();
    my $object = $class->new(polygons => $polygons);
    my %translate_params = (
        shift_x => -2,
        shift_y => 1,
        shift_z => 3,
    );
    my %translated_args = (polygons => [
        map { $_->translate(%translate_params) } @{$polygons}
    ]);
    my $expected_object = $class->new(%translated_args);
    ok($object->translate(%translate_params) == $expected_object, "Move object a constant distance in a specified direction");
}
########################################
{
    my $polygons = get_polygons();
    my $object = $class->new(polygons => $polygons);
    my %scale_params = (
        scale_x => 2,
        scale_y => 2,
        scale_z => 3,
    );
    my %scaled_args = (polygons => [
        map { $_->scale(%scale_params) } @{$polygons}
    ]);
    my $expected_object = $class->new(%scaled_args);
    ok($object->scale(%scale_params) == $expected_object, "Enlarge, shrink or stretch object by a scale factor");
}
########################################
{
    my $polygons = get_polygons();
    my $object = $class->new(polygons => $polygons);
    my %rotate_params = (
        rotate_xy => 30 * ($pi / 180),
        rotate_yz => -30 * ($pi / 180),
        rotate_xz => 45 * ($pi / 180),
    );
    my %rotated_args = (polygons => [
        map { $_->rotate(%rotate_params) } @{$polygons}
    ]);
    my $expected_object = $class->new(%rotated_args);
    ok($object->rotate(%rotate_params) == $expected_object, "Rotate object by a given angle around three rotation axis");
}
########################################
{
    my $polygons = get_polygons();
    my $object = $class->new(polygons => $polygons);
    my %cast_params = (
        type => 'parallel',
    );
    my %casted_args = (polygons => [
        map { $_->cast(%cast_params) } @{$polygons}
    ]);
    my $expected_object = $class->new(%casted_args);
    ok($object->cast(%cast_params) == $expected_object, "Project object onto a two-dimensional plane using an orthographic projection");
}
########################################
{
    my $polygons = get_polygons();
    my $object = $class->new(polygons => $polygons);
    my %cast_params = (
        type     => 'perspective',
        distance => 5,
    );
    my %casted_args = (polygons => [
        map { $_->cast(%cast_params) } @{$polygons}
    ]);
    my $expected_object = $class->new(%casted_args);
    ok($object->cast(%cast_params) == $expected_object, "Project object onto a two-dimensional plane using a perspective projection");
}
########################################
{
    my $object = get_object();
    dies_ok { $object->get_polygons(mode => 'invalid'); } 'Invalid mode used to get polygons';
}
########################################
{
    my $object = get_object();
    my $polygons = get_polygons();
    cmp_deeply([ $object->get_polygons(mode => 'all') ], $polygons, 'Get all polygons explicitly');
}
########################################
{
    my $object = get_object();
    my $polygons = get_polygons();
    my @visible_polygons = @{$polygons}[1,2,3,4];
    cmp_deeply([ $object->get_polygons(mode => 'visible') ], \@visible_polygons, 'Get visible polygons only without defining the observer');
}
########################################
{
    my $object = get_object();
    my $polygons = get_polygons();
    my @visible_polygons = @{$polygons}[1,2,3,4];
    my $observer = Vector::Object3D::Point->new(x => 0, y => 0, z => 5);
    cmp_deeply([ $object->get_polygons(mode => 'visible', observer => $observer) ], \@visible_polygons, 'Get visible polygons only with explicitly defined observer');
}
########################################
{
    my $object = get_object();
    my $polygons = get_polygons();
    my @visible_polygons = @{$polygons}[0,1,4];
    my $observer = Vector::Object3D::Point->new(x => -5, y => 1, z => -1);
    cmp_deeply([ $object->get_polygons(mode => 'visible', observer => $observer) ], \@visible_polygons, 'Get visible polygons only with the observer defined');
}
########################################
