package Venus::Validate;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';
with 'Venus::Role::Encaseable';

# ATTRIBUTES

attr 'input';
attr 'issue';
attr 'path';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    input => [$data],
  };
}

sub build_args {
  my ($self, $data) = @_;

  if (!grep CORE::exists $data->{$_}, qw(input issue path)) {
    $data = {input => [$data]} if keys %{$data};
  }

  if (CORE::exists $data->{input}) {
    $data->{input} = ref $data->{input} eq 'ARRAY'
      ? ((@{$data->{input}} > 1) ? [$data->{input}] : $data->{input})
      : [$data->{input}];
  }
  else {
    $data->{input} = [];
  }

  return $data;
}

# METHODS

sub arrayref {
  my ($self) = @_;

  $self->type('arrayref');

  return $self;
}

sub boolean {
  my ($self) = @_;

  $self->type('boolean');

  return $self;
}

sub check {
  my ($self, $type, $name, $code, @args) = @_;

  return $self if $self->issue;

  return $self if !$type;

  $self->type($type);

  return $self if $self->issue;

  return $self if !$code;

  my $value = $self->value;

  if ((!CORE::defined($value) || $value eq '') && $self->presence eq 'required') {
    $self->issue_info($name, @args);

    return $self;
  }

  local $_ = $value;

  $self->issue_info($name, @args) if !$self->$code($value, @args);

  return $self;
}

sub defined {
  my ($self) = @_;

  $self->type('defined');

  return $self;
}

sub each {
  my ($self, $method, $path) = @_;

  my $result = [];

  $method ||= 'optional';

  my $node = (
    (CORE::defined($path))
      && $method eq 'optional'
      || $method eq 'present'
      || $method eq 'required'
  ) ? $self->$method($path) : $self;

  my $value = $node->value;

  if (ref $value eq 'ARRAY') {
    push @{$result}, $node->$method($_) for 0..$#${value};
  }
  else {
    push @{$result}, $node;
  }

  return wantarray ? @{$result} : $result;
}

sub errors {
  my ($self, $data) = @_;

  my $errors = $self->encased('errors');

  $errors = $self->recase('errors', ref $data eq 'ARRAY' ? $data : []) if !$errors;

  return wantarray ? @{$errors} : $errors;
}

sub exists {
  my ($self) = @_;

  my @value = $self->value;

  return @value ? true : false;
}

sub float {
  my ($self) = @_;

  $self->type('float');

  return $self;
}

sub hashref {
  my ($self) = @_;

  $self->type('hashref');

  return $self;
}

sub is_invalid {
  my ($self) = @_;

  my $invalid = $self->is_valid ? false : true;

  return $invalid;
}

sub is_valid {
  my ($self) = @_;

  my $valid = $self->issue ? false : true;

  return $valid;
}

sub issue_args {
  my ($self) = @_;

  my $issue = $self->issue;

  my $args = ref $issue eq 'ARRAY' ? $issue->[1] : [];

  return $args;
}

sub issue_info {
  my ($self, $type, @args) = @_;

  if ($type) {
    $self->issue([$type, [@args]]);

    push @{$self->errors}, [$self->path, $self->issue] if ref $self->errors eq 'ARRAY';
  }
  else {
    ($type, @args) = ($self->issue_type, @{$self->issue_args});
  }

  return wantarray ? ($type, @args) : $self->issue;
}

sub issue_type {
  my ($self) = @_;

  my $issue = $self->issue;

  my $type = ref $issue eq 'ARRAY' ? $issue->[0] : undef;

  return $type;
}

sub length {
  my ($self, $min_length, $max_length) = @_;

  $self->min_length($min_length);

  $self->max_length($max_length);

  return $self;
}

sub lowercase {
  my ($self) = @_;

  my $value = $self->value;

  if (CORE::defined($value) && !ref $value) {
    $self->value(lc $value);
  }

  return $self;
}

sub max_length {
  my ($self, $length) = @_;

  return $self if $self->issue;

  my $value = $self->value;

  if (ref $value) {
    $self->issue_info('max_length', $length);

    return $self;
  }

  if (!CORE::defined($value) && $self->presence eq 'optional') {
    return $self;
  }

  if ((!CORE::defined($value) || $value eq '') && $self->presence eq 'required') {
    $self->issue_info('max_length', $length);

    return $self;
  }

  if (CORE::length($value) > $length) {
    $self->issue_info('max_length', $length);
  }

  return $self;
}

sub max_number {
  my ($self, $maximum) = @_;

  return $self if $self->issue;

  my $value = $self->value;

  if (ref $value) {
    $self->issue_info('max_number', $maximum);

    return $self;
  }

  if (!CORE::defined($value) && $self->presence eq 'optional') {
    return $self;
  }

  if ((!CORE::defined($value) || $value eq '') && $self->presence eq 'required') {
    $self->issue_info('max_number', $maximum);

    return $self;
  }

  if ($value !~ /^-?\d+\.?\d*$/ || $value > $maximum) {
    $self->issue_info('max_number', $maximum);
  }

  return $self;
}

sub min_length {
  my ($self, $length) = @_;

  return $self if $self->issue;

  my $value = $self->value;

  if (ref $value) {
    $self->issue_info('min_length', $length);

    return $self;
  }

  if (!CORE::defined($value) && $self->presence eq 'optional') {
    return $self;
  }

  if ((!CORE::defined($value) || $value eq '') && $self->presence eq 'required') {
    $self->issue_info('min_length', $length);

    return $self;
  }

  if (CORE::length($value) < $length) {
    $self->issue_info('min_length', $length);
  }

  return $self;
}

sub min_number {
  my ($self, $minimum) = @_;

  return $self if $self->issue;

  my $value = $self->value;

  if (ref $value) {
    $self->issue_info('min_number', $minimum);

    return $self;
  }

  if (!CORE::defined($value) && $self->presence eq 'optional') {
    return $self;
  }

  if ((!CORE::defined($value) || $value eq '') && $self->presence eq 'required') {
    $self->issue_info('min_number', $minimum);

    return $self;
  }

  if ($value !~ /^-?\d+\.?\d*$/ || $value < $minimum) {
    $self->issue_info('min_number', $minimum);
  }

  return $self;
}

sub number {
  my ($self) = @_;

  $self->type('number');

  return $self;
}

sub on_invalid {
  my ($self, $code, @args) = @_;

  return $self if !$code || !$self->issue;

  local $_ = $self;

  return $self->$code(@args);
}

sub on_valid {
  my ($self, $code, @args) = @_;

  return $self if !$code || $self->issue;

  local $_ = $self;

  return $self->$code(@args);
}

sub optional {
  my ($self, $path) = @_;

  if (!CORE::defined($path)) {
    $self->recase('presence', 'optional');

    return $self;
  }

  my $node = $self->select($path);

  $node->recase('presence', 'optional');

  return $node;
}

sub pointer {
  my ($self, @path) = @_;

  my $pointer = join '.', grep defined, $self->path, @path;

  return $pointer;
}

sub presence {
  my ($self) = @_;

  my $presence = $self->encased('presence');

  return $presence || 'required';
}

sub present {
  my ($self, $path) = @_;

  my $node = CORE::defined($path) ? $self->select($path) : $self;

  $node->recase('presence', 'present');

  my @value = $node->value;

  $node->issue_info('present') if !@value;

  return $node;
}

sub required {
  my ($self, $path) = @_;

  my $node = CORE::defined($path) ? $self->select($path) : $self;

  $node->recase('presence', 'required');

  my @value = $node->value;

  return $node if @value && scalar grep defined, grep CORE::length, @value;

  $node->issue_info('required');

  return $node;
}

sub select {
  my ($self, $path) = @_;

  if (!CORE::defined($path)) {
    return $self;
  }

  my @value = $self->value;

  my $object;

  if (!$object && ref $value[0] eq 'ARRAY') {
    require Venus::Array;
    $object = Venus::Array->new(value => $value[0]);
  }

  if (!$object && ref $value[0] eq 'HASH') {
    require Venus::Hash;
    $object = Venus::Hash->new(value => $value[0]);
  }

  my ($data, $okay) =  ($object ? ($object->path($path)) : (undef, 0));

  my $node = $self->class->new(path => $self->pointer($path), input => [$okay ? $data : ()]);

  $node->errors(scalar $self->errors) if $self->errors;

  return $node;
}

sub string {
  my ($self) = @_;

  $self->type('string');

  return $self;
}

sub strip {
  my ($self) = @_;

  my $value = $self->value;

  if (CORE::defined($value) && !ref $value) {
    $value =~ s/\s{2,}/ /g;
    $self->value($value);
  }

  return $self;
}

sub sync {
  my ($self, $node) = @_;

  return $self if !$node;

  my @value = $node->value;

  return $self if !@value;

  @value = $self->value;

  my $object;

  if (!$object && ref $value[0] eq 'ARRAY') {
    require Venus::Array;
    $object = Venus::Array->new(value => $value[0]);
  }

  if (!$object && ref $value[0] eq 'HASH') {
    require Venus::Hash;
    $object = Venus::Hash->new(value => $value[0]);
  }

  if (!$object) {
    return $self;
  }

  $object->sets($node->path, $node->value);

  return $self;
}

sub titlecase {
  my ($self) = @_;

  my $value = $self->value;

  if (CORE::defined($value) && !ref $value) {
    $value =~ s/\b(\w)/\U$1/g;
    $self->value($value);
  }

  return $self;
}

sub trim {
  my ($self) = @_;

  my $value = $self->value;

  if (CORE::defined($value) && !ref $value) {
    $value =~ s/^\s+|\s+$//g;
    $self->value($value);
  }

  return $self;
}

sub type {
  my ($self, $expr) = @_;

  if ($self->issue) {
    return $self
  }

  my $value = $self->value;

  if (!CORE::defined($value) && $self->presence eq 'optional') {
    return $self;
  }

  $expr ||= 'any';

  require Venus::Type;

  my $type = Venus::Type->new;

  my $passed = $type->check($expr)->eval($value);

  $self->issue_info('type', $expr) if !$passed;

  return $self;
}

sub uppercase {
  my ($self) = @_;

  my $value = $self->value;

  if (CORE::defined($value) && !ref $value) {
    $self->value(uc $value);
  }

  return $self;
}

sub value {
  my ($self, @args) = @_;

  my $input = @args ? $self->input([@args]) : $self->input;

  return wantarray ? (@{$input}) : $input->[0];
}

sub yesno {
  my ($self) = @_;

  $self->type('yesno');

  return $self;
}

1;



=head1 NAME

Venus::Validate - Validate Class

=cut

=head1 ABSTRACT

Validate Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  # $validate->string->trim->strip;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=cut

=head1 DESCRIPTION

This package provides a mechanism for performing data validation of simple and
hierarchal data at runtime.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 issue

  issue(arrayref $issue) (arrayref)

The issue attribute is read/write, accepts C<(arrayref)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item issue example 1

  # given: synopsis;

  my $issue = $validate->issue([]);

  # []

=back

=over 4

=item issue example 2

  # given: synopsis;

  # given: example-1 issue;

  $issue = $validate->issue;

  # []

=back

=cut

=head2 path

  path(string $path) (string)

The path attribute is read/write, accepts C<(string)> values, is optional, and
defaults to C<".">.

I<Since C<4.15>>

=over 4

=item path example 1

  # given: synopsis;

  my $path = $validate->path('name');

  # "name"

=back

=over 4

=item path example 2

  # given: synopsis;

  # given: example-1 path;

  $path = $validate->path;

  # "name"

=back

=cut

=head2 input

  input(arrayref $input) (arrayref)

The input attribute is read/write, accepts C<(arrayref)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item input example 1

  # given: synopsis;

  my $input = $validate->input([]);

  # []

=back

=over 4

=item input example 2

  # given: synopsis;

  # given: example-1 input;

  $input = $validate->input;

  # []

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Encaseable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 arrayref

  arrayref() (Venus::Validate)

The arrayref method is shorthand for calling L</type> with C<"arrayref">. This
method is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item arrayref example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([1,2]);

  my $arrayref = $validate->arrayref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item arrayref example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({1..4});

  my $arrayref = $validate->arrayref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=over 4

=item arrayref example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([1..4]);

  my $arrayref = $validate->arrayref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=cut

=head2 boolean

  boolean() (Venus::Validate)

The boolean method is shorthand for calling L</type> with C<"boolean">. This
method is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item boolean example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(true);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item boolean example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(false);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item boolean example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=over 4

=item boolean example 4

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(0);

  my $boolean = $validate->boolean;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=cut

=head2 check

  check(string $type, string $name, string | coderef $callback, any @args) (Venus::Validate)

The check method provides a mechanism for performing a custom data validation
check. The first argument enables a data type check via L</type> based on the
type expression provided. The second argument is the name of the check being
performed, which will be used by L</issue_info> if the validation fails. The
remaining arguments are used in the callback provided which performs the custom
data validation.

I<Since C<4.15>>

=over 4

=item check example 1

  # given: synopsis

  package main;

  my $check = $validate->check;

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # true

=back

=over 4

=item check example 2

  # given: synopsis

  package main;

  my $check = $validate->check('string');

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # true

=back

=over 4

=item check example 3

  # given: synopsis

  package main;

  my $check = $validate->check('string', 'is_email', sub{
    /\w\@\w/
  });

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # false

  # $check->issue;

  # ['is_email', []]

=back

=over 4

=item check example 4

  # given: synopsis

  package main;

  $validate->value('hello@example.com');

  my $check = $validate->check('string', 'is_email', sub{
    /\w\@\w/
  });

  # bless(..., "Venus::Validate")

  # $check->is_valid;

  # true

  # $check->issue;

  # undef

=back

=cut

=head2 defined

  defined() (Venus::Validate)

The defined method is shorthand for calling L</type> with C<"defined">. This
method is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item defined example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $defined = $validate->defined;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item defined example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(undef);

  my $defined = $validate->defined;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=over 4

=item defined example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new;

  my $defined = $validate->defined;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=cut

=head2 each

  each(string $type, string $path) (within[arrayref, Venus::Validate])

The each method uses L</select> to retrieve data and for each item, builds a
L<Venus::Validate> object for the value, settings the object to C<"present">,
C<"required"> or C<"optional"> based on the argument provided, executing the
callback provided for each object, and returns list of objects created.
Defaults to C<"optional"> if no argument is provided. Returns a list in list
context.

I<Since C<4.15>>

=over 4

=item each example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(['hello', 'bonjour']);

  my $each = $validate->each;

  # [bless(..., "Venus::Validate"), ...]

=back

=over 4

=item each example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(['hello', 'bonjour']);

  my @each = $validate->each;

  # (bless(..., "Venus::Validate"), ...)

=back

=over 4

=item each example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(['hello', 'bonjour']);

  my $each = $validate->each('required');

  # [bless(..., "Venus::Validate"), ...]

=back

=over 4

=item each example 4

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    greetings => ['hello', 'bonjour'],
  });

  my $each = $validate->each('optional', 'greetings');

  # [bless(..., "Venus::Validate"), ...]

=back

=cut

=head2 errors

  errors(arrayref $data) (arrayref)

The errors method gets and sets the arrayref used by the current object and all
subsequent nodes to capture errors/issues encountered. Each element of the
arrayref will be an arrayref consisting of the node's L</path> and the
L</issue>. This method returns a list in list context.

I<Since C<4.15>>

=over 4

=item errors example 1

  # given: synopsis

  package main;

  my $errors = $validate->errors;

  # []

=back

=over 4

=item errors example 2

  # given: synopsis

  package main;

  my $errors = $validate->errors([]);

  # []

=back

=over 4

=item errors example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  $validate->errors([]);

  # []

  my $required = $validate->required('2.name');

  # bless(..., "Venus::Validate")

  my $errors = $validate->errors;

  # [['2.name', ['required', []]]]

=back

=over 4

=item errors example 4

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  $validate->errors([]);

  # []

  my $required = $validate->required('1.name');

  # bless(..., "Venus::Validate")

  $required->min_length(10);

  # bless(..., "Venus::Validate")

  my $errors = $validate->errors;

  # [['1.name', ['min_length', [10]]]]

=back

=over 4

=item errors example 5

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  $validate->errors([]);

  # []

  my $name_0 = $validate->required('0.name');

  # bless(..., "Venus::Validate")

  $name_0->min_length(10);

  # bless(..., "Venus::Validate")

  my $name_1 = $validate->required('1.name');

  # bless(..., "Venus::Validate")

  $name_1->min_length(10);

  # bless(..., "Venus::Validate")

  my $errors = $validate->errors;

  # [['0.name', ['min_length', [10]]], ['1.name', ['min_length', [10]]]]

=back

=cut

=head2 exists

  exists() (boolean)

The exists method returns true if a value exists for the current object, and
otherwise returns false.

I<Since C<4.15>>

=over 4

=item exists example 1

  # given: synopsis

  package main;

  my $exists = $validate->exists;

  # true

=back

=over 4

=item exists example 2

  # given: synopsis

  package main;

  $validate->value(undef);

  my $exists = $validate->exists;

  # true

=back

=over 4

=item exists example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new;

  my $exists = $validate->exists;

  # false

=back

=cut

=head2 float

  float() (Venus::Validate)

The float method is shorthand for calling L</type> with C<"float">. This method
is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item float example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1.23);

  my $float = $validate->float;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item float example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1_23);

  my $float = $validate->float;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=over 4

=item float example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new("1.23");

  my $float = $validate->float;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=cut

=head2 hashref

  hashref() (Venus::Validate)

The hashref method is shorthand for calling L</type> with C<"hashref">. This
method is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item hashref example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({1,2});

  my $hashref = $validate->hashref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item hashref example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([1..4]);

  my $hashref = $validate->hashref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=over 4

=item hashref example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({1..4});

  my $hashref = $validate->hashref;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=cut

=head2 is_invalid

  is_invalid() (boolean)

The is_invalid method returns true if an issue exists, and false otherwise.

I<Since C<4.15>>

=over 4

=item is_invalid example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $is_invalid = $validate->is_invalid;

  # false

=back

=over 4

=item is_invalid example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $is_invalid = $validate->is_invalid;

  # true

=back

=cut

=head2 is_valid

  is_valid() (boolean)

The is_valid method returns true if no issue exists, and false otherwise.

I<Since C<4.15>>

=over 4

=item is_valid example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $is_valid = $validate->is_valid;

  # true

=back

=over 4

=item is_valid example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $is_valid = $validate->is_valid;

  # false

=back

=cut

=head2 issue_args

  issue_args() (arrayref)

The issue_args method returns the arguments provided as part of the issue
context. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item issue_args example 1

  # given: synopsis;

  $validate->issue(['max_length', ['255']]);

  my $issue_args = $validate->issue_args;

  # ['255']

=back

=cut

=head2 issue_info

  issue_info(string $type, any @args) (tuple[string, arrayref])

The issue_info method gets or sets the issue context and returns the
L</issue_type> and L</issue_args>. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item issue_info example 1

  # given: synopsis;

  my $issue_info = $validate->issue_info;

  # undef

=back

=over 4

=item issue_info example 2

  # given: synopsis;

  my $issue_info = $validate->issue_info('max_length', '255');

  # ['max_length', ['255']]

=back

=over 4

=item issue_info example 3

  # given: synopsis;

  # given: example-2 issue_info

  $issue_info = $validate->issue_info;

  # ['max_length', ['255']]

=back

=over 4

=item issue_info example 4

  # given: synopsis;

  # given: example-2 issue_info

  my ($type, @args) = $validate->issue_info;

  # ('max_length', '255')

=back

=cut

=head2 issue_type

  issue_type() (string)

The issue_type method returns the issue type (i.e. type of issue) provided as
part of the issue context.

I<Since C<4.15>>

=over 4

=item issue_type example 1

  # given: synopsis;

  $validate->issue(['max_length', ['255']]);

  my $issue_type = $validate->issue_type;

  # 'max_length'

=back

=cut

=head2 length

  length(number $min, number $max) (Venus::Validate)

The length method accepts a minimum and maximum and validates that the length
of the data meets the criteria and returns the invocant. This method is a proxy
for the L</min_length> and L</max_length> methods and the errors/issues
encountered will be specific to those operations.

I<Since C<4.15>>

=over 4

=item length example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $length = $validate->length(1, 3);

  # bless(..., "Venus::Validate")

  # $length->issue;

  # ['min_length', [1]]

=back

=over 4

=item length example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $length = $validate->length(1, 3);

  # bless(..., "Venus::Validate")

  # $length->issue;

  # ['max_length', [3]]

=back

=cut

=head2 lowercase

  lowercase() (Venus::Validate)

The lowercase method lowercases the value and returns the invocant.

I<Since C<4.15>>

=over 4

=item lowercase example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('Hello world');

  my $lowercase = $validate->lowercase;

  # bless(..., "Venus::Validate")

  # $lowercase->value;

  # "hello world"

=back

=cut

=head2 max_length

  max_length(number $max) (Venus::Validate)

The max_length method accepts a maximum and validates that the length of the
data meets the criteria and returns the invocant. This method is a validator
and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item max_length example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $max_length = $validate->max_length(5);

  # bless(..., "Venus::Validate")

  # $max_length->issue;

  # undef

=back

=over 4

=item max_length example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $max_length = $validate->max_length(3);

  # bless(..., "Venus::Validate")

  # $max_length->issue;

  # ['max_length', [3]]

=back

=cut

=head2 max_number

  max_number(number $max) (Venus::Validate)

The max_number accepts a maximum and validates that the data is exactly the
number provided or less, and returns the invocant. This method is a validator
and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item max_number example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $max_number = $validate->max_number(1);

  # bless(..., "Venus::Validate")

  # $max_number->issue;

  # undef

=back

=over 4

=item max_number example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $max_number = $validate->max_number(0);

  # bless(..., "Venus::Validate")

  # $max_number->issue;

  # ['max_number', [0]]

=back

=cut

=head2 min_length

  min_length(number $min) (Venus::Validate)

The min_length accepts a minimum and validates that the length of the data
meets the criteria and returns the invocant. This method is a validator and
uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item min_length example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $min_length = $validate->min_length(1);

  # bless(..., "Venus::Validate")

  # $min_length->issue;

  # undef

=back

=over 4

=item min_length example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $min_length = $validate->min_length(1);

  # bless(..., "Venus::Validate")

  # $min_length->issue;

  # ['min_length', [1]]

=back

=cut

=head2 min_number

  min_number(number $min) (Venus::Validate)

The min_number accepts a minimum and validates that the data is exactly the
number provided or greater, and returns the invocant. This method is a
validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item min_number example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $min_number = $validate->min_number(1);

  # bless(..., "Venus::Validate")

  # $min_number->issue;

  # undef

=back

=over 4

=item min_number example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $min_number = $validate->min_number(2);

  # bless(..., "Venus::Validate")

  # $min_number->issue;

  # ['min_number', [2]]

=back

=cut

=head2 new

  new(hashref $data) (Venus::Validate)

The new method returns a L<Venus::Validate> object.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new;

  # bless(..., "Venus::Validate")

=back

=over 4

=item new example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(input => 'hello');

  # bless(..., "Venus::Validate")

=back

=over 4

=item new example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({input => 'hello'});

  # bless(..., "Venus::Validate")

=back

=over 4

=item new example 4

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  # bless(..., "Venus::Validate")

=back

=cut

=head2 number

  number() (Venus::Validate)

The number method is shorthand for calling L</type> with C<"number">. This
method is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item number example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(123);

  my $number = $validate->number;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item number example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1.23);

  my $number = $validate->number;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=over 4

=item number example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1_23);

  my $number = $validate->number;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=cut

=head2 on_invalid

  on_invalid(coderef $callback, any @args) (Venus::Validate)

The on_invalid method chains an operations by passing the issue value of the
object to the callback provided and returns a L<Venus::Validate> object.

I<Since C<4.15>>

=over 4

=item on_invalid example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $on_invalid = $validate->on_invalid;

  # bless(..., "Venus::Validate")

=back

=over 4

=item on_invalid example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->number;

  my $on_invalid = $validate->on_invalid(sub{
    $validate->{called} = time;
    return $validate;
  });

  # bless(..., "Venus::Validate")

=back

=cut

=head2 on_valid

  on_valid(coderef $callback, any @args) (Venus::Validate)

The on_valid method chains an operations by passing the value of the object to
the callback provided and returns a L<Venus::Validate> object.

I<Since C<4.15>>

=over 4

=item on_valid example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $on_valid = $validate->on_valid;

  # bless(..., "Venus::Validate")

=back

=over 4

=item on_valid example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello')->string;

  my $on_valid = $validate->on_valid(sub{
    $validate->{called} = time;
    return $validate;
  });

  # bless(..., "Venus::Validate")

=back

=cut

=head2 optional

  optional(string $path) (Venus::Validate)

The optional method uses L</select> to retrieve data and returns a
L<Venus::Validate> object with the selected data marked as optional.

I<Since C<4.15>>

=over 4

=item optional example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
  });

  my $optional = $validate->optional('email');

  # bless(..., "Venus::Validate")

  # $optional->is_valid;

  # true

=back

=over 4

=item optional example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
    email => 'johndoe@example.com',
  });

  my $optional = $validate->optional('email');

  # bless(..., "Venus::Validate")

  # $optional->is_valid;

  # true

=back

=cut

=head2 present

  present(string $path) (Venus::Validate)

The present method uses L</select> to retrieve data and returns a
L<Venus::Validate> object with the selected data marked as needing to be
present. This method is a validator and uses L</issue_info> to capture
validation errors.

I<Since C<4.15>>

=over 4

=item present example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
  });

  my $present = $validate->present('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # false

=back

=over 4

=item present example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
    email => 'johndoe@example.com',
  });

  my $present = $validate->present('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # true

=back

=cut

=head2 required

  required(string $path) (Venus::Validate)

The required method uses L</select> to retrieve data and returns a
L<Venus::Validate> object with the selected data marked as required. This
method is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item required example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
  });

  my $required = $validate->required('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # false

=back

=over 4

=item required example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    fname => 'John',
    lname => 'Doe',
    email => 'johndoe@example.com',
  });

  my $required = $validate->required('email');

  # bless(..., "Venus::Validate")

  # $present->is_valid;

  # true

=back

=cut

=head2 select

  select(string $path) (Venus::Validate)

The select method uses L<Venus::Hash/path> to retrieve data and returns a
L<Venus::Validate> object with the selected data. Returns C<undef> if the data
can't be selected.

I<Since C<4.15>>

=over 4

=item select example 1

  # given: synopsis;

  my $select = $validate->select;

  # bless(..., "Venus::Validate")

=back

=over 4

=item select example 2

  # given: synopsis;

  my $select = $validate->select('ello');

  # bless(..., "Venus::Validate")

=back

=over 4

=item select example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  my $select = $validate->select('0.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "john"

=back

=over 4

=item select example 4

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([
    {
      name => 'john',
    },
    {
      name => 'jane',
    },
  ]);

  my $select = $validate->select('1.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "jane"

=back

=over 4

=item select example 5

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    persons => [
      {
        name => 'john',
      },
      {
        name => 'jane',
      },
    ]
  });

  my $select = $validate->select('persons.0.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "john"

=back

=over 4

=item select example 6

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({
    persons => [
      {
        name => 'john',
      },
      {
        name => 'jane',
      },
    ]
  });

  my $select = $validate->select('persons.1.name');

  # bless(..., "Venus::Validate")

  # $select->value;

  # "jane"

=back

=cut

=head2 string

  string() (Venus::Validate)

The string method is shorthand for calling L</type> with C<"string">. This
method is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item string example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $string = $validate->string;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item string example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('');

  my $string = $validate->string;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item string example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('1.23');

  my $string = $validate->string;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=cut

=head2 strip

  strip() (Venus::Validate)

The strip method removes multiple consecutive whitespace characters from the
value and returns the invocant.

I<Since C<4.15>>

=over 4

=item strip example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello    world');

  my $strip = $validate->strip;

  # bless(..., "Venus::Validate")

  # $strip->value;

  # "hello world"

=back

=over 4

=item strip example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({text => 'hello    world'});

  my $strip = $validate->strip;

  # bless(..., "Venus::Validate")

  # $strip->value;

  # {text => 'hello    world'}

=back

=cut

=head2 sync

  sync(Venus::Validate $node) (Venus::Validate)

The sync method merges the L<Venus::Validate> node provided with the current
object.

I<Since C<4.15>>

=over 4

=item sync example 1

  # given: synopsis;

  my $sync = $validate->sync;

  # bless(..., "Venus::Validate")

=back

=over 4

=item sync example 2

  package main;

  use Venus::Validate;

  my $root = Venus::Validate->new({
    persons => [
      {
        name => 'john',
      },
      {
        name => 'jane',
      },
    ]
  });

  my $node = $root->select('persons.1.name');

  # bless(..., "Venus::Validate")

  $node->value('jack');

  # "jack"

  # $root->select('persons.1.name')->value;

  # "john"

  $root->sync($node);

  # bless(..., "Venus::Validate")

  # $root->select('persons.1.name')->value;

  # "jack"

=back

=over 4

=item sync example 3

  package main;

  use Venus::Validate;

  my $root = Venus::Validate->new(['john', 'jane']);

  my $node = $root->select(1);

  # bless(..., "Venus::Validate")

  $node->value('jill');

  # "jill"

  # $root->select(1)->value;

  # "jane"

  $root->sync($node);

  # bless(..., "Venus::Validate")

  # $root->select(1)->value;

  # "jill"

=back

=cut

=head2 titlecase

  titlecase() (Venus::Validate)

The titlecase method titlecases the value and returns the invocant.

I<Since C<4.15>>

=over 4

=item titlecase example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello world');

  my $titlecase = $validate->titlecase;

  # bless(..., "Venus::Validate")

  # $titlecase->value;

  # "Hello World"

=back

=cut

=head2 trim

  trim() (Venus::Validate)

The trim method removes whitespace characters from both ends of the value and
returns the invocant.

I<Since C<4.15>>

=over 4

=item trim example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('  hello world  ');

  my $trim = $validate->trim;

  # bless(..., "Venus::Validate")

  # $trim->value;

  # "hello world"

=back

=over 4

=item trim example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new({text => '  hello world  '});

  my $trim = $validate->trim;

  # bless(..., "Venus::Validate")

  # $trim->value;

  # {text => '  hello world  '}

=back

=cut

=head2 type

  type(string $type) (Venus::Validate)

The type method validates that the value conforms with the L<Venus::Type> type
expression provided, and returns the invocant. This method is a validator and
uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item type example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $type = $validate->type;

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=back

=over 4

=item type example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $type = $validate->type('string');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=back

=over 4

=item type example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $type = $validate->type('number');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # false

=back

=over 4

=item type example 4

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('Y');

  my $type = $validate->type('yesno');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=back

=over 4

=item type example 5

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('A');

  my $type = $validate->type('enum[A, B]');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=back

=over 4

=item type example 6

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new([200, [], '']);

  my $type = $validate->type('tuple[number, arrayref, string]');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=back

=over 4

=item type example 7

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(undef);

  my $type = $validate->type('string');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=back

=over 4

=item type example 8

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(undef);

  my $type = $validate->optional->type('string');

  # bless(..., "Venus::Validate")

  # $type->is_valid;

  # true

=back

=cut

=head2 uppercase

  uppercase() (Venus::Validate)

The uppercase method uppercases the value and returns the invocant.

I<Since C<4.15>>

=over 4

=item uppercase example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello world');

  my $uppercase = $validate->uppercase;

  # bless(..., "Venus::Validate")

  # $uppercase->value;

  # "HELLO WORLD"

=back

=cut

=head2 value

  value() (any)

The value method returns the value being validated.

I<Since C<4.15>>

=over 4

=item value example 1

  # given: synopsis;

  my $value = $validate->value;

  # "hello"

=back

=cut

=head2 yesno

  yesno() (Venus::Validate)

The yesno method is shorthand for calling L</type> with C<"yesno">. This method
is a validator and uses L</issue_info> to capture validation errors.

I<Since C<4.15>>

=over 4

=item yesno example 1

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('Yes');

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item yesno example 2

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('No');

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item yesno example 3

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(1);

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item yesno example 4

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new(0);

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # true

=back

=over 4

=item yesno example 5

  package main;

  use Venus::Validate;

  my $validate = Venus::Validate->new('hello');

  my $yesno = $validate->yesno;

  # bless(..., "Venus::Validate")

  # $validate->is_valid;

  # false

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut