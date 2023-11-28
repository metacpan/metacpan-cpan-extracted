package Venus::Assert;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Buildable';

use overload (
  '&{}' => sub{$_[0]->validator},
  fallback => 1,
);

# ATTRIBUTES

attr 'name';

# BUILDERS

sub build_arg {
  my ($self, $name) = @_;

  return {
    name => $name,
  };
}

sub build_self {
  my ($self, $data) = @_;

  $self->conditions;

  return $self;
}

# METHODS

sub accept {
  my ($self, $name, @args) = @_;

  return $self if !$name;

  $self->check->accept($name, @args);

  return $self;
}

sub check {
  my ($self, @args) = @_;

  require Venus::Check;

  $self->{check} = $args[0] if @args;

  $self->{check} ||= Venus::Check->new;

  return $self->{check};
}

sub clear {
  my ($self) = @_;

  $self->check->clear;
  $self->constraint->clear;
  $self->coercion->clear;

  return $self;
}

sub coerce {
  my ($self, $data) = @_;

  return $self->coercion->result($self->value($data));
}

sub coercion {
  my ($self, @args) = @_;

  require Venus::Coercion;

  $self->{coercion} = $args[0] if @args;

  $self->{coercion} ||= Venus::Coercion->new->do('check', $self->check);

  return $self->{coercion};
}

sub conditions {
  my ($self) = @_;

  return $self;
}

sub constraint {
  my ($self, @args) = @_;

  require Venus::Constraint;

  $self->{constraint} = $args[0] if @args;

  $self->{constraint} ||= Venus::Constraint->new->do('check', $self->check);

  return $self->{constraint};
}

sub ensure {
  my ($self, @code) = @_;

  $self->constraint->ensure(@code);

  return $self;
}

sub expression {
  my ($self, $data) = @_;

  return $self if !$data;

  $data =
  $data =~ s/\s*\n+\s*/ /gr =~ s/^\s+|\s+$//gr =~ s/\[\s+/[/gr =~ s/\s+\]/]/gr;

  $self->name($data) if !$self->name;

  my $parsed = $self->parse($data);

  $self->accept(
    @{$parsed} > 0
    ? ((ref $parsed->[0] eq 'ARRAY') ? @{$parsed->[0]} : @{$parsed})
    : @{$parsed}
  );

  return $self;
}

sub format {
  my ($self, @code) = @_;

  $self->coercion->format(@code);

  return $self;
}

sub match {
  my ($self, @args) = @_;

  require Venus::Coercion;
  my $match = Venus::Coercion->new->accept(@args);

  push @{$self->matches}, sub {
    my ($source, $value) = @_;
    local $_ = $value;
    return $match->result($value);
  };

  return $match;
}

sub matches {
  my ($self) = @_;

  my $matches = $self->{'matches'} ||= [];

  return wantarray ? (@{$matches}) : $matches;
}

sub parse {
  my ($self, $expr) = @_;

  $expr ||= '';

  $expr =
  $expr =~ s/\s*\n+\s*/ /gr =~ s/^\s+|\s+$//gr =~ s/\[\s+/[/gr =~ s/\s+\]/]/gr;

  return _type_parse($expr);
}

sub received {
  my ($self, $data) = @_;

  require Scalar::Util;

  if (!defined $data) {
    return '';
  }

  my $blessed = Scalar::Util::blessed($data);
  my $isvenus = $blessed && $data->isa('Venus::Core') && $data->can('does');

  if (!$blessed && !ref $data) {
    return $data;
  }
  if ($blessed && ref($data) eq 'Regexp') {
    return "$data";
  }
  if ($isvenus && $data->does('Venus::Role::Explainable')) {
    return $self->dump(sub{$data->explain});
  }
  if ($isvenus && $data->does('Venus::Role::Valuable')) {
    return $self->dump(sub{$data->value});
  }
  if ($isvenus && $data->does('Venus::Role::Dumpable')) {
    return $data->dump;
  }
  if ($blessed && overload::Method($data, '""')) {
    return "$data";
  }
  if ($blessed && $data->can('as_string')) {
    return $data->as_string;
  }
  if ($blessed && $data->can('to_string')) {
    return $data->to_string;
  }
  if ($blessed && $data->isa('Venus::Kind')) {
    return $data->stringified;
  }
  else {
    return $self->dump(sub{$data});
  }
}

sub render {
  my ($self, $into, $data) = @_;

  return _type_render($into, $data);
}

sub result {
  my ($self, $data) = @_;

  return $self->coerce($self->validate($self->value($data)));
}

sub valid {
  my ($self, $data) = @_;

  return $self->constraint->result($self->value($data));
}

sub validate {
  my ($self, $data) = @_;

  my $valid = $self->valid($data);

  return $data if $valid;

  my $error = $self->check->catch('result');

  my $received = $self->received($data);

  my $message = join("\n\n",
    'Type:',
    ($self->name || 'Unknown'),
    'Failure:',
    $error->message,
    'Received:',
    (defined $data ? ($received eq '' ? '""' : $received) : ('(undefined)')),
  );

  $error->message($message);

  return $error->throw;
}

sub validator {
  my ($self) = @_;

  return $self->defer('validate');
}

sub value {
  my ($self, $data) = @_;

  my $result = $data;

  for my $match ($self->matches) {
    $result = $match->($self, $result);
  }

  return $result;
}

# ROUTINES

sub _type_parse {
  my @items = _type_parse_pipes(@_);

  my $either = @items > 1;

  @items = map _type_parse_nested($_), @items;

  return wantarray && !$either ? (@items) : [$either ? ("either") : (), @items];
}

sub _type_parse_lists {
  my @items = @_;

  my $r0 = '[\"\'\[\]]';
  my $r1 = '[^\"\'\[\]]';
  my $r2 = _type_subexpr_type_2();
  my $r3 = _type_subexpr_delimiter();

  return (
    grep length,
      map {split/,\s*(?=(?:$r1*$r0$r1*$r0)*$r1*$)(${r2}(?:${r3}[^,]*)?)?/}
        @items
  );
}

sub _type_parse_nested {
  my ($expr) = @_;

  return ($expr) if $expr !~ _type_regexp(_type_subexpr_type_2());

  my @items = ($expr);

  @items = ($expr =~ /^(\w+)\s*\[\s*(.*)\s*\]+$/g);

  @items = map _type_parse_lists($_), @items;

  @items = map +(
    $_ =~ qr/^@{[_type_subexpr_type_2()]},.*$/ ? _type_parse_lists($_) : $_
  ),
  @items;

  @items = map {s/^["']+|["']+$//gr} @items;

  @items = map _type_parse($_), @items;

  return (@items > 1 ? [@items] : @items);
}

sub _type_parse_pipes {
  my ($expr) = @_;

  my @items;

  # i.e. tuple[number, string] | tuple[string, number]
  if
  (
    _type_regexp_eval(
      $expr, _type_regexp(_type_subexpr_type_2(), _type_subexpr_type_2())
    )
  )
  {
    @items = map _type_parse_tuples($_),
      _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_2(), _type_subexpr_type_2()));
  }
  # i.e. string | tuple[number, string]
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_1(), _type_subexpr_type_2()))
  )
  {
    @items = map _type_parse_tuples($_),
      _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_1(), _type_subexpr_type_2()));
  }
  # i.e. tuple[number, string] | string
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_2(), _type_subexpr_type_1()))
  )
  {
    @items = map _type_parse_tuples($_),
      _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_2(), _type_subexpr_type_1()));
  }
  # special condition: i.e. tuple[number, string]
  elsif
  (
    _type_regexp_eval($expr, _type_regexp(_type_subexpr_type_2()))
  )
  {
    @items = ($expr);
  }
  # i.e. "..." | tuple[number, string]
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_3(), _type_subexpr_type_2()))
  )
  {
    @items = _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_3(), _type_subexpr_type_2()));
    @items = (_type_parse_pipes($items[0]), _type_parse_tuples($items[1]));
  }
  # i.e. tuple[number, string] | "..."
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_2(), _type_subexpr_type_3()))
  )
  {
    @items = _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_2(), _type_subexpr_type_3()));
    @items = (_type_parse_tuples($items[0]), _type_parse_pipes($items[1]));
  }
  # i.e. Package::Name | "..."
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_4(), _type_subexpr_type_3()))
  )
  {
    @items = _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_4(), _type_subexpr_type_3()));
    @items = ($items[0], _type_parse_pipes($items[1]));
  }
  # i.e. "..." | Package::Name
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_3(), _type_subexpr_type_4()))
  )
  {
    @items = _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_3(), _type_subexpr_type_4()));
    @items = (_type_parse_pipes($items[0]), $items[1]);
  }
  # i.e. string | "..."
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_1(), _type_subexpr_type_3()))
  )
  {
    @items = _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_1(), _type_subexpr_type_3()));
    @items = ($items[0], _type_parse_pipes($items[1]));
  }
  # i.e. "..." | string
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_3(), _type_subexpr_type_1()))
  )
  {
    @items = _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_3(), _type_subexpr_type_1()));
    @items = (_type_parse_pipes($items[0]), $items[1]);
  }
  # i.e. "..." | "..."
  elsif
  (
    _type_regexp_eval($expr,
      _type_regexp(_type_subexpr_type_3(), _type_subexpr_type_3()))
  )
  {
    @items = map _type_parse_pipes($_),
      _type_regexp_eval($expr,
      _type_regexp_groups(_type_subexpr_type_3(), _type_subexpr_type_3()));
  }
  else {
    @items = ($expr);
  }

  return (@items);
}

sub _type_parse_tuples {
  map +(scalar(_type_regexp_eval($_,
    _type_regexp(_type_subexpr_type_2(), _type_subexpr_type_2())))
      ? (_type_parse_pipes($_))
      : ($_)), @_
}

sub _type_regexp {
  qr/^@{[_type_regexp_joined(@_)]}$/
}

sub _type_regexp_eval {
  map {s/^\s+|\s+$//gr} ($_[0] =~ $_[1])
}

sub _type_regexp_groups {
  qr/^@{[_type_regexp_joined(_type_subexpr_groups(@_))]}$/
}

sub _type_regexp_joined {
  join(_type_subexpr_delimiter(), @_)
}

sub _type_render {
  my ($into, $data) = @_;

  if (ref $data eq 'HASH') {
    $data = join ', ', map +(qq("$_"), _type_render($into, $$data{$_})),
      sort keys %{$data};
    $data = "$into\[$data\]";
  }

  if (ref $data eq 'ARRAY') {
    $data = join ', ', map +(/^\w+$/ ? qq("$_") : $_), @{$data};
    $data = "$into\[$data\]";
  }

  return $data;
}

sub _type_subexpr_delimiter {
  '\s*\|\s*'
}

sub _type_subexpr_groups {
  map "($_)", @_
}

sub _type_subexpr_type_1 {
  '\w+'
}

sub _type_subexpr_type_2 {
  '\w+\s*\[.*\]+'
}

sub _type_subexpr_type_3 {
  '.*'
}

sub _type_subexpr_type_4 {
  '[A-Za-z][:\^\w]+\w*'
}

1;



=head1 NAME

Venus::Assert - Assert Class

=cut

=head1 ABSTRACT

Assert Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Assert;

  my $assert = Venus::Assert->new('Float');

  # $assert->accept('float');

  # $assert->format(sub{sprintf('%.2f', $_)});

  # $assert->result(123.456);

  # 123.46

=cut

=head1 DESCRIPTION

This package provides a mechanism for asserting type constraints and coercions
on data. Type constraints are handled via L<Venus::Constraint>, and coercions
are handled via L<Venus::Coercion>, using L<Venus::Check> to perform data type
validations.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 name

  name(string $data) (string)

The name attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<1.40>>

=over 4

=item name example 1

  # given: synopsis

  package main;

  my $set_name = $assert->name("Example");

  # "Example"

=back

=over 4

=item name example 2

  # given: synopsis

  # given: example-1 name

  package main;

  my $get_name = $assert->name;

  # "Example"

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 accept

  accept(string $name, any @args) (Venus::Assert)

The accept method registers a condition via L</check> based on the arguments
provided. The built-in types are defined as methods in L<Venus::Check>.

I<Since C<1.40>>

=over 4

=item accept example 1

  # given: synopsis

  package main;

  $assert = $assert->accept('float');

  # bless(..., "Venus::Assert")

  # $assert->valid;

  # false

  # $assert->valid(1.01);

  # true

=back

=over 4

=item accept example 2

  # given: synopsis

  package main;

  $assert = $assert->accept('number');

  # bless(..., "Venus::Assert")

  # $assert->valid(1.01);

  # false

  # $assert->valid(1_01);

  # true

=back

=over 4

=item accept example 3

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $assert = $assert->accept('object');

  # bless(..., "Venus::Assert")

  # $assert->valid;

  # false

  # $assert->valid(qr//);

  # false

  # $assert->valid(Example1->new);

  # true

  # $assert->valid(Example2->new);

  # true

=back

=over 4

=item accept example 4

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $assert = $assert->accept('Example1');

  # bless(..., "Venus::Assert")

  # $assert->valid;

  # false

  # $assert->valid(qr//);

  # false

  # $assert->valid(Example1->new);

  # true

  # $assert->valid(Example2->new);

  # false

=back

=cut

=head2 check

  check(Venus::Check $data) (Venus::Check)

The check method gets or sets the L<Venus::Check> object used for performing
runtime data type validation.

I<Since C<3.55>>

=over 4

=item check example 1

  # given: synopsis

  package main;

  my $check = $assert->check(Venus::Check->new);

  # bless(..., 'Venus::Check')

=back

=over 4

=item check example 2

  # given: synopsis

  package main;

  $assert->check(Venus::Check->new);

  my $check = $assert->check;

  # bless(..., 'Venus::Check')

=back

=cut

=head2 clear

  clear() (Venus::Assert)

The clear method resets the L</check>, L</constraint>, and L</coercion>
attributes and returns the invocant.

I<Since C<1.40>>

=over 4

=item clear example 1

  # given: synopsis

  package main;

  $assert->accept('string');

  $assert = $assert->clear;

  # bless(..., "Venus::Assert")

=back

=cut

=head2 coerce

  coerce(any $data) (any)

The coerce method dispatches to the L</coercion> object and returns the result
of the L<Venus::Coercion/result> operation.

I<Since C<3.55>>

=over 4

=item coerce example 1

  # given: synopsis

  package main;

  $assert->accept('float');

  $assert->format(sub{sprintf('%.2f', $_)});

  my $coerce = $assert->coerce(123.456);

  # 123.46

=back

=over 4

=item coerce example 2

  # given: synopsis

  package main;

  $assert->accept('string');

  $assert->format(sub{ucfirst lc $_});

  my $coerce = $assert->coerce('heLLo');

  # "Hello"

=back

=cut

=head2 coercion

  coercion(Venus::Coercion $data) (Venus::Coercion)

The coercion method gets or sets the L<Venus::Coercion> object used for
performing runtime data type coercions.

I<Since C<3.55>>

=over 4

=item coercion example 1

  # given: synopsis

  package main;

  my $coercion = $assert->coercion(Venus::Coercion->new);

  # bless(..., 'Venus::Coercion')

=back

=over 4

=item coercion example 2

  # given: synopsis

  package main;

  $assert->coercion(Venus::Coercion->new);

  my $coercion = $assert->coercion;

  # bless(..., 'Venus::Coercion')

=back

=cut

=head2 conditions

  conditions() (Venus::Assert)

The conditions method is an object construction hook that allows subclasses to
configure the object on construction setting up constraints and coercions and
returning the invocant.

I<Since C<1.40>>

=over 4

=item conditions example 1

  # given: synopsis

  package main;

  $assert = $assert->conditions;

  # bless(..., 'Venus::Assert')

=back

=over 4

=item conditions example 2

  package Example::Type::PositveNumber;

  use base 'Venus::Assert';

  sub conditions {
    my ($self) = @_;

    $self->accept('number', sub {
      $_ >= 0
    });

    return $self;
  }

  package main;

  my $assert = Example::Type::PositveNumber->new;

  # $assert->valid(0);

  # true

  # $assert->valid(1);

  # true

  # $assert->valid(-1);

  # false

=back

=cut

=head2 constraint

  constraint(Venus::Constraint $data) (Venus::Constraint)

The constraint method gets or sets the L<Venus::Constraint> object used for
performing runtime data type constraints.

I<Since C<3.55>>

=over 4

=item constraint example 1

  # given: synopsis

  package main;

  my $constraint = $assert->constraint(Venus::Constraint->new);

  # bless(..., 'Venus::Constraint')

=back

=over 4

=item constraint example 2

  # given: synopsis

  package main;

  $assert->constraint(Venus::Constraint->new);

  my $constraint = $assert->constraint;

  # bless(..., 'Venus::Constraint')

=back

=cut

=head2 ensure

  ensure(coderef $code) (Venus::Assert)

The ensure method registers a custom (not built-in) constraint condition and
returns the invocant.

I<Since C<3.55>>

=over 4

=item ensure example 1

  # given: synopsis

  package main;

  $assert->accept('number');

  my $ensure = $assert->ensure(sub {
    $_ >= 0
  });

  # bless(.., "Venus::Assert")

=back

=cut

=head2 expression

  expression(string $expr) (Venus::Assert)

The expression method parses a string representation of an type assertion,
registers the subexpressions using the L</accept> method, and returns the
invocant.

I<Since C<1.71>>

=over 4

=item expression example 1

  # given: synopsis

  package main;

  $assert = $assert->expression('string');

  # bless(..., 'Venus::Assert')

  # $assert->valid('hello');

  # true

  # $assert->valid(['goodbye']);

  # false

=back

=over 4

=item expression example 2

  # given: synopsis

  package main;

  $assert = $assert->expression('string | coderef');

  # bless(..., 'Venus::Assert')

  # $assert->valid('hello');

  # true

  # $assert->valid(sub{'hello'});

  # true

  # $assert->valid(['goodbye']);

  # false

=back

=over 4

=item expression example 3

  # given: synopsis

  package main;

  $assert = $assert->expression('string | coderef | Venus::Assert');

  # bless(..., 'Venus::Assert')

  # $assert->valid('hello');

  # true

  # $assert->valid(sub{'hello'});

  # true

  # $assert->valid($assert);

  # true

  # $assert->valid(['goodbye']);

  # false

=back

=over 4

=item expression example 4

  # given: synopsis

  package main;

  $assert = $assert->expression('Venus::Assert | within[arrayref, Venus::Assert]');

  # bless(..., 'Venus::Assert')

  # $assert->valid('hello');

  # false

  # $assert->valid(sub{'hello'});

  # false

  # $assert->valid($assert);

  # true

  # $assert->valid(['goodbye']);

  # false

  # $assert->valid([$assert]);

  # true

=back

=over 4

=item expression example 5

  # given: synopsis

  package main;

  $assert = $assert->expression('
    string
    | within[
        arrayref, within[
          hashref, string
        ]
      ]
  ');

  # bless(..., 'Venus::Assert')

  # $assert->valid('hello');

  # true

  # $assert->valid(sub{'hello'});

  # false

  # $assert->valid($assert);

  # false

  # $assert->valid([]);

  # false

  # $assert->valid([{'test' => ['okay']}]);

  # false

  # $assert->valid([{'test' => 'okay'}]);

  # true

=back

=cut

=head2 format

  format(coderef $code) (Venus::Assert)

The format method registers a custom (not built-in) coercion condition and
returns the invocant.

I<Since C<3.55>>

=over 4

=item format example 1

  # given: synopsis

  package main;

  $assert->accept('number');

  my $format = $assert->format(sub {
    sprintf '%.2f', $_
  });

  # bless(.., "Venus::Assert")

=back

=cut

=head2 parse

  parse(string $expr) (any)

The parse method accepts a string representation of a type assertion and
returns a data structure representing one or more method calls to be used for
validating the assertion signature.

I<Since C<2.01>>

=over 4

=item parse example 1

  # given: synopsis

  package main;

  my $parsed = $assert->parse('');

  # ['']

=back

=over 4

=item parse example 2

  # given: synopsis

  package main;

  my $parsed = $assert->parse('any');

  # ['any']

=back

=over 4

=item parse example 3

  # given: synopsis

  package main;

  my $parsed = $assert->parse('string | number');

  # ['either', 'string', 'number']

=back

=over 4

=item parse example 4

  # given: synopsis

  package main;

  my $parsed = $assert->parse('enum[up,down,left,right]');

  # [['enum', 'up', 'down', 'left', 'right']]

=back

=over 4

=item parse example 5

  # given: synopsis

  package main;

  my $parsed = $assert->parse('number | float | boolean');

  # ['either', 'number', 'float', 'boolean']

=back

=over 4

=item parse example 6

  # given: synopsis

  package main;

  my $parsed = $assert->parse('Example');

  # ['Example']

=back

=over 4

=item parse example 7

  # given: synopsis

  package main;

  my $parsed = $assert->parse('coderef | Venus::Code');

  # ['either', 'coderef', 'Venus::Code']

=back

=over 4

=item parse example 8

  # given: synopsis

  package main;

  my $parsed = $assert->parse('tuple[number, arrayref, coderef]');

  # [['tuple', 'number', 'arrayref', 'coderef']]

=back

=over 4

=item parse example 9

  # given: synopsis

  package main;

  my $parsed = $assert->parse('tuple[number, within[arrayref, hashref], coderef]');

  # [['tuple', 'number', ['within', 'arrayref', 'hashref'], 'coderef']]

=back

=over 4

=item parse example 10

  # given: synopsis

  package main;

  my $parsed = $assert->parse(
    'tuple[number, within[arrayref, hashref] | arrayref, coderef]'
  );

  # [
  #   ['tuple', 'number',
  #     ['either', ['within', 'arrayref', 'hashref'], 'arrayref'], 'coderef']
  # ]




=back

=over 4

=item parse example 11

  # given: synopsis

  package main;

  my $parsed = $assert->parse(
    'hashkeys["id", number | float, "upvotes", within[arrayref, boolean]]'
  );

  # [[
  #   'hashkeys',
  #   'id',
  #     ['either', 'number', 'float'],
  #   'upvotes',
  #     ['within', 'arrayref', 'boolean']
  # ]]

=back

=cut

=head2 render

  render(string $into, string $expression) (string)

The render method builds and returns a type expressions suitable for providing
to L</expression> based on the data provided.

I<Since C<2.55>>

=over 4

=item render example 1

  # given: synopsis

  package main;

  $assert = $assert->render;

  # undef

=back

=over 4

=item render example 2

  # given: synopsis

  package main;

  $assert = $assert->render(undef, 'string');

  # "string"

=back

=over 4

=item render example 3

  # given: synopsis

  package main;

  $assert = $assert->render('routines', ['say', 'say_pretty']);

  # 'routines["say", "say_pretty"]'

=back

=over 4

=item render example 4

  # given: synopsis

  package main;

  $assert = $assert->render('hashkeys', {id => 'number', name => 'string'});

  # 'hashkeys["id", number, "name", string]'

=back

=over 4

=item render example 5

  # given: synopsis

  package main;

  $assert = $assert->render('hashkeys', {
    id => 'number',
    profile => {
      level => 'string',
    },
  });

  # 'hashkeys["id", number, "profile", hashkeys["level", string]]'

=back

=cut

=head2 result

  result(any $data) (any)

The result method validates the value provided against the registered
constraints and if valid returns the result of the value having any registered
coercions applied. If the value is invalid an exception from L<Venus::Check>
will be thrown.

I<Since C<3.55>>

=over 4

=item result example 1

  # given: synopsis

  package main;

  $assert->accept('number')->format(sub{sprintf '%.2f', $_});

  my $result = $assert->result(1);

  # "1.00"

=back

=over 4

=item result example 2

  # given: synopsis

  package main;

  $assert->accept('number')->format(sub{sprintf '%.2f', $_});

  my $result = $assert->result('hello');

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 valid

  valid(any $data) (any)

The valid method dispatches to the L</constraint> object and returns the result
of the L<Venus::Constraint/result> operation.

I<Since C<3.55>>

=over 4

=item valid example 1

  # given: synopsis

  package main;

  $assert->accept('float');

  $assert->ensure(sub{$_ >= 1});

  my $valid = $assert->valid('1.00');

  # true

=back

=over 4

=item valid example 2

  # given: synopsis

  package main;

  $assert->accept('float');

  $assert->ensure(sub{$_ >= 1});

  my $valid = $assert->valid('0.99');

  # false

=back

=cut

=head2 validate

  validate(any $data) (any)

The validate method validates the value provided against the registered
constraints and if valid returns the value. If the value is invalid an
exception from L<Venus::Check> will be thrown.

I<Since C<3.55>>

=over 4

=item validate example 1

  # given: synopsis

  package main;

  $assert->accept('number');

  my $validate = $assert->validate(1);

  # 1

=back

=over 4

=item validate example 2

  # given: synopsis

  package main;

  $assert->accept('number');

  my $validate = $assert->validate('hello');

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=cut

=head2 validator

  validator(any @args) (coderef)

The validator method returns a coderef which calls the L</validate> method with
the invocant when called.

I<Since C<3.55>>

=over 4

=item validator example 1

  # given: synopsis

  package main;

  $assert->accept('string');

  my $validator = $assert->validator;

  # sub{...}

  # my $result = $validator->();

  # Exception! (isa Venus::Check::Error) (see error_on_coded)

=back

=over 4

=item validator example 2

  # given: synopsis

  package main;

  $assert->accept('string');

  my $validator = $assert->validator;

  # sub{...}

  # my $result = $validator->('hello');

  # "hello"

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