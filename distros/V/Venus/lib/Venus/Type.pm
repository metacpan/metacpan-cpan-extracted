package Venus::Type;

use 5.018;

use strict;
use warnings;

use Moo;

extends 'Venus::Kind::Utility';

with 'Venus::Role::Accessible';

use Scalar::Util ();

# METHODS

sub code {
  my ($self) = @_;

  my $package = $self->package;

  return "ARRAY" if $package eq "Venus::Array";
  return "BOOLEAN" if $package eq "Venus::Boolean";
  return "HASH" if $package eq "Venus::Hash";
  return "CODE" if $package eq "Venus::Code";
  return "FLOAT" if $package eq "Venus::Float";
  return "NUMBER" if $package eq "Venus::Number";
  return "STRING" if $package eq "Venus::String";
  return "SCALAR" if $package eq "Venus::Scalar";
  return "REGEXP" if $package eq "Venus::Regexp";
  return "UNDEF" if $package eq "Venus::Undef";

  return undef;
}

sub deduce {
  my ($self) = @_;

  my $data = $self->get;

  return $self->object_undef if not(defined($data));
  return $self->deduce_blessed if scalar_is_blessed($data);
  return $self->deduce_defined;
}

sub deduce_boolean {
  my ($self) = @_;

  my $data = $self->get;

  return $self->object_boolean;
}

sub deduce_blessed {
  my ($self) = @_;

  my $data = $self->get;

  return $self->object_regexp if $data->isa('Regexp');
  return $data;
}

sub deduce_deep {
  my ($self) = @_;

  my $data = $self->deduce;

  if ($data and $data->isa('Venus::Hash')) {
    for my $i (keys %{$data->get}) {
      my $val = $data->get->{$i};
      $data->get->{$i} = ref($val)
        ? $self->class->new(value => $val)->deduce_deep
        : $self->class->new(value => $val)->deduce;
    }
  }
  if ($data and $data->isa('Venus::Array')) {
    for (my $i = 0; $i < @{$data->get}; $i++) {
      my $val = $data->get->[$i];
      $data->get->[$i] = ref($val)
        ? $self->class->new(value => $val)->deduce_deep
        : $self->class->new(value => $val)->deduce;
    }
  }

  return $data;
}

sub deduce_defined {
  my ($self) = @_;

  my $data = $self->get;

  return $self->deduce_references if ref($data);
  return $self->deduce_boolean if scalar_is_boolean($data);
  return $self->deduce_numberlike if scalar_is_numeric($data);
  return $self->deduce_stringlike;
}

sub deduce_numberlike {
  my ($self) = @_;

  my $data = $self->get;

  return $self->object_float if $data =~ /\./;
  return $self->object_number;
}

sub deduce_references {
  my ($self) = @_;

  my $data = $self->get;

  return $self->object_array if ref($data) eq 'ARRAY';
  return $self->object_code if ref($data) eq 'CODE';
  return $self->object_hash if ref($data) eq 'HASH';
  return $self->object_scalar; # glob, etc
}

sub deduce_stringlike {
  my ($self) = @_;

  my $data = $self->get;

  return $self->object_string;
}

sub detract {
  my ($self) = @_;

  my $data = $self->get;

  return $data if not(scalar_is_blessed($data));

  return $data->value if UNIVERSAL::isa($data, 'Venus::Kind');

  return $data;
}

sub detract_deep {
  my ($self) = @_;

  my $data = $self->detract;

  if ($data and ref($data) and ref($data) eq 'HASH') {
    for my $i (keys %{$data}) {
      my $val = $data->{$i};
      $data->{$i} = scalar_is_blessed($val)
        ? $self->class->new(value => $val)->detract_deep
        : $self->class->new(value => $val)->detract;
    }
  }
  if ($data and ref($data) and ref($data) eq 'ARRAY') {
    for (my $i = 0; $i < @{$data}; $i++) {
      my $val = $data->[$i];
      $data->[$i] = scalar_is_blessed($val)
        ? $self->class->new(value => $val)->detract_deep
        : $self->class->new(value => $val)->detract;
    }
  }

  return $data;
}

sub package {
  my ($self) = @_;

  my $data = $self->deduce;

  return ref($data);
}

sub object_array {
  my ($self) = @_;

  require Venus::Array;

  return Venus::Array->new([@{$self->get}]);
}

sub object_boolean {
  my ($self) = @_;

  require Venus::Boolean;

  return Venus::Boolean->new($self->get);
}

sub object_code {
  my ($self) = @_;

  require Venus::Code;

  return Venus::Code->new($self->get);
}

sub object_float {
  my ($self) = @_;

  require Venus::Float;

  return Venus::Float->new($self->get);
}

sub object_hash {
  my ($self) = @_;

  require Venus::Hash;

  return Venus::Hash->new({%{$self->get}});
}

sub object_number {
  my ($self) = @_;

  require Venus::Number;

  return Venus::Number->new($self->get);
}

sub object_regexp {
  my ($self) = @_;

  require Venus::Regexp;

  return Venus::Regexp->new($self->get);
}

sub object_scalar {
  my ($self) = @_;

  require Venus::Scalar;

  return Venus::Scalar->new($self->get);
}

sub object_string {
  my ($self) = @_;

  require Venus::String;

  return Venus::String->new($self->get);
}

sub object_undef {
  my ($self) = @_;

  require Venus::Undef;

  return Venus::Undef->new($self->get);
}

sub scalar_is_blessed {
  my ($value) = @_;

  return Scalar::Util::blessed($value);
}

sub scalar_is_boolean {
  my ($value) = @_;

  return Scalar::Util::isdual($value) && (
    ("$value" == "1" && ($value + 0) == 1) ||
    ("$value" == "0" && ($value + 0) == 0)
  );
}

sub scalar_is_numeric {
  my ($value) = @_;

  return Scalar::Util::looks_like_number($value) && length(do{
    no if $] >= 5.022, "feature", "bitwise";
    no warnings "numeric";
    $value & ""
  });
}

1;



=head1 NAME

Venus::Type - Type Class

=cut

=head1 ABSTRACT

Type Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Type;

  my $type = Venus::Type->new([]);

  # $type->code;

=cut

=head1 DESCRIPTION

This package provides methods for casting native data types to objects and the
reverse.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Accessible>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 code

  code() (Str | Undef)

The code method returns the name of the value's data type.

I<Since C<0.01>>

=over 4

=item code example 1

  # given: synopsis;

  my $code = $type->code;

  # "ARRAY"

=back

=over 4

=item code example 2

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => {});

  my $code = $type->code;

  # "HASH"

=back

=over 4

=item code example 3

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => qr//);

  my $code = $type->code;

  # "REGEXP"

=back

=cut

=head2 deduce

  deduce() (Object)

The deduce methods returns the argument as a data type object.

I<Since C<0.01>>

=over 4

=item deduce example 1

  # given: synopsis;

  my $deduce = $type->deduce;

  # bless({ value => [] }, "Venus::Array")

=back

=over 4

=item deduce example 2

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => {});

  my $deduce = $type->deduce;

  # bless({ value => {} }, "Venus::Hash")

=back

=over 4

=item deduce example 3

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => qr//);

  my $deduce = $type->deduce;

  # bless({ value => qr// }, "Venus::Regexp")

=back

=cut

=head2 deduce_deep

  deduce_deep() (Object)

The deduce_deep function returns any arguments as data type objects, including
nested data.

I<Since C<0.01>>

=over 4

=item deduce_deep example 1

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => [1..4]);

  my $deduce_deep = $type->deduce_deep;

  # bless({
  #   value => [
  #     bless({ value => 1 }, "Venus::Number"),
  #     bless({ value => 2 }, "Venus::Number"),
  #     bless({ value => 3 }, "Venus::Number"),
  #     bless({ value => 4 }, "Venus::Number"),
  #   ],
  # }, "Venus::Array")

=back

=over 4

=item deduce_deep example 2

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => {1..4});

  my $deduce_deep = $type->deduce_deep;

  # bless({
  #   value => {
  #     1 => bless({ value => 2 }, "Venus::Number"),
  #     3 => bless({ value => 4 }, "Venus::Number"),
  #   },
  # }, "Venus::Hash")

=back

=cut

=head2 detract

  detract() (Any)

The detract method returns the argument as native Perl data type value.

I<Since C<0.01>>

=over 4

=item detract example 1

  package main;

  use Venus::Type;
  use Venus::Hash;

  my $type = Venus::Type->new(Venus::Hash->new({1..4}));

  my $detract = $type->detract;

  # { 1 => 2, 3 => 4 }

=back

=over 4

=item detract example 2

  package main;

  use Venus::Type;
  use Venus::Array;

  my $type = Venus::Type->new(Venus::Array->new([1..4]));

  my $detract = $type->detract;

  # [1..4]

=back

=over 4

=item detract example 3

  package main;

  use Venus::Type;
  use Venus::Regexp;

  my $type = Venus::Type->new(Venus::Regexp->new(qr/\w+/));

  my $detract = $type->detract;

  # qr/\w+/

=back

=cut

=head2 detract_deep

  detract_deep() (Any)

The detract_deep method returns any arguments as native Perl data type values,
including nested data.

I<Since C<0.01>>

=over 4

=item detract_deep example 1

  package main;

  use Venus::Type;
  use Venus::Hash;

  my $type = Venus::Type->new(Venus::Hash->new({1..4}));

  my $detract_deep = Venus::Type->new($type->deduce_deep)->detract_deep;

  # { 1 => 2, 3 => 4 }

=back

=over 4

=item detract_deep example 2

  package main;

  use Venus::Type;
  use Venus::Array;

  my $type = Venus::Type->new(Venus::Array->new([1..4]));

  my $detract_deep = Venus::Type->new($type->deduce_deep)->detract_deep;

  # [1..4]

=back

=cut

=head2 package

  package() (Str)

The code method returns the package name of the objectified value, i.e.
C<ref()>.

I<Since C<0.01>>

=over 4

=item package example 1

  # given: synopsis;

  my $package = $type->package;

  # "Venus::Array"

=back

=over 4

=item package example 2

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => {});

  my $package = $type->package;

  # "Venus::Hash"

=back

=cut

=head1 AUTHORS

Cpanery, C<cpanery@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2021, Cpanery

Read the L<"license"|https://github.com/cpanery/venus/blob/master/LICENSE> file.

=cut