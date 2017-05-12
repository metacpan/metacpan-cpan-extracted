package Vector::Object3D::Parameters;

=head1 NAME

Vector::Object3D::Parameters - additional vector object parameters

=head2 SYNOPSIS

  package Vector::Object3D::Matrix;

  use Moose;
  with 'Vector::Object3D::Parameters';

  # Define list of allowed parameter names with their default values and wrap it by an appropriate method call:
  sub build_default_parameter_values {
    return { precision => undef };
  }

  # Get currently used parameter value:
  my $param = 'precision';
  my $value = $object->get(parameter => $param);

  # Set new parameter value:
  my $param = 'precision';
  my $value = 2;
  $object->set(parameter => $param, value => $value);

  # Get complete list of allowed parameter names:
  my @names = $object->get_parameter_names;

  # Get complete list of currently used parameter values:
  my %values = $object->get_parameter_values;

=head1 DESCRIPTION

C<Vector::Object3D::Parameters> is a Moose role that is meant to be applied to the family of C<Vector::Object3D::> classes in order to provide them with additional methods supporting maintenance of additional object properties. That might for example be a parameter named C<precision>, as used by i.a. C<Vector::Object3D::Matrix> and C<Vector::Object3D::Point> classes. Understanding the importance of this parameter is illustrated in the following example:

  use Vector::Object3D::Matrix;

  # Create two almost identical matrix objects:
  my $matrix1 = Vector::Object3D::Matrix->new(rows => [[-2, 2], [2.018, 1]]);
  my $matrix2 = Vector::Object3D::Matrix->new(rows => [[-2, 2], [2.021, 1]]);

  # Set new precision values for both objects that will not be sufficient to consider them equal:
  $matrix1->set(parameter => 'precision', value => 3);
  $matrix2->set(parameter => 'precision', value => 3);

  # Comparing two almost identical matrix objects with too high precision yields false:
  my $are_the_same = $matrix1 == $matrix2; # false

  # Set new precision values for both objects that will be good enough to have a match:
  $matrix1->set(parameter => 'precision', value => 2);
  $matrix2->set(parameter => 'precision', value => 2);

  # Comparing two almost identical matrix objects with accurate precision yields true:
  my $are_the_same = $matrix1 == $matrix2; # true

This becomes especially important when comparing different transformation matrices, which might not appear to be equal due to divisions that produce results with theoretically infinite number of decimal places, just like in this example:

  $ perl -e 'print 2/3'
  0.666666666666667

Since calculations of input values that feed transformation matrix data during their construction involve producing such numbers, you should always consider setting up an accurate precision value if you plan to compare them later with each other.

The exactly same reasoning could be applied to C<Vector::Object3D::Point> objects as well.

=head1 METHODS

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Storable 'dclone';

use Moose::Role;

has _allowed_parameters => (
    builder  => '_build_allowed_parameters',
    init_arg => undef,
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    reader   => '_get_allowed_parameters',
);

has _parameters => (
    builder  => 'build_default_parameter_values',
    is       => 'rw',
    isa      => 'HashRef[Maybe[Int]]',
    accessor => '_parameters',
);

sub _build_allowed_parameters {
    my ($self) = @_;

    my $parameter_values = $self->build_default_parameter_values();

    my @allowed_parameters = keys %{$parameter_values};

    return \@allowed_parameters;
}

=head2 set

Set new parameter value:

  my $param = 'precision';
  my $value = 2;
  $object->set(parameter => $param, value => $value);

=cut

sub set {
    my ($self, %args) = @_;

    my $parameter = $args{parameter};
    my $value     = $args{value};

    die qq{Unable to set unrecognized parameter value: "${parameter}"} unless $self->_is_allowed_parameter($parameter);

    my $parameters = dclone $self->_parameters;
    $parameters->{$parameter} = $value;
    $self->_parameters($parameters);

    return $value;
}

=head2 get

Get currently used parameter value:

  my $param = 'precision';
  my $value = $object->get(parameter => $param);

=cut

sub get {
    my ($self, %args) = @_;

    my $parameter = $args{parameter};

    die qq{Unable to get unrecognized parameter value: "${parameter}"} unless $self->_is_allowed_parameter($parameter);

    return $self->_parameters->{$parameter};
}

sub _is_allowed_parameter {
    my ($self, $name) = @_;

    my $allowed_parameters = $self->_get_allowed_parameters;

    return grep { $name eq $_ } @{$allowed_parameters};
}

=head2 get_parameter_names

Get complete list of allowed parameter names:

  my @names = $object->get_parameter_names;

=cut

sub get_parameter_names {
    my ($self) = @_;

    my $parameter_names = $self->_get_allowed_parameters;

    return @{$parameter_names};
}

=head2 get_parameter_values

Get complete list of currently used parameter values:

  my %values = $object->get_parameter_values;

=cut

sub get_parameter_values {
    my ($self) = @_;

    my @parameter_names = $self->get_parameter_names;

    my %parameter_values;

    for my $name (@parameter_names) {
        $parameter_values{$name} = $self->get(parameter => $name);
    }

    return %parameter_values;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Parameters> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Vector::Object3D::Matrix>, L<Vector::Object3D::Point>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.01 (2012-12-24)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

no Moose::Role;

1;
