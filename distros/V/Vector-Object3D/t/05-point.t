########################################
use strict;
use warnings;
use Test::More tests => 45;
use Test::Deep;
use Test::Exception;
use Test::Moose;
########################################
our $class;
BEGIN {
    $class = 'Vector::Object3D::Point';
    use_ok($class);
}
########################################
{
    can_ok($class, qw(get_x get_y get_z get_xy get_xyz get_matrix cast print rotate scale translate _comparison _negative_comparison));
}
########################################
{
    does_ok($class, 'Vector::Object3D::Parameters');
    does_ok($class, 'Vector::Object3D::Point::Cast');
    does_ok($class, 'Vector::Object3D::Point::Transform');
}
########################################
{
    has_attribute_ok($class, 'x');
    has_attribute_ok($class, 'y');
    has_attribute_ok($class, 'z');
}
########################################
{
    my @args = (x => -2);
    my $point = new_ok($class => \@args);
}
########################################
{
    my @args = (y => 2);
    dies_ok { my $point = $class->new(@args); } 'Initialize point object with insufficient coordinates (only Y)';
}
########################################
{
    my @args = (z => 1);
    dies_ok { my $point = $class->new(@args); } 'Initialize point object with insufficient coordinates (only Z)';
}
########################################
{
    my @args = (x => 'two', y => 'one');
    dies_ok { my $point = $class->new(@args); } 'Initialize point object with non-numeric coordinate values';
}
########################################
{
    my @args = (x => -2, y => 2);
    my $point = new_ok($class => \@args);
}
########################################
{
    my @args = (x => -2, y => 2, z => 1);
    my $point = new_ok($class => \@args);
}
########################################
{
    my @args = (x => -2, y => 2);
    my $point = $class->new(@args);
    my $z = $point->get_z;
    is($z, undef, 'Initialize point object with a default Z value');
}
########################################
{
    my @args = (coord => []);
    dies_ok { my $point = $class->new(@args); } 'Initialize point object with insufficient number of "coord" parameters';
}
########################################
{
    my @args = (coord => ['two', 'one']);
    dies_ok { my $point = $class->new(@args); } 'Initialize point object with non-numeric values of "coord" parameters';
}
########################################
{
    my @args = (coord => [-2, 2]);
    my $point = new_ok($class => \@args);
}
########################################
{
    my @args = (coord => [-2, 2, 1]);
    my $point = new_ok($class => \@args);
}
########################################
{
    my @args = (coord => [-2, 2, 1, -1]);
    my $point = new_ok($class => \@args);
}
########################################
{
    my @args = (x => -2, y => 2, z => 1);
    my $point = $class->new(@args);
    my $copy = $point->copy;
    my @xyz = @args[1, 3, 5];
    cmp_deeply([ $copy->get_xyz ], \@xyz, 'Create a new object as a copy of an existing object');
}
########################################
{
    my @args = (x => -2, y => 2, z => 1);
    my $point = $class->new(@args);
    my $copy = $point->copy;
    $point->set_x(3);
    my @xyz = @args[1, 3, 5];
    cmp_deeply([ $copy->get_xyz ], \@xyz, 'Copied object remains unchanged when the original one gets modified');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my $x = $point->get_x;
    is($x, $args{x}, 'Get current X coordinate value');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my $y = $point->get_y;
    is($y, $args{y}, 'Get current Y coordinate value');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my $z = $point->get_z;
    is($z, $args{z}, 'Get current Z coordinate value');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my @xy = @args{qw(x y)};
    cmp_deeply([ $point->get_xy ], \@xy, 'Get current coordinate values on two-dimensional plane');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my @xyz = @args{qw(x y z)};
    cmp_deeply([ $point->get_xyz ], \@xyz, 'Get current coordinate values in three-dimensional space');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my $new_value = 3;
    my $x = $point->set_x($new_value);
    my @xyz = @args{qw(x y z)};
    $xyz[0] = $new_value;
    cmp_deeply([ $point->get_xyz ], \@xyz, 'Set new X coordinate value');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my $new_value = -4;
    my $y = $point->set_y($new_value);
    my @xyz = @args{qw(x y z)};
    $xyz[1] = $new_value;
    cmp_deeply([ $point->get_xyz ], \@xyz, 'Set new Y coordinate value');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    my $new_value = 5;
    my $z = $point->set_z($new_value);
    my @xyz = @args{qw(x y z)};
    $xyz[2] = $new_value;
    cmp_deeply([ $point->get_xyz ], \@xyz, 'Set new Z coordinate value');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    dies_ok { $point->set(parameter => 'xxx', value => 1) } 'Cannot set unrecognized parameter value for a point object';
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    dies_ok { $point->set(parameter => 'precision', value => 'yyy') } 'Cannot set non-numeric parameter value for a point object';
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point = $class->new(%args);
    $point->set(parameter => 'precision', value => 3);
    my $precision = $point->get(parameter => 'precision');
    is($precision, 3, 'Set a new value of "precision" parameter for a point object')
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point1 = $class->new(%args);
    my $point2 = $class->new(%args);
    my $result = $point1 == $point2;
    ok($result, 'Overload comparison operator (verify that object constructed from a hash of individual components is okay)');
}
########################################
{
    my %args = (coord => [-2, 2, 1]);
    my $point1 = $class->new(%args);
    my $point2 = $class->new(%args);
    my $result = $point1 == $point2;
    ok($result, 'Overload comparison operator (verify that object constructed from a list of coordinates is okay)');
}
########################################
{
    my %args1 = (x => -2, y => 2, z => 1);
    my $point1 = $class->new(%args1);
    my %args2 = (x => -2, y => 2, z => -1);
    my $point2 = $class->new(%args2);
    my $result = $point1 == $point2;
    ok(!$result, 'Overload comparison operator (comparing two different objects yields false)');
}
########################################
{
    my %args1 = (x => -2, y => 2, z => 1);
    my $point1 = $class->new(%args1);
    my %args2 = (x => -2, y => 2, z => -1);
    my $point2 = $class->new(%args2);
    my $result = $point1 != $point2;
    ok($result, 'Overload negative comparison operator (verify that two different objects are not equal)');
}
########################################
{
    my %args = (x => -2, y => 2, z => 1);
    my $point1 = $class->new(%args);
    my $point2 = $class->new(%args);
    my $result = $point1 != $point2;
    ok(!$result, 'Overload negative comparison operator (comparing two identical objects yields false)');
}
########################################
{
    my %args1 = (x => -2, y => 2.018, z => 1);
    my $point1 = $class->new(%args1);
    $point1->set(parameter => 'precision', value => 2);
    my %args2 = (x => -2, y => 2.021, z => 1);
    my $point2 = $class->new(%args2);
    $point2->set(parameter => 'precision', value => 3);
    my $result = $point1 != $point2;
    ok($result, 'Compare two almost identical point objects with too high precision yields false');
}
########################################
{
    my %args1 = (x => -2, y => 2.018, z => 1);
    my $point1 = $class->new(%args1);
    $point1->set(parameter => 'precision', value => 2);
    my %args2 = (x => -2, y => 2.021, z => 1);
    my $point2 = $class->new(%args2);
    $point2->set(parameter => 'precision', value => 2);
    my $result = $point1 == $point2;
    ok($result, 'Compare two almost identical point objects with accurate precision yields true');
}
########################################
{
    my %args1 = (x => -2, y => 2.018, z => 1);
    my $point1 = $class->new(%args1);
    $point1->set(parameter => 'precision', value => 2);
    my %args2 = (x => -2, y => 2.020, z => 1);
    my $point2 = $class->new(%args2);
    $point2->set(parameter => 'precision', value => 3);
    my $result = $point1 == $point2;
    ok($result, 'Compare two almost identical point objects with too high precision but still matching values yields true');
}
########################################
{
    my %args = (x => 3, y => -2, z => 1);
    my $point = $class->new(%args);
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $point->print(fh => $fh, precision => 2);
    close $fh;
    select $old_fh;
    my $content_expected = <<POINT;

[  3.00 -2.00  1.00 ]
POINT
    chomp $content_expected;
    is($content_got, $content_expected, "Print out the contents of a point object (2 digits after floating point)");
}
########################################
{
    my %args = (x => 3, y => -2, z => 1.33333);
    my $point = $class->new(%args);
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $point->print(fh => $fh, precision => 3);
    close $fh;
    select $old_fh;
    my $content_expected = <<POINT;

[  3.000 -2.000  1.333 ]
POINT
    chomp $content_expected;
    is($content_got, $content_expected, "Print out the contents of a point object (3 digits after floating point)");
}
########################################
{
    my %args = (x => 3, y => -2, z => 1.33333);
    my $point = $class->new(%args);
    my $pointMatrix = $point->get_matrix;
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $pointMatrix->print(fh => $fh, precision => 3);
    close $fh;
    select $old_fh;
    my $content_expected = <<MATRIX;

[  3.000 -2.000  1.333 ]
MATRIX
    chomp $content_expected;
    is($content_got, $content_expected, "Get current coordinates as a matrix object");
}
########################################
{
    my @args = (x => -2, y => 2, z => 1);
    my $point = $class->new(@args);
    $point->set(parameter => 'precision', value => 3);
    my $copy = $point->copy;
    my $precision = $copy->get(parameter => 'precision');
    is($precision, 3, 'Copying point object preserves additional parameter values');
}
########################################
