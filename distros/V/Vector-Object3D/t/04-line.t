########################################
use strict;
use warnings;
use Test::More tests => 25;
use Test::Deep;
use Test::Exception;
use Test::Moose;
use Vector::Object3D::Point;
########################################
our $class;
BEGIN {
    $class = 'Vector::Object3D::Line';
    use_ok($class);
}
########################################
{
    can_ok($class, qw(copy get_vertex1 get_vertex2 get_vertices print _comparison _negative_comparison));
}
########################################
{
    has_attribute_ok($class, 'vertex1');
    has_attribute_ok($class, 'vertex2');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my @args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = new_ok($class => \@args);
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my @args = (vertices => [$vertex1, $vertex2]);
    my $line = new_ok($class => \@args);
}
########################################
{
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex2 => $vertex2);
    dies_ok { my $line = $class->new(%args); } 'Initialize line object with insufficient endpoints (missing vertex1)';
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my %args = (vertex1 => $vertex1);
    dies_ok { my $line = $class->new(%args); } 'Initialize line object with insufficient endpoints (missing vertex2)';
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my %args = (vertices => [$vertex1]);
    dies_ok { my $line = $class->new(%args); } 'Initialize line object with insufficient vertices (only one point object)';
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my $copy = $line->copy;
    my @vertices = @args{qw/vertex1 vertex2/};
    cmp_deeply([ $copy->get_vertices ], \@vertices, 'Create a new object as a copy of an existing object');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my $copy = $line->copy;
    my @vertices = ($vertex1->copy, $vertex2->copy);
    $vertex1->set_x(-2);
    cmp_deeply([ $copy->get_vertices ], \@vertices, 'Copied object remains unchanged when the original one gets modified');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my $expected_vertex = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    cmp_deeply($line->get_vertex1, $expected_vertex, 'Get first vertex point');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my $expected_vertex = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    cmp_deeply($line->get_vertex2, $expected_vertex, 'Get last vertex point');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my @vertices = ($vertex1, $vertex2);
    cmp_deeply([$line->get_vertices], \@vertices, 'Get both vertex points');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1.333);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $line->print(fh => $fh, precision => 1);
    close $fh;
    select $old_fh;
    my $content_expected = <<LINE;

[  3.0 -2.0  1.3 ]
[ -1.0  2.0  3.0 ]
LINE
    chomp $content_expected;
    is($content_got, $content_expected, "Print out the contents of a line object (1 digit after floating point)");
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1.333);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $line->print(fh => $fh);
    close $fh;
    select $old_fh;
    my $content_expected = <<LINE;

[  3.00 -2.00  1.33 ]
[ -1.00  2.00  3.00 ]
LINE
    chomp $content_expected;
    is($content_got, $content_expected, "Print out the contents of a line object (default number of digits after floating point)");
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1.333);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line = $class->new(%args);
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $line->print(fh => $fh, precision => 3);
    close $fh;
    select $old_fh;
    my $content_expected = <<LINE;

[  3.000 -2.000  1.333 ]
[ -1.000  2.000  3.000 ]
LINE
    chomp $content_expected;
    is($content_got, $content_expected, "Print out the contents of a line object (3 digits after floating point)");
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line1 = $class->new(%args);
    my $line2 = $class->new(%args);
    my $result = $line1 == $line2;
    ok($result, 'Overload comparison operator (verify that object constructed from a hash of two vertex components is okay)');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertices => [$vertex1, $vertex2]);
    my $line1 = $class->new(%args);
    my $line2 = $class->new(%args);
    my $result = $line1 == $line2;
    ok($result, 'Overload comparison operator (verify that object constructed from a list of two point objects is okay)');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my $vertex3 = Vector::Object3D::Point->new(x => -1, y => 2, z => -3);
    my %args1 = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line1 = $class->new(%args1);
    my %args2 = (vertex1 => $vertex1, vertex2 => $vertex3);
    my $line2 = $class->new(%args2);
    my $result = $line1 == $line2;
    ok(!$result, 'Overload comparison operator (comparing two different objects yields false)');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my $vertex3 = Vector::Object3D::Point->new(x => -1, y => 2, z => -3);
    my %args1 = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line1 = $class->new(%args1);
    my %args2 = (vertex1 => $vertex1, vertex2 => $vertex3);
    my $line2 = $class->new(%args2);
    my $result = $line1 != $line2;
    ok($result, 'Overload negative comparison operator (verify that two different objects are not equal)');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
    my %args = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line1 = $class->new(%args);
    my $line2 = $class->new(%args);
    my $result = $line1 != $line2;
    ok(!$result, 'Overload negative comparison operator (comparing two identical objects yields false)');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2.018, z => 3);
    $vertex2->set(parameter => 'precision', value => 2);
    my $vertex3 = Vector::Object3D::Point->new(x => -1, y => 2.021, z => 3);
    $vertex3->set(parameter => 'precision', value => 3);
    my %args1 = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line1 = $class->new(%args1);
    my %args2 = (vertex1 => $vertex1, vertex2 => $vertex3);
    my $line2 = $class->new(%args2);
    my $result = $line1 != $line2;
    ok($result, 'Compare two almost identical line objects with too high precision yields false');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2.018, z => 3);
    $vertex2->set(parameter => 'precision', value => 2);
    my $vertex3 = Vector::Object3D::Point->new(x => -1, y => 2.021, z => 3);
    $vertex3->set(parameter => 'precision', value => 2);
    my %args1 = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line1 = $class->new(%args1);
    my %args2 = (vertex1 => $vertex1, vertex2 => $vertex3);
    my $line2 = $class->new(%args2);
    my $result = $line1 == $line2;
    ok($result, 'Compare two almost identical line objects with accurate precision yields true');
}
########################################
{
    my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
    my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2.018, z => 3);
    $vertex2->set(parameter => 'precision', value => 2);
    my $vertex3 = Vector::Object3D::Point->new(x => -1, y => 2.020, z => 3);
    $vertex3->set(parameter => 'precision', value => 3);
    my %args1 = (vertex1 => $vertex1, vertex2 => $vertex2);
    my $line1 = $class->new(%args1);
    my %args2 = (vertex1 => $vertex1, vertex2 => $vertex3);
    my $line2 = $class->new(%args2);
    my $result = $line1 == $line2;
    ok($result, 'Compare two almost identical line objects with too high precision but still matching values yields true');
}
########################################
