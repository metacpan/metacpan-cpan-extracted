package Venus::Type;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';

# STATE

state $SIMPLE_TYPES = {
  any => 'any',
  array => 'array',
  arrayref => 'arrayref',
  bool => 'bool',
  boolean => 'boolean',
  code => 'code',
  coderef => 'coderef',
  defined => 'defined',
  dirhandle => 'dirhandle',
  filehandle => 'filehandle',
  float => 'float',
  glob => 'glob',
  hash => 'hash',
  hashref => 'hashref',
  identity => 'identity',
  number => 'number',
  object => 'object',
  package => 'package',
  reference => 'reference',
  regexp => 'regexp',
  scalar => 'scalar',
  scalarref => 'scalarref',
  string => 'string',
  undef => 'undef',
  value => 'value',
  yesno => 'yesno',
};

state $COMPLEX_TYPES = {
  attributes => 'attributes',
  consumes => 'consumes',
  either => 'either',
  hashkeys => 'hashkeys',
  includes => 'includes',
  inherits => 'inherits',
  integrates => 'integrates',
  maybe => 'maybe',
  routines => 'routines',
  tuple => 'tuple',
  within => 'within',
};

# METHODS

sub assert {
  my ($self, $expr) = @_;

  require Venus::Assert;

  return Venus::Assert->new->accept($self->offer($expr));
}

sub check {
  my ($self, $expr) = @_;

  require Venus::Check;

  return Venus::Check->new->accept($self->offer($expr));
}

sub clean {
  my ($self, $expr) = @_;

  return '' if !defined $expr;

  $expr =~ s/\n//g;
  $expr =~ s/^\s+|\s+$//g;

  return $expr;
}

sub coercion {
  my ($self, $expr) = @_;

  require Venus::Coercion;

  return Venus::Coercion->new->accept($self->offer($expr));
}

sub constraint {
  my ($self, $expr) = @_;

  require Venus::Constraint;

  return Venus::Constraint->new->accept($self->offer($expr));
}

sub expression {
  my ($self, $data) = @_;

  return ref $data eq 'ARRAY' ? $self->generate_expression($data) : $self->parse_expression($data);
}

sub parse_expression {
  my ($self, $expr) = @_;

  return $self->parser_parse_expression($self->clean($expr));
}

sub parse_signature {
  my ($self, $expr) = @_;

  $expr = $self->clean($expr);

  my $pattern = qr/^(\w+)\s*\((.*?)\)\s*\((.*?)\)$/;

  my ($name, $input_types, $output_types) = ($expr =~ $pattern);

  if ($name && $output_types) {
    return [
      $name,
      [$self->parse_signature_type_expression($input_types)],
      [$self->parse_signature_type_expression($output_types)],
    ];
  }

  return $self->error_on_signature_parse({signature => $expr})->input($self, $expr)->throw;
}

sub parse_signature_input {
  my ($self, $expr) = @_;

  my $parsed_signature = $self->parse_signature($expr);

  my $input = [map $$_[0], @{$parsed_signature->[1]}];

  return wantarray ? @{$input} : $input;
}

sub parse_signature_output {
  my ($self, $expr) = @_;

  my $parsed_signature = $self->parse_signature($expr);

  my $output = [map $$_[0], @{$parsed_signature->[2]}];

  return wantarray ? @{$output} : $output;
}

sub parse_signature_type_expression {
  my ($self, $expr) = @_;

  $expr = $self->clean($expr);

  my $type_expressions = [];

  my @parts = map $self->clean($_), split(/\s*,(?![^\[]*\])/, $expr);

  for my $part (@parts) {
    if ($part =~ /^(.+?)\s*([\*\$\@\%]\w+)$/) {
      push @{$type_expressions}, [$1, $2];
    }
    else {
      push @{$type_expressions}, [$part];
    }
  }

  return wantarray ? @{$type_expressions} : $type_expressions;
}

sub parser_complex_type {
  my ($self, $expr) = @_;

  return $$COMPLEX_TYPES{$expr};
}

sub parser_has_complex_type {
  my ($self, $expr) = @_;

  return $self->parser_complex_type($expr) ? true : false;
}

sub parser_has_simple_type {
  my ($self, $expr) = @_;

  return $self->parser_simple_type($expr) ? true : false;
}

sub parser_has_type {
  my ($self, $expr) = @_;

  return $self->parser_has_simple_type($expr) || $self->parser_has_complex_type($expr);
}

sub parser_parse_expression {
  my ($self, $expr) = @_;

  $expr =~ s/^\s+|\s+$//g;

  if ($expr =~ /^(\w+)\[(.+)\]$/ && $expr !~ /^\w+\[.+\]\s*[\|\+]\s*\w+\[.+\]$/) {
    my $type = $1;
    my $inner = $2;
    my @params = $self->parser_parse_parameters($inner);
    return [$type, @params];
  }

  if ($expr =~ /\|/ ? $expr =~ /^[^|]*\+[^|]*\|/ : $expr =~ /\+/) {
    my @parts = $self->parser_split_by_operator($expr, '\+');
    return ['includes', map { $self->parser_parse_expression($_) } @parts];
  }

  if ($expr =~ /\+/ ? $expr =~ /^[^+]*\|[^+]*\+/ : $expr =~ /\|/) {
    my @parts = $self->parser_split_by_operator($expr, '\|');
    return ['either', map { $self->parser_parse_expression($_) } @parts];
  }

  if ($expr =~ /^(\w+)\[(.+)\]$/) {
    my $type = $1;
    my $inner = $2;
    my @params = $self->parser_parse_parameters($inner);
    return [$type, @params];
  }

  if ($self->parser_has_simple_type($expr)) {
    return $expr;
  }

  if ($expr =~ /^[A-Z](?:(?:\w|::)*[a-zA-Z0-9])?$/) {
    return $expr;
  }

  my $unquoted = 0;

  $expr =~ s/^\"|\"$//g if !$unquoted++ && $expr =~ /^\".*\"$/;
  $expr =~ s/^\'|\'$//g if !$unquoted++ && $expr =~ /^\'.*\'$/;

  return $expr;
}

sub parser_split_by_operator {
  my ($self, $expr, $operator) = @_;

  my @parts;
  my $depth = 0;
  my $current_part = '';

  for my $char (split //, $expr) {
    if ($char eq '[') {
      $depth++;
    }
    elsif ($char eq ']') {
      $depth--;
    }
    elsif ($char =~ /$operator/ && $depth == 0) {
      $current_part =~ s/^\s+|\s+$//g;
      push @parts, $current_part;
      $current_part = '';
      next;
    }
    $current_part .= $char;
  }

  $current_part =~ s/^\s+|\s+$//g;
  push @parts, $current_part if $current_part;

  return @parts;
}

sub parser_parse_parameters {
  my ($self, $param_str) = @_;

  $param_str =~ s/^\s+|\s+$//g;

  my @params;
  my $depth = 0;
  my $current_param = '';

  for my $char (split //, $param_str) {
    if ($char eq '[') {
      $depth++;
    }
    elsif ($char eq ']') {
      $depth--;
    }
    elsif ($char eq ',' && $depth == 0) {
      $current_param =~ s/^\s+|\s+$//g;
      push @params, $self->parser_parse_expression($current_param);
      $current_param = '';
      next;
    }
    $current_param .= $char;
  }

  $current_param =~ s/^\s+|\s+$//g;
  push @params, $self->parser_parse_expression($current_param)
    if $current_param;

  return @params;
}

sub parser_simple_type {
  my ($self, $expr) = @_;

  return $$SIMPLE_TYPES{$expr};
}

sub parser_type {
  my ($self, $expr) = @_;

  return $self->parser_simple_type($expr) || $self->parser_complex_type($expr);
}

sub generate_expression {
  my ($self, $data) = @_;

  if (!defined $data) {
    return "";
  }

  if (ref $data eq 'HASH' && keys %{$data} == 0) {
    return "";
  }

  if (ref $data eq 'HASH' && keys %{$data} == 1 && values %{$data} == 1 && ref((values %{$data})[0]) eq 'HASH') {
    return $self->generate_expression([(keys %{$data}), (values %{$data})]);
  }

  if (ref $data eq 'HASH') {
    return join ', ', map +($self->generate_expression($_), $self->generate_expression($data->{$_})), sort keys %{$data};
  }

  if (ref $data eq 'ARRAY' && defined $data->[0] && $data->[0] eq 'either') {
    return join ' | ', map $self->generate_expression($_), @{$data}[1..$#$data];
  }

  if (ref $data eq 'ARRAY' && defined $data->[0] && $data->[0] eq 'includes') {
    return join ' + ', map $self->generate_expression($_), @{$data}[1..$#$data];
  }

  if (ref $data eq 'ARRAY' && scalar(@{$data}) >= 2) {
    return join '', $data->[0], '[', (join ', ', map $self->generate_expression($_), @{$data}[1..$#$data]), ']';
  }

  if (ref $data eq 'ARRAY' && scalar(@{$data}) <= 1) {
    return $self->generate_expression($data->[0]);
  }

  if ($data =~ /\"|\s/) {
    $data =~ s/(?<!\\)\"/\\"/g;
    $data = "\"$data\"";
  }

  return $data;
}

sub generate_signature {
  my ($self, $data) = @_;

  return sprintf '%s(%s) (%s)', $data->[0],
    $self->generate_signature_input($data->[1]),
    $self->generate_signature_input($data->[2]);
}

sub generate_signature_input {
  my ($self, $data) = @_;

  return join ', ', map +(join ' ', @{$_}), @{$data};
}

sub generate_signature_output {
  my ($self, $data) = @_;

  return join ', ', map +(join ' ', @{$_}), @{$data};
}

sub offer {
  my ($self, $expr) = @_;

  my $data = $self->expression($expr) || [];

  $data = [$data] if ref $data ne 'ARRAY';

  return wantarray ? @{$data} : $data;
}

sub signature {
  my ($self, $data) = @_;

  return ref $data eq 'ARRAY' ? $self->generate_signature($data) : $self->parse_signature($data);
}

sub unpack {
  my ($self, $args, $data) = @_;

  require Venus::Unpack;

  my $upto = $#$args > $#$data ? $#$args : $#$data;

  return Venus::Unpack->new(args => $args)->use(0..$upto)->types(@{$data});
}

sub unpack_signature_input {
  my ($self, $expr, $args) = @_;

  my $data = $self->parse_signature_input($expr);

  return $self->unpack($args, $data);
}

sub unpack_signature_output {
  my ($self, $expr, $args) = @_;

  my $data = $self->parse_signature_output($expr);

  return $self->unpack($args, $data);
}

# ERRORS

sub error_on_signature_parse {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t parse signature "{{signature}}"';

  $error->name('on.signature.parse');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
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

  my $type = Venus::Type->new;

  # bless({}, "Venus::Type")

=cut

=head1 DESCRIPTION

This package provides a mechanism for parsing, generating, and validating data
type expressions and subroutine signatures.

=head2 Types

The following types are supported by the parser:

=head3 Simple Types

Simple types are basic types supported directly without requiring parameters or nested structures. They include:

=over 4

=item C<any>

Accepts any value.

Example expression: C<any>

Example parsed output: C<["any"]>

=item C<array>

Accepts array references.

Example expression: C<array>

Example parsed output: C<["array"]>

=item C<arrayref>

Accepts array references.

Example expression: C<arrayref>

Example parsed output: C<["arrayref"]>

=item C<bool>

Accepts boolean values (true or false).

Example expression: C<bool>

Example parsed output: C<["bool"]>

=item C<boolean>

Accepts boolean values (true or false).

Example expression: C<boolean>

Example parsed output: C<["boolean"]>

=item C<code>

Accepts code references.

Example expression: C<code>

Example parsed output: C<["code"]>

=item C<coderef>

Accepts code references.

Example expression: C<coderef>

Example parsed output: C<["coderef"]>

=item C<defined>

Accepts any value that is defined (not undefined).

Example expression: C<defined>

Example parsed output: C<["defined"]>

=item C<dirhandle>

Accepts dirhandle values.

Example expression: C<dirhandle>

Example parsed output: C<["dirhandle"]>

=item C<filehandle>

Accepts filehandle values.

Example expression: C<filehandle>

Example parsed output: C<["filehandle"]>

=item C<float>

Accepts floating-point values.

Example expression: C<float>

Example parsed output: C<["float"]>

=item C<glob>

Accepts typeglob values.

Example expression: C<glob>

Example parsed output: C<["glob"]>

=item C<hash>

Accepts hash references.

Example expression: C<hash>

Example parsed output: C<["hash"]>

=item C<hashref>

Accepts hash references.

Example expression: C<hashref>

Example parsed output: C<["hashref"]>

=item C<identity>

Accepts objects of the specified type.

Example expression: C<identity[Example]>

Example parsed output: C<["identity", "Example"]>

=item C<number>

Accepts numeric values (integers and floats).

Example expression: C<number>

Example parsed output: C<["number"]>

=item C<object>

Accepts package (or class) instances.

Example expression: C<object>

Example parsed output: C<["object"]>

=item C<package>

Accepts package names.

Example expression: C<package>

Example parsed output: C<["package"]>

=item C<reference>

Accepts any reference type.

Example expression: C<reference>

Example parsed output: C<["reference"]>

=item C<regexp>

Accepts regular expression objects.

Example expression: C<regexp>

Example parsed output: C<["regexp"]>

=item C<scalar>

Accepts scalar references.

Example expression: C<scalar>

Example parsed output: C<["scalar"]>

=item C<scalarref>

Accepts scalar references.

Example expression: C<scalarref>

Example parsed output: C<["scalarref"]>

=item C<string>

Accepts string values.

Example expression: C<string>

Example parsed output: C<["string"]>

=item C<undef>

Accepts undefined values.

Example expression: C<undef>

Example parsed output: C<["undef"]>

=item C<value>

Accepts defined, non-reference, scalar values.

Example expression: C<value>

Example parsed output: C<["value"]>

=item C<yesno>

Accepts a string value, case-insensitive, that is either C<y>, C<yes>, C<1>, C<n>, C<no>, or C<0>.

Example expression: C<yesno>

Example parsed output: C<["yesno"]>

=back

=head3 Complex Types

Complex types are types that can take one or more type expressions as arguments or involve nesting. These include:

=over 4

=item C<attributes>

Accepts objects with attributes matching the specified names and types.

Example expression: C<attributes[name, string]>

Example parsed output: C<["attributes", "name", "string"]>

=item C<consumes>

Accepts objects that consume the specified role.

Example expression: C<consumes[Example::Role]>

Example parsed output: C<["consumes", "Example::Role"]>

=item C<either>

Accepts one of the provided type expressions.

Example expression: C<string | number>

Example parsed output: C<["either", "string", "number"]>

=item C<hashkeys>

Accepts hashes containing keys whose values match the specified types.

Example expression: C<hashkeys[name, string]>

Example parsed output: C<["hashkeys", "name", "string"]>

=item C<includes>

Accepts all of the provided type expressions.

Example expression: C<string + number>

Example parsed output: C<["includes", "string", "number"]>

=item C<inherits>

Accepts objects that inherit from the specified type.

Example expression: C<inherits[Example]>

Example parsed output: C<["inherits", "Example"]>

=item C<integrates>

Accepts objects that support the "does" behavior and consume the specified role.

Example expression: C<integrates[Example::Role]>

Example parsed output: C<["integrates", "Example::Role"]>

=item C<maybe>

Accepts the provided type or an undefined value.

Example expression: C<maybe[string]>

Example parsed output: C<["maybe", "string"]>

=item C<routines>

Accepts an object having all of the routines specified.

Example expression: C<routines[new]>

Example parsed output: C<["routines", "new"]>

=item C<tuple>

Accepts array references that conform to a tuple specification.

Example expression: C<tuple[string, number]>

Example parsed output: C<["tuple", "string", "number"]>

=item C<within>

Accepts array references, hash references, or mappables (i.e. objects derived
from classes which consume the "mappable" role, see L<Venus::Role::Mappable>),
whose values match the specified type expression.

Example expression: C<within[arrayref, string]>

Example parsed output: C<["within", "arrayref", "string"]>

=back

=head2 Type Expressions

A type expression is a combination of one or more simple or complex types, optionally with parameters, that describes a data structure or value expected by the system.

=head3 Expression Components

=over 4

=item *

B<either> - Denoted by a pipe symbol, C<|>, and used to accept one of multiple types. For example: C<string | number>.

=item *

B<includes> - Denoted by a plus symbol, C<+>, and used to require all of the specified types. For example: C<string + number>.

=item *

B<string-simple> - A simple string is an unquoted string matching the regular expression: C<^\w+$>.

=item *

B<string-quoted> - A quoted string is either single-quoted or double-quoted. For example: C<'name'> or C<"name">.

=item *

B<string-package> - A string-package refers to a Perl package name, following the regular expression: C<^[A-Z](?:(?:\w|::)*[a-zA-Z0-9])?$>.

=item *

B<parameterized> - A parameterized type includes a type followed by an open square bracket, C<[>, followed by one or more type expressions separated by commas, and a closing square bracket, C<]>. For example, C<within[arrayref, string]> means an array reference where each element is a string.

=back

=head2 Subroutine Signatures

A subroutine signature is a string that defines the name of a subroutine, its input types, and its output types. The parser supports subroutine signatures in the following format: C<name(input_type $variable, ...) (output_type)>.

=over 4

=item *

B<name> - The name of the subroutine.

=item *

B<()> - Parentheses enclosing the input type expressions.

=item *

B<input_type> - Each input is a type expression followed by a Perl variable (e.g., C<$variable>).

=item *

B<,> - If more than one input exists, they are separated by a comma.

=item *

B<()> - Parentheses enclosing the output type expression.

=item *

B<output_type> - The type expression for the output of the subroutine.

=back

=head3 Signature Examples

=over 4

=item C<chmod(string $mode) (Venus::Path)>

A subroutine C<chmod> takes a single argument: a string variable C<$mode>, and returns a C<Venus::Path>.

=item C<copy(string | Venus::Path $path) (Venus::Path)>

A subroutine C<copy> takes an argument C<$path>, which can be either a string or a C<Venus::Path> object, and returns a C<Venus::Path>.

=item C<directories() (within[arrayref, Venus::Path])>

A subroutine C<directories> takes no arguments and returns a list of C<Venus::Path> objects contained in an array reference.

=item C<find(string | regexp $expr) (within[arrayref, Venus::Path])>

A subroutine C<find> takes a string or regular expression as input and returns a list of C<Venus::Path> objects contained in an array reference.

=item C<mkdir(maybe[string] $mode) (Venus::Path)>

A subroutine C<mkdir> accepts an optional string argument C<$mode> (or C<undef>) and returns a C<Venus::Path> object.

=item C<root(string $spec, string $base) (maybe[Venus::Path])>

A subroutine C<root> accepts two string arguments and may return a C<Venus::Path> object or C<undef>.

=back

=head2 Usage Examples

=over 4

=item Parsing an "includes" expression

  my $parsed = $type->expression('object + within[arrayref, either[string, number]]');

  # ['includes', 'object', ['within', 'arrayref', ['either', 'string', 'number']]]

=item Generating an "includes" expression

  my $generated = $type->expression(['includes', 'object', ['within', 'arrayref', ['either', 'string', 'number']]]);

  # object + within[arrayref, either[string, number]]

=item Parsing an "either" expression

  my $parsed = $type->expression('string | number | within[arrayref, string | number]');

  # ['either', 'string', 'number', ['within', 'arrayref', ['either', 'string', 'number']]]

=item Generating an "either" expression

  my $generated = $type->expression(['either', 'string', 'number', ['within', 'arrayref', ['either', 'string', 'number']]]);

  # string | number | within[arrayref, string | number]

=item Parsing a subroutine signature

  my $parsed = $type->signature('copy(string | Venus::Path $path) (Venus::Path)');

  # ['copy', [['string | Venus::Path', '$path']], ['Venus::Path']]

=item Generating a subroutine signature

  my $generated = $type->signature(['copy', [['string | Venus::Path', '$path']], ['Venus::Path']]);

  # copy(string | Venus::Path $path) (Venus::Path)

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

=head2 assert

  assert(string $expr) (Venus::Assert)

Returns a L<Venus::Assert> object based on the type expression provided.

I<Since C<4.15>>

=over 4

=item assert example 1

  # given: synopsis;

  my $assert = $type->assert('string | number');

  # bless(..., "Venus::Assert")

=back

=cut

=head2 check

  check(string $expr) (Venus::Check)

Returns a L<Venus::Check> object based on the type expression provided.

I<Since C<4.15>>

=over 4

=item check example 1

  # given: synopsis;

  my $check = $type->check('string | number');

  # bless(..., "Venus::Check")

=back

=cut

=head2 coercion

  coercion(string $expr) (Venus::Coercion)

Returns a L<Venus::Coercion> object based on the type expression provided.

I<Since C<4.15>>

=over 4

=item coercion example 1

  # given: synopsis;

  my $coercion = $type->coercion('string | number');

  # bless(..., "Venus::Coercion")

=back

=cut

=head2 constraint

  constraint(string $expr) (Venus::Constraint)

Returns a L<Venus::Constraint> object based on the type expression provided.

I<Since C<4.15>>

=over 4

=item constraint example 1

  # given: synopsis;

  my $constraint = $type->constraint('string | number');

  # bless(..., "Venus::Constraint")

=back

=cut

=head2 generate_expression

  generate_expression(arrayref $expr) (string)

Returns the type expression for the data structure (representing a type expression) provided.

I<Since C<4.15>>

=over 4

=item generate_expression example 1

  # given: synopsis;

  my $generate_expression = $type->generate_expression(["string"]);

  # "string"

=back

=over 4

=item generate_expression example 2

  # given: synopsis;

  my $generate_expression = $type->generate_expression(["either", "string", "number"]);

  # "string | number"

=back

=over 4

=item generate_expression example 3

  # given: synopsis;

  my $generate_expression = $type->generate_expression([
    "tuple", "number", ["either", ["within", "arrayref", "hashref"], "arrayref"], "coderef",
  ]);

  # "tuple[number, within[arrayref, hashref] | arrayref, coderef]"

=back

=cut

=head2 generate_signature

  generate_signature(arrayref $expr) (string)

Returns the subroutine signature for the data structure (representing a subroutine signature) provided.

I<Since C<4.15>>

=over 4

=item generate_signature example 1

  # given: synopsis;

  my $generate_signature = $type->generate_signature(["output", [], []]);

  # "output() ()"

=back

=over 4

=item generate_signature example 2

  # given: synopsis;

  my $generate_signature = $type->generate_signature(["count", [], [["number"]]]);

  # "count() (number)"

=back

=over 4

=item generate_signature example 3

  # given: synopsis;

  my $generate_signature = $type->generate_signature(["count", [["coderef", "\$filter"]], [["number"]]]);

  # "count(coderef $filter) (number)"

=back

=cut

=head2 generate_signature_input

  generate_signature_input(arrayref $expr) (string)

Returns the subroutine signature input expression for the data structure
(representing a subroutine signature input expression) provided.

I<Since C<4.15>>

=over 4

=item generate_signature_input example 1

  # given: synopsis;

  my $generate_signature_input = $type->generate_signature_input([["string", "\$string"]]);

  # "string $string"

=back

=over 4

=item generate_signature_input example 2

  # given: synopsis;

  my $generate_signature_input = $type->generate_signature_input([["string", "\$string"], ["number", "\$number"]]);

  # "string $string, number $number"

=back

=over 4

=item generate_signature_input example 3

  # given: synopsis;

  my $generate_signature_input = $type->generate_signature_input([
    ["string", "\$string"], ["coderef", "\$filter"]
  ]);

  # "string $string, coderef $filter"

=back

=cut

=head2 generate_signature_output

  generate_signature_output(arrayref $expr) (string)

Returns the subroutine signature output expression for the data structure
(representing a subroutine signature output expression) provided.

I<Since C<4.15>>

=over 4

=item generate_signature_output example 1

  # given: synopsis;

  my $generate_signature_output = $type->generate_signature_output([["string", "\$string"]]);

  # "string $string"

=back

=over 4

=item generate_signature_output example 2

  # given: synopsis;

  my $generate_signature_output = $type->generate_signature_output([["string", "\$string"], ["number", "\$number"]]);

  # "string $string, number $number"

=back

=over 4

=item generate_signature_output example 3

  # given: synopsis;

  my $generate_signature_output = $type->generate_signature_output([
    ["string", "\$string"], ["coderef", "\$filter"]
  ]);

  # "string $string, coderef $filter"

=back

=cut

=head2 new

  new(hashref $data) (Venus::Type)

Constructs a new object.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Type;

  my $type = Venus::Type->new;

  # bless({}, "Venus::Type")

=back

=cut

=head2 parse_expression

  parse_expression(string $expr) (arrayref)

Returns the parsed data structure based on the type expression provided.

I<Since C<4.15>>

=over 4

=item parse_expression example 1

  # given: synopsis;

  my $parse_expression = $type->parse_expression('string | number | Example');

  # ["either", "string", "number", "Example"]

=back

=over 4

=item parse_expression example 2

  # given: synopsis;

  my $parse_expression = $type->parse_expression('scalarref | object + string');

  # ["either", "scalarref", ["includes", "object", "string"]]

=back

=over 4

=item parse_expression example 3

  # given: synopsis;

  my $parse_expression = $type->parse_expression('within[arrayref, string | number]');

  # ["within", "arrayref", ["either", "string", "number"]]

=back

=over 4

=item parse_expression example 4

  # given: synopsis;

  my $parse_expression = $type->parse_expression('attributes[name, string, age, number]');

  # ["attributes", "name", "string", "age", "number"]

=back

=over 4

=item parse_expression example 5

  # given: synopsis;

  my $parse_expression = $type->parse_expression('tuple[string, arrayref, code]');

  # ["tuple", "string", "arrayref", "code"]

=back

=over 4

=item parse_expression example 6

  # given: synopsis;

  my $parse_expression = $type->parse_expression('inherits[Example] + attributes[value, string]');

  # ["includes", ["inherits", "Example"], ["attributes", "value", "string"]]

=back

=over 4

=item parse_expression example 7

  # given: synopsis;

  my $parse_expression = $type->parse_expression('consumes[Example::Role] | identity[Example]');

  # ["either", ["consumes", "Example::Role"], ["identity", "Example"]]

=back

=over 4

=item parse_expression example 8

  # given: synopsis;

  my $parse_expression = $type->parse_expression('either[tuple[string, number], coderef]');

  # ["either", ["tuple", "string", "number"], "coderef"]

=back

=over 4

=item parse_expression example 9

  # given: synopsis;

  my $parse_expression = $type->parse_expression('within[hashref, attributes["name", string]]');

  # ["within", "hashref", ["attributes", "name", "string"]]

=back

=over 4

=item parse_expression example 10

  # given: synopsis;

  my $parse_expression = $type->parse_expression('maybe[arrayref] | either[scalar, code]');

  # ["either", ["maybe", "arrayref"], ["either", "scalar", "code"]]

=back

=cut

=head2 parse_signature

  parse_signature(string $expr) (arrayref)

Returns the parsed data structure based on the subroutine signature provided.

I<Since C<4.15>>

=over 4

=item parse_signature example 1

  # given: synopsis;

  my $parse_signature = $type->parse_signature('print(string @values) (boolean)');

  # ["print", [["string", "\@values"]], [["boolean"]]]

=back

=over 4

=item parse_signature example 2

  # given: synopsis;

  my $parse_signature = $type->parse_signature('chmod(string $mode) (Venus::Path)');

  # ["chmod", [["string", "\$mode"]], [["Venus::Path"]]]

=back

=over 4

=item parse_signature example 3

  # given: synopsis;

  my $parse_signature = $type->parse_signature('copy(string | Venus::Path $path) (Venus::Path)');

  # ["copy", [["string | Venus::Path", "\$path"]], [["Venus::Path"]]]

=back

=over 4

=item parse_signature example 4

  # given: synopsis;

  my $parse_signature = $type->parse_signature('find(string | regexp $expr) (within[arrayref, Venus::Path])');

  # ["find", [["string | regexp", "\$expr"]], [["within[arrayref, Venus::Path]"]]]

=back

=over 4

=item parse_signature example 5

  # given: synopsis;

  my $parse_signature = $type->parse_signature('mkdir(maybe[string] $mode) (Venus::Path)');

  # ["mkdir", [["maybe[string]", "\$mode"]], [[ "Venus::Path" ]]]

=back

=over 4

=item parse_signature example 6

  # given: synopsis;

  my $parse_signature = $type->parse_signature('open(any @data) (FileHandle)');

  # ["open", [["any", "\@data"]], [["FileHandle"]]]

=back

=over 4

=item parse_signature example 7

  # given: synopsis;

  my $parse_signature = $type->parse_signature('root(string $spec, string $base) (maybe[Venus::Path])');

  # ["root", [["string", "\$spec"], ["string", "\$base"]], [["maybe[Venus::Path]"]]]

=back

=over 4

=item parse_signature example 8

  # given: synopsis;

  my $parse_signature = $type->parse_signature('extension(string $name) (string | Venus::Path)');

  # ["extension", [["string", "\$name"]], [["string | Venus::Path"]]]

=back

=over 4

=item parse_signature example 9

  # given: synopsis;

  my $parse_signature = $type->parse_signature('count()');

  # Exception! isa Venus::Type::Error (see error_on_signature_parse)

=back

=over 4

=item B<may raise> L<Venus::Type::Error> C<on.signature.parse>

  package main;

  use Venus::Type;

  my $type = Venus::Type->new;

  $type->parse_signature('count()');

  # Error! (on.signature.parse)

=back

=cut

=head2 parse_signature_input

  parse_signature_input(string $expr) (arrayref)

Returns the parsed data structure for the input type expressions in the subroutine signature provided.

I<Since C<4.15>>

=over 4

=item parse_signature_input example 1

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('print(string @values) (boolean)');

  # ["string"]

=back

=over 4

=item parse_signature_input example 2

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('chmod(string $mode) (Venus::Path)');

  # ["string"]

=back

=over 4

=item parse_signature_input example 3

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('copy(string | Venus::Path $path) (Venus::Path)');

  # ["string | Venus::Path"]

=back

=over 4

=item parse_signature_input example 4

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('find(string | regexp $expr) (within[arrayref, Venus::Path])');

  # ["string | regexp"]

=back

=over 4

=item parse_signature_input example 5

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('mkdir(maybe[string] $mode) (Venus::Path)');

  # ["maybe[string]"]

=back

=over 4

=item parse_signature_input example 6

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('open(any @data) (FileHandle)');

  # ["any"]

=back

=over 4

=item parse_signature_input example 7

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('root(string $spec, string $base) (maybe[Venus::Path])');

  # ["string", "string"]

=back

=over 4

=item parse_signature_input example 8

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('extension(string $name) (string | Venus::Path)');

  # ["string"]

=back

=cut

=head2 parse_signature_output

  parse_signature_output(string $expr) (arrayref)

Returns the parsed data structure for the output type expression in the subroutine signature provided.

I<Since C<4.15>>

=over 4

=item parse_signature_output example 1

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('print(string @values) (boolean)');

  # ["boolean"]

=back

=over 4

=item parse_signature_output example 2

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('chmod(string $mode) (Venus::Path)');

  # ["Venus::Path"]

=back

=over 4

=item parse_signature_output example 3

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('copy(string | Venus::Path $path) (Venus::Path)');

  # ["Venus::Path"]

=back

=over 4

=item parse_signature_output example 4

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('find(string | regexp $expr) (within[arrayref, Venus::Path])');

  # ["within[arrayref, Venus::Path]"]

=back

=over 4

=item parse_signature_output example 5

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('mkdir(maybe[string] $mode) (Venus::Path)');

  # ["Venus::Path"]

=back

=over 4

=item parse_signature_output example 6

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('open(any @data) (FileHandle)');

  # ["FileHandle"]

=back

=over 4

=item parse_signature_output example 7

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('root(string $spec, string $base) (maybe[Venus::Path])');

  # ["maybe[Venus::Path]"]

=back

=over 4

=item parse_signature_output example 8

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('extension(string $name) (string | Venus::Path)');

  # ["string | Venus::Path"]

=back

=cut

=head2 unpack

  unpack(arrayref $args, arrayref $expr) (Venus::Unpack)

Returns a L<Venus::Unpack> object based on the values and data structure
(representing type expressions) provided.

I<Since C<4.15>>

=over 4

=item unpack example 1

  # given: synopsis;

  my $unpack = $type->unpack(["hello world"], ["string"]);

  # bless(..., "Venus::Unpack")

=back

=over 4

=item unpack example 2

  # given: synopsis;

  my $unpack = $type->unpack(["hello world"], ["string | number"]);

  # bless(..., "Venus::Unpack")

=back

=cut

=head2 unpack_signature_input

  unpack_signature_input(string $signature, arrayref $args) (Venus::Unpack)

Returns a L<Venus::Unpack> object based on the values and data structure
(representing a subroutine signature input expression) provided.

I<Since C<4.15>>

=over 4

=item unpack_signature_input example 1

  # given: synopsis;

  my $unpack_signature_input = $type->unpack_signature_input(
    'output(string $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

=back

=over 4

=item unpack_signature_input example 2

  # given: synopsis;

  my $unpack_signature_input = $type->unpack_signature_input(
    'output(string | number $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

=back

=cut

=head2 unpack_signature_output

  unpack_signature_output(string $signature, arrayref $args) (Venus::Unpack)

Returns a L<Venus::Unpack> object based on the values and data structure
(representing a subroutine signature output expression) provided.

I<Since C<4.15>>

=over 4

=item unpack_signature_output example 1

  # given: synopsis;

  my $unpack_signature_output = $type->unpack_signature_output(
    'output(string $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

=back

=over 4

=item unpack_signature_output example 2

  # given: synopsis;

  my $unpack_signature_output = $type->unpack_signature_output(
    'output(string | number $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

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