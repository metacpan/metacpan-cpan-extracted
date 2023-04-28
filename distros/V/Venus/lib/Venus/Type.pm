package Venus::Type;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';

use Scalar::Util ();

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data
  };
}

sub build_args {
  my ($self, $data) = @_;

  if (keys %$data == 1 && exists $data->{value}) {
    return $data;
  }
  elsif (keys %$data) {
    return {
      value => $data,
    }
  }
  else {
    return {
      value => $self->default
    };
  }
}

sub build_nil {
  my ($self, $data) = @_;

  return {
    value => $data
  };
}

# METHODS

sub cast {
  my ($self, $kind, $callback, @args) = @_;

  my $code = $self->code;

  return undef if !$code;

  my $method = join '_', map lc, 'from', $code, 'to', $kind || $code;

  my $result = $self->$method($self->value);

  local $_ = $result;

  $result = Venus::Type->new($result->$callback(@args))->deduce if $callback;

  return $result;
}

sub code {
  my ($self) = @_;

  return scalar $self->identify;
}

sub coded {
  my ($self, $code) = @_;

  return uc($self->code) eq uc("$code");
}

sub deduce {
  my ($self) = @_;

  my $data = $self->get;

  return $self->into_undef if not(defined($data));
  return $self->deduce_blessed if scalar_is_blessed($data);
  return $self->deduce_defined;
}

sub deduce_boolean {
  my ($self) = @_;

  my $data = $self->get;

  return $self->into_boolean;
}

sub deduce_blessed {
  my ($self) = @_;

  my $data = $self->get;

  return $self->into_regexp if $data->isa('Regexp');
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
  return $self->deduce_floatlike if scalar_is_float($data);
  return $self->deduce_numberlike if scalar_is_numeric($data);
  return $self->deduce_stringlike;
}

sub deduce_floatlike {
  my ($self) = @_;

  my $data = $self->get;

  return $self->into_float;
}

sub deduce_numberlike {
  my ($self) = @_;

  my $data = $self->get;

  return $self->into_number;
}

sub deduce_references {
  my ($self) = @_;

  my $data = $self->get;

  return $self->into_array if ref($data) eq 'ARRAY';
  return $self->into_code if ref($data) eq 'CODE';
  return $self->into_hash if ref($data) eq 'HASH';
  return $self->into_scalar; # glob, etc
}

sub deduce_stringlike {
  my ($self) = @_;

  my $data = $self->get;

  return $self->into_string;
}

sub default {

  return undef;
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

sub from_array_to_array {
  my ($self, $data) = @_;

  return $self->into_array($data);
}

sub from_array_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean(1);
}

sub from_array_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_array_to_float {
  my ($self, $data) = @_;

  return $self->into_float(join('.', map int, !!$data, 0));
}

sub from_array_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({map +($_, $data->[$_]), 0..$#$data});
}

sub from_array_to_number {
  my ($self, $data) = @_;

  return $self->into_number(length($self->dump('value')));
}

sub from_array_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[quotemeta($self->dump('value'))]}});
}

sub from_array_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_array_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_array_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_boolean_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_boolean_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean($data);
}

sub from_boolean_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_boolean_to_float {
  my ($self, $data) = @_;

  return $self->into_float(join('.', map int, !!$data, 0));
}

sub from_boolean_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({$data, $data});
}

sub from_boolean_to_number {
  my ($self, $data) = @_;

  return $self->into_number(0+!!$data);
}

sub from_boolean_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[$self->dump('value')]}});
}

sub from_boolean_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_boolean_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_boolean_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_code_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_code_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean(1);
}

sub from_code_to_code {
  my ($self, $data) = @_;

  return $self->into_code($data);
}

sub from_code_to_float {
  my ($self, $data) = @_;

  return $self->into_float(join('.', map int, !!$data, 0));
}

sub from_code_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({0, $data});
}

sub from_code_to_number {
  my ($self, $data) = @_;

  return $self->into_number(length($self->dump('value')));
}

sub from_code_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[quotemeta($self->dump('value'))]}});
}

sub from_code_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_code_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_code_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_float_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_float_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean($data);
}

sub from_float_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_float_to_float {
  my ($self, $data) = @_;

  return $self->into_float($data);
}

sub from_float_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({$data, $data});
}

sub from_float_to_number {
  my ($self, $data) = @_;

  return $self->into_number(0+$data);
}

sub from_float_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[quotemeta($self->dump('value'))]}});
}

sub from_float_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_float_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_float_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_hash_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_hash_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean(1);
}

sub from_hash_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_hash_to_float {
  my ($self, $data) = @_;

  return $self->into_float(join('.', map int, !!$data, 0));
}

sub from_hash_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash($data);
}

sub from_hash_to_number {
  my ($self, $data) = @_;

  return $self->into_number(length($self->dump('value')));
}

sub from_hash_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[quotemeta($self->dump('value'))]}});
}

sub from_hash_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_hash_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_hash_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_number_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_number_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean(!!$data);
}

sub from_number_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_number_to_float {
  my ($self, $data) = @_;

  return $self->into_float(join('.', map int, (split(/\./, "${data}.0"))[0,1]));
}

sub from_number_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({$data, $data});
}

sub from_number_to_number {
  my ($self, $data) = @_;

  return $self->into_number($data);
}

sub from_number_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[quotemeta($self->dump('value'))]}});
}

sub from_number_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_number_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_number_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_regexp_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_regexp_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean($data);
}

sub from_regexp_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_regexp_to_float {
  my ($self, $data) = @_;

  return $self->into_float(join('.', map int, !!$data, 0));
}

sub from_regexp_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({0, $data});
}

sub from_regexp_to_number {
  my ($self, $data) = @_;

  return $self->into_number(length($self->dump('value')));
}

sub from_regexp_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp($data);
}

sub from_regexp_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_regexp_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_regexp_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_scalar_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_scalar_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean(1);
}

sub from_scalar_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_scalar_to_float {
  my ($self, $data) = @_;

  return $self->into_float(join('.', map int, !!$data, 0));
}

sub from_scalar_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({0, $data});
}

sub from_scalar_to_number {
  my ($self, $data) = @_;

  return $self->into_number(length($self->dump('value')));
}

sub from_scalar_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[quotemeta($self->dump('value'))]}});
}

sub from_scalar_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar($data);
}

sub from_scalar_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_scalar_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_string_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_string_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean(!!$data);
}

sub from_string_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_string_to_float {
  my ($self, $data) = @_;

  require Scalar::Util;

  return $self->into_float(join('.',
    Scalar::Util::looks_like_number($data) ? (split(/\./, "$data.0"))[0,1] : (0,0))
  );
}

sub from_string_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({$data, $data});
}

sub from_string_to_number {
  my ($self, $data) = @_;

  require Scalar::Util;

  return $self->into_number(Scalar::Util::looks_like_number($data) ? 0+$data : 0);
}

sub from_string_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr{@{[$self->dump('value')]}});
}

sub from_string_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\$data);
}

sub from_string_to_string {
  my ($self, $data) = @_;

  return $self->into_string($self->dump('value'));
}

sub from_string_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub from_undef_to_array {
  my ($self, $data) = @_;

  return $self->into_array([$data]);
}

sub from_undef_to_boolean {
  my ($self, $data) = @_;

  return $self->into_boolean(0);
}

sub from_undef_to_code {
  my ($self, $data) = @_;

  return $self->into_code(sub{$data});
}

sub from_undef_to_float {
  my ($self, $data) = @_;

  return $self->into_float('0.0');
}

sub from_undef_to_hash {
  my ($self, $data) = @_;

  return $self->into_hash({});
}

sub from_undef_to_number {
  my ($self, $data) = @_;

  return $self->into_number(0);
}

sub from_undef_to_regexp {
  my ($self, $data) = @_;

  return $self->into_regexp(qr//);
}

sub from_undef_to_scalar {
  my ($self, $data) = @_;

  return $self->into_scalar(\'');
}

sub from_undef_to_string {
  my ($self, $data) = @_;

  return $self->into_string('');
}

sub from_undef_to_undef {
  my ($self, $data) = @_;

  return $self->into_undef($data);
}

sub identify {
  my ($self) = @_;

  my $data = $self->get;

  my $defined = true;
  my $blessed = false;

  my $type_name;

  if (not(defined($data))) {
    $type_name = 'UNDEF';
    $defined = false;
  }
  elsif (scalar_is_blessed($data)) {
    $type_name = $data->isa('Regexp') ? 'REGEXP' : 'OBJECT';
    $blessed = true;
  }
  elsif (ref($data)) {
    if (ref($data) eq 'ARRAY') {
      $type_name = 'ARRAY';
    }
    elsif (ref($data) eq 'CODE') {
      $type_name = 'CODE';
    }
    elsif (ref($data) eq 'HASH') {
      $type_name = 'HASH';
    }
    else {
      $type_name = 'SCALAR';
    }
  }
  elsif (scalar_is_boolean($data)) {
    $type_name = 'BOOLEAN';
  }
  elsif (scalar_is_float($data)) {
    $type_name = 'FLOAT';
  }
  elsif (scalar_is_numeric($data)) {
    $type_name = 'NUMBER';
  }
  else {
    $type_name = 'STRING';
  }

  return wantarray ? ($defined, $blessed, $type_name) : $type_name;
}

sub into_array {
  my ($self, $data) = @_;

  $data = [@{$self->get}] if $#_ <= 0;

  require Venus::Array;

  return Venus::Array->new($data);
}

sub into_boolean {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::Boolean;

  return Venus::Boolean->new($data);
}

sub into_code {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::Code;

  return Venus::Code->new($data);
}

sub into_float {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::Float;

  return Venus::Float->new($data);
}

sub into_hash {
  my ($self, $data) = @_;

  $data = {%{$self->get}} if $#_ <= 0;

  require Venus::Hash;

  return Venus::Hash->new($data);
}

sub into_number {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::Number;

  return Venus::Number->new($data);
}

sub into_regexp {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::Regexp;

  return Venus::Regexp->new($data);
}

sub into_scalar {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::Scalar;

  return Venus::Scalar->new($data);
}

sub into_string {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::String;

  return Venus::String->new($data);
}

sub into_undef {
  my ($self, $data) = @_;

  $data = $self->get if $#_ <= 0;

  require Venus::Undef;

  return Venus::Undef->new($data);
}

sub package {
  my ($self) = @_;

  my $data = $self->deduce;

  return ref($data);
}

sub scalar_is_blessed {
  my ($value) = @_;

  return Scalar::Util::blessed($value);
}

sub scalar_is_boolean {
  my ($value) = @_;

  return Scalar::Util::isdual($value) && (
    ("$value" eq "" && ($value + 0) == 0) || # support !!0
    ("$value" == "1" && ($value + 0) == 1) ||
    ("$value" == "0" && ($value + 0) == 0)
  );
}

sub scalar_is_float {
  my ($value) = @_;

  return Scalar::Util::looks_like_number($value) && length(do{
    $value =~ /^[+-]?([0-9]*)?\.[0-9]+$/;
  });
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

L<Venus::Role::Buildable>

L<Venus::Role::Valuable>

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

=head2 coded

  coded(Str $code) (Bool)

The coded method return true or false if the data type name provided matches
the result of L</code>.

I<Since C<1.23>>

=over 4

=item coded example 1

  # given: synopsis;

  my $coded = $type->coded('ARRAY');

  # 1

=back

=over 4

=item coded example 2

  # given: synopsis;

  my $coded = $type->coded('HASH');

  # 0

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

=over 4

=item deduce example 4

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => '1.23');

  my $deduce = $type->deduce;

  # bless({ value => "1.23" }, "Venus::Float")

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

=over 4

=item detract example 4

  package main;

  use Venus::Type;
  use Venus::Float;

  my $type = Venus::Type->new(Venus::Float->new('1.23'));

  my $detract = $type->detract;

  # "1.23"

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

=head2 identify

  identify() (Bool, Bool, Str)

The identify method returns the value's data type, or L</code>, in scalar
context. In list context, this method will return a tuple with (defined,
blessed, and data type) elements. B<Note:> For globs and file handles this
method will return "scalar" as the data type.

I<Since C<1.23>>

=over 4

=item identify example 1

  # given: synopsis

  package main;

  my ($defined, $blessed, $typename) = $type->identify;

  # (1, 0, 'ARRAY')

=back

=over 4

=item identify example 2

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => {});

  my ($defined, $blessed, $typename) = $type->identify;

  # (1, 0, 'HASH')

=back

=over 4

=item identify example 3

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => qr//);

  my ($defined, $blessed, $typename) = $type->identify;

  # (1, 1, 'REGEXP')

=back

=over 4

=item identify example 4

  package main;

  use Venus::Type;

  my $type = Venus::Type->new(value => bless{});

  my ($defined, $blessed, $typename) = $type->identify;

  # (1, 1, 'OBJECT')

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

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut