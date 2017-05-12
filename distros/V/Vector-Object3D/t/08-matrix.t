########################################
use strict;
use warnings;
use Test::More tests => 57;
use Test::Deep;
use Test::Exception;
use Test::Moose;
########################################
our $class;
BEGIN {
    $class = 'Vector::Object3D::Matrix';
    use_ok($class);
}
########################################
{
    can_ok($class, qw(num_rows num_cols get_rows get_cols add print get_rotation_matrix get_scaling_matrix get_translation_matrix _multiplication _addition _subtraction _comparison _negative_comparison));
}
########################################
{
    does_ok($class, 'Vector::Object3D::Matrix::Transform');
    does_ok($class, 'Vector::Object3D::Parameters');
}
########################################
{
    has_attribute_ok($class, 'rows');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = new_ok($class => \@args);
}
########################################
{
    my @args = (cols => [[-2, 2, -1], [2, 1, -1.5]]);
    my $matrix = new_ok($class => \@args);
}
########################################
{
    my $rows = [[-2, 2, 1], [2, -1], [-1]];
    dies_ok { $class->new(rows => $rows) } 'Cannot construct new matrix object from an inconsistent rows data';
}
########################################
{
    my $cols = [[1, -3, 2], [1, -2], [-2]];
    dies_ok { $class->new(cols => $cols) } 'Cannot construct new matrix object from an inconsistent columns data';
}
########################################
{
    my $rows = [[-2, 2], [2, 1], [-1, -1.5]];
    my $matrix = $class->new(rows => $rows);
    push @{$rows->[0]}, -3;
    my $cols = [[-2, 2, -1], [2, 1, -1.5]];
    cmp_deeply($matrix->get_cols, $cols, 'Altering the contents of an array that was used to initialize Matrix object does not modify the object itself')
}
########################################
{
    my $rows = [[-2, 2], [2, 1], [-1, -1.5]];
    my $cols = [[-2, 2, -1], [2, 1, -1.5]];
    cmp_deeply($class->_to_cols(rows => $rows), $cols, 'Internal conversion from rows to columns')
}
########################################
{
    my $cols = [[-2, 2, -1], [2, 1, -1.5]];
    my $rows = [[-2, 2], [2, 1], [-1, -1.5]];
    cmp_deeply($class->_to_rows(cols => $cols), $rows, 'Internal conversion from columns to rows')
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    my $num_cols = $matrix->num_cols;
    is($num_cols, 2, 'Get number of columns from a matrix object');
}
########################################
{
    my @args = (cols => [[-2, 2, -1], [2, 1, -1.5]]);
    my $matrix = $class->new(@args);
    my $num_rows = $matrix->num_rows;
    is($num_rows, 3, 'Get number of rows from a matrix object');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    my $cols = [[-2, 2, -1], [2, 1, -1.5]];
    cmp_deeply($matrix->get_cols, $cols, 'Fetch matrix data as an array of column values');
}
########################################
{
    my @args = (cols => [[-2, 2, -1], [2, 1, -1.5]]);
    my $matrix = $class->new(@args);
    my $rows = [[-2, 2], [2, 1], [-1, -1.5]];
    cmp_deeply($matrix->get_rows, $rows, 'Fetch matrix data as an array of row values');
}
########################################
{
    my @args = (rows => [[-1, 2]], cols => [[1], [-2]]);
    my $matrix = $class->new(@args);
    my $rows = [[1, -2]];
    cmp_deeply($matrix->get_rows, $rows, 'Columns constructor parameter takes precedence over rows');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    my $copy = $matrix->copy;
    my $cols = [[-2, 2, -1], [2, 1, -1.5]];
    cmp_deeply($copy->get_cols, $cols, 'Create a new object as a copy of an existing object');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    my $copy = $matrix->copy;
    $matrix->add(row => [3, 0]);
    my $cols = [[-2, 2, -1], [2, 1, -1.5]];
    cmp_deeply($copy->get_cols, $cols, 'Copied object remains unchanged when the original one gets modified');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1]]);
    my $matrix = $class->new(@args);
    $matrix->add(row => [-1, -1.5]);
    my $cols = [[-2, 2, -1], [2, 1, -1.5]];
    cmp_deeply($matrix->get_cols, $cols, 'Add new row to a matrix object');
}
########################################
{
    my @args = (cols => [[-2, 2, -1]]);
    my $matrix = $class->new(@args);
    $matrix->add(col => [2, 1, -1.5]);
    my $rows = [[-2, 2], [2, 1], [-1, -1.5]];
    cmp_deeply($matrix->get_rows, $rows, 'Add new column to a matrix object');
}
########################################
{
    my @args = (rows => [[-2, 2.5], [2, 1], [-1, -1]]);
    my $matrix = $class->new(@args);
    $matrix->add(row => [1]);
    my $rows = [[-2, 2.5], [2, 1], [-1, -1], [1, 0]];
    cmp_deeply($matrix->get_rows, $rows, 'Add incomplete row to a matrix object');
}
########################################
{
    my @args = (rows => [[-2, 2.5], [2, 1], [-1, -1]]);
    my $matrix = $class->new(@args);
    $matrix->add(row => [1, 3, -2]);
    my $rows = [[-2, 2.5], [2, 1], [-1, -1], [1, 3]];
    cmp_deeply($matrix->get_rows, $rows, 'Add exceeding row to a matrix object');
}
########################################
{
    my @args = (cols => [[-2, 2.5, 2], [2, 1, -1]]);
    my $matrix = $class->new(@args);
    $matrix->add(col => [-1, -1]);
    my $cols = [[-2, 2.5, 2], [2, 1, -1], [-1, -1, 0]];
    cmp_deeply($matrix->get_cols, $cols, 'Add incomplete column to a matrix object');
}
########################################
{
    my @args = (cols => [[-2, 2.5, 2], [2, 1, -1]]);
    my $matrix = $class->new(@args);
    $matrix->add(col => [-1, -1, 3, -2.5]);
    my $cols = [[-2, 2.5, 2],[2, 1, -1], [-1, -1, 3]];
    cmp_deeply($matrix->get_cols, $cols, 'Add exceeding column to a matrix object');
}
########################################
{
    my $matrix = $class->new(rows => [[-2, 2.5], [2, 1], [-1, -1.33333]]);
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $matrix->print(fh => $fh, precision => 2);
    close $fh;
    select $old_fh;
    my $content_expected = <<MATRIX;

[ -2.00  2.50 ]
[  2.00  1.00 ]
[ -1.00 -1.33 ]
MATRIX
    chomp $content_expected;
    is($content_got, $content_expected, "Print out the contents of a matrix object (2 digits after floating point)");
}
########################################
{
    my $matrix = $class->new(rows => [[-2, 2.5], [2, 1], [-1, -1.33333]]);
    my $content_got;
    my $old_fh = open my $fh, '>', \$content_got;
    $matrix->print(fh => $fh, precision => 3);
    close $fh;
    select $old_fh;
    my $content_expected = <<MATRIX;

[ -2.000  2.500 ]
[  2.000  1.000 ]
[ -1.000 -1.333 ]
MATRIX
    chomp $content_expected;
    is($content_got, $content_expected, "Print out the contents of a matrix object (3 digits after floating point)");
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args);
    my $matrix2 = $class->new(@args);
    my $result = $matrix1 == $matrix2;
    ok($result, 'Overload comparison operator (verify that object constructed from rows is okay)');
}
########################################
{
    my @args = (cols => [[-2, 2, -1], [2, 1, -1.5]]);
    my $matrix1 = $class->new(@args);
    my $matrix2 = $class->new(@args);
    my $result = $matrix1 == $matrix2;
    ok($result, 'Overload comparison operator (verify that object constructed from columns is okay)');
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    my @args2 = (rows => [[-2, 2], [2, 1], [-1, 1.5]]);
    my $matrix2 = $class->new(@args2);
    my $result = $matrix1 == $matrix2;
    ok(!$result, 'Overload comparison operator (comparing two different objects yields false)');
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    my @args2 = (rows => [[-2, 2], [2, 1], [-1, 1.5]]);
    my $matrix2 = $class->new(@args2);
    my $result = $matrix1 != $matrix2;
    ok($result, 'Overload negative comparison operator (verify that two different objects are not equal)');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args);
    my $matrix2 = $class->new(@args);
    my $result = $matrix1 != $matrix2;
    ok(!$result, 'Overload negative comparison operator (comparing two identical objects yields false)');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    my @expected_args = (rows => [[-4, 4], [4, 2], [-2, -3]]);
    my $expected_matrix = $class->new(@expected_args);
    ok(2 * $matrix == $expected_matrix, 'Multiply matrix object by a constant number value');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args);
    my $matrix2 = $class->new(@args);
    dies_ok { $matrix1 * $matrix2 } 'Cannot multiply two matrix objects of incompatible dimensions';
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    my @args2 = (rows => [[-2], [2]]);
    my $matrix2 = $class->new(@args2);
    my @expected_args = (rows => [[8], [-2], [-1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($matrix1 * $matrix2 == $expected_matrix, 'Multiply two matrix objects');
}
########################################
{
    my @args1 = (rows => [[3, -2, 1, 1]]);
    my $point = $class->new(@args1);
    my @args2 = (rows => [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [-1, -2, 1, 1]]);
    my $translation_matrix = $class->new(@args2);
    my @expected_args = (rows => [[2, -4, 2, 1]]);
    my $point_translated = $class->new(@expected_args);
    ok($point * $translation_matrix == $point_translated, 'Translate point object by multiplying two matrix objects');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    dies_ok { 2 + $matrix } 'Cannot add number to a matrix object';
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    my @args2 = (rows => [[-2], [2], [-1]]);
    my $matrix2 = $class->new(@args2);
    dies_ok { $matrix1 + $matrix2 } 'Cannot add two matrix objects of incompatible number of columns';
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    my @args2 = (rows => [[-2, 2], [2, 1]]);
    my $matrix2 = $class->new(@args2);
    dies_ok { $matrix1 + $matrix2 } 'Cannot add two matrix objects of incompatible number of rows';
}
########################################
{
    my @args1 = (rows => [[2, 3], [-1, 2]]);
    my $matrix1 = $class->new(@args1);
    my @args2 = (rows => [[1, -2], [3, -2]]);
    my $matrix2 = $class->new(@args2);
    my @expected_args = (rows => [[3, 1], [2, 0]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($matrix1 + $matrix2 == $expected_matrix, 'Add two matrix objects');
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    dies_ok { $matrix - 1 } 'Cannot subtract number from a matrix object';
}
########################################
{
    my @args1 = (rows => [[2, 3], [-1, 2]]);
    my $matrix1 = $class->new(@args1);
    my @args2 = (rows => [[1, -2], [3, -2]]);
    my $matrix2 = $class->new(@args2);
    my @expected_args = (rows => [[1, 5], [-4, 4]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($matrix1 - $matrix2 == $expected_matrix, 'Subtract two matrix objects');
}
########################################
{
    my $translateMatrix2D = $class->get_translation_matrix(shift_x => -2, shift_y => 1);
    my @expected_args = (rows => [[1, 0, 0], [0, 1, 0], [-2, 1, 1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($translateMatrix2D == $expected_matrix, 'Setup translation matrix in 2D based on the X/Y shift values');
}
########################################
{
    my $scalingMatrix2D = $class->get_scaling_matrix(scale_x => 2, scale_y => 2);
    my @expected_args = (rows => [[2, 0, 0], [0, 2, 0], [0, 0, 1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($scalingMatrix2D == $expected_matrix, 'Setup scaling matrix in 2D based on the X/Y scale values');
}
########################################
{
    my $pi = 3.14;
    my $rotateMatrix2D = $class->get_rotation_matrix(rotate_xy => 30 * ($pi / 180));
    $rotateMatrix2D->set(parameter => 'precision', value => 2);
    my @expected_args = (rows => [[0.87, -0.5, 0], [0.5, 0.87, 0], [0, 0, 1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($rotateMatrix2D == $expected_matrix, "Setup rotation matrix in 2D based on the X/Y plane's angle of rotation around Z axis");
}
########################################
{
    my @args = (rows => [[2, 3], [-1, 2]]);
    my $matrix = $class->new(@args);
    my $transformationMatrix = $matrix->get_translation_matrix(shift_x => 1, shift_y => -3);
    my @expected_args = (rows => [[1, 0, 0], [0, 1, 0], [1, -3, 1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($transformationMatrix == $expected_matrix, 'Setup transformation matrix out of an existing matrix object');
}
########################################
{
    my $translateMatrix3D = $class->get_translation_matrix(shift_x => -2, shift_y => 1, shift_z => 3);
    my @expected_args = (rows => [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [-2, 1, 3, 1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($translateMatrix3D == $expected_matrix, 'Setup translation matrix in 3D based on the X/Y/Z shift values');
}
########################################
{
    my $scalingMatrix3D = $class->get_scaling_matrix(scale_x => 2, scale_y => 2, scale_z => 3);
    my @expected_args = (rows => [[2, 0, 0, 0], [0, 2, 0, 0], [0, 0, 3, 0], [0, 0, 0, 1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($scalingMatrix3D == $expected_matrix, 'Setup scaling matrix in 3D based on the X/Y/Z scale values');
}
########################################
{
    my $pi = 3.14;
    my $rotateMatrix3D = $class->get_rotation_matrix(rotate_xy => 30 * ($pi / 180), rotate_yz => -30 * ($pi / 180), rotate_xz => 45 * ($pi / 180));
    $rotateMatrix3D->set(parameter => 'precision', value => 2);
    my @expected_args = (rows => [[0.61, -0.5, -0.71, 0], [0.5, 0.75, -0.5, 0], [0.71, 0.5, 0.61, 0], [0, 0, 0, 1]]);
    my $expected_matrix = $class->new(@expected_args);
    ok($rotateMatrix3D == $expected_matrix, "Setup rotation matrix in 3D based on the X/Y/Z plane's angle of rotation around X/Y/Z axes");
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    dies_ok { $matrix->get(parameter => 'xxx') } 'Cannot get unrecognized parameter value from a matrix object';
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    dies_ok { $matrix->set(parameter => 'xxx', value => 1) } 'Cannot set unrecognized parameter value for a matrix object';
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    dies_ok { $matrix->set(parameter => 'precision', value => 'yyy') } 'Cannot set non-numeric parameter value for a matrix object';
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    my $precision = $matrix->get(parameter => 'precision');
    is($precision, undef, 'Get the default value of "precision" parameter from a matrix object')
}
########################################
{
    my @args = (rows => [[-2, 2], [2, 1], [-1, -1.5]]);
    my $matrix = $class->new(@args);
    $matrix->set(parameter => 'precision', value => 3);
    my $precision = $matrix->get(parameter => 'precision');
    is($precision, 3, 'Set a new value of "precision" parameter for a matrix object')
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2.018, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    $matrix1->set(parameter => 'precision', value => 2);
    my @args2 = (rows => [[-2, 2], [2.021, 1], [-1, -1.5]]);
    my $matrix2 = $class->new(@args2);
    $matrix2->set(parameter => 'precision', value => 3);
    my $result = $matrix1 != $matrix2;
    ok($result, 'Comparing two almost identical matrix objects with too high precision yields false');
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2.018, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    $matrix1->set(parameter => 'precision', value => 2);
    my @args2 = (rows => [[-2, 2], [2.021, 1], [-1, -1.5]]);
    my $matrix2 = $class->new(@args2);
    $matrix2->set(parameter => 'precision', value => 2);
    my $result = $matrix1 == $matrix2;
    ok($result, 'Comparing two almost identical matrix objects with accurate precision yields true');
}
########################################
{
    my @args1 = (rows => [[-2, 2], [2.018, 1], [-1, -1.5]]);
    my $matrix1 = $class->new(@args1);
    $matrix1->set(parameter => 'precision', value => 2);
    my @args2 = (rows => [[-2, 2], [2.020, 1], [-1, -1.5]]);
    my $matrix2 = $class->new(@args2);
    $matrix2->set(parameter => 'precision', value => 3);
    my $result = $matrix1 == $matrix2;
    ok($result, 'Comparing two almost identical matrix objects with too high precision but still matching values yields true');
}
########################################
