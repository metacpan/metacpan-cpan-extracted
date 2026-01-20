package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Type

=cut

$test->for('name');

=tagline

Type Class

=cut

$test->for('tagline');

=abstract

Type Class for Perl 5

=cut

$test->for('abstract');

=includes

method: assert
method: check
method: coercion
method: constraint
method: new
method: parse_expression
method: parse_signature
method: parse_signature_input
method: parse_signature_output
method: generate_expression
method: generate_signature
method: generate_signature_input
method: generate_signature_output
method: unpack
method: unpack_signature_input
method: unpack_signature_output

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Type;

  my $type = Venus::Type->new;

  # bless({}, "Venus::Type")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Type');

  $result
});

=description

This package provides a mechanism for parsing, generating, and validating data
type expressions and subroutine signatures.

+=head2 Types

The following types are supported by the parser:

+=head3 Simple Types

Simple types are basic types supported directly without requiring parameters or nested structures. They include:

+=over 4

+=item C<any>

Accepts any value.

Example expression: C<any>

Example parsed output: C<["any"]>

+=item C<array>

Accepts array references.

Example expression: C<array>

Example parsed output: C<["array"]>

+=item C<arrayref>

Accepts array references.

Example expression: C<arrayref>

Example parsed output: C<["arrayref"]>

+=item C<bool>

Accepts boolean values (true or false).

Example expression: C<bool>

Example parsed output: C<["bool"]>

+=item C<boolean>

Accepts boolean values (true or false).

Example expression: C<boolean>

Example parsed output: C<["boolean"]>

+=item C<code>

Accepts code references.

Example expression: C<code>

Example parsed output: C<["code"]>

+=item C<coderef>

Accepts code references.

Example expression: C<coderef>

Example parsed output: C<["coderef"]>

+=item C<defined>

Accepts any value that is defined (not undefined).

Example expression: C<defined>

Example parsed output: C<["defined"]>

+=item C<dirhandle>

Accepts dirhandle values.

Example expression: C<dirhandle>

Example parsed output: C<["dirhandle"]>

+=item C<filehandle>

Accepts filehandle values.

Example expression: C<filehandle>

Example parsed output: C<["filehandle"]>

+=item C<float>

Accepts floating-point values.

Example expression: C<float>

Example parsed output: C<["float"]>

+=item C<glob>

Accepts typeglob values.

Example expression: C<glob>

Example parsed output: C<["glob"]>

+=item C<hash>

Accepts hash references.

Example expression: C<hash>

Example parsed output: C<["hash"]>

+=item C<hashref>

Accepts hash references.

Example expression: C<hashref>

Example parsed output: C<["hashref"]>

+=item C<identity>

Accepts objects of the specified type.

Example expression: C<identity[Example]>

Example parsed output: C<["identity", "Example"]>

+=item C<number>

Accepts numeric values (integers and floats).

Example expression: C<number>

Example parsed output: C<["number"]>

+=item C<object>

Accepts package (or class) instances.

Example expression: C<object>

Example parsed output: C<["object"]>

+=item C<package>

Accepts package names.

Example expression: C<package>

Example parsed output: C<["package"]>

+=item C<reference>

Accepts any reference type.

Example expression: C<reference>

Example parsed output: C<["reference"]>

+=item C<regexp>

Accepts regular expression objects.

Example expression: C<regexp>

Example parsed output: C<["regexp"]>

+=item C<scalar>

Accepts scalar references.

Example expression: C<scalar>

Example parsed output: C<["scalar"]>

+=item C<scalarref>

Accepts scalar references.

Example expression: C<scalarref>

Example parsed output: C<["scalarref"]>

+=item C<string>

Accepts string values.

Example expression: C<string>

Example parsed output: C<["string"]>

+=item C<undef>

Accepts undefined values.

Example expression: C<undef>

Example parsed output: C<["undef"]>

+=item C<value>

Accepts defined, non-reference, scalar values.

Example expression: C<value>

Example parsed output: C<["value"]>

+=item C<yesno>

Accepts a string value, case-insensitive, that is either C<y>, C<yes>, C<1>, C<n>, C<no>, or C<0>.

Example expression: C<yesno>

Example parsed output: C<["yesno"]>

+=back

+=head3 Complex Types

Complex types are types that can take one or more type expressions as arguments or involve nesting. These include:

+=over 4

+=item C<attributes>

Accepts objects with attributes matching the specified names and types.

Example expression: C<attributes[name, string]>

Example parsed output: C<["attributes", "name", "string"]>

+=item C<consumes>

Accepts objects that consume the specified role.

Example expression: C<consumes[Example::Role]>

Example parsed output: C<["consumes", "Example::Role"]>

+=item C<either>

Accepts one of the provided type expressions.

Example expression: C<string | number>

Example parsed output: C<["either", "string", "number"]>

+=item C<hashkeys>

Accepts hashes containing keys whose values match the specified types.

Example expression: C<hashkeys[name, string]>

Example parsed output: C<["hashkeys", "name", "string"]>

+=item C<includes>

Accepts all of the provided type expressions.

Example expression: C<string + number>

Example parsed output: C<["includes", "string", "number"]>

+=item C<inherits>

Accepts objects that inherit from the specified type.

Example expression: C<inherits[Example]>

Example parsed output: C<["inherits", "Example"]>

+=item C<integrates>

Accepts objects that support the "does" behavior and consume the specified role.

Example expression: C<integrates[Example::Role]>

Example parsed output: C<["integrates", "Example::Role"]>

+=item C<maybe>

Accepts the provided type or an undefined value.

Example expression: C<maybe[string]>

Example parsed output: C<["maybe", "string"]>

+=item C<routines>

Accepts an object having all of the routines specified.

Example expression: C<routines[new]>

Example parsed output: C<["routines", "new"]>

+=item C<tuple>

Accepts array references that conform to a tuple specification.

Example expression: C<tuple[string, number]>

Example parsed output: C<["tuple", "string", "number"]>

+=item C<within>

Accepts array references, hash references, or mappables (i.e. objects derived
from classes which consume the "mappable" role, see L<Venus::Role::Mappable>),
whose values match the specified type expression.

Example expression: C<within[arrayref, string]>

Example parsed output: C<["within", "arrayref", "string"]>

+=back

+=head2 Type Expressions

A type expression is a combination of one or more simple or complex types, optionally with parameters, that describes a data structure or value expected by the system.

+=head3 Expression Components

+=over 4

+=item *

B<either> - Denoted by a pipe symbol, C<|>, and used to accept one of multiple types. For example: C<string | number>.

+=item *

B<includes> - Denoted by a plus symbol, C<+>, and used to require all of the specified types. For example: C<string + number>.

+=item *

B<string-simple> - A simple string is an unquoted string matching the regular expression: C<^\w+$>.

+=item *

B<string-quoted> - A quoted string is either single-quoted or double-quoted. For example: C<'name'> or C<"name">.

+=item *

B<string-package> - A string-package refers to a Perl package name, following the regular expression: C<^[A-Z](?:(?:\w|::)*[a-zA-Z0-9])?$>.

+=item *

B<parameterized> - A parameterized type includes a type followed by an open square bracket, C<[>, followed by one or more type expressions separated by commas, and a closing square bracket, C<]>. For example, C<within[arrayref, string]> means an array reference where each element is a string.

+=back

+=head2 Subroutine Signatures

A subroutine signature is a string that defines the name of a subroutine, its input types, and its output types. The parser supports subroutine signatures in the following format: C<name(input_type $variable, ...) (output_type)>.

+=over 4

+=item *

B<name> - The name of the subroutine.

+=item *

B<()> - Parentheses enclosing the input type expressions.

+=item *

B<input_type> - Each input is a type expression followed by a Perl variable (e.g., C<$variable>).

+=item *

B<,> - If more than one input exists, they are separated by a comma.

+=item *

B<()> - Parentheses enclosing the output type expression.

+=item *

B<output_type> - The type expression for the output of the subroutine.

+=back

+=head3 Signature Examples

+=over 4

+=item C<chmod(string $mode) (Venus::Path)>

A subroutine C<chmod> takes a single argument: a string variable C<$mode>, and returns a C<Venus::Path>.

+=item C<copy(string | Venus::Path $path) (Venus::Path)>

A subroutine C<copy> takes an argument C<$path>, which can be either a string or a C<Venus::Path> object, and returns a C<Venus::Path>.

+=item C<directories() (within[arrayref, Venus::Path])>

A subroutine C<directories> takes no arguments and returns a list of C<Venus::Path> objects contained in an array reference.

+=item C<find(string | regexp $expr) (within[arrayref, Venus::Path])>

A subroutine C<find> takes a string or regular expression as input and returns a list of C<Venus::Path> objects contained in an array reference.

+=item C<mkdir(maybe[string] $mode) (Venus::Path)>

A subroutine C<mkdir> accepts an optional string argument C<$mode> (or C<undef>) and returns a C<Venus::Path> object.

+=item C<root(string $spec, string $base) (maybe[Venus::Path])>

A subroutine C<root> accepts two string arguments and may return a C<Venus::Path> object or C<undef>.

+=back

+=head2 Usage Examples

+=over 4

+=item Parsing an "includes" expression

  my $parsed = $type->expression('object + within[arrayref, either[string, number]]');

  # ['includes', 'object', ['within', 'arrayref', ['either', 'string', 'number']]]

+=item Generating an "includes" expression

  my $generated = $type->expression(['includes', 'object', ['within', 'arrayref', ['either', 'string', 'number']]]);

  # object + within[arrayref, either[string, number]]

+=item Parsing an "either" expression

  my $parsed = $type->expression('string | number | within[arrayref, string | number]');

  # ['either', 'string', 'number', ['within', 'arrayref', ['either', 'string', 'number']]]

+=item Generating an "either" expression

  my $generated = $type->expression(['either', 'string', 'number', ['within', 'arrayref', ['either', 'string', 'number']]]);

  # string | number | within[arrayref, string | number]

+=item Parsing a subroutine signature

  my $parsed = $type->signature('copy(string | Venus::Path $path) (Venus::Path)');

  # ['copy', [['string | Venus::Path', '$path']], ['Venus::Path']]

+=item Generating a subroutine signature

  my $generated = $type->signature(['copy', [['string | Venus::Path', '$path']], ['Venus::Path']]);

  # copy(string | Venus::Path $path) (Venus::Path)

+=back

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Buildable

=cut

$test->for('integrates');

=method new

Constructs a new object.

=signature new

  new(hashref $data) (Venus::Type)

=metadata new

{
  since => '4.15',
}

=example-1 new

  package main;

  use Venus::Type;

  my $type = Venus::Type->new;

  # bless({}, "Venus::Type")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Type');

  $result
});

=method assert

Returns a L<Venus::Assert> object based on the type expression provided.

=signature assert

  assert(string $expr) (Venus::Assert)

=metadata assert

{
  since => '4.15',
}

=example-1 assert

  # given: synopsis;

  my $assert = $type->assert('string | number');

  # bless(..., "Venus::Assert")

=cut

$test->for('example', 1, 'assert', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Assert');

  $result
});

=method check

Returns a L<Venus::Check> object based on the type expression provided.

=signature check

  check(string $expr) (Venus::Check)

=metadata check

{
  since => '4.15',
}

=example-1 check

  # given: synopsis;

  my $check = $type->check('string | number');

  # bless(..., "Venus::Check")

=cut

$test->for('example', 1, 'check', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Check');

  $result
});

=method coercion

Returns a L<Venus::Coercion> object based on the type expression provided.

=signature coercion

  coercion(string $expr) (Venus::Coercion)

=metadata coercion

{
  since => '4.15',
}

=example-1 coercion

  # given: synopsis;

  my $coercion = $type->coercion('string | number');

  # bless(..., "Venus::Coercion")

=cut

$test->for('example', 1, 'coercion', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Coercion');

  $result
});

=method constraint

Returns a L<Venus::Constraint> object based on the type expression provided.

=signature constraint

  constraint(string $expr) (Venus::Constraint)

=metadata constraint

{
  since => '4.15',
}

=example-1 constraint

  # given: synopsis;

  my $constraint = $type->constraint('string | number');

  # bless(..., "Venus::Constraint")

=cut

$test->for('example', 1, 'constraint', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Constraint');

  $result
});

=method parse_expression

Returns the parsed data structure based on the type expression provided.

=signature parse_expression

  parse_expression(string $expr) (arrayref)

=metadata parse_expression

{
  since => '4.15',
}

=example-1 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('string | number | Example');

  # ["either", "string", "number", "Example"]

=cut

$test->for('example', 1, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["either", "string", "number", "Example"];

  $result
});

=example-2 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('scalarref | object + string');

  # ["either", "scalarref", ["includes", "object", "string"]]

=cut

$test->for('example', 2, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["either", "scalarref", ["includes", "object", "string"]];

  $result
});

=example-3 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('within[arrayref, string | number]');

  # ["within", "arrayref", ["either", "string", "number"]]

=cut

$test->for('example', 3, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["within", "arrayref", ["either", "string", "number"]];

  $result
});

=example-4 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('attributes[name, string, age, number]');

  # ["attributes", "name", "string", "age", "number"]

=cut

$test->for('example', 4, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["attributes", "name", "string", "age", "number"];

  $result
});

=example-5 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('tuple[string, arrayref, code]');

  # ["tuple", "string", "arrayref", "code"]

=cut

$test->for('example', 5, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["tuple", "string", "arrayref", "code"];

  $result
});

=example-6 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('inherits[Example] + attributes[value, string]');

  # ["includes", ["inherits", "Example"], ["attributes", "value", "string"]]

=cut

$test->for('example', 6, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["includes", ["inherits", "Example"], ["attributes", "value", "string"]];

  $result
});

=example-7 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('consumes[Example::Role] | identity[Example]');

  # ["either", ["consumes", "Example::Role"], ["identity", "Example"]]

=cut

$test->for('example', 7, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["either", ["consumes", "Example::Role"], ["identity", "Example"]];

  $result
});

=example-8 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('either[tuple[string, number], coderef]');

  # ["either", ["tuple", "string", "number"], "coderef"]

=cut

$test->for('example', 8, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["either", ["tuple", "string", "number"], "coderef"];

  $result
});

=example-9 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('within[hashref, attributes["name", string]]');

  # ["within", "hashref", ["attributes", "name", "string"]]

=cut

$test->for('example', 9, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["within", "hashref", ["attributes", "name", "string"]];

  $result
});

=example-10 parse_expression

  # given: synopsis;

  my $parse_expression = $type->parse_expression('maybe[arrayref] | either[scalar, code]');

  # ["either", ["maybe", "arrayref"], ["either", "scalar", "code"]]

=cut

$test->for('example', 10, 'parse_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["either", ["maybe", "arrayref"], ["either", "scalar", "code"]];

  $result
});

=method parse_signature

Returns the parsed data structure based on the subroutine signature provided.

=signature parse_signature

  parse_signature(string $expr) (arrayref)

=metadata parse_signature

{
  since => '4.15',
}

=example-1 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('print(string @values) (boolean)');

  # ["print", [["string", "\@values"]], [["boolean"]]]

=cut

$test->for('example', 1, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["print", [["string", "\@values"]], [["boolean"]]];

  $result
});

=example-2 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('chmod(string $mode) (Venus::Path)');

  # ["chmod", [["string", "\$mode"]], [["Venus::Path"]]]

=cut

$test->for('example', 2, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["chmod", [["string", "\$mode"]], [["Venus::Path"]]];

  $result
});

=example-3 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('copy(string | Venus::Path $path) (Venus::Path)');

  # ["copy", [["string | Venus::Path", "\$path"]], [["Venus::Path"]]]

=cut

$test->for('example', 3, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["copy", [["string | Venus::Path", "\$path"]], [["Venus::Path"]]];

  $result
});

=example-4 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('find(string | regexp $expr) (within[arrayref, Venus::Path])');

  # ["find", [["string | regexp", "\$expr"]], [["within[arrayref, Venus::Path]"]]]

=cut

$test->for('example', 4, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["find", [["string | regexp", "\$expr"]], [["within[arrayref, Venus::Path]"]]];

  $result
});

=example-5 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('mkdir(maybe[string] $mode) (Venus::Path)');

  # ["mkdir", [["maybe[string]", "\$mode"]], [[ "Venus::Path" ]]]

=cut

$test->for('example', 5, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["mkdir", [["maybe[string]", "\$mode"]], [[ "Venus::Path" ]]];

  $result
});

=example-6 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('open(any @data) (FileHandle)');

  # ["open", [["any", "\@data"]], [["FileHandle"]]]

=cut

$test->for('example', 6, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["open", [["any", "\@data"]], [["FileHandle"]]];

  $result
});

=example-7 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('root(string $spec, string $base) (maybe[Venus::Path])');

  # ["root", [["string", "\$spec"], ["string", "\$base"]], [["maybe[Venus::Path]"]]]

=cut

$test->for('example', 7, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["root", [["string", "\$spec"], ["string", "\$base"]], [["maybe[Venus::Path]"]]];

  $result
});

=example-8 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('extension(string $name) (string | Venus::Path)');

  # ["extension", [["string", "\$name"]], [["string | Venus::Path"]]]

=cut

$test->for('example', 8, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["extension", [["string", "\$name"]], [["string | Venus::Path"]]];

  $result
});

=example-9 parse_signature

  # given: synopsis;

  my $parse_signature = $type->parse_signature('count()');

  # Exception! isa Venus::Type::Error (see error_on_signature_parse)

=cut

$test->for('example', 9, 'parse_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error->result;
  ok $result->isa('Venus::Type::Error');
  is $result->name, 'on.signature.parse';

  $result
});

=method parse_signature_input

Returns the parsed data structure for the input type expressions in the subroutine signature provided.

=signature parse_signature_input

  parse_signature_input(string $expr) (arrayref)

=metadata parse_signature_input

{
  since => '4.15',
}

=example-1 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('print(string @values) (boolean)');

  # ["string"]

=cut

$test->for('example', 1, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["string"];

  $result
});

=example-2 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('chmod(string $mode) (Venus::Path)');

  # ["string"]

=cut

$test->for('example', 2, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["string"];

  $result
});

=example-3 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('copy(string | Venus::Path $path) (Venus::Path)');

  # ["string | Venus::Path"]

=cut

$test->for('example', 3, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["string | Venus::Path"];

  $result
});

=example-4 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('find(string | regexp $expr) (within[arrayref, Venus::Path])');

  # ["string | regexp"]

=cut

$test->for('example', 4, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["string | regexp"];

  $result
});

=example-5 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('mkdir(maybe[string] $mode) (Venus::Path)');

  # ["maybe[string]"]

=cut

$test->for('example', 5, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["maybe[string]"];

  $result
});

=example-6 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('open(any @data) (FileHandle)');

  # ["any"]

=cut

$test->for('example', 6, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["any"];

  $result
});

=example-7 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('root(string $spec, string $base) (maybe[Venus::Path])');

  # ["string", "string"]

=cut

$test->for('example', 7, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["string", "string"];

  $result
});

=example-8 parse_signature_input

  # given: synopsis;

  my $parse_signature_input = $type->parse_signature_input('extension(string $name) (string | Venus::Path)');

  # ["string"]

=cut

$test->for('example', 8, 'parse_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["string"];

  $result
});

=method parse_signature_output

Returns the parsed data structure for the output type expression in the subroutine signature provided.

=signature parse_signature_output

  parse_signature_output(string $expr) (arrayref)

=metadata parse_signature_output

{
  since => '4.15',
}

=example-1 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('print(string @values) (boolean)');

  # ["boolean"]

=cut

$test->for('example', 1, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["boolean"];

  $result
});

=example-2 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('chmod(string $mode) (Venus::Path)');

  # ["Venus::Path"]

=cut

$test->for('example', 2, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["Venus::Path"];

  $result
});

=example-3 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('copy(string | Venus::Path $path) (Venus::Path)');

  # ["Venus::Path"]

=cut

$test->for('example', 3, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["Venus::Path"];

  $result
});

=example-4 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('find(string | regexp $expr) (within[arrayref, Venus::Path])');

  # ["within[arrayref, Venus::Path]"]

=cut

$test->for('example', 4, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["within[arrayref, Venus::Path]"];

  $result
});

=example-5 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('mkdir(maybe[string] $mode) (Venus::Path)');

  # ["Venus::Path"]

=cut

$test->for('example', 5, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["Venus::Path"];

  $result
});

=example-6 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('open(any @data) (FileHandle)');

  # ["FileHandle"]

=cut

$test->for('example', 6, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["FileHandle"];

  $result
});

=example-7 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('root(string $spec, string $base) (maybe[Venus::Path])');

  # ["maybe[Venus::Path]"]

=cut

$test->for('example', 7, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["maybe[Venus::Path]"];

  $result
});

=example-8 parse_signature_output

  # given: synopsis;

  my $parse_signature_output = $type->parse_signature_output('extension(string $name) (string | Venus::Path)');

  # ["string | Venus::Path"]

=cut

$test->for('example', 8, 'parse_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["string | Venus::Path"];

  $result
});

=method generate_expression

Returns the type expression for the data structure (representing a type expression) provided.

=signature generate_expression

  generate_expression(arrayref $expr) (string)

=metadata generate_expression

{
  since => '4.15',
}

=example-1 generate_expression

  # given: synopsis;

  my $generate_expression = $type->generate_expression(["string"]);

  # "string"

=cut

$test->for('example', 1, 'generate_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, 'string';

  $result
});

=example-2 generate_expression

  # given: synopsis;

  my $generate_expression = $type->generate_expression(["either", "string", "number"]);

  # "string | number"

=cut

$test->for('example', 2, 'generate_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, 'string | number';

  $result
});

=example-3 generate_expression

  # given: synopsis;

  my $generate_expression = $type->generate_expression([
    "tuple", "number", ["either", ["within", "arrayref", "hashref"], "arrayref"], "coderef",
  ]);

  # "tuple[number, within[arrayref, hashref] | arrayref, coderef]"

=cut

$test->for('example', 3, 'generate_expression', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, 'tuple[number, within[arrayref, hashref] | arrayref, coderef]';

  $result
});

=method generate_signature

Returns the subroutine signature for the data structure (representing a subroutine signature) provided.

=signature generate_signature

  generate_signature(arrayref $expr) (string)

=metadata generate_signature

{
  since => '4.15',
}

=example-1 generate_signature

  # given: synopsis;

  my $generate_signature = $type->generate_signature(["output", [], []]);

  # "output() ()"

=cut

$test->for('example', 1, 'generate_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "output() ()";

  $result
});

=example-2 generate_signature

  # given: synopsis;

  my $generate_signature = $type->generate_signature(["count", [], [["number"]]]);

  # "count() (number)"

=cut

$test->for('example', 2, 'generate_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "count() (number)";

  $result
});

=example-3 generate_signature

  # given: synopsis;

  my $generate_signature = $type->generate_signature(["count", [["coderef", "\$filter"]], [["number"]]]);

  # "count(coderef $filter) (number)"

=cut

$test->for('example', 3, 'generate_signature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "count(coderef \$filter) (number)";

  $result
});

=method generate_signature_input

Returns the subroutine signature input expression for the data structure
(representing a subroutine signature input expression) provided.

=signature generate_signature_input

  generate_signature_input(arrayref $expr) (string)

=metadata generate_signature_input

{
  since => '4.15',
}

=example-1 generate_signature_input

  # given: synopsis;

  my $generate_signature_input = $type->generate_signature_input([["string", "\$string"]]);

  # "string $string"

=cut

$test->for('example', 1, 'generate_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "string \$string";

  $result
});

=example-2 generate_signature_input

  # given: synopsis;

  my $generate_signature_input = $type->generate_signature_input([["string", "\$string"], ["number", "\$number"]]);

  # "string $string, number $number"

=cut

$test->for('example', 2, 'generate_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "string \$string, number \$number";

  $result
});

=example-3 generate_signature_input

  # given: synopsis;

  my $generate_signature_input = $type->generate_signature_input([
    ["string", "\$string"], ["coderef", "\$filter"]
  ]);

  # "string $string, coderef $filter"

=cut

$test->for('example', 3, 'generate_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "string \$string, coderef \$filter";

  $result
});

=method generate_signature_output

Returns the subroutine signature output expression for the data structure
(representing a subroutine signature output expression) provided.

=signature generate_signature_output

  generate_signature_output(arrayref $expr) (string)

=metadata generate_signature_output

{
  since => '4.15',
}

=example-1 generate_signature_output

  # given: synopsis;

  my $generate_signature_output = $type->generate_signature_output([["string", "\$string"]]);

  # "string $string"

=cut

$test->for('example', 1, 'generate_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "string \$string";

  $result
});

=example-2 generate_signature_output

  # given: synopsis;

  my $generate_signature_output = $type->generate_signature_output([["string", "\$string"], ["number", "\$number"]]);

  # "string $string, number $number"

=cut

$test->for('example', 2, 'generate_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "string \$string, number \$number";

  $result
});

=example-3 generate_signature_output

  # given: synopsis;

  my $generate_signature_output = $type->generate_signature_output([
    ["string", "\$string"], ["coderef", "\$filter"]
  ]);

  # "string $string, coderef $filter"

=cut

$test->for('example', 3, 'generate_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, "string \$string, coderef \$filter";

  $result
});

=method unpack

Returns a L<Venus::Unpack> object based on the values and data structure
(representing type expressions) provided.

=signature unpack

  unpack(arrayref $args, arrayref $expr) (Venus::Unpack)

=metadata unpack

{
  since => '4.15',
}

=example-1 unpack

  # given: synopsis;

  my $unpack = $type->unpack(["hello world"], ["string"]);

  # bless(..., "Venus::Unpack")

=cut

$test->for('example', 1, 'unpack', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Unpack');

  $result
});

=example-2 unpack

  # given: synopsis;

  my $unpack = $type->unpack(["hello world"], ["string | number"]);

  # bless(..., "Venus::Unpack")

=cut

$test->for('example', 2, 'unpack', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Unpack');

  $result
});

=method unpack_signature_input

Returns a L<Venus::Unpack> object based on the values and data structure
(representing a subroutine signature input expression) provided.

=signature unpack_signature_input

  unpack_signature_input(string $signature, arrayref $args) (Venus::Unpack)

=metadata unpack_signature_input

{
  since => '4.15',
}

=example-1 unpack_signature_input

  # given: synopsis;

  my $unpack_signature_input = $type->unpack_signature_input(
    'output(string $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

=cut

$test->for('example', 1, 'unpack_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Unpack');

  $result
});

=example-2 unpack_signature_input

  # given: synopsis;

  my $unpack_signature_input = $type->unpack_signature_input(
    'output(string | number $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

=cut

$test->for('example', 2, 'unpack_signature_input', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Unpack');

  $result
});

=method unpack_signature_output

Returns a L<Venus::Unpack> object based on the values and data structure
(representing a subroutine signature output expression) provided.

=signature unpack_signature_output

  unpack_signature_output(string $signature, arrayref $args) (Venus::Unpack)

=metadata unpack_signature_output

{
  since => '4.15',
}

=example-1 unpack_signature_output

  # given: synopsis;

  my $unpack_signature_output = $type->unpack_signature_output(
    'output(string $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

=cut

$test->for('example', 1, 'unpack_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Unpack');

  $result
});

=example-2 unpack_signature_output

  # given: synopsis;

  my $unpack_signature_output = $type->unpack_signature_output(
    'output(string | number $error) (string)', ["hello world"],
  );

  # bless(..., "Venus::Unpack")

=cut

$test->for('example', 2, 'unpack_signature_output', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Unpack');

  $result
});

=raise parse_signature Venus::Type::Error on.signature.parse

  package main;

  use Venus::Type;

  my $type = Venus::Type->new;

  $type->parse_signature('count()');

  # Error! (on.signature.parse)

=cut

$test->for('raise', 'parse_signature', 'Venus::Type::Error', 'on.signature.parse', sub {
  my ($tryable) = @_;

  $test->is_error(my $error = $tryable->error->result);

  $error
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Type.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
