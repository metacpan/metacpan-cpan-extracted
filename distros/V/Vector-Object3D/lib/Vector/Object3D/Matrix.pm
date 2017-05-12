package Vector::Object3D::Matrix;

=head1 NAME

Vector::Object3D::Matrix - Matrix definitions and basic operations

=head2 SYNOPSIS

  use Vector::Object3D::Matrix;

  # Create an instance of a class:
  my $matrix = Vector::Object3D::Matrix->new(rows => [[-2, 2], [2, 1], [-1, -1]]);
  my $matrix = Vector::Object3D::Matrix->new(cols => [[-2, 2, -1], [2, 1, -1]]);

  # Create a new object as a copy of an existing object:
  my $copy = $matrix->copy;

  # Get number of columns/rows from a matrix object:
  my $num_cols = $matrix->num_cols;
  my $num_rows = $matrix->num_rows;

  # Fetch matrix data as an array of column/row values:
  my $cols = $matrix->get_cols;
  my $rows = $matrix->get_rows;

  # Set new precision value (which is used while printing out data and comparing
  # the matrix object with others):
  my $precision = 2;
  $matrix->set(parameter => 'precision', value => $precision);

  # Get currently used precision value (undef indicates maximum possible precision
  # which is designated to the Perl core):
  my $precision = $matrix->get(parameter => 'precision');

  # Print out formatted matrix data:
  $matrix->print(fh => $fh, precision => $precision);

  # Produce a matrix that is a result of scalar multiplication:
  my $matrix2 = 2 * $matrix1;

  # Produce a matrix that is a result of matrix multiplication:
  my $matrix3 = $matrix1 * $matrix2;

  # Add two matrices:
  my $matrix4 = $matrix1 + $matrix2;

  # Subtract one matrix from another:
  my $matrix5 = $matrix1 - $matrix2;

  # Compare two matrix objects:
  my $are_the_same = $matrix1 == $matrix2;

  # Append another column to a matrix object:
  $matrix->add(col => [2, -1, 3]);

  # Add another row to a matrix object:
  $matrix->add(row => [0, 1, -2]);

=head1 DESCRIPTION

Although C<Vector::Object3D::Matrix> was originally meant as an auxiliary package supporting all the necessary calculations performed in the 3D space that are handled by C<Vector::Object3D> module only, it may still be used as a standalone module providing support for basic matrix operations (please note however that there are plenty more advanced modules available on CPAN already that serve exactly same purpose).

Matrix definitions and basic operations like multiplication, addition and subtraction are implemented. It is also feasible to print out text-based contents of a matrix object to the standard output. Auxiliary static methods allow setting up 2D/3D transformation matrices.

=head1 METHODS

=head2 new

Create an instance of a C<Vector::Object3D::Matrix> class:

  my $rows = [[-2, 2], [2, 1], [-1, -1]];
  my $matrix = Vector::Object3D::Matrix->new(rows => $rows);

  my $cols = [[-2, 2, -1], [2, 1, -1]];
  my $matrix = Vector::Object3D::Matrix->new(cols => $cols);

There are two individual means of C<Vector::Object3D::Matrix> object construction, provided list of either rows or columns of numeric values. Although data is internally always stored as rows, cols constructor parameter takes precedence over rows in case both values are provided at the same time.

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose;
with 'Vector::Object3D::Parameters';
with 'Vector::Object3D::Matrix::Transform';

use Carp qw(croak);
use Data::Dumper;
use IO::Scalar;
use List::Util qw(max);
use Storable 'dclone';

use overload
    '*'  => \&_multiplication,
    '+'  => \&_addition,
    '-'  => \&_subtraction,
    '==' => \&_comparison,
    '!=' => \&_negative_comparison;

has rows => (
    is       => 'ro',
    isa      => 'ArrayRef[ArrayRef[Num]]',
    required => 1,
);

sub build_default_parameter_values {
    my %parameter_values = (
        precision => undef,
    );

    return \%parameter_values;
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $cols = $args{cols};

    my $rows = defined $cols ? $class->_to_rows(cols => $cols) : $args{rows};

    return $class->$orig(rows => dclone $rows);
};

sub BUILD {
    my ($self) = @_;

    # Prepare printable version of matrix data:
    my $data;
    my $sh = new IO::Scalar \$data;
    $self->print(fh => $sh);

    # Check rows data for inconsistencies:
    my $rows = $self->get_rows;
    my $num_cols = $self->num_cols;

    for my $row (@{$rows}) {
        croak qq{Inconsistent matrix initialization data (number of columns varies between different rows): ${data}} unless @{$row} == $num_cols;
    }

    return;
}

sub _to_cols {
    my ($class, %args) = @_;

    my $rows = $args{rows};

    my @cols;

    for my $vals (@{$rows}) {

        for (my $col = 0; $col < @{$vals}; $col++) {

            push @{ $cols[$col] }, $vals->[$col];
        }
    }

    return \@cols;
}

sub _to_rows {
    my ($class, %args) = @_;

    my $cols = $args{cols};

    my @rows;

    for my $vals (@{$cols}) {

        for (my $row = 0; $row < @{$vals}; $row++) {

            push @{ $rows[$row] }, $vals->[$row];
        }
    }

    return \@rows;
}

=head2 copy

Create a new C<Vector::Object3D::Matrix> object as a copy of an existing object:

  my $copy = $matrix->copy;

=cut

sub copy {
    my ($self) = @_;

    my $rows = $self->rows;

    my $class = $self->meta->name;
    my $copy = $class->new(rows => $rows);

    return $copy;
}

=head2 num_cols

Get number of columns from a matrix object:

  my $num_cols = $matrix->num_cols;

=cut

sub num_cols {
    my ($self) = @_;

    my $cols = $self->get_cols;

    return scalar @{$cols};
}

=head2 num_rows

Get number of rows from a matrix object:

  my $num_rows = $matrix->num_rows;

=cut

sub num_rows {
    my ($self) = @_;

    my $rows = $self->get_rows;

    return scalar @{$rows};
}

=head2 get_cols

Fetch matrix data as an array of column values:

  my $cols = $matrix->get_cols;

=cut

sub get_cols {
    my ($self) = @_;

    my $rows = $self->rows;

    my $cols = $self->_to_cols(rows => $rows);

    return $cols;
}

=head2 get_rows

Fetch matrix data as an array of row values:

  my $rows = $matrix->get_rows;

=cut

sub get_rows {
    my ($self) = @_;

    my $rows = $self->rows;

    return dclone($rows);
}

=head2 add

Append another column to a matrix instance:

  $matrix->add(col => [2, -1, 3]);

Add another row to an existing matrix object:

  $matrix->add(row => [0, 1, -2]);

Both add scenarios (adding a new column and adding a new row) will skip adding values that would exceed the other size of a matrix and fill in the missing ones with zeroes.

=cut

sub add {
    my ($self, %args) = @_;

    my $col = $args{col};
    my $row = $args{row};

    if (defined $col) {

        # Number of rows in a column needs to match a number of rows in a
        # matrix object, otherwise adding a new column would not make sense:
        my $num_rows = $self->num_rows;
        my $new_col = dclone $col;

        if (@{$new_col} > $num_rows) {
            $self->_reduce_array_length($new_col, $num_rows);
        }
        else {
            $self->_fill_up_array_with_zeroes($new_col, $num_rows);
        }

        for (my $i = 0; $i < @{$new_col}; $i++) {
            my $val = $new_col->[$i];
            push @{$self->rows->[$i]}, $val;
        }
    }
    else {

        # Number of columns in a row needs to match a number of columns in
        # a matrix object, otherwise adding a new row would not make sense:
        my $num_cols = $self->num_cols;
        my $new_row = dclone $row;

        if (@{$new_row} > $num_cols) {
            $self->_reduce_array_length($new_row, $num_cols);
        }
        else {
            $self->_fill_up_array_with_zeroes($new_row, $num_cols);
        }

        push @{$self->rows}, $new_row;
    }

    return;
}

sub _reduce_array_length {
    my ($self, $array, $length) = @_;

    splice @{$array}, $length;

    return;
}

sub _fill_up_array_with_zeroes {
    my ($self, $array, $length) = @_;

    push @{$array}, split //, 0 x ($length - @{$array});

    return;
}

=head2 set

Set new precision value (which is used while comparing matrix objects with each other):

  my $precision = 2;
  $matrix->set(parameter => 'precision', value => $precision);

=head2 get

Get currently used precision value (undef indicates maximum possible precision which is designated to the Perl core):

  my $precision = $matrix->get(parameter => 'precision');

=head2 print

Print out text-formatted matrix data (which might be, for instance, useful for debugging purposes):

  $matrix->print(fh => $fh, precision => $precision);

C<fh> defaults to the standard output. C<precision> is intended for internal use by string format specifier that outputs individual matrix values as decimal floating points, and defaults to 2.

=cut

sub print {
    my ($self, %args) = @_;

    my $fh = $args{fh} || *STDOUT;
    my $precision = $args{precision} || 2;

    $precision =~ s/\D//;

    # Calculate maximum possible length of a single matrix item:
    my $maxlen = $self->_get_item_max_length($precision);

    my $stdout = select $fh;

    foreach my $row (@{$self->rows}) {
        print qq{\n[ };
        foreach my $val (@{$row}) {
            printf qq{%${maxlen}.${precision}f }, $val;
        }
        print qq{]};
    }

    select $stdout;

    return;
}

sub _get_item_max_length {
    my ($self, $precision) = @_;

    my @values = map { @{$_} } @{$self->get_rows};
    my @lengths = map { length sprintf qq{%.${precision}f}, $_ } @values;

    my $max = max(@lengths);
    return $max;
}

=head2 get_rotation_matrix

Construct rotation matrix on a 2D plane:

  my $rotateMatrix2D = Vector::Object3D::Matrix->get_rotation_matrix(
    rotate_xy => (30 * $pi / 180),
  );

Construct rotation matrix in a 3D space:

  my $rotateMatrix3D = Vector::Object3D::Matrix->get_rotation_matrix(
    rotate_xy => (30 * $pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

=head2 get_scaling_matrix

Construct scaling matrix on a 2D plane:

  my $scaleMatrix2D = Vector::Object3D::Matrix->get_scaling_matrix(
    scale_x => 2,
    scale_y => 2,
  );

Construct scaling matrix in a 3D space:

  my $scaleMatrix3D = Vector::Object3D::Matrix->get_scaling_matrix(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

=head2 get_translation_matrix

Construct translation matrix on a 2D plane:

  my $translateMatrix2D = Vector::Object3D::Matrix->get_translation_matrix(
    shift_x => -2,
    shift_y => 1,
  );

Construct translation matrix in a 3D space:

  my $translateMatrix3D = Vector::Object3D::Matrix->get_translation_matrix(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=head1 OPERATORS

=head2 multiply (*)

Produce a matrix that is a result of scalar multiplication:

  my $matrix2 = 2 * $matrix1;

Produce a matrix that is a result of matrix multiplication:

  my $matrix3 = $matrix1 * $matrix2;

=cut

sub _multiplication {
    my ($self, $arg) = @_;

    if (ref $arg eq __PACKAGE__) {
        return $self->_multiplication_by_matrix($arg);
    }
    elsif ($arg =~ m/^-?(\d+|\.\d+|\d+\.\d+)$/) {
        return $self->_multiplication_by_number($arg);
    }
    else {
        croak "Incorrect call of overloaded operator '*' method";
    }
}

sub _multiplication_by_matrix {
    my ($self, $arg) = @_;

    my $num_cols1 = $self->num_cols;
    my $num_rows2 = $arg->num_rows;

    unless ($num_cols1 == $num_rows2) {
        my ($matrix1, $matrix2);

        my $old_fh = open my $fh, '>', \$matrix1;
        $self->print(fh => $fh);

        open $fh, '>', \$matrix2;
        $arg->print(fh => $fh);

        close $fh;
        select $old_fh;

        croak "Number of columns of the first matrix (${num_cols1}) does not match number of rows of the second matrix (${num_rows2}) - incompatibility makes matrix multiplication impossible:\n\nMATRIX #1$matrix1\n\nMATRIX #2$matrix2";
    }

    my $rows1 = $self->get_rows;
    my $rows2 = $arg->get_rows;
    my $rows  = [];

    my $num_rows = $self->num_rows;
    my $num_cols = $arg->num_cols;

    for (my $i = 0; $i < $num_rows; $i++) {
        for (my $j = 0; $j < $num_cols; $j++) {
            my $val = 0;
            for (my $k = 0; $k < $num_cols1; $k++) {
                $val += $rows1->[$i]->[$k] * $rows2->[$k]->[$j];
            }
            $rows->[$i]->[$j] = $val;
        }
    }

    my $result = (ref $self)->new(rows => $rows);
    return $result;
}

sub _multiplication_by_number {
    my ($self, $arg) = @_;

    my $rows = $self->get_rows;

    for my $row (@{$rows}) {
        $row = [ map { $_ * $arg } @{$row} ];
    }

    my $result = (ref $self)->new(rows => $rows);
    return $result;
}

=head2 add (+)

Add two matrices:

  my $matrix3 = $matrix1 + $matrix2;

A matrix may be added to another one if they both share exactly same dimensions.

=cut

sub _addition {
    my ($self, $arg) = @_;

    if (ref $arg eq __PACKAGE__) {
        return $self->_addition_to_matrix($arg);
    }
    else {
        croak "Incorrect use of overloaded operator '+' method";
    }
}

sub _addition_to_matrix {
    my ($self, $arg) = @_;

    my $num_rows1 = $self->num_rows;
    my $num_rows2 = $arg->num_rows;
    my $num_cols1 = $self->num_cols;
    my $num_cols2 = $arg->num_cols;

    croak "Size of the first matrix (${num_rows1}x${num_cols1}) does not match size of the second matrix (${num_rows2}x${num_cols2}) - incompatibility makes matrix addition impossible" unless $num_rows1 == $num_rows2 and $num_cols1 == $num_cols2;

    my $rows1 = $self->get_rows;
    my $rows2 = $arg->get_rows;
    my $rows  = [];

    for (my $i = 0; $i < $num_rows1; $i++) {
        for (my $j = 0; $j < $num_cols1; $j++) {
            $rows->[$i]->[$j] = $rows1->[$i]->[$j] + $rows2->[$i]->[$j];
        }
    }

    my $result = (ref $self)->new(rows => $rows);
    return $result;
}

=head2 subtract (-)

Subtract one matrix from another:

  my $matrix3 = $matrix1 - $matrix2;

A matrix may be subtracted from another one if they both share exactly same dimensions.

=cut

sub _subtraction {
    my ($self, $arg) = @_;

    if (ref $arg eq __PACKAGE__) {
        return $self->_subtraction_from_matrix($arg);
    }
    else {
        croak "Incorrect use of overloaded operator '-' method";
    }
}

sub _subtraction_from_matrix {
    my ($self, $arg) = @_;

    my $num_rows1 = $self->num_rows;
    my $num_rows2 = $arg->num_rows;
    my $num_cols1 = $self->num_cols;
    my $num_cols2 = $arg->num_cols;

    croak "Size of the first matrix (${num_rows1}x${num_cols1}) does not match size of the second matrix (${num_rows2}x${num_cols2}) - incompatibility makes matrix subtraction impossible" unless $num_rows1 == $num_rows2 and $num_cols1 == $num_cols2;

    return $self + -1 * $arg;
}

=head2 compare (==)

Compare two matrix objects:

  my $are_the_same = $matrix1 == $matrix2;

Overloaded comparison operator evaluates to true whenever two matrix objects are identical (same number of rows, columns and identical values in the corresponding cells).

=cut

sub _comparison {
    my ($self, $arg) = @_;

    return 0 unless $self->num_cols == $arg->num_cols;
    return 0 unless $self->num_rows == $arg->num_rows;

    # Get compare precision for both matrices:
    my $precision1 = $self->get(parameter => 'precision');
    $precision1 = defined $precision1 ? '.' . $precision1 : '';
    my $precision2 = $arg->get(parameter => 'precision');
    $precision2 = defined $precision2 ? '.' . $precision2 : '';

    my $rows1 = $self->get_rows;
    my $rows2 = $arg->get_rows;

    for (my $i = 0; $i < $self->num_rows; $i++) {
        for (my $j = 0; $j < $self->num_cols; $j++) {

            my $val1 = sprintf qq{%${precision1}f}, $rows1->[$i][$j];
            $val1 =~ s/^(.*\..*?)0*$/$1/;
            $val1 =~ s/\.$//;

            my $val2 = sprintf qq{%${precision2}f}, $rows2->[$i][$j];
            $val2 =~ s/^(.*\..*?)0*$/$1/;
            $val2 =~ s/\.$//;

            return 0 if $val1 ne $val2;
        }
    }

    return 1;
}

=head2 negative compare (!=)

Compare two matrix objects:

  my $are_not_the_same = $matrix1 != $matrix2;

Overloaded negative comparison operator evaluates to true whenever two matrix objects differ (unequal number of rows, columns or diverse values in the corresponding cells).

=cut

sub _negative_comparison {
    my ($self, $arg) = @_;

    return not $self->_comparison($arg);
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Matrix> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Inline::Octave>, L<Math::Cephes::Matrix>, L<Math::Matrix>, L<PDL::MatrixOps>, L<Vector::Object3D>, L<Vector::Object3D::Matrix::Transform>, L<Vector::Object3D::Parameters>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.01 (2012-12-24)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
