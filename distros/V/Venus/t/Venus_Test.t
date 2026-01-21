package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Test

=cut

$test->for('name');

=tagline

Test Class

=cut

$test->for('tagline');

=abstract

Test Class for Perl 5

=cut

$test->for('abstract');

=includes

function: test
method: auto
method: diag
method: done
method: eval
method: explain
method: fail
method: for
method: gate
method: handler
method: in
method: is
method: is_arrayref
method: is_blessed
method: is_boolean
method: is_coderef
method: is_dirhandle
method: is_enum
method: is_error
method: is_false
method: is_fault
method: is_filehandle
method: is_float
method: is_glob
method: is_hashref
method: is_number
method: is_object
method: is_package
method: is_reference
method: is_regexp
method: is_scalarref
method: is_string
method: is_true
method: is_undef
method: is_value
method: is_yesno
method: isnt
method: isnt_arrayref
method: isnt_blessed
method: isnt_boolean
method: isnt_coderef
method: isnt_dirhandle
method: isnt_enum
method: isnt_error
method: isnt_false
method: isnt_fault
method: isnt_filehandle
method: isnt_float
method: isnt_glob
method: isnt_hashref
method: isnt_number
method: isnt_object
method: isnt_package
method: isnt_reference
method: isnt_regexp
method: isnt_scalarref
method: isnt_string
method: isnt_true
method: isnt_undef
method: isnt_value
method: isnt_yesno
method: lfile
method: like
method: mktemp_dir
method: mktemp_file
method: new
method: note
method: only_if
method: os
method: os_is_bsd
method: os_is_cyg
method: os_is_dos
method: os_is_lin
method: os_is_mac
method: os_is_non
method: os_is_sun
method: os_is_vms
method: os_is_win
method: os_isnt_bsd
method: os_isnt_cyg
method: os_isnt_dos
method: os_isnt_lin
method: os_isnt_mac
method: os_isnt_non
method: os_isnt_sun
method: os_isnt_vms
method: os_isnt_win
method: pass
method: patch
method: path
method: pfile
method: render
method: same
method: skip
method: skip_if
method: space
method: subtest
method: text
method: tfile
method: type
method: unlike
method: unpatch

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Test;

  my $test = Venus::Test->new('t/Venus_Test.t');

  # $test->for('name');

  # $test->for('tagline');

  # $test->for('abstract');

  # $test->for('synopsis');

  # $test->done;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  $test->okay($result->isa('Venus::Test'));

  $result
});

=description

This package aims to provide a standard for documenting L<Venus> derived
software projects, a framework writing tests, test automation, and
documentation generation. This package will automatically exports C<true>,
C<false>, and L</test> keyword functions.

+=cut

+=head1 SPECIFICATION

This section describes the specification format used by L<Venus::Test> to
generate documentation and automate testing for Perl packages. The
specification uses specially formatted POD blocks that serve as both
human-readable documentation and executable test cases.

B<Note:> When code blocks are evaluated, "redefined" warnings are automatically
disabled.

+=head2 Overview

A specification document consists of POD blocks that describe a package. The
blocks are organized into the following categories:

+=over 4

+=item * B<Required Blocks> - Must be present in every specification

+=item * B<Package Structure Blocks> - Define inheritance and dependencies

+=item * B<API Blocks> - Document attributes, methods, functions, etc.

+=item * B<Supporting Blocks> - Signatures, examples, metadata, and exceptions

+=item * B<Feature Blocks> - Special capabilities and operators

+=item * B<Document Control Blocks> - Layout and partial inclusions

+=item * B<Project Information Blocks> - Authors, license, version

+=back

+=head2 Quick Reference

  # [required]

  =name
  =abstract
  =tagline
  =synopsis
  =description

  # [optional]

  =encoding
  =includes
  =libraries
  =inherits
  =integrates

  # [optional; repeatable]

  =attribute $name
  =signature $name
  =metadata $name
  =example-$number $name
  =raise $name $error ($id optional)

  =function $name
  =signature $name
  =metadata $name
  =example-$number $name
  =raise $name $error ($id optional)

  =message $name
  =signature $name
  =metadata $name
  =example-$number $name

  =method $name
  =signature $name
  =metadata $name
  =example-$number $name
  =raise $name $error ($id optional)

  =routine $name
  =signature $name
  =metadata $name
  =example-$number $name
  =raise $name $error ($id optional)

  =feature $name
  =metadata $name
  =example-$number $name

  =error $name
  =example-$number $name

  =operator $name
  =example-$number $name

  # [optional]

  =layout
  =partials
  =authors
  =license
  =project
  =version

+=head1 REQUIRED BLOCKS

These blocks must be present in every specification document.

+=head2 name

  =name

  Example

  =cut

  $test->for('name');

The C<name> block should contain the package name. This is tested for
loadability.

+=head2 abstract

  =abstract

  Example Test Documentation

  =cut

  $test->for('abstract');

The C<abstract> block should contain a subtitle describing the package. This is
tested for existence.

+=head2 tagline

  =tagline

  Example Class

  =cut

  $test->for('tagline');

The C<tagline> block should contain a 2-5 word description of the package,
which will be prepended to the name as a full description of the package.

+=head2 synopsis

  =synopsis

    use Example;

    my $example = Example->new;

    # bless(..., "Example")

  =cut

  $test->for('synopsis', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<synopsis> block should contain the normative usage of the package. This
is tested for existence. This block should be written in a way that allows it
to be evaled successfully and should return a value.

+=head2 description

  =description

  This package provides an example class.

  =cut

  $test->for('description');

The C<description> block should contain a description of the package and its
behaviors.

+=head1 PACKAGE BLOCKS

These optional blocks define the package's relationships and dependencies.

+=head2 includes

  =includes

  function: eg

  method: prepare
  method: execute

  =cut

  $test->for('includes');

The C<includes> block should contain a list of C<function>, C<method>, and/or
C<routine> names in the format of C<$type: $name>. Empty (or commented out)
lines are ignored. Each function, method, and/or routine is tested to be
documented properly, i.e. has the requisite counterparts (e.g. signature and at
least one example block). Also, the package must recognize that each exists.

+=head2 libraries

  =libraries

  Venus::Check

  =cut

  $test->for('libraries');

The C<libraries> block should contain a list of packages, each describing how
particular type names used within function and method signatures will be
validated. These packages are tested for loadability.

+=head2 inherits

  =inherits

  Venus::Core::Class

  =cut

  $test->for('inherits');

The C<inherits> block should contain a list of parent packages. These packages
are tested for loadability.

+=head2 integrates

  =integrates

  Venus::Role::Catchable
  Venus::Role::Throwable

  =cut

  $test->for('integrates');

The C<integrates> block should contain a list of packages that are involved in
the behavior of the main package (typically roles). These packages are not
automatically tested.

+=head1 API BLOCKS

These blocks document the package's interface: attributes, methods, functions,
messages, and routines. Each API block follows a common pattern requiring a
description block, a signature block, and at least one example block.

+=head2 Common Pattern

All API blocks (attribute, function, message, method, routine) follow this
structure:

  =$type $name               # Description of the $type
  =signature $name           # Type signature
  =metadata $name            # Optional metadata (since, deprecated, etc.)
  =example-1 $name           # First example (required)
  =example-2 $name           # Additional examples (optional)
  =raise $name $error        # Document exceptions (optional)
  =raise $name $error $id    # Exception with named error (optional)
  ...

The C<signature> block should contain a routine signature in the form of
C<$signature : $return_type>, where C<$signature> is a valid typed signature
and C<$return_type> is any valid L<Venus::Check> expression.

The C<example-$number> block should contain valid Perl code and return a value.
Examples can include a "magic" comment to incorporate other code:

+=over 4

+=item * C<# given: synopsis> - Include the synopsis code

+=item * C<# given: example-$number $name> - Include another example's code

+=back

+=head2 attribute

  =attribute name

  The name attribute is read-write, optional, and holds a string.

  =signature name

    name(string $value) (string)

  =metadata name

  since: 1.0.0

  =example-1 name

    # given: synopsis

    my $name = $example->name;

    # "..."

  =cut

  $test->for('attribute', 'name');

  $test->for('example', 1, 'name', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<attribute> block should contain a description of the attribute and its
purpose. Each attribute is tested and must be recognized to exist.

+=head2 method

  =method prepare

  The prepare method prepares for execution.

  =signature prepare

    prepare() (boolean)

  =example-1 prepare

    # given: synopsis

    my $prepare = $example->prepare;

    # "..."

  =cut

  $test->for('method', 'prepare');

  $test->for('example', 1, 'prepare', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<method> block should contain a description of the method and its purpose.
Each method is tested and must be recognized to exist.

+=head2 function

  =function eg

  The eg function returns a new instance of Example.

  =signature eg

    eg() (Example)

  =example-1 eg

    # given: synopsis

    my $example = eg();

    # "..."

  =cut

  $test->for('function', 'eg');

  $test->for('example', 1, 'eg', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<function> block should contain a description of the function and its
purpose. Each function is tested and must be recognized to exist.

+=head2 routine

  =routine process

  The process routine processes and returns data.

  =signature process

    process(any @args) (any)

  =example-1 process

    # given: synopsis

    my $result = $example->process;

    # "..."

  =cut

  $test->for('routine', 'process');

  $test->for('example', 1, 'process', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<routine> block documents a subroutine that can be called as either a
function or a method. It follows the same pattern as method and function
blocks.

+=head2 message

  =message accept

  The accept message represents acceptance.

  =signature accept

    accept(any @args) (string)

  =example-1 accept

    # given: synopsis

    my $accept = $example->accept;

    # "..."

  =cut

  $test->for('message', 'accept');

  $test->for('example', 1, 'accept', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<message> block documents a method that returns a message string, typically
used for error messages or localization. It follows the same pattern as other
API blocks.

+=head1 SUPPORTING BLOCKS

These blocks provide additional context for API documentation.

+=head2 signature

  =signature prepare

    prepare() (boolean)

  =cut

  $test->for('signature', 'prepare');

The C<signature> block should contain a routine signature in the form of
C<$signature : $return_type>, where C<$signature> is a valid typed signature
and C<$return_type> is any valid L<Venus::Check> expression.

+=head2 example

  =example-1 name

    # given: synopsis

    my $name = $example->name;

    # "..."

  =cut

  $test->for('example', 1, 'name', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<example-$number $name> block should contain valid Perl code and return a
value. The block may contain a "magic" comment in the form of C<given:
synopsis> or C<given: example-$number $name> which if present will include the
given code example(s) with the evaluation of the current block.

+=head2 metadata

  =metadata prepare

  {since => "1.2.3"}

  =cut

  $test->for('metadata', 'prepare');

The C<metadata $name> block should contain a stringified hashref containing
Perl data structures used in the rendering of the package's documentation.
Metadata can also be specified as flat key/value pairs:

  =metadata prepare

  introduced: 1.2.3
  deprecated: 2.0.0

  =cut

+=head2 raise

  =raise execute Venus::Error

    # given: synopsis

    $example->operation; # throw exception

    # Error

  =cut

  $test->for('raise', 'execute', 'Venus::Error', sub {
    my ($tryable) = @_;
    my $error = $tryable->error->result;
    $test->is_error($error);
  });

The C<raise $name $error> block documents an exception that may be thrown by
an API (attribute, function, method, or routine). The parameters are:

+=over 4

+=item * C<$name> - The name of the attribute, function, method, or routine that may throw the exception.

+=item * C<$error> - The error class or package that may be caught (e.g., C<Venus::Error>, C<Example::Error>).

+=item * C<$id> (optional) - An error name for further classification within the error class.

+=back

The C<$error> represents the exception class that calling code can catch using
a try/catch mechanism. This links the API documentation to error handling
expectations.

An optional C<$id> can be appended to specify a named error. Venus::Error
objects support named errors for further classification:

  =raise execute Venus::Error on.unknown

    # given: synopsis

    $example->operation; # throw exception

    # Error (on.unknown)

  =cut

  $test->for('raise', 'execute', 'Venus::Error', 'on.unknown', sub {
    my ($tryable) = @_;
    my $error = $tryable->error->result;
    $test->is_error($error);
    $test->is($error->name, 'on.unknown');
  });

When C<$id> is provided, it indicates a specific named error within the error
class, allowing for more granular error documentation and handling.

+=head1 FEATURE BLOCKS

These blocks document special capabilities, errors, and operator overloads.

+=head2 feature

  =feature noop

  This package provides no particularly useful features.

  =example-1 noop

    # given: synopsis

    my $feature = $example->feature;

    # "..."

  =cut

  $test->for('feature');

  $test->for('example', 1, 'noop', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<feature $name> block should contain a description of the feature(s) the
package enables, and can include an C<example-$number $name> block to ensure
the feature described works as expected.

+=head2 error

  =error error_on_unknown

  This package may raise an error_on_unknown error.

  =example-1 error_on_unknown

    # given: synopsis

    my $error = $example->catch('error', {
      with => 'error_on_unknown',
    });

    # "..."

  =cut

  $test->for('error', 'error_on_unknown');

  $test->for('example', 1, 'error_on_unknown', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<error $name> block should contain a description of the error the package
may raise, and can include an C<example-$number $name> block to ensure the
error is raised and caught.

+=head2 operator

  =operator ("")

  This package overloads the C<""> operator.

  =example-1 ("")

    # given: synopsis

    my $string = "$example";

    # "..."

  =cut

  $test->for('operator', '("")');

  $test->for('example', 1, '("")', sub {
    my ($tryable) = @_;
    $tryable->result;
  });

The C<operator $name> block should contain a description of the overloaded
operation the package performs, and can include an C<example-$number $name>
block to ensure the operation is functioning properly.

+=head1 CONTROL BLOCKS

These blocks control how documentation is rendered.

+=head2 encoding

  =encoding

  utf8

  =cut

  $test->for('encoding');

The C<encoding> block should contain the appropriate
L<encoding|perlpod/encoding-encodingname>.

+=head2 layout

  =layout

  encoding
  name
  synopsis
  description
  attributes: attribute
  authors
  license

  =cut

  $test->for('layout');

The C<layout> block should contain a list of blocks to render using L</render>,
in the order they should be rendered.

+=head2 partials

  =partials

  t/path/to/other.t: present: authors
  t/path/to/other.t: present: license

  =cut

  $test->for('partials');

The C<partials> block should contain references to other marked-up test files
in the form of C<$file: $method: $section>, which will call the C<$method> on a
L<Venus::Test> instance for the C<$file> and include the results in-place as
part of the rendering of the current file.

+=head1 PROJECT BLOCKS

These blocks provide metadata about the project.

+=head2 authors

  =authors

  Awncorp, C<awncorp@cpan.org>

  =cut

  $test->for('authors');

The C<authors> block should contain text describing the authors of the package.

+=head2 license

  =license

  No license granted.

  =cut

  $test->for('license');

The C<license> block should contain a link and/or description of the license
governing the package.

+=head2 project

  =project

  https://github.com/awncorp/example

  =cut

  $test->for('project');

The C<project> block should contain a description and/or links for the
package's project.

+=head2 version

  =version

  1.2.3

  =cut

  $test->for('version');

The C<version> block should contain a valid version number for the package.

+=head1 TESTING

This framework provides automated subtests based on the package specification,
but also provides hooks for manual testing when automation is not sufficient.

+=head2 Basic Testing

For simple blocks, testing verifies existence:

  $test->for('name');
  $test->for('abstract');
  $test->for('description');

+=head2 Testing with Callbacks

Code examples can be evaluated and returned using a callback for further
testing:

  $test->for('synopsis', sub {
    my ($tryable) = @_;

    my $result = $tryable->result;

    # must return truthy to continue
    $result;
  });

+=head2 Exception Testing

Because code examples are returned as L<Venus::Try> objects, capturing and
testing exceptions is straightforward:

  $test->for('synopsis', sub {
    my ($tryable) = @_;

    # catch exception thrown by the synopsis
    $tryable->catch('Path::Find::Error', sub {
      return $_[0];
    });

    # test the exception
    my $result = $tryable->result;
    ok $result->isa('Path::Find::Error'), 'exception caught';

    # must return truthy to continue
    $result;
  });

+=head2 Testing Examples

The C<example> method evaluates a given example and returns the result as a
L<Venus::Try> object. The first argument is the example number:

  $test->for('example', 1, 'children', sub {
    my ($tryable) = @_;

    my $result = $tryable->result;

    # must return truthy to continue
    $result;
  });

+=head2 Testing Features

The C<feature> method evaluates a documented feature and returns the result as
a L<Venus::Try> object:

  $test->for('feature', 'export-path-make', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';

    # must return truthy to continue
    $result;
  });

+=head2 Benefits

The test automation and documentation generation enabled through this framework
makes it easy to maintain source/test/documentation parity. This also increases
reusability and reduces the need for complicated state and test setup.

=cut

$test->for('description');

=inherits

Venus::Kind

=cut

$test->for('inherits');

=integrates

Venus::Role::Buildable
Venus::Role::Encaseable

=cut

$test->for('integrates');

=attribute file

The file attribute is read-write, accepts C<(string)> values, and is required.

=signature file

  file(string $data) (string)

=metadata file

since: 4.15

=cut

=example-1 file

  # given: synopsis

  package main;

  my $set_file = $test->file("t/Venus_Test.t");

  # "t/Venus_Test.t"

=cut

$test->for('example', 1, 'file', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "t/Venus_Test.t";

  $result
});

=example-2 file

  # given: synopsis

  # given: example-1 file

  package main;

  my $get_file = $test->file;

  # "t/Venus_Test.t"

=cut

$test->for('example', 2, 'file', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "t/Venus_Test.t";

  $result
});

=function test

The test function is exported automatically and returns a L<Venus::Test> object
for the test file given.

=signature test

  test(string $file) (Venus::Test)

=metadata test

{
  since => '0.09',
}

=example-1 test

  package main;

  use Venus::Test;

  my $test = test 't/Venus_Test.t';

  # bless(..., "Venus::Test")

=cut

$test->for('example', 1, 'test', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  $test->okay_isa($result, 'Venus::Test');

  $result
});

=method done

The done method dispatches to the L<Test::More/done_testing> operation and
returns the result.

=signature done

  done() (any)

=metadata done

since: 4.15

=cut

=example-1 done

  # given: synopsis

  package main;

  my $done = $test->done;

  # true

=cut

$test->for('example', 1, 'done', sub {
  my ($tryable) = @_;
  my $space = $test->space('Test::More');
  my $call = 0;
  $space->patch('done_testing', sub {++$call});
  my $result = $tryable->result;
  is $result, 1;
  is $call, 1;
  $space->unpatch('done_testing');

  $result
});

=method explain

The explain method dispatches to the L<Test::More/explain> operation and
returns the result.

=signature explain

  explain(any @args) (any)

=metadata explain

since: 4.15

=cut

=example-1 explain

  # given: synopsis

  package main;

  my $explain = $test->explain(123.456);

  # "123.456"

=cut

$test->for('example', 1, 'explain', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "123.456";

  $result
});

=method fail

The fail method dispatches to the L<Test::More/ok> operation expecting the
first argument to be falsy and returns the result.

=signature fail

  fail(any $data, string $description) (any)

=metadata fail

since: 4.15

=cut

=example-1 fail

  # given: synopsis

  package main;

  my $fail = $test->fail(0, 'example-1 fail passed');

  # true

=cut

$test->for('example', 1, 'fail', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method for

The for method dispatches to the L</execute> method using the arguments
provided within a L<subtest|Test::More/subtest> and returns the invocant.

=signature for

  for(any @args) (Venus::Test)

=metadata for

since: 4.15

=cut

=example-1 for

  # given: synopsis

  package main;

  my $for = $test->for('name');

  # bless(..., "Venus::Test")

=cut

$test->for('example', 1, 'for', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Test";

  $result
});

=example-2 for

  # given: synopsis

  package main;

  my $for = $test->for('synopsis');

  # bless(..., "Venus::Test")

=cut

$test->for('example', 2, 'for', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Test";

  $result
});

=example-3 for

  # given: synopsis

  package main;

  my $for = $test->for('synopsis', sub{
    my ($tryable) = @_;
    return $tryable->result;
  });

  # bless(..., "Venus::Test")

=cut

$test->for('example', 3, 'for', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Test";

  $result
});

=example-4 for

  # given: synopsis

  package main;

  my $for = $test->for('example', 1, 'test', sub {
    my ($tryable) = @_;
    return $tryable->result;
  });

  # bless(..., "Venus::Test")

=cut

$test->for('example', 4, 'for', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Test";

  $result
});

=method handler

The handler method dispatches to the L<Test::More> method specified by the
first argument and returns its result.

=signature handler

  handler(any @args) (any)

=metadata handler

since: 4.15

=cut

=example-1 handler

  # given: synopsis

  package main;

  my $handler = $test->handler('ok', true);

  # true

=cut

$test->for('example', 1, 'handler', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=method like

The like method dispatches to the L<Test::More/like> operation and returns the
result.

=signature like

  like(string $data, string | Venus::Regexp $match, string $description) (any)

=metadata like

since: 4.15

=cut

=example-1 like

  # given: synopsis

  package main;

  my $like = $test->like('hello world', 'world', 'example-1 like passed');

  # true

=cut

$test->for('example', 1, 'like', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 like

  # given: synopsis

  package main;

  my $like = $test->like('hello world', qr/world/, 'example-1 like passed');

  # true

=cut

$test->for('example', 2, 'like', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Test)

=metadata new

since: 4.15

=cut

=example-1 new

  package main;

  use Venus::Test;

  my $new = Venus::Test->new;

  # bless(..., "Venus::Test")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Test');

  $result
});

=example-2 new

  package main;

  use Venus::Test;

  my $new = Venus::Test->new('t/Venus_Test.t');

  # bless(..., "Venus::Test")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Test');
  is $result->file, 't/Venus_Test.t';

  $result
});

=example-3 new

  package main;

  use Venus::Test;

  my $new = Venus::Test->new(file => 't/Venus_Test.t');

  # bless(..., "Venus::Test")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Test');
  is $result->file, 't/Venus_Test.t';

  $result
});

=method pass

The pass method dispatches to the L<Test::More/ok> operation expecting the
first argument to be truthy and returns the result.

=signature pass

  pass(any $data, string $description) (any)

=metadata pass

since: 4.15

=cut

=example-1 pass

  # given: synopsis

  package main;

  my $fail = $test->pass(1, 'example-1 pass passed');

  # true

=cut

$test->for('example', 1, 'pass', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method render

The render method reads the test specification and generates L<perlpod>
documentation and returns a L<Venus::Path> object for the filename provided.

=signature render

  render(string $file) (Venus::Path)

=metadata render

since: 4.15

=cut

=example-1 render

  # given: synopsis

  package main;

  my $path = $test->render('t/path/pod/test');

  # bless(..., "Venus::Path")

=cut

$test->for('example', 1, 'render', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Path";
  ok -f $result->absolute;
  my $lines = $result->read;
  like $lines, qr/=head1 NAME/;
  like $lines, qr/Venus::Test - Test Class/;
  like $lines, qr/=head1 ABSTRACT/;
  like $lines, qr/Test Class for Perl 5/;
  like $lines, qr/=head1 SYNOPSIS/;
  like $lines, qr/=head1 DESCRIPTION/;
  like $lines, qr/=head1 INHERITS/;
  like $lines, qr/=head1 INTEGRATES/;
  like $lines, qr/=head1 FUNCTIONS/;
  like $lines, qr/=head1 METHODS/;
  like $lines, qr/=head2 for/;
  like $lines, qr/=item for example 1/;
  like $lines, qr/=item for example 2/;
  like $lines, qr/=item for example 3/;
  like $lines, qr/=item for example 4/;
  like $lines, qr/=head2 text/;
  like $lines, qr/=item text example 1/;
  like $lines, qr/=head1 AUTHORS/;
  like $lines, qr/=head1 LICENSE/;

  $result
});

=method same

The same method dispatches to the L<Test::More/is_deeply> operation and returns
the result.

=signature same

  same(any $data1, any $data2, string $description) (any)

=metadata same

since: 4.15

=cut

=example-1 same

  # given: synopsis

  package main;

  my $same = $test->same({1..4}, {1..4}, 'example-1 same passed');

  # true

=cut

$test->for('example', 1, 'same', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method skip

The skip method dispatches to the L<Test::More/skip> operation with the
C<plan_all> option and returns the result.

=signature skip

  skip(string $reason) (any)

=metadata skip

since: 4.15

=cut

=example-1 skip

  # given: synopsis

  package main;

  my $skip = $test->skip('Unsupported');

  # true

=cut

$test->for('example', 1, 'skip', sub {
  my ($tryable) = @_;
  my $space = $test->space('Test::More');
  my $call = 0;
  $space->patch('plan', sub {++$call});
  my $result = $tryable->result;
  is $result, 1;
  is $call, 1;
  $space->unpatch('plan');

  $result
});

=method text

The text method returns a L<Venus::Text::Pod> object using L</file> for parsing
the test specification.

=signature text

  text() (Venus::Text::Pod)

=metadata text

since: 4.15

=cut

=example-1 text

  # given: synopsis

  package main;

  my $text = $test->text;

  # bless(..., "Venus::Text::Pod")

=cut

$test->for('example', 1, 'text', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Text::Pod";

  $result
});

=method auto

The auto method gets or sets environment variables that control automatic
behaviors in the testing framework. When called with just a name, it returns
the current value of the corresponding environment variable. When called with
a name and value, it sets the environment variable. The environment variable
name is derived from the name parameter as C<VENUS_TEST_AUTO_${NAME}>.

Supported auto settings:

+=over 4

+=item * C<bailout> - When truthy, bails out of testing on the first error.

+=item * C<render> - When truthy, automatically renders POD when L</done> is
called.

+=item * C<scrub> - When truthy, uses L<Venus::Space/scrub> to clean up packages
created in example code for testing.

+=item * C<unpatch> - When truthy, uses L<Venus::Space/unpatch> (via
L</unpatch>) to restore any existing monkey-patching on the package associated
with the test.

+=back

=cut

=signature auto

  auto(string $name, any @args) (any)

=metadata auto

since: 4.15

=cut

=example-1 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('render');

  # undef

=cut

$test->for('example', 1, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_RENDER};
  my $result = $tryable->result;
  ok !defined $result;
  delete $ENV{VENUS_TEST_AUTO_RENDER};

  !$result
});

=example-2 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('render', 1);

  # 1

=cut

$test->for('example', 2, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_RENDER};
  my $result = $tryable->result;
  ok $result;
  ok $ENV{VENUS_TEST_AUTO_RENDER};
  delete $ENV{VENUS_TEST_AUTO_RENDER};

  $result
});

=example-3 auto

  # given: synopsis

  package main;

  $test->auto('render', 1);

  my $auto = $test->auto('render');

  # 1

=cut

$test->for('example', 3, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_RENDER};
  my $result = $tryable->result;
  ok $result;
  delete $ENV{VENUS_TEST_AUTO_RENDER};

  $result
});

=example-4 auto

  # given: synopsis

  package main;

  $test->auto('render', 0);

  my $auto = $test->auto('render');

  # 0

=cut

$test->for('example', 4, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_RENDER};
  my $result = $tryable->result;
  ok defined $result;
  ok !$result;
  delete $ENV{VENUS_TEST_AUTO_RENDER};

  !$result
});

=example-5 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('bailout');

  # undef

=cut

$test->for('example', 5, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};
  my $result = $tryable->result;
  ok !defined $result;
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};

  !$result
});

=example-6 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('bailout', 1);

  # 1

=cut

$test->for('example', 6, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};
  my $result = $tryable->result;
  ok $result;
  ok $ENV{VENUS_TEST_AUTO_BAILOUT};
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};

  $result
});

=example-7 auto

  # given: synopsis

  package main;

  $test->auto('bailout', 1);

  my $auto = $test->auto('bailout');

  # 1

=cut

$test->for('example', 7, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};
  my $result = $tryable->result;
  ok $result;
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};

  $result
});

=example-8 auto

  # given: synopsis

  package main;

  $test->auto('bailout', 0);

  my $auto = $test->auto('bailout');

  # 0

=cut

$test->for('example', 8, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};
  my $result = $tryable->result;
  ok defined $result;
  ok !$result;
  delete $ENV{VENUS_TEST_AUTO_BAILOUT};

  !$result
});

=example-9 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('scrub');

  # undef

=cut

$test->for('example', 9, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_SCRUB};
  my $result = $tryable->result;
  ok !defined $result;
  delete $ENV{VENUS_TEST_AUTO_SCRUB};

  !$result
});

=example-10 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('scrub', 1);

  # 1

=cut

$test->for('example', 10, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_SCRUB};
  my $result = $tryable->result;
  ok $result;
  ok $ENV{VENUS_TEST_AUTO_SCRUB};
  delete $ENV{VENUS_TEST_AUTO_SCRUB};

  $result
});

=example-11 auto

  # given: synopsis

  package main;

  $test->auto('scrub', 1);

  my $auto = $test->auto('scrub');

  # 1

=cut

$test->for('example', 11, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_SCRUB};
  my $result = $tryable->result;
  ok $result;
  delete $ENV{VENUS_TEST_AUTO_SCRUB};

  $result
});

=example-12 auto

  # given: synopsis

  package main;

  $test->auto('scrub', 0);

  my $auto = $test->auto('scrub');

  # 0

=cut

$test->for('example', 12, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_SCRUB};
  my $result = $tryable->result;
  ok defined $result;
  ok !$result;
  delete $ENV{VENUS_TEST_AUTO_SCRUB};

  !$result
});

=example-13 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('unpatch');

  # undef

=cut

$test->for('example', 13, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};
  my $result = $tryable->result;
  ok !defined $result;
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};

  !$result
});

=example-14 auto

  # given: synopsis

  package main;

  my $auto = $test->auto('unpatch', 1);

  # 1

=cut

$test->for('example', 14, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};
  my $result = $tryable->result;
  ok $result;
  ok $ENV{VENUS_TEST_AUTO_UNPATCH};
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};

  $result
});

=example-15 auto

  # given: synopsis

  package main;

  $test->auto('unpatch', 1);

  my $auto = $test->auto('unpatch');

  # 1

=cut

$test->for('example', 15, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};
  my $result = $tryable->result;
  ok $result;
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};

  $result
});

=example-16 auto

  # given: synopsis

  package main;

  $test->auto('unpatch', 0);

  my $auto = $test->auto('unpatch');

  # 0

=cut

$test->for('example', 16, 'auto', sub {
  my ($tryable) = @_;
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};
  my $result = $tryable->result;
  ok defined $result;
  ok !$result;
  delete $ENV{VENUS_TEST_AUTO_UNPATCH};

  !$result
});

=method diag

The diag method prints diagnostic messages using L<Test::More/diag>.

=signature diag

  diag(string @messages) (any)

=metadata diag

since: 4.15

=cut

=example-1 diag

  # given: synopsis

  package main;

  my $diag = $test->diag('Test failed due to...');

  # ()

=cut

$test->for('example', 1, 'diag', sub {
  # my ($tryable) = @_;
  # my $result = $tryable->result;

  1
});

=method eval

The eval method evaluates Perl code and returns the result.

=signature eval

  eval(string $perl) (any)

=metadata eval

since: 4.15

=cut

=example-1 eval

  # given: synopsis

  package main;

  my $eval = $test->eval('1 + 1');

  # 2

=cut

$test->for('example', 1, 'eval', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, 2;

  $result
});

=method gate

The gate method creates a new L<Venus::Test> instance with a gate callback that
prevents subtests from running unless the callback returns a truthy value.

=signature gate

  gate(string $note, coderef $code) (Venus::Test)

=metadata gate

since: 4.15

=cut

=example-1 gate

  # given: synopsis

  package main;

  my $test2 = $test->gate('OS is linux', sub {
    $^O eq 'linux'
  });

  # bless(..., "Venus::Test")

=cut

$test->for('example', 1, 'gate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Test";

  $result
});

=method in

The in method checks if a value exists in a collection (arrayref, hashref, or
L<"mappable"|Venus::Role::Mappable> object) and returns true if the type and
value match.

=signature in

  in(arrayref | hashref | consumes[Venus::Role::Mappable] $collection, any $value) (boolean)

=metadata in

since: 4.15

=cut

=example-1 in

  # given: synopsis

  package main;

  my $in = $test->in([1, 2, 3], 2);

  # true

=cut

$test->for('example', 1, 'in', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is

The is method tests for equality using L<Test::More/is>.

=signature is

  is(any $data1, any $data2, string $description) (any)

=metadata is

since: 4.15

=cut

=example-1 is

  # given: synopsis

  package main;

  my $is = $test->is('hello', 'hello', 'strings match');

  # ()

=cut

$test->for('example', 1, 'is', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt

The isnt method tests for inequality using L<Test::More/isnt>.

=signature isnt

  isnt(any $data1, any $data2, string $description) (any)

=metadata isnt

since: 4.15

=cut

=example-1 isnt

  # given: synopsis

  package main;

  my $isnt = $test->isnt('hello', 'world', 'strings differ');

  # ()

=cut

$test->for('example', 1, 'isnt', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method lfile

The lfile method returns the path to a lib file for the package being tested.

=signature lfile

  lfile() (Venus::Path)

=metadata lfile

since: 4.15

=cut

=example-1 lfile

  # given: synopsis

  package main;

  my $lfile = $test->lfile;

  # "lib/Venus/Test.pm"

=cut

$test->for('example', 1, 'lfile', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  like $result, qr/lib\/Venus\/Test\.pm$/;

  $result
});

=method mktemp_dir

The mktemp_dir method creates and returns a temporary directory as a
L<Venus::Path> object.

=signature mktemp_dir

  mktemp_dir() (Venus::Path)

=metadata mktemp_dir

since: 4.15

=cut

=example-1 mktemp_dir

  # given: synopsis

  package main;

  my $mktemp_dir = $test->mktemp_dir;

  # bless(..., "Venus::Path")

=cut

$test->for('example', 1, 'mktemp_dir', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Path";
  ok $result->exists;
  ok $result->is_directory;

  $result
});

=method mktemp_file

The mktemp_file method creates and returns a temporary file as a L<Venus::Path>
object.

=signature mktemp_file

  mktemp_file() (Venus::Path)

=metadata mktemp_file

since: 4.15

=cut

=example-1 mktemp_file

  # given: synopsis

  package main;

  my $mktemp_file = $test->mktemp_file;

  # bless(..., "Venus::Path")

=cut

$test->for('example', 1, 'mktemp_file', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Path";
  ok $result->exists;
  ok $result->is_file;

  $result
});

=method note

The note method prints debugging messages using L<Test::More/diag> and
L<Test::More/explain>.

=signature note

  note(string @messages) (any)

=metadata note

since: 4.15

=cut

=example-1 note

  # given: synopsis

  package main;

  my $note = $test->note('Example note...');

  # ()

=cut

$test->for('example', 1, 'note', sub {
  # my ($tryable) = @_;
  # my $result = $tryable->result;

  1
});

=method only_if

The only_if method creates a gate that only runs subtests if the callback
returns a truthy value.

=signature only_if

  only_if(string | coderef $code) (Venus::Test)

=metadata only_if

since: 4.15

=cut

=example-1 only_if

  # given: synopsis

  package main;

  my $gate = $test->only_if('os_is_mac');

  # bless(..., "Venus::Test")

=cut

$test->for('example', 1, 'only_if', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Test";

  $result
});

=method os

The os method returns a L<Venus::Os> object.

=signature os

  os() (Venus::Os)

=metadata os

since: 4.15

=cut

=example-1 os

  # given: synopsis

  package main;

  my $os = $test->os;

  # bless(..., "Venus::Os")

=cut

$test->for('example', 1, 'os', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Os";

  $result
});

=method patch

The patch method monkey-patches the named subroutine and returns the original
coderef.

=signature patch

  patch(string $name, coderef $code) (coderef)

=metadata patch

since: 4.15

=cut

=example-1 patch

  # given: synopsis

  package main;

  my $orig = $test->patch('pass', sub {
    return 'patched';
  });

  # sub {...}

  $test->unpatch;

  # bless(..., "Venus::Space")

  $orig

  # sub {...}

=cut

$test->for('example', 1, 'patch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  $test->is_coderef($result);

  $result
});

=method path

The path method returns a L<Venus::Path> object for the given path. Defaults to
the test file.

=signature path

  path(string $path) (Venus::Path)

=metadata path

since: 4.15

=cut

=example-1 path

  # given: synopsis

  package main;

  my $path = $test->path('t/Venus_Test.t');

  # bless(..., "Venus::Path")

=cut

$test->for('example', 1, 'path', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Path";
  like $result->get, qr/t\/Venus_Test\.t$/;

  $result
});

=method pfile

The pfile method returns the path to a pod file for the package being tested.

=signature pfile

  pfile() (Venus::Path)

=metadata pfile

since: 4.15

=cut

=example-1 pfile

  # given: synopsis

  package main;

  my $pfile = $test->pfile;

  # "lib/Venus/Test.pod"

=cut

$test->for('example', 1, 'pfile', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  like $result, qr/lib\/Venus\/Test\.pod$/;

  $result
});

=method skip_if

The skip_if method creates a gate that only runs subtests if the callback
returns a falsy value.

=signature skip_if

  skip_if(string | coderef $code) (Venus::Test)

=metadata skip_if

since: 4.15

=cut

=example-1 skip_if

  # given: synopsis

  package main;

  my $gate = $test->skip_if('os_is_mac');

  # bless(..., "Venus::Test")

=cut

$test->for('example', 1, 'skip_if', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Test";

  $result
});

=method space

The space method returns a L<Venus::Space> object for the package being tested,
or for the package name provided.

=signature space

  space(string $package) (Venus::Space)

=metadata space

since: 4.15

=cut

=example-1 space

  # given: synopsis

  package main;

  my $space = $test->space;

  # bless(..., "Venus::Space")

=cut

$test->for('example', 1, 'space', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Space";
  is $result->package, "Venus::Test";

  $result
});

=example-2 space

  # given: synopsis

  package main;

  my $space = $test->space('Venus::Path');

  # bless(..., "Venus::Space")

=cut

$test->for('example', 2, 'space', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Space";
  is $result->package, "Venus::Path";

  $result
});

=method subtest

The subtest method runs a subtest using L<Test::More/subtest>. Enclosed tests
maybe be made conditional using a L</gate>, e.g., L</only_if> and L</skip_if>.

=signature subtest

  subtest(string $name, coderef $code) (any)

=metadata subtest

since: 4.15

=cut

=example-1 subtest

  # given: synopsis

  package main;

  my $subtest = $test->subtest('test something', sub {
    $test->pass('it works');
  });

  # ()

=cut

$test->for('example', 1, 'subtest', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  1
});

=method tfile

The tfile method returns the path to a test file for the package being tested.

=signature tfile

  tfile() (Venus::Path)

=metadata tfile

since: 4.15

=cut

=example-1 tfile

  # given: synopsis

  package main;

  my $tfile = $test->tfile;

  # "t/Venus_Test.t"

=cut

$test->for('example', 1, 'tfile', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  like $result, qr/t\/Venus_Test\.t$/;

  $result
});

=method type

The type method performs type assertion using L<Venus::Type> and tests if the
data matches the type expression.

=signature type

  type(any $data, string $expression, string @args) (boolean)

=metadata type

since: 4.15

=cut

=example-1 type

  # given: synopsis

  package main;

  my $type = $test->type([1,2,3], 'arrayref', 'valid arrayref');

  # true

=cut

$test->for('example', 1, 'type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method unlike

The unlike method tests that a string doesn't match a regex using
L<Test::More/unlike>.

=signature unlike

  unlike(string $data, regexp $regex, string $description) (any)

=metadata unlike

since: 4.15

=cut

=example-1 unlike

  # given: synopsis

  package main;

  my $unlike = $test->unlike('hello', qr/world/, 'does not match');

  # ()

=cut

$test->for('example', 1, 'unlike', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method unpatch

The unpatch method undoes patches by name, or undoes all patches if no names
are provided.

=signature unpatch

  unpatch(string @names) (Venus::Space)

=metadata unpatch

since: 4.15

=cut

=example-1 unpatch

  # given: synopsis

  package main;

  $test->patch('pass', sub {'patched'});

  # sub {...}

  my $unpatch = $test->unpatch('pass');

  # bless(..., "Venus::Space")

=cut

$test->for('example', 1, 'unpatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Space";

  $result
});

=method is_arrayref

The is_arrayref method tests whether the data is an arrayref using
L<Venus/is_arrayref>.

=signature is_arrayref

  is_arrayref(any $data, string @args) (boolean)

=metadata is_arrayref

since: 4.15

=cut

=example-1 is_arrayref

  # given: synopsis

  package main;

  my $is_arrayref = $test->is_arrayref([1,2,3], 'valid arrayref');

  # true

=cut

$test->for('example', 1, 'is_arrayref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_blessed

The is_blessed method tests whether the data is blessed using
L<Venus/is_blessed>.

=signature is_blessed

  is_blessed(any $data, string @args) (boolean)

=metadata is_blessed

since: 4.15

=cut

=example-1 is_blessed

  # given: synopsis

  package main;

  my $is_blessed = $test->is_blessed(bless({}), 'valid blessed');

  # true

=cut

$test->for('example', 1, 'is_blessed', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_boolean

The is_boolean method tests whether the data is a boolean using
L<Venus/is_boolean>.

=signature is_boolean

  is_boolean(any $data, string @args) (boolean)

=metadata is_boolean

since: 4.15

=cut

=example-1 is_boolean

  # given: synopsis

  package main;

  require Venus;

  my $is_boolean = $test->is_boolean(true, 'valid boolean');

  # true

=cut

$test->for('example', 1, 'is_boolean', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_coderef

The is_coderef method tests whether the data is a coderef using
L<Venus/is_coderef>.

=signature is_coderef

  is_coderef(any $data, string @args) (boolean)

=metadata is_coderef

since: 4.15

=cut

=example-1 is_coderef

  # given: synopsis

  package main;

  my $is_coderef = $test->is_coderef(sub{}, 'valid coderef');

  # true

=cut

$test->for('example', 1, 'is_coderef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_hashref

The is_hashref method tests whether the data is a hashref using
L<Venus/is_hashref>.

=signature is_hashref

  is_hashref(any $data, string @args) (boolean)

=metadata is_hashref

since: 4.15

=cut

=example-1 is_hashref

  # given: synopsis

  package main;

  my $is_hashref = $test->is_hashref({a=>1}, 'valid hashref');

  # true

=cut

$test->for('example', 1, 'is_hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_number

The is_number method tests whether the data is a number using
L<Venus/is_number>.

=signature is_number

  is_number(any $data, string @args) (boolean)

=metadata is_number

since: 4.15

=cut

=example-1 is_number

  # given: synopsis

  package main;

  my $is_number = $test->is_number(123, 'valid number');

  # true

=cut

$test->for('example', 1, 'is_number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_object

The is_object method tests whether the data is an object using
L<Venus/is_object>.

=signature is_object

  is_object(any $data, string @args) (boolean)

=metadata is_object

since: 4.15

=cut

=example-1 is_object

  # given: synopsis

  package main;

  my $is_object = $test->is_object(bless({}), 'valid object');

  # true

=cut

$test->for('example', 1, 'is_object', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_regexp

The is_regexp method tests whether the data is a regexp using
L<Venus/is_regexp>.

=signature is_regexp

  is_regexp(any $data, string @args) (boolean)

=metadata is_regexp

since: 4.15

=cut

=example-1 is_regexp

  # given: synopsis

  package main;

  my $is_regexp = $test->is_regexp(qr/test/, 'valid regexp');

  # true

=cut

$test->for('example', 1, 'is_regexp', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_string

The is_string method tests whether the data is a string using
L<Venus/is_string>.

=signature is_string

  is_string(any $data, string @args) (boolean)

=metadata is_string

since: 4.15

=cut

=example-1 is_string

  # given: synopsis

  package main;

  my $is_string = $test->is_string('hello', 'valid string');

  # true

=cut

$test->for('example', 1, 'is_string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_undef

The is_undef method tests whether the data is undef using L<Venus/is_undef>.

=signature is_undef

  is_undef(any $data, string @args) (boolean)

=metadata is_undef

since: 4.15

=cut

=example-1 is_undef

  # given: synopsis

  package main;

  my $is_undef = $test->is_undef(undef, 'valid undef');

  # true

=cut

$test->for('example', 1, 'is_undef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_dirhandle

The is_dirhandle method tests whether the data is a directory handle using
L<Venus/is_dirhandle>.

=signature is_dirhandle

  is_dirhandle(any $data, string @args) (boolean)

=metadata is_dirhandle

since: 4.15

=cut

=example-1 is_dirhandle

  # given: synopsis

  package main;

  opendir(my $dh, '.');
  my $is_dirhandle = $test->is_dirhandle($dh, 'valid dirhandle');

  # true

=cut

# Unsupported on Windows: The dirfd function is unimplemented
$test->skip_if('os_is_win')->for('example', 1, 'is_dirhandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_enum

The is_enum method tests whether the data is an enum using L<Venus/is_enum>.

=signature is_enum

  is_enum(any $data, arrayref | hashref $data, string @args) (boolean)

=metadata is_enum

since: 4.15

=cut

=example-1 is_enum

  # given: synopsis

  package main;

  $test->is_enum('light', ['light', 'dark'], 'is in enum');

  # true

=cut

$test->for('example', 1, 'is_enum', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_error

The is_error method tests whether the data is a Venus::Error object using
L<Venus/is_error>.

=signature is_error

  is_error(any $data, string @args) (boolean)

=metadata is_error

since: 4.15

=cut

=example-1 is_error

  # given: synopsis

  package main;

  use Venus::Error;

  my $is_error = $test->is_error(Venus::Error->new, 'valid error');

  # true

=cut

$test->for('example', 1, 'is_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_false

The is_false method tests whether the data is a false value using
L<Venus/is_false>.

=signature is_false

  is_false(any $data, string @args) (boolean)

=metadata is_false

since: 4.15

=cut

=example-1 is_false

  # given: synopsis

  package main;

  my $is_false = $test->is_false(0, 'valid false');

  # true

=cut

$test->for('example', 1, 'is_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_fault

The is_fault method tests whether the data is a Venus::Fault object using
L<Venus/is_fault>.

=signature is_fault

  is_fault(any $data, string @args) (boolean)

=metadata is_fault

since: 4.15

=cut

=example-1 is_fault

  # given: synopsis

  package main;

  use Venus::Fault;

  my $is_fault = $test->is_fault(Venus::Fault->new, 'valid fault');

  # true

=cut

$test->for('example', 1, 'is_fault', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_filehandle

The is_filehandle method tests whether the data is a file handle using
L<Venus/is_filehandle>.

=signature is_filehandle

  is_filehandle(any $data, string @args) (boolean)

=metadata is_filehandle

since: 4.15

=cut

=example-1 is_filehandle

  # given: synopsis

  package main;

  open(my $fh, '<', 't/Venus_Test.t');
  my $is_filehandle = $test->is_filehandle($fh, 'valid filehandle');

  # true

=cut

$test->for('example', 1, 'is_filehandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_float

The is_float method tests whether the data is a float using L<Venus/is_float>.

=signature is_float

  is_float(any $data, string @args) (boolean)

=metadata is_float

since: 4.15

=cut

=example-1 is_float

  # given: synopsis

  package main;

  my $is_float = $test->is_float(1.5, 'valid float');

  # true

=cut

$test->for('example', 1, 'is_float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_glob

The is_glob method tests whether the data is a glob reference using
L<Venus/is_glob>.

=signature is_glob

  is_glob(any $data, string @args) (boolean)

=metadata is_glob

since: 4.15

=cut

=example-1 is_glob

  # given: synopsis

  package main;

  my $is_glob = $test->is_glob(\*STDOUT, 'valid glob');

  # true

=cut

$test->for('example', 1, 'is_glob', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_package

The is_package method tests whether the data is a package name using
L<Venus/is_package>.

=signature is_package

  is_package(any $data, string @args) (boolean)

=metadata is_package

since: 4.15

=cut

=example-1 is_package

  # given: synopsis

  package main;

  my $is_package = $test->is_package('Venus::Test', 'valid package');

  # true

=cut

$test->for('example', 1, 'is_package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_reference

The is_reference method tests whether the data is a reference using
L<Venus/is_reference>.

=signature is_reference

  is_reference(any $data, string @args) (boolean)

=metadata is_reference

since: 4.15

=cut

=example-1 is_reference

  # given: synopsis

  package main;

  my $is_reference = $test->is_reference([], 'valid reference');

  # true

=cut

$test->for('example', 1, 'is_reference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_scalarref

The is_scalarref method tests whether the data is a scalar reference using
L<Venus/is_scalarref>.

=signature is_scalarref

  is_scalarref(any $data, string @args) (boolean)

=metadata is_scalarref

since: 4.15

=cut

=example-1 is_scalarref

  # given: synopsis

  package main;

  my $scalar = 'hello';
  my $is_scalarref = $test->is_scalarref(\$scalar, 'valid scalarref');

  # true

=cut

$test->for('example', 1, 'is_scalarref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_true

The is_true method tests whether the data is a true value using L<Venus/is_true>.

=signature is_true

  is_true(any $data, string @args) (boolean)

=metadata is_true

since: 4.15

=cut

=example-1 is_true

  # given: synopsis

  package main;

  my $is_true = $test->is_true(1, 'valid true');

  # true

=cut

$test->for('example', 1, 'is_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_value

The is_value method tests whether the data is a defined value using
L<Venus/is_value>.

=signature is_value

  is_value(any $data, string @args) (boolean)

=metadata is_value

since: 4.15

=cut

=example-1 is_value

  # given: synopsis

  package main;

  my $is_value = $test->is_value('hello', 'valid value');

  # true

=cut

$test->for('example', 1, 'is_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method is_yesno

The is_yesno method tests whether the data is a yes/no value using
L<Venus/is_yesno>.

=signature is_yesno

  is_yesno(any $data, string @args) (boolean)

=metadata is_yesno

since: 4.15

=cut

=example-1 is_yesno

  # given: synopsis

  package main;

  my $is_yesno = $test->is_yesno(1, 'valid yesno');

  # true

=cut

$test->for('example', 1, 'is_yesno', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_arrayref

The isnt_arrayref method tests whether the data is not an arrayref.

=signature isnt_arrayref

  isnt_arrayref(any $data, string @args) (boolean)

=metadata isnt_arrayref

since: 4.15

=cut

=example-1 isnt_arrayref

  # given: synopsis

  package main;

  my $isnt_arrayref = $test->isnt_arrayref({}, 'not an arrayref');

  # true

=cut

$test->for('example', 1, 'isnt_arrayref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_hashref

The isnt_hashref method tests whether the data is not a hashref.

=signature isnt_hashref

  isnt_hashref(any $data, string @args) (boolean)

=metadata isnt_hashref

since: 4.15

=cut

=example-1 isnt_hashref

  # given: synopsis

  package main;

  my $isnt_hashref = $test->isnt_hashref([], 'not a hashref');

  # true

=cut

$test->for('example', 1, 'isnt_hashref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_blessed

The isnt_blessed method tests whether the data is not a blessed object.

=signature isnt_blessed

  isnt_blessed(any $data, string @args) (boolean)

=metadata isnt_blessed

since: 4.15

=cut

=example-1 isnt_blessed

  # given: synopsis

  package main;

  my $isnt_blessed = $test->isnt_blessed('string', 'not blessed');

  # true

=cut

$test->for('example', 1, 'isnt_blessed', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_boolean

The isnt_boolean method tests whether the data is not a boolean.

=signature isnt_boolean

  isnt_boolean(any $data, string @args) (boolean)

=metadata isnt_boolean

since: 4.15

=cut

=example-1 isnt_boolean

  # given: synopsis

  package main;

  my $isnt_boolean = $test->isnt_boolean('string', 'not boolean');

  # true

=cut

$test->for('example', 1, 'isnt_boolean', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_coderef

The isnt_coderef method tests whether the data is not a coderef.

=signature isnt_coderef

  isnt_coderef(any $data, string @args) (boolean)

=metadata isnt_coderef

since: 4.15

=cut

=example-1 isnt_coderef

  # given: synopsis

  package main;

  my $isnt_coderef = $test->isnt_coderef('string', 'not coderef');

  # true

=cut

$test->for('example', 1, 'isnt_coderef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_dirhandle

The isnt_dirhandle method tests whether the data is not a directory handle.

=signature isnt_dirhandle

  isnt_dirhandle(any $data, string @args) (boolean)

=metadata isnt_dirhandle

since: 4.15

=cut

=example-1 isnt_dirhandle

  # given: synopsis

  package main;

  my $isnt_dirhandle = $test->isnt_dirhandle('string', 'not dirhandle');

  # true

=cut

$test->for('example', 1, 'isnt_dirhandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_enum

The isnt_enum method tests whether the data is not an enum.

=signature isnt_enum

  isnt_enum(any $data, arrayref | hashref $data, string @args) (boolean)

=metadata isnt_enum

since: 4.15

=cut

=example-1 isnt_enum

  # given: synopsis

  package main;

  my $isnt_enum = $test->isnt_enum('light', [], 'not in enum');

  # true

=cut

$test->for('example', 1, 'isnt_enum', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_error

The isnt_error method tests whether the data is not a Venus::Error object.

=signature isnt_error

  isnt_error(any $data, string @args) (boolean)

=metadata isnt_error

since: 4.15

=cut

=example-1 isnt_error

  # given: synopsis

  package main;

  my $isnt_error = $test->isnt_error('string', 'not error');

  # true

=cut

$test->for('example', 1, 'isnt_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_false

The isnt_false method tests whether the data is not a false value.

=signature isnt_false

  isnt_false(any $data, string @args) (boolean)

=metadata isnt_false

since: 4.15

=cut

=example-1 isnt_false

  # given: synopsis

  package main;

  my $isnt_false = $test->isnt_false(1, 'not false');

  # true

=cut

$test->for('example', 1, 'isnt_false', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_fault

The isnt_fault method tests whether the data is not a Venus::Fault object.

=signature isnt_fault

  isnt_fault(any $data, string @args) (boolean)

=metadata isnt_fault

since: 4.15

=cut

=example-1 isnt_fault

  # given: synopsis

  package main;

  my $isnt_fault = $test->isnt_fault('string', 'not fault');

  # true

=cut

$test->for('example', 1, 'isnt_fault', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_filehandle

The isnt_filehandle method tests whether the data is not a file handle.

=signature isnt_filehandle

  isnt_filehandle(any $data, string @args) (boolean)

=metadata isnt_filehandle

since: 4.15

=cut

=example-1 isnt_filehandle

  # given: synopsis

  package main;

  my $isnt_filehandle = $test->isnt_filehandle('string', 'not filehandle');

  # true

=cut

$test->for('example', 1, 'isnt_filehandle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_float

The isnt_float method tests whether the data is not a float.

=signature isnt_float

  isnt_float(any $data, string @args) (boolean)

=metadata isnt_float

since: 4.15

=cut

=example-1 isnt_float

  # given: synopsis

  package main;

  my $isnt_float = $test->isnt_float(123, 'not float');

  # true

=cut

$test->for('example', 1, 'isnt_float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_glob

The isnt_glob method tests whether the data is not a glob reference.

=signature isnt_glob

  isnt_glob(any $data, string @args) (boolean)

=metadata isnt_glob

since: 4.15

=cut

=example-1 isnt_glob

  # given: synopsis

  package main;

  my $isnt_glob = $test->isnt_glob('string', 'not glob');

  # true

=cut

$test->for('example', 1, 'isnt_glob', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_number

The isnt_number method tests whether the data is not a number.

=signature isnt_number

  isnt_number(any $data, string @args) (boolean)

=metadata isnt_number

since: 4.15

=cut

=example-1 isnt_number

  # given: synopsis

  package main;

  my $isnt_number = $test->isnt_number('string', 'not number');

  # true

=cut

$test->for('example', 1, 'isnt_number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_object

The isnt_object method tests whether the data is not an object.

=signature isnt_object

  isnt_object(any $data, string @args) (boolean)

=metadata isnt_object

since: 4.15

=cut

=example-1 isnt_object

  # given: synopsis

  package main;

  my $isnt_object = $test->isnt_object('string', 'not object');

  # true

=cut

$test->for('example', 1, 'isnt_object', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_package

The isnt_package method tests whether the data is not a package name.

=signature isnt_package

  isnt_package(any $data, string @args) (boolean)

=metadata isnt_package

since: 4.15

=cut

=example-1 isnt_package

  # given: synopsis

  package main;

  my $isnt_package = $test->isnt_package([], 'not package');

  # true

=cut

$test->for('example', 1, 'isnt_package', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_reference

The isnt_reference method tests whether the data is not a reference.

=signature isnt_reference

  isnt_reference(any $data, string @args) (boolean)

=metadata isnt_reference

since: 4.15

=cut

=example-1 isnt_reference

  # given: synopsis

  package main;

  my $isnt_reference = $test->isnt_reference('string', 'not reference');

  # true

=cut

$test->for('example', 1, 'isnt_reference', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_regexp

The isnt_regexp method tests whether the data is not a regexp.

=signature isnt_regexp

  isnt_regexp(any $data, string @args) (boolean)

=metadata isnt_regexp

since: 4.15

=cut

=example-1 isnt_regexp

  # given: synopsis

  package main;

  my $isnt_regexp = $test->isnt_regexp('string', 'not regexp');

  # true

=cut

$test->for('example', 1, 'isnt_regexp', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_scalarref

The isnt_scalarref method tests whether the data is not a scalar reference.

=signature isnt_scalarref

  isnt_scalarref(any $data, string @args) (boolean)

=metadata isnt_scalarref

since: 4.15

=cut

=example-1 isnt_scalarref

  # given: synopsis

  package main;

  my $isnt_scalarref = $test->isnt_scalarref('string', 'not scalarref');

  # true

=cut

$test->for('example', 1, 'isnt_scalarref', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_string

The isnt_string method tests whether the data is not a string.

=signature isnt_string

  isnt_string(any $data, string @args) (boolean)

=metadata isnt_string

since: 4.15

=cut

=example-1 isnt_string

  # given: synopsis

  package main;

  my $isnt_string = $test->isnt_string([], 'not string');

  # true

=cut

$test->for('example', 1, 'isnt_string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_true

The isnt_true method tests whether the data is not a true value.

=signature isnt_true

  isnt_true(any $data, string @args) (boolean)

=metadata isnt_true

since: 4.15

=cut

=example-1 isnt_true

  # given: synopsis

  package main;

  my $isnt_true = $test->isnt_true(0, 'not true');

  # true

=cut

$test->for('example', 1, 'isnt_true', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_undef

The isnt_undef method tests whether the data is not undef.

=signature isnt_undef

  isnt_undef(any $data, string @args) (boolean)

=metadata isnt_undef

since: 4.15

=cut

=example-1 isnt_undef

  # given: synopsis

  package main;

  my $isnt_undef = $test->isnt_undef('string', 'not undef');

  # true

=cut

$test->for('example', 1, 'isnt_undef', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_value

The isnt_value method tests whether the data is not a defined value.

=signature isnt_value

  isnt_value(any $data, string @args) (boolean)

=metadata isnt_value

since: 4.15

=cut

=example-1 isnt_value

  # given: synopsis

  package main;

  my $isnt_value = $test->isnt_value(undef, 'not value');

  # true

=cut

$test->for('example', 1, 'isnt_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method isnt_yesno

The isnt_yesno method tests whether the data is not a yes/no value.

=signature isnt_yesno

  isnt_yesno(any $data, string @args) (boolean)

=metadata isnt_yesno

since: 4.15

=cut

=example-1 isnt_yesno

  # given: synopsis

  package main;

  my $isnt_yesno = $test->isnt_yesno('string', 'not yesno');

  # true

=cut

$test->for('example', 1, 'isnt_yesno', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;

  $result
});

=method os_is_bsd

The os_is_bsd method returns true if the operating system is BSD.

=signature os_is_bsd

  os_is_bsd() (boolean)

=metadata os_is_bsd

since: 4.15

=cut

=example-1 os_is_bsd

  # given: synopsis

  package main;

  my $os_is_bsd = $test->os_is_bsd;

  # true

=cut

$test->only_if('os_is_bsd')->for('example', 1, 'os_is_bsd', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_lin

The os_is_lin method returns true if the operating system is Linux.

=signature os_is_lin

  os_is_lin() (boolean)

=metadata os_is_lin

since: 4.15

=cut

=example-1 os_is_lin

  # given: synopsis

  package main;

  my $os_is_lin = $test->os_is_lin;

  # true

=cut

$test->only_if('os_is_lin')->for('example', 1, 'os_is_lin', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_mac

The os_is_mac method returns true if the operating system is macOS.

=signature os_is_mac

  os_is_mac() (boolean)

=metadata os_is_mac

since: 4.15

=cut

=example-1 os_is_mac

  # given: synopsis

  package main;

  my $os_is_mac = $test->os_is_mac;

  # true

=cut

$test->only_if('os_is_mac')->for('example', 1, 'os_is_mac', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_cyg

The os_is_cyg method returns true if the operating system is Cygwin.

=signature os_is_cyg

  os_is_cyg() (boolean)

=metadata os_is_cyg

since: 4.15

=cut

=example-1 os_is_cyg

  # given: synopsis

  package main;

  my $os_is_cyg = $test->os_is_cyg;

  # true

=cut

$test->only_if('os_is_cyg')->for('example', 1, 'os_is_cyg', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_dos

The os_is_dos method returns true if the operating system is DOS.

=signature os_is_dos

  os_is_dos() (boolean)

=metadata os_is_dos

since: 4.15

=cut

=example-1 os_is_dos

  # given: synopsis

  package main;

  my $os_is_dos = $test->os_is_dos;

  # true

=cut

$test->only_if('os_is_dos')->for('example', 1, 'os_is_dos', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_non

The os_is_non method returns true if the operating system is non-Unix.

=signature os_is_non

  os_is_non() (boolean)

=metadata os_is_non

since: 4.15

=cut

=example-1 os_is_non

  # given: synopsis

  package main;

  my $os_is_non = $test->os_is_non;

  # true

=cut

$test->only_if('os_is_non')->for('example', 1, 'os_is_non', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_sun

The os_is_sun method returns true if the operating system is Solaris.

=signature os_is_sun

  os_is_sun() (boolean)

=metadata os_is_sun

since: 4.15

=cut

=example-1 os_is_sun

  # given: synopsis

  package main;

  my $os_is_sun = $test->os_is_sun;

  # true

=cut

$test->only_if('os_is_sun')->for('example', 1, 'os_is_sun', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_vms

The os_is_vms method returns true if the operating system is VMS.

=signature os_is_vms

  os_is_vms() (boolean)

=metadata os_is_vms

since: 4.15

=cut

=example-1 os_is_vms

  # given: synopsis

  package main;

  my $os_is_vms = $test->os_is_vms;

  # true

=cut

$test->only_if('os_is_vms')->for('example', 1, 'os_is_vms', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_is_win

The os_is_win method returns true if the operating system is Windows.

=signature os_is_win

  os_is_win() (boolean)

=metadata os_is_win

since: 4.15

=cut

=example-1 os_is_win

  # given: synopsis

  package main;

  my $os_is_win = $test->os_is_win;

  # true

=cut

$test->only_if('os_is_win')->for('example', 1, 'os_is_win', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_bsd

The os_isnt_bsd method returns true if the operating system is not BSD.

=signature os_isnt_bsd

  os_isnt_bsd() (boolean)

=metadata os_isnt_bsd

since: 4.15

=cut

=example-1 os_isnt_bsd

  # given: synopsis

  package main;

  my $os_isnt_bsd = $test->os_isnt_bsd;

  # true

=cut

$test->skip_if('os_is_bsd')->for('example', 1, 'os_isnt_bsd', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_mac

The os_isnt_mac method returns true if the operating system is not macOS.

=signature os_isnt_mac

  os_isnt_mac() (boolean)

=metadata os_isnt_mac

since: 4.15

=cut

=example-1 os_isnt_mac

  # given: synopsis

  package main;

  my $os_isnt_mac = $test->os_isnt_mac;

  # true

=cut

$test->skip_if('os_is_mac')->for('example', 1, 'os_isnt_mac', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_cyg

The os_isnt_cyg method returns true if the operating system is not Cygwin.

=signature os_isnt_cyg

  os_isnt_cyg() (boolean)

=metadata os_isnt_cyg

since: 4.15

=cut

=example-1 os_isnt_cyg

  # given: synopsis

  package main;

  my $os_isnt_cyg = $test->os_isnt_cyg;

  # true

=cut

$test->skip_if('os_is_cyg')->for('example', 1, 'os_isnt_cyg', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_dos

The os_isnt_dos method returns true if the operating system is not DOS.

=signature os_isnt_dos

  os_isnt_dos() (boolean)

=metadata os_isnt_dos

since: 4.15

=cut

=example-1 os_isnt_dos

  # given: synopsis

  package main;

  my $os_isnt_dos = $test->os_isnt_dos;

  # true

=cut

$test->skip_if('os_is_dos')->for('example', 1, 'os_isnt_dos', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_lin

The os_isnt_lin method returns true if the operating system is not Linux.

=signature os_isnt_lin

  os_isnt_lin() (boolean)

=metadata os_isnt_lin

since: 4.15

=cut

=example-1 os_isnt_lin

  # given: synopsis

  package main;

  my $os_isnt_lin = $test->os_isnt_lin;

  # true

=cut

$test->skip_if('os_is_lin')->for('example', 1, 'os_isnt_lin', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_non

The os_isnt_non method returns true if the operating system is not non-Unix.

=signature os_isnt_non

  os_isnt_non() (boolean)

=metadata os_isnt_non

since: 4.15

=cut

=example-1 os_isnt_non

  # given: synopsis

  package main;

  my $os_isnt_non = $test->os_isnt_non;

  # true

=cut

$test->skip_if('os_is_non')->for('example', 1, 'os_isnt_non', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_sun

The os_isnt_sun method returns true if the operating system is not Solaris.

=signature os_isnt_sun

  os_isnt_sun() (boolean)

=metadata os_isnt_sun

since: 4.15

=cut

=example-1 os_isnt_sun

  # given: synopsis

  package main;

  my $os_isnt_sun = $test->os_isnt_sun;

  # true

=cut

$test->skip_if('os_is_sun')->for('example', 1, 'os_isnt_sun', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_vms

The os_isnt_vms method returns true if the operating system is not VMS.

=signature os_isnt_vms

  os_isnt_vms() (boolean)

=metadata os_isnt_vms

since: 4.15

=cut

=example-1 os_isnt_vms

  # given: synopsis

  package main;

  my $os_isnt_vms = $test->os_isnt_vms;

  # true

=cut

$test->skip_if('os_is_vms')->for('example', 1, 'os_isnt_vms', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=method os_isnt_win

The os_isnt_win method returns true if the operating system is not Windows.

=signature os_isnt_win

  os_isnt_win() (boolean)

=metadata os_isnt_win

since: 4.15

=cut

=example-1 os_isnt_win

  # given: synopsis

  package main;

  my $os_isnt_win = $test->os_isnt_win;

  # true

=cut

$test->skip_if('os_is_win')->for('example', 1, 'os_isnt_win', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;

  $result
});

=feature collect

The collect method dispatches to the C<collect_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

=signature collect

  collect(string $name, any @args) (any)

=metadata collect

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect

  # given: synopsis

  package main;

  my ($collect) = $test->collect('name');

  # "Venus::Test"

=cut

$test->for('example', 1, 'collect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, "Venus::Test";

  $result
});

=example-2 collect

  # given: synopsis

  package main;

  my $collect = $test->collect('name');

  # ["Venus::Test"]

=cut

$test->for('example', 2, 'collect', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Venus::Test"];

  $result
});

=feature collect_data_for_abstract

The collect_data_for_abstract method uses L</data> to fetch data for the C<abstract>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_abstract

  collect_data_for_abstract() (arrayref)

=metadata collect_data_for_abstract

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_abstract

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_abstract = $test->collect_data_for_abstract;

  # ["Example Test Documentation"]

=cut

$test->for('example', 1, 'collect_data_for_abstract', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Example Test Documentation"];

  $result
});

=example-2 collect_data_for_abstract

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_abstract) = $test->collect_data_for_abstract;

  # "Example Test Documentation"

=cut

$test->for('example', 2, 'collect_data_for_abstract', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "Example Test Documentation";

  $result
});

=feature collect_data_for_attribute

The collect_data_for_attribute method uses L</data> to fetch data for the
C<attribute $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

=signature collect_data_for_attribute

  collect_data_for_attribute(string $name) (arrayref)

=metadata collect_data_for_attribute

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_attribute

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_attribute = $test->collect_data_for_attribute('name');

  # ["The name attribute is read-write, optional, and holds a string."]

=cut

$test->for('example', 1, 'collect_data_for_attribute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["The name attribute is read-write, optional, and holds a string."];

  $result
});

=example-2 collect_data_for_attribute

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_attribute) = $test->collect_data_for_attribute('name');

  # "The name attribute is read-write, optional, and holds a string."

=cut

$test->for('example', 2, 'collect_data_for_attribute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "The name attribute is read-write, optional, and holds a string.";

  $result
});

=feature collect_data_for_authors

The collect_data_for_authors method uses L</data> to fetch data for the
C<authors> section and returns the data. Returns an arrayref in scalar context,
and a list in list context.

=signature collect_data_for_authors

  collect_data_for_authors() (arrayref)

=metadata collect_data_for_authors

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_authors

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_authors = $test->collect_data_for_authors;

  # ["Awncorp, C<awncorp@cpan.org>"]

=cut

$test->for('example', 1, 'collect_data_for_authors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Awncorp, C<awncorp\@cpan.org>"];

  $result
});

=example-2 collect_data_for_authors

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_authors) = $test->collect_data_for_authors;

  # "Awncorp, C<awncorp@cpan.org>"

=cut

$test->for('example', 2, 'collect_data_for_authors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "Awncorp, C<awncorp\@cpan.org>";

  $result
});

=feature collect_data_for_description

The collect_data_for_description method uses L</data> to fetch data for the C<description>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_description

  collect_data_for_description() (arrayref)

=metadata collect_data_for_description

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_description

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_description = $test->collect_data_for_description;

  # ["This package provides an example class."]

=cut

$test->for('example', 1, 'collect_data_for_description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["This package provides an example class."];

  $result
});

=example-2 collect_data_for_description

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_description) = $test->collect_data_for_description;

  # "This package provides an example class."

=cut

$test->for('example', 2, 'collect_data_for_description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "This package provides an example class.";

  $result
});

=feature collect_data_for_encoding

The collect_data_for_encoding method uses L</data> to fetch data for the C<encoding>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_encoding

  collect_data_for_encoding() (arrayref)

=metadata collect_data_for_encoding

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_encoding

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_encoding = $test->collect_data_for_encoding;

  # ["UTF8"]

=cut

$test->for('example', 1, 'collect_data_for_encoding', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["UTF8"];

  $result
});

=example-2 collect_data_for_encoding

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_encoding) = $test->collect_data_for_encoding;

  # "UTF8"

=cut

$test->for('example', 2, 'collect_data_for_encoding', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "UTF8";

  $result
});

=feature collect_data_for_error

The collect_data_for_error method uses L</data> to fetch data for the C<error
$name> section and returns the data. Returns an arrayref in scalar context, and
a list in list context.

=signature collect_data_for_error

  collect_data_for_error(string $name) (arrayref)

=metadata collect_data_for_error

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_error

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_error = $test->collect_data_for_error('error_on_unknown');

  # ["This package may raise an error_on_unknown error."]

=cut

$test->for('example', 1, 'collect_data_for_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["This package may raise an error_on_unknown error."];

  $result
});

=example-2 collect_data_for_error

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_error) = $test->collect_data_for_error('error_on_unknown');

  # "This package may raise an error_on_unknown error."

=cut

$test->for('example', 2, 'collect_data_for_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "This package may raise an error_on_unknown error.";

  $result
});

=feature collect_data_for_example

The collect_data_for_example method uses L</data> to fetch data for the
C<example-$number $name> section and returns the data. Returns an arrayref in
scalar context, and a list in list context.

=signature collect_data_for_example

  collect_data_for_example(number $numberm string $name) (arrayref)

=metadata collect_data_for_example

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_example

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_example = $test->collect_data_for_example(1, 'name');

  # ['  # given: synopsis', '  my $name = $example->name;', '  # "..."']

=cut

$test->for('example', 1, 'collect_data_for_example', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ['  # given: synopsis', '  my $name = $example->name;', '  # "..."'];

  $result
});

=example-2 collect_data_for_example

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my @collect_data_for_example = $test->collect_data_for_example(1, 'name');

  # ('  # given: synopsis', '  my $name = $example->name;', '  # "..."')

=cut

$test->for('example', 2, 'collect_data_for_example', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, ['  # given: synopsis', '  my $name = $example->name;', '  # "..."'];

  @result
});

=feature collect_data_for_feature

The collect_data_for_feature method uses L</data> to fetch data for the
C<feature $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

=signature collect_data_for_feature

  collect_data_for_feature(string $name) (arrayref)

=metadata collect_data_for_feature

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_feature

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_feature = $test->collect_data_for_feature('noop');

  # ["This package is no particularly useful features."]

=cut

$test->for('example', 1, 'collect_data_for_feature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["This package is no particularly useful features."];

  $result
});

=example-2 collect_data_for_feature

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_feature) = $test->collect_data_for_feature('noop');

  # "This package is no particularly useful features."

=cut

$test->for('example', 2, 'collect_data_for_feature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "This package is no particularly useful features.";

  $result
});

=feature collect_data_for_function

The collect_data_for_function method uses L</data> to fetch data for the
C<function $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

=signature collect_data_for_function

  collect_data_for_function(string $name) (arrayref)

=metadata collect_data_for_function

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_function

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_function = $test->collect_data_for_function('eg');

  # ["The eg function returns a new instance of Example."]

=cut

$test->for('example', 1, 'collect_data_for_function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["The eg function returns a new instance of Example."];

  $result
});

=example-2 collect_data_for_function

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_function) = $test->collect_data_for_function('eg');

  # "The eg function returns a new instance of Example."

=cut

$test->for('example', 2, 'collect_data_for_function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "The eg function returns a new instance of Example.";

  $result
});

=feature collect_data_for_includes

The collect_data_for_includes method uses L</data> to fetch data for the
C<includes> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

=signature collect_data_for_includes

  collect_data_for_includes() (arrayref)

=metadata collect_data_for_includes

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_includes

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_includes = $test->collect_data_for_includes;

  # ["function: eg", "method: prepare", "method: execute"]

=cut

$test->for('example', 1, 'collect_data_for_includes', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["function: eg", "method: prepare", "method: execute"];

  $result
});

=example-2 collect_data_for_includes

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my @collect_data_for_includes = $test->collect_data_for_includes;

  # ("function: eg", "method: prepare", "method: execute")

=cut

$test->for('example', 2, 'collect_data_for_includes', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, ["function: eg", "method: prepare", "method: execute"];

  @result
});

=feature collect_data_for_inherits

The collect_data_for_inherits method uses L</data> to fetch data for the C<inherits>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_inherits

  collect_data_for_inherits() (arrayref)

=metadata collect_data_for_inherits

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_inherits

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_inherits = $test->collect_data_for_inherits;

  # ["Venus::Core::Class"]

=cut

$test->for('example', 1, 'collect_data_for_inherits', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Venus::Core::Class"];

  $result
});

=example-2 collect_data_for_inherits

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_inherits) = $test->collect_data_for_inherits;

  # "Venus::Core::Class"

=cut

$test->for('example', 2, 'collect_data_for_inherits', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "Venus::Core::Class";

  $result
});

=feature collect_data_for_integrates

The collect_data_for_integrates method uses L</data> to fetch data for the C<integrates>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_integrates

  collect_data_for_integrates() (arrayref)

=metadata collect_data_for_integrates

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_integrates

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_integrates = $test->collect_data_for_integrates;

  # ["Venus::Role::Catchable\nVenus::Role::Throwable"]

=cut

$test->for('example', 1, 'collect_data_for_integrates', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Venus::Role::Catchable\nVenus::Role::Throwable"];

  $result
});

=example-2 collect_data_for_integrates

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_integrates) = $test->collect_data_for_integrates;

  # "Venus::Role::Catchable\nVenus::Role::Throwable"

=cut

$test->for('example', 2, 'collect_data_for_integrates', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "Venus::Role::Catchable\nVenus::Role::Throwable";

  $result
});

=feature collect_data_for_layout

The collect_data_for_layout method uses L</data> to fetch data for the C<layout>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_layout

  collect_data_for_layout() (arrayref)

=metadata collect_data_for_layout

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_layout

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_layout = $test->collect_data_for_layout;

  # ["encoding\nname\nsynopsis\ndescription\nattributes: attribute\nauthors\nlicense"]

=cut

$test->for('example', 1, 'collect_data_for_layout', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["encoding\nname\nsynopsis\ndescription\nattributes: attribute\nauthors\nlicense"];

  $result
});

=example-2 collect_data_for_layout

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_layout) = $test->collect_data_for_layout;

  # "encoding\nname\nsynopsis\ndescription\nattributes: attribute\nauthors\nlicense"

=cut

$test->for('example', 2, 'collect_data_for_layout', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "encoding\nname\nsynopsis\ndescription\nattributes: attribute\nauthors\nlicense";

  $result
});

=feature collect_data_for_libraries

The collect_data_for_libraries method uses L</data> to fetch data for the C<libraries>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_libraries

  collect_data_for_libraries() (arrayref)

=metadata collect_data_for_libraries

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_libraries

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_libraries = $test->collect_data_for_libraries;

  # ["Venus::Check"]

=cut

$test->for('example', 1, 'collect_data_for_libraries', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Venus::Check"];

  $result
});

=example-2 collect_data_for_libraries

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_libraries) = $test->collect_data_for_libraries;

  # "Venus::Check"

=cut

$test->for('example', 2, 'collect_data_for_libraries', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "Venus::Check";

  $result
});

=feature collect_data_for_license

The collect_data_for_license method uses L</data> to fetch data for the C<license>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_license

  collect_data_for_license() (arrayref)

=metadata collect_data_for_license

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_license

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_license = $test->collect_data_for_license;

  # ["No license granted."]

=cut

$test->for('example', 1, 'collect_data_for_license', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["No license granted."];

  $result
});

=example-2 collect_data_for_license

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_license) = $test->collect_data_for_license;

  # "No license granted."

=cut

$test->for('example', 2, 'collect_data_for_license', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "No license granted.";

  $result
});

=feature collect_data_for_message

The collect_data_for_message method uses L</data> to fetch data for the
C<message $name> section and returns the data. Returns an arrayref in scalar
context, and a list in list context.

=signature collect_data_for_message

  collect_data_for_message(string $name) (arrayref)

=metadata collect_data_for_message

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_message

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_message = $test->collect_data_for_message('accept');

  # ["The accept message represents acceptance."]

=cut

$test->for('example', 1, 'collect_data_for_message', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["The accept message represents acceptance."];

  $result
});

=example-2 collect_data_for_message

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_message) = $test->collect_data_for_message('accept');

  # "The accept message represents acceptance."

=cut

$test->for('example', 2, 'collect_data_for_message', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "The accept message represents acceptance.";

  $result
});

=feature collect_data_for_metadata

The collect_data_for_metadata method uses L</data> to fetch data for the C<metadata $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_metadata

  collect_data_for_metadata(string $name) (arrayref)

=metadata collect_data_for_metadata

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_metadata

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_metadata = $test->collect_data_for_metadata('prepare');

  # ["{since => 1.2.3}"]

=cut

$test->for('example', 1, 'collect_data_for_metadata', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ['{since => "1.2.3"}'];

  $result
});

=example-2 collect_data_for_metadata

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_metadata) = $test->collect_data_for_metadata('prepare');

  # "{since => 1.2.3}"

=cut

$test->for('example', 2, 'collect_data_for_metadata', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, '{since => "1.2.3"}';

  $result
});

=feature collect_data_for_method

The collect_data_for_method method uses L</data> to fetch data for the C<method $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_method

  collect_data_for_method(string $name) (arrayref)

=metadata collect_data_for_method

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_method

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_method = $test->collect_data_for_method('execute');

  # ["The execute method executes the logic."]

=cut

$test->for('example', 1, 'collect_data_for_method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["The execute method executes the logic."];

  $result
});

=example-2 collect_data_for_method

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_method) = $test->collect_data_for_method('execute');

  # "The execute method executes the logic."

=cut

$test->for('example', 2, 'collect_data_for_method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "The execute method executes the logic.";

  $result
});

=feature collect_data_for_name

The collect_data_for_name method uses L</data> to fetch data for the C<name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_name

  collect_data_for_name() (arrayref)

=metadata collect_data_for_name

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_name

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_name = $test->collect_data_for_name;

  # ["Example"]

=cut

$test->for('example', 1, 'collect_data_for_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Example"];

  $result
});

=example-2 collect_data_for_name

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_name) = $test->collect_data_for_name;

  # "Example"

=cut

$test->for('example', 2, 'collect_data_for_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "Example";

  $result
});

=feature collect_data_for_operator

The collect_data_for_operator method uses L</data> to fetch data for the C<operator $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_operator

  collect_data_for_operator(string $name) (arrayref)

=metadata collect_data_for_operator

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_operator

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_operator = $test->collect_data_for_operator('("")');

  # ['This package overloads the C<""> operator.']

=cut

$test->for('example', 1, 'collect_data_for_operator', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ['This package overloads the C<""> operator.'];

  $result
});

=example-2 collect_data_for_operator

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_operator) = $test->collect_data_for_operator('("")');

  # 'This package overloads the C<""> operator.'

=cut

$test->for('example', 2, 'collect_data_for_operator', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, 'This package overloads the C<""> operator.';

  $result
});

=feature collect_data_for_partials

The collect_data_for_partials method uses L</data> to fetch data for the C<partials>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_partials

  collect_data_for_partials() (arrayref)

=metadata collect_data_for_partials

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_partials

  # =partials
  #
  # t/path/to/other.t: present: authors
  # t/path/to/other.t: present: license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_partials = $test->collect_data_for_partials;

  # ["t/path/to/other.t: present: authors\nt/path/to/other.t: present: license"]

=cut

$test->for('example', 1, 'collect_data_for_partials', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["t/path/to/other.t: present: authors\nt/path/to/other.t: present: license"];

  $result
});

=example-2 collect_data_for_partials

  # =partials
  #
  # t/path/to/other.t: present: authors
  # t/path/to/other.t: present: license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_partials) = $test->collect_data_for_partials;

  # "t/path/to/other.t: present: authors\nt/path/to/other.t: present: license"

=cut

$test->for('example', 2, 'collect_data_for_partials', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "t/path/to/other.t: present: authors\nt/path/to/other.t: present: license";

  $result
});

=feature collect_data_for_project

The collect_data_for_project method uses L</data> to fetch data for the C<project>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_project

  collect_data_for_project() (arrayref)

=metadata collect_data_for_project

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_project

  # =project
  #
  # https://github.com/awncorp/example
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_project = $test->collect_data_for_project;

  # ["https://github.com/awncorp/example"]

=cut

$test->for('example', 1, 'collect_data_for_project', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["https://github.com/awncorp/example"];

  $result
});

=example-2 collect_data_for_project

  # =project
  #
  # https://github.com/awncorp/example
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_project) = $test->collect_data_for_project;

  # "https://github.com/awncorp/example"

=cut

$test->for('example', 2, 'collect_data_for_project', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "https://github.com/awncorp/example";

  $result
});

=feature collect_data_for_signature

The collect_data_for_signature method uses L</data> to fetch data for the C<signature $name>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_signature

  collect_data_for_signature(string $name) (arrayref)

=metadata collect_data_for_signature

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_signature

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =signature execute
  #
  #   execute() (boolean)
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_signature = $test->collect_data_for_signature('execute');

  # ["  execute() (boolean)"]

=cut

$test->for('example', 1, 'collect_data_for_signature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["  execute() (boolean)"];

  $result
});

=example-2 collect_data_for_signature

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =signature execute
  #
  #   execute() (boolean)
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_signature) = $test->collect_data_for_signature('execute');

  # "  execute() (boolean)"

=cut

$test->for('example', 2, 'collect_data_for_signature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "  execute() (boolean)";

  $result
});

=feature collect_data_for_synopsis

The collect_data_for_synopsis method uses L</data> to fetch data for the C<synopsis>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_synopsis

  collect_data_for_synopsis() (arrayref)

=metadata collect_data_for_synopsis

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_synopsis

  # =synopsis
  #
  #   use Example;
  #
  #   my $example = Example->new;
  #
  #   # bless(..., "Example")
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_synopsis = $test->collect_data_for_synopsis;

  # ['  use Example;', '  my $example = Example->new;', '  # bless(..., "Example")']

=cut

$test->for('example', 1, 'collect_data_for_synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ['  use Example;', '  my $example = Example->new;',  '  # bless(..., "Example")'];

  $result
});

=example-2 collect_data_for_synopsis

  # =synopsis
  #
  #   use Example;
  #
  #   my $example = Example->new;
  #
  #   # bless(..., "Example")
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my @collect_data_for_synopsis = $test->collect_data_for_synopsis;

  # ('  use Example;', '  my $example = Example->new;', '  # bless(..., "Example")')

=cut

$test->for('example', 2, 'collect_data_for_synopsis', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply \@result, ['  use Example;', '  my $example = Example->new;', '  # bless(..., "Example")'];

  @result
});

=feature collect_data_for_tagline

The collect_data_for_tagline method uses L</data> to fetch data for the C<tagline>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_tagline

  collect_data_for_tagline() (arrayref)

=metadata collect_data_for_tagline

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_tagline

  # =tagline
  #
  # Example Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_tagline = $test->collect_data_for_tagline;

  # ["Example Class"]

=cut

$test->for('example', 1, 'collect_data_for_tagline', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["Example Class"];

  $result
});

=example-2 collect_data_for_tagline

  # =tagline
  #
  # Example Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_tagline) = $test->collect_data_for_tagline;

  # "Example Class"

=cut

$test->for('example', 2, 'collect_data_for_tagline', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "Example Class";

  $result
});

=feature collect_data_for_version

The collect_data_for_version method uses L</data> to fetch data for the C<version>
section and returns the data. Returns an arrayref in scalar context, and a list
in list context.

=signature collect_data_for_version

  collect_data_for_version() (arrayref)

=metadata collect_data_for_version

introduced: 3.55
deprecated: 4.15

=cut

=example-1 collect_data_for_version

  # =version
  #
  # 1.2.3
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $collect_data_for_version = $test->collect_data_for_version;

  # ["1.2.3"]

=cut

$test->for('example', 1, 'collect_data_for_version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, ["1.2.3"];

  $result
});

=example-2 collect_data_for_version

  # =version
  #
  # 1.2.3
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my ($collect_data_for_version) = $test->collect_data_for_version;

  # "1.2.3"

=cut

$test->for('example', 2, 'collect_data_for_version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is_deeply $result, "1.2.3";

  $result
});

=feature data

The data method returns a L<Venus::Text::Pod> object using L</file> for parsing
the test specification.

=signature data

  data() (Venus::Text::Pod)

=metadata data

introduced: 3.55
deprecated: 4.15

=cut

=example-1 data

  # given: synopsis

  package main;

  my $data = $test->data;

  # bless(..., "Venus::Text::Pod")

=cut

$test->for('example', 1, 'data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  isa_ok $result, "Venus::Text::Pod";

  $result
});

=feature execute

The execute method dispatches to the C<execute_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

=signature execute

  execute(string $name, any @args) (boolean)

=metadata execute

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute

  # given: synopsis

  package main;

  my $execute = $test->execute('name');

  # true

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=example-2 execute

  # given: synopsis

  package main;

  my $execute = $test->execute('name', sub {
    my ($data) = @_;

    my $result = $data->[0] eq 'Venus::Test' ? true : false;

    $self->pass($result, 'name set as Venus::Test');

    return $result;
  });

  # true

=cut

$test->for('example', 2, 'execute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});


=feature execute_test_for_abstract

The execute_test_for_abstract method tests a documentation block for the C<abstract> section and returns the result.

=signature execute_test_for_abstract

  execute_test_for_abstract() (arrayref)

=metadata execute_test_for_abstract

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_abstract

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_abstract = $test->execute_test_for_abstract;

  # true

=cut

$test->for('example', 1, 'execute_test_for_abstract', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_attribute

The execute_test_for_attribute method tests a documentation block for the C<attribute $name> section and returns the result.

=signature execute_test_for_attribute

  execute_test_for_attribute(string $name) (arrayref)

=metadata execute_test_for_attribute

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_attribute

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_attribute = $test->execute_test_for_attribute('name');

  # true

=cut

$test->for('example', 1, 'execute_test_for_attribute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_authors

The execute_test_for_authors method tests a documentation block for the C<authors> section and returns the result.

=signature execute_test_for_authors

  execute_test_for_authors() (arrayref)

=metadata execute_test_for_authors

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_authors

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_authors = $test->execute_test_for_authors;

  # true

=cut

$test->for('example', 1, 'execute_test_for_authors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_description

The execute_test_for_description method tests a documentation block for the C<description> section and returns the result.

=signature execute_test_for_description

  execute_test_for_description() (arrayref)

=metadata execute_test_for_description

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_description

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_description = $test->execute_test_for_description;

  # true

=cut

$test->for('example', 1, 'execute_test_for_description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_encoding

The execute_test_for_encoding method tests a documentation block for the C<encoding> section and returns the result.

=signature execute_test_for_encoding

  execute_test_for_encoding() (arrayref)

=metadata execute_test_for_encoding

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_encoding

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_encoding = $test->execute_test_for_encoding;

  # true

=cut

$test->for('example', 1, 'execute_test_for_encoding', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_error

The execute_test_for_error method tests a documentation block for the C<error $name> section and returns the result.

=signature execute_test_for_error

  execute_test_for_error(string $name) (arrayref)

=metadata execute_test_for_error

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_error

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_error = $test->execute_test_for_error('error_on_unknown');

  # true

=cut

$test->for('example', 1, 'execute_test_for_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_example

The execute_test_for_example method tests a documentation block for the C<example-$number $name> section and returns the result.

=signature execute_test_for_example

  execute_test_for_example(number $numberm string $name) (arrayref)

=metadata execute_test_for_example

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_example

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_example = $test->execute_test_for_example(1, 'name');

  # true

=cut

$test->for('example', 1, 'execute_test_for_example', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_feature

The execute_test_for_feature method tests a documentation block for the C<feature $name> section and returns the result.

=signature execute_test_for_feature

  execute_test_for_feature(string $name) (arrayref)

=metadata execute_test_for_feature

introduced: 3.55
deprecated: 4.15

=example-1 execute_test_for_feature

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_feature = $test->execute_test_for_feature('noop');

  # true

=cut

$test->for('example', 1, 'execute_test_for_feature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_function

The execute_test_for_function method tests a documentation block for the C<function $name> section and returns the result.

=signature execute_test_for_function

  execute_test_for_function(string $name) (arrayref)

=metadata execute_test_for_function

introduced: 3.55
deprecated: 4.15

=example-1 execute_test_for_function

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_function = $test->execute_test_for_function('eg');

  # true

=cut

$test->for('example', 1, 'execute_test_for_function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_includes

The execute_test_for_includes method tests a documentation block for the C<includes> section and returns the result.

=signature execute_test_for_includes

  execute_test_for_includes() (arrayref)

=metadata execute_test_for_includes

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_includes

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_includes = $test->execute_test_for_includes;

  # true

=cut

$test->for('example', 1, 'execute_test_for_includes', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_inherits

The execute_test_for_inherits method tests a documentation block for the C<inherits> section and returns the result.

=signature execute_test_for_inherits

  execute_test_for_inherits() (arrayref)

=metadata execute_test_for_inherits

introduced: 3.55
deprecated: 4.15

=example-1 execute_test_for_inherits

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_inherits = $test->execute_test_for_inherits;

  # true

=cut

$test->for('example', 1, 'execute_test_for_inherits', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_integrates

The execute_test_for_integrates method tests a documentation block for the C<integrates> section and returns the result.

=signature execute_test_for_integrates

  execute_test_for_integrates() (arrayref)

=metadata execute_test_for_integrates

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_integrates

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_integrates = $test->execute_test_for_integrates;

  # true

=cut

$test->for('example', 1, 'execute_test_for_integrates', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_layout

The execute_test_for_layout method tests a documentation block for the C<layout> section and returns the result.

=signature execute_test_for_layout

  execute_test_for_layout() (arrayref)

=metadata execute_test_for_layout

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_layout

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_layout = $test->execute_test_for_layout;

  # true

=cut

$test->for('example', 1, 'execute_test_for_layout', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_libraries

The execute_test_for_libraries method tests a documentation block for the C<libraries> section and returns the result.

=signature execute_test_for_libraries

  execute_test_for_libraries() (arrayref)

=metadata execute_test_for_libraries

introduced: 3.55
deprecated: 4.15

=example-1 execute_test_for_libraries

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_libraries = $test->execute_test_for_libraries;

  # true

=cut

$test->for('example', 1, 'execute_test_for_libraries', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_license

The execute_test_for_license method tests a documentation block for the C<license> section and returns the result.

=signature execute_test_for_license

  execute_test_for_license() (arrayref)

=metadata execute_test_for_license

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_license

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_license = $test->execute_test_for_license;

  # true

=cut

$test->for('example', 1, 'execute_test_for_license', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_message

The execute_test_for_message method tests a documentation block for the C<message $name> section and returns the result.

=signature execute_test_for_message

  execute_test_for_message(string $name) (arrayref)

=metadata execute_test_for_message

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_message

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_message = $test->execute_test_for_message('accept');

  # true

=cut

$test->for('example', 1, 'execute_test_for_message', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_metadata

The execute_test_for_metadata method tests a documentation block for the C<metadata $name> section and returns the result.

=signature execute_test_for_metadata

  execute_test_for_metadata(string $name) (arrayref)

=metadata execute_test_for_metadata

introduced: 3.55
deprecated: 4.15

=example-1 execute_test_for_metadata

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_metadata = $test->execute_test_for_metadata('prepare');

  # true

=cut

$test->for('example', 1, 'execute_test_for_metadata', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_method

The execute_test_for_method method tests a documentation block for the C<method $name> section and returns the result.

=signature execute_test_for_method

  execute_test_for_method(string $name) (arrayref)

=metadata execute_test_for_method

introduced: 3.55
deprecated: 4.15

=example-1 execute_test_for_method

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_method = $test->execute_test_for_method('execute');

  # true

=cut

$test->for('example', 1, 'execute_test_for_method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_name

The execute_test_for_name method tests a documentation block for the C<name> section and returns the result.

=signature execute_test_for_name

  execute_test_for_name() (arrayref)

=metadata execute_test_for_name

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_name

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_name = $test->execute_test_for_name;

  # true

=cut

$test->for('example', 1, 'execute_test_for_name', sub {
  true;
});

=feature execute_test_for_operator

The execute_test_for_operator method tests a documentation block for the C<operator $name> section and returns the result.

=signature execute_test_for_operator

  execute_test_for_operator(string $name) (arrayref)

=metadata execute_test_for_operator

introduced: 3.55
deprecated: 4.15

=cut

=example-1 execute_test_for_operator

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_operator = $test->execute_test_for_operator('("")');

  # true

=cut

$test->for('example', 1, 'execute_test_for_operator', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature execute_test_for_raise

The execute_test_for_raise method tests a documentation block for the C<raise
$name $error $id> section and returns the result.

=signature execute_test_for_raise

  execute_test_for_raise(string $name, string $class, string $id) (arrayref)

=metadata execute_test_for_raise

introduced: 4.15

=example-1 execute_test_for_raise

  # =raise execute Venus::Error on.unknown
  #
  #   # given: synopsis
  #
  #   $example->operation; # throw exception
  #
  #   # Error (on.unknown)
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $execute_test_for_raise = $test->execute_test_for_raise('execute', 'Venus::Error', 'on.unknown');

  # true

=cut

$test->for('example', 1, 'execute_test_for_raise', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature more

The more method dispatches to the L<Test::More> method specified by the first
argument and returns its result.

=signature more

  more(any @args) (any)

=metadata more

introduced: 3.55
deprecated: 4.15

=cut

=example-1 more

  # given: synopsis

  package main;

  my $more = $test->more('ok', true);

  # true

=cut

$test->for('example', 1, 'more', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature okay

The okay method dispatches to the L<Test::More/ok> operation and returns the
result.

=signature okay

  okay(any $data, string $description) (any)

=metadata okay

introduced: 3.55
deprecated: 4.15

=cut

=example-1 okay

  # given: synopsis

  package main;

  my $okay = $test->okay(1, 'example-1 okay passed');

  # true

=cut

$test->for('example', 1, 'okay', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 okay

  # given: synopsis

  package main;

  my $okay = $test->okay(!0, 'example-1 okay passed');

  # true

=cut

$test->for('example', 2, 'okay', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=feature okay_can

The okay_can method dispatches to the L<Test::More/can_ok> operation and
returns the result.

=signature okay_can

  okay_can(string $name, string @args) (any)

=metadata okay_can

introduced: 3.55
deprecated: 4.15

=cut

=example-1 okay_can

  # given: synopsis

  package main;

  my $okay_can = $test->okay_can('Venus::Test', 'diag');

  # true

=cut

$test->for('example', 1, 'okay_can', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=feature okay_isa

The okay_isa method dispatches to the L<Test::More/isa_ok> operation and
returns the result.

=signature okay_isa

  okay_isa(string $name, string $base) (any)

=metadata okay_isa

introduced: 3.55
deprecated: 4.15


=cut

=example-1 okay_isa

  # given: synopsis

  package main;

  my $okay_isa = $test->okay_isa('Venus::Test', 'Venus::Kind');

  # true

=cut

$test->for('example', 1, 'okay_isa', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=feature perform

The perform method dispatches to the C<perform_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

=signature perform

  perform(string $name, any @args) (boolean)

=metadata perform

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform

  # given: synopsis

  package main;

  my $data = $test->collect('name');

  my $perform = $test->perform('name', $data);

  # true

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  $result
});

=feature perform_test_for_abstract

The perform_data_for_abstract method performs an overridable test for the C<abstract> section and returns truthy or falsy.

=signature perform_test_for_abstract

  perform_test_for_abstract(arrayref $data) (boolean)

=metadata perform_test_for_abstract

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_abstract

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_abstract {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=abstract content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_abstract;

  my $perform_test_for_abstract = $test->perform_test_for_abstract(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_abstract', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_attribute

The perform_data_for_attribute method performs an overridable test for the C<attribute $name> section and returns truthy or falsy.

=signature perform_test_for_attribute

  perform_test_for_attribute(string $name, arrayref $data) (boolean)

=metadata perform_test_for_attribute

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_attribute

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_attribute {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=attribute $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_attribute('name');

  my $perform_test_for_attribute = $test->perform_test_for_attribute(
    'name', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_attribute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_authors

The perform_data_for_authors method performs an overridable test for the C<authors> section and returns truthy or falsy.

=signature perform_test_for_authors

  perform_test_for_authors(arrayref $data) (boolean)

=metadata perform_test_for_authors

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_authors

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_authors {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=authors content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_authors;

  my $perform_test_for_authors = $test->perform_test_for_authors(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_authors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_description

The perform_data_for_description method performs an overridable test for the C<description> section and returns truthy or falsy.

=signature perform_test_for_description

  perform_test_for_description(arrayref $data) (boolean)

=metadata perform_test_for_description

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_description

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_description {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=description content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_description;

  my $perform_test_for_description = $test->perform_test_for_description(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_encoding

The perform_data_for_encoding method performs an overridable test for the C<encoding> section and returns truthy or falsy.

=signature perform_test_for_encoding

  perform_test_for_encoding(arrayref $data) (boolean)

=metadata perform_test_for_encoding

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_encoding

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_encoding {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=encoding content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_encoding;

  my $perform_test_for_encoding = $test->perform_test_for_encoding(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_encoding', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_error

The perform_data_for_error method performs an overridable test for the C<error $name> section and returns truthy or falsy.

=signature perform_test_for_error

  perform_test_for_error(arrayref $data) (boolean)

=metadata perform_test_for_error

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_error

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_error {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=error $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_error('error_on_unknown');

  my $perform_test_for_error = $test->perform_test_for_error(
    'error_on_unknown', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_example

The perform_data_for_example method performs an overridable test for the C<example-$number $name> section and returns truthy or falsy.

=signature perform_test_for_example

  perform_test_for_example(arrayref $data) (boolean)

=metadata perform_test_for_example

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_example

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_example {
    my ($self, $number, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=example-$number $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_example(1, 'execute');

  my $perform_test_for_example = $test->perform_test_for_example(
    1, 'execute', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_example', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_feature

The perform_data_for_feature method performs an overridable test for the C<feature $name> section and returns truthy or falsy.

=signature perform_test_for_feature

  perform_test_for_feature(arrayref $data) (boolean)

=metadata perform_test_for_feature

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_feature

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_feature {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=feature $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_feature('noop');

  my $perform_test_for_feature = $test->perform_test_for_feature(
    'noop', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_feature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_function

The perform_data_for_function method performs an overridable test for the C<function $name> section and returns truthy or falsy.

=signature perform_test_for_function

  perform_test_for_function(arrayref $data) (boolean)

=metadata perform_test_for_function

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_function

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_function {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=function $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_function('eg');

  my $perform_test_for_function = $test->perform_test_for_function(
    'eg', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_includes

The perform_data_for_includes method performs an overridable test for the C<includes> section and returns truthy or falsy.

=signature perform_test_for_includes

  perform_test_for_includes(arrayref $data) (boolean)

=metadata perform_test_for_includes

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_includes

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_includes {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=includes content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_includes;

  my $perform_test_for_includes = $test->perform_test_for_includes(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_includes', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_inherits

The perform_data_for_inherits method performs an overridable test for the C<inherits> section and returns truthy or falsy.

=signature perform_test_for_inherits

  perform_test_for_inherits(arrayref $data) (boolean)

=metadata perform_test_for_inherits

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_inherits

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_inherits {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=inherits content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_inherits;

  my $perform_test_for_inherits = $test->perform_test_for_inherits(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_inherits', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_integrates

The perform_data_for_integrates method performs an overridable test for the C<integrates> section and returns truthy or falsy.

=signature perform_test_for_integrates

  perform_test_for_integrates(arrayref $data) (boolean)

=metadata perform_test_for_integrates

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_integrates

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_integrates {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=integrates content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_integrates;

  my $perform_test_for_integrates = $test->perform_test_for_integrates(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_integrates', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_layout

The perform_data_for_layout method performs an overridable test for the C<layout> section and returns truthy or falsy.

=signature perform_test_for_layout

  perform_test_for_layout(arrayref $data) (boolean)

=metadata perform_test_for_layout

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_layout

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_layout {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=layout content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_layout;

  my $perform_test_for_layout = $test->perform_test_for_layout(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_layout', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_libraries

The perform_data_for_libraries method performs an overridable test for the C<libraries> section and returns truthy or falsy.

=signature perform_test_for_libraries

  perform_test_for_libraries(arrayref $data) (boolean)

=metadata perform_test_for_libraries

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_libraries

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_libraries {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=libraries content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_libraries;

  my $perform_test_for_libraries = $test->perform_test_for_libraries(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_libraries', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_license

The perform_data_for_license method performs an overridable test for the C<license> section and returns truthy or falsy.

=signature perform_test_for_license

  perform_test_for_license(arrayref $data) (boolean)

=metadata perform_test_for_license

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_license

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_license {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=license content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_license;

  my $perform_test_for_license = $test->perform_test_for_license(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_license', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_message

The perform_data_for_message method performs an overridable test for the C<message $name> section and returns truthy or falsy.

=signature perform_test_for_message

  perform_test_for_message(arrayref $data) (boolean)

=metadata perform_test_for_message

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_message

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_message {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=message $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_message('accept');

  my $perform_test_for_message = $test->perform_test_for_message(
    'accept', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_message', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_metadata

The perform_data_for_metadata method performs an overridable test for the C<metadata $name> section and returns truthy or falsy.

=signature perform_test_for_metadata

  perform_test_for_metadata(arrayref $data) (boolean)

=metadata perform_test_for_metadata

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_metadata

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_metadata {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=metadata $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_metadata('execute');

  my $perform_test_for_metadata = $test->perform_test_for_metadata(
    'execute', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_metadata', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_method

The perform_data_for_method method performs an overridable test for the C<method $name> section and returns truthy or falsy.

=signature perform_test_for_method

  perform_test_for_method(arrayref $data) (boolean)

=metadata perform_test_for_method

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_method

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_method {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=method $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_method('execute');

  my $perform_test_for_method = $test->perform_test_for_method(
    'execute', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_name

The perform_data_for_name method performs an overridable test for the C<name> section and returns truthy or falsy.

=signature perform_test_for_name

  perform_test_for_name(arrayref $data) (boolean)

=metadata perform_test_for_name

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_name

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_name {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_name;

  my $perform_test_for_name = $test->perform_test_for_name(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_operator

The perform_data_for_operator method performs an overridable test for the C<operator $name> section and returns truthy or falsy.

=signature perform_test_for_operator

  perform_test_for_operator(arrayref $data) (boolean)

=metadata perform_test_for_operator

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_operator

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_operator {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=operator $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_operator('("")');

  my $perform_test_for_operator = $test->perform_test_for_operator(
    '("")', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_operator', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_partials

The perform_data_for_partials method performs an overridable test for the C<partials> section and returns truthy or falsy.

=signature perform_test_for_partials

  perform_test_for_partials(arrayref $data) (boolean)

=metadata perform_test_for_partials

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_partials

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_partials {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=partials content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_partials;

  my $perform_test_for_partials = $test->perform_test_for_partials(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_partials', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_project

The perform_data_for_project method performs an overridable test for the C<project> section and returns truthy or falsy.

=signature perform_test_for_project

  perform_test_for_project(arrayref $data) (boolean)

=metadata perform_test_for_project

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_project

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_project {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=project content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_project;

  my $perform_test_for_project = $test->perform_test_for_project(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_project', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_signature

The perform_data_for_signature method performs an overridable test for the C<signature $name> section and returns truthy or falsy.

=signature perform_test_for_signature

  perform_test_for_signature(arrayref $data) (boolean)

=metadata perform_test_for_signature

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_signature

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_signature {
    my ($self, $name, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=signature $name content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_signature('execute');

  my $perform_test_for_signature = $test->perform_test_for_signature(
    'execute', $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_signature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_synopsis

The perform_data_for_synopsis method performs an overridable test for the C<synopsis> section and returns truthy or falsy.

=signature perform_test_for_synopsis

  perform_test_for_synopsis(arrayref $data) (boolean)

=metadata perform_test_for_synopsis

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_synopsis

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_synopsis {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=synopsis content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_synopsis;

  my $perform_test_for_synopsis = $test->perform_test_for_synopsis(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_tagline

The perform_data_for_tagline method performs an overridable test for the C<tagline> section and returns truthy or falsy.

=signature perform_test_for_tagline

  perform_test_for_tagline(arrayref $data) (boolean)

=metadata perform_test_for_tagline

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_tagline

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_tagline {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=tagline content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_tagline;

  my $perform_test_for_tagline = $test->perform_test_for_tagline(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_tagline', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature perform_test_for_version

The perform_data_for_version method performs an overridable test for the C<version> section and returns truthy or falsy.

=signature perform_test_for_version

  perform_test_for_version(arrayref $data) (boolean)

=metadata perform_test_for_version

introduced: 3.55
deprecated: 4.15

=cut

=example-1 perform_test_for_version

  package Example::Test;

  use Venus::Class 'base';

  base 'Venus::Test';

  sub perform_test_for_version {
    my ($self, $data) = @_;

    my $result = length(join "\n", @{$data}) ? true : false;

    $self->pass($result, "=version content");

    return $result;
  }

  package main;

  my $test = Example::Test->new('t/path/pod/example');

  my $data = $test->collect_data_for_version;

  my $perform_test_for_version = $test->perform_test_for_version(
    $data,
  );

  # true

=cut

$test->for('example', 1, 'perform_test_for_version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, true;

  require Venus::Space;
  Venus::Space->new('Example::Test')->unload;

  $result
});

=feature present

The present method dispatches to the C<present_data_for_${name}> method
indictated by the first argument and returns the result. Returns an arrayref in
scalar context, and a list in list context.

=signature present

  present(string $name, any @args) (string)

=metadata present

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present

  # given: synopsis

  package main;

  my $present = $test->present('name');

  # =head1 NAME
  #
  # Venus::Test - Test Class
  #
  # =cut

=cut

$test->for('example', 1, 'present', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 NAME

Venus::Test - Test Class

=cut';

  $result
});

=feature present_data_for_abstract

The present_data_for_abstract method builds a documentation block for the C<abstract> section and returns it as a string.

=signature present_data_for_abstract

  present_data_for_abstract() (arrayref)

=metadata present_data_for_abstract

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_abstract

  # =abstract
  #
  # Example Test Documentation
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_abstract = $test->present_data_for_abstract;

  # =head1 ABSTRACT
  #
  # Example Test Documentation
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_abstract', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 ABSTRACT

Example Test Documentation

=cut';

  $result
});

=feature present_data_for_attribute

The present_data_for_attribute method builds a documentation block for the C<attribute $name> section and returns it as a string.

=signature present_data_for_attribute

  present_data_for_attribute(string $name) (arrayref)

=metadata present_data_for_attribute

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_attribute

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_attribute = $test->present_data_for_attribute('name');

  # =head2 name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =over 4
  #
  # =item name example 1
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =back
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_attribute', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head2 name

The name attribute is read-write, optional, and holds a string.

=over 4

=item name example 1

  # given: synopsis

  my $name = $example->name;

  # "..."

=back

=cut';

  $result
});

=feature present_data_for_authors

The present_data_for_authors method builds a documentation block for the C<authors> section and returns it as a string.

=signature present_data_for_authors

  present_data_for_authors() (arrayref)

=metadata present_data_for_authors

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_authors

  # =authors
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_authors = $test->present_data_for_authors;

  # =head1 AUTHORS
  #
  # Awncorp, C<awncorp@cpan.org>
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_authors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut';

  $result
});

=feature present_data_for_description

The present_data_for_description method builds a documentation block for the C<description> section and returns it as a string.

=signature present_data_for_description

  present_data_for_description() (arrayref)

=metadata present_data_for_description

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_description

  # =description
  #
  # This package provides an example class.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_description = $test->present_data_for_description;

  # =head1 DESCRIPTION
  #
  # This package provides an example class.
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 DESCRIPTION

This package provides an example class.

=cut';

  $result
});

=feature present_data_for_encoding

The present_data_for_encoding method builds a documentation block for the C<encoding> section and returns it as a string.

=signature present_data_for_encoding

  present_data_for_encoding() (arrayref)

=metadata present_data_for_encoding

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_encoding

  # =encoding
  #
  # utf8
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_encoding = $test->present_data_for_encoding;

  # =encoding UTF8
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_encoding', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=encoding UTF8

=cut';

  $result
});

=feature present_data_for_error

The present_data_for_error method builds a documentation block for the C<error $name> section and returns it as a string.

=signature present_data_for_error

  present_data_for_error(string $name) (arrayref)

=metadata present_data_for_error

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_error

  # =error error_on_unknown
  #
  # This package may raise an error_on_unknown error.
  #
  # =cut
  #
  # =example-1 error_on_unknown
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_error = $test->present_data_for_error('error_on_unknown');

  # =over 4
  #
  # =item error: C<error_on_unknown>
  #
  # This package may raise an error_on_unknown error.
  #
  # B<example 1>
  #
  #   # given: synopsis
  #
  #   my $error = $example->catch('error', {
  #     with => 'error_on_unknown',
  #   });
  #
  #   # "..."
  #
  # =back

=cut

$test->for('example', 1, 'present_data_for_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, q|
=over 4

=item error: C<error_on_unknown>

This package may raise an error_on_unknown error.

B<example 1>

  # given: synopsis

  my $error = $example->catch('error', {
    with => 'error_on_unknown',
  });

  # "..."

=back|;

  $result
});

=feature present_data_for_example

The present_data_for_example method builds a documentation block for the C<example-$number $name> section and returns it as a string.

=signature present_data_for_example

  present_data_for_example(number $numberm string $name) (arrayref)

=metadata present_data_for_example

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_example

  # =attribute name
  #
  # The name attribute is read-write, optional, and holds a string.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_example = $test->present_data_for_example(1, 'name');

  # =over 4
  #
  # =item name example 1
  #
  #   # given: synopsis
  #
  #   my $name = $example->name;
  #
  #   # "..."
  #
  # =back

=cut

$test->for('example', 1, 'present_data_for_example', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, q|
=over 4

=item name example 1

  # given: synopsis

  my $name = $example->name;

  # "..."

=back|;

  $result
});

=feature present_data_for_feature

The present_data_for_feature method builds a documentation block for the C<feature $name> section and returns it as a string.

=signature present_data_for_feature

  present_data_for_feature(string $name) (arrayref)

=metadata present_data_for_feature

introduced: 3.55
deprecated: 4.15

=example-1 present_data_for_feature

  # =feature noop
  #
  # This package is no particularly useful features.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_feature = $test->present_data_for_feature('noop');

  # =over 4
  #
  # =item noop
  #
  # This package is no particularly useful features.
  #
  # =back

=cut

$test->for('example', 1, 'present_data_for_feature', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=over 4

=item noop

This package is no particularly useful features.

=back';

  $result
});

=feature present_data_for_function

The present_data_for_function method builds a documentation block for the C<function $name> section and returns it as a string.

=signature present_data_for_function

  present_data_for_function(string $name) (arrayref)

=metadata present_data_for_function

introduced: 3.55
deprecated: 4.15

=example-1 present_data_for_function

  # =function eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut
  #
  # =example-1 name
  #
  #   # given: synopsis
  #
  #   my $example = eg();
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_function = $test->present_data_for_function('eg');

  # =head2 eg
  #
  # The eg function returns a new instance of Example.
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_function', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head2 eg

The eg function returns a new instance of Example.

=cut';

  $result
});

=feature present_data_for_includes

The present_data_for_includes method builds a documentation block for the C<includes> section and returns it as a string.

=signature present_data_for_includes

  present_data_for_includes() (arrayref)

=metadata present_data_for_includes

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_includes

  # =includes
  #
  # function: eg
  #
  # method: prepare
  # method: execute
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_includes = $test->present_data_for_includes;

  # undef

=cut

$test->for('example', 1, 'present_data_for_includes', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;
  is $result, undef;

  !$result
});

=feature present_data_for_inherits

The present_data_for_inherits method builds a documentation block for the C<inherits> section and returns it as a string.

=signature present_data_for_inherits

  present_data_for_inherits() (arrayref)

=metadata present_data_for_inherits

introduced: 3.55
deprecated: 4.15

=example-1 present_data_for_inherits

  # =inherits
  #
  # Venus::Core::Class
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_inherits = $test->present_data_for_inherits;

  # =head1 INHERITS
  #
  # This package inherits behaviors from:
  #
  # L<Venus::Core::Class>
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_inherits', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 INHERITS

This package inherits behaviors from:

L<Venus::Core::Class>

=cut';

  $result
});

=feature present_data_for_integrates

The present_data_for_integrates method builds a documentation block for the C<integrates> section and returns it as a string.

=signature present_data_for_integrates

  present_data_for_integrates() (arrayref)

=metadata present_data_for_integrates

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_integrates

  # =integrates
  #
  # Venus::Role::Catchable
  # Venus::Role::Throwable
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_integrates = $test->present_data_for_integrates;

  # =head1 INTEGRATES
  #
  # This package integrates behaviors from:
  #
  # L<Venus::Role::Catchable>
  #
  # L<Venus::Role::Throwable>
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_integrates', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Catchable>

L<Venus::Role::Throwable>

=cut';

  $result
});

=feature present_data_for_layout

The present_data_for_layout method builds a documentation block for the C<layout> section and returns it as a string.

=signature present_data_for_layout

  present_data_for_layout() (arrayref)

=metadata present_data_for_layout

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_layout

  # =layout
  #
  # encoding
  # name
  # synopsis
  # description
  # attributes: attribute
  # authors
  # license
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_layout = $test->present_data_for_layout;

  # undef

=cut

$test->for('example', 1, 'present_data_for_layout', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;
  is $result, undef;

  !$result
});

=feature present_data_for_libraries

The present_data_for_libraries method builds a documentation block for the C<libraries> section and returns it as a string.

=signature present_data_for_libraries

  present_data_for_libraries() (arrayref)

=metadata present_data_for_libraries

introduced: 3.55
deprecated: 4.15

=example-1 present_data_for_libraries

  # =libraries
  #
  # Venus::Check
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_libraries = $test->present_data_for_libraries;

  # =head1 LIBRARIES
  #
  # This package uses type constraints from:
  #
  # L<Venus::Check>
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_libraries', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 LIBRARIES

This package uses type constraints from:

L<Venus::Check>

=cut';

  $result
});

=feature present_data_for_license

The present_data_for_license method builds a documentation block for the C<license> section and returns it as a string.

=signature present_data_for_license

  present_data_for_license() (arrayref)

=metadata present_data_for_license

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_license

  # =license
  #
  # No license granted.
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_license = $test->present_data_for_license;

  # =head1 LICENSE
  #
  # No license granted.
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_license', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 LICENSE

No license granted.

=cut';

  $result
});

=feature present_data_for_message

The present_data_for_message method builds a documentation block for the C<message $name> section and returns it as a string.

=signature present_data_for_message

  present_data_for_message(string $name) (arrayref)

=metadata present_data_for_message

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_message

  # =message accept
  #
  # The accept message represents acceptance.
  #
  # =cut
  #
  # =example-1 accept
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_message = $test->present_data_for_message('accept');

  # =over 4
  #
  # =item accept
  #
  # The accept message represents acceptance.
  #
  # B<example 1>
  #
  #   # given: synopsis
  #
  #   my $accept = $example->accept;
  #
  #   # "..."
  #
  # =back

=cut

$test->for('example', 1, 'present_data_for_message', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=over 4

=item accept

The accept message represents acceptance.

B<example 1>

  # given: synopsis

  my $accept = $example->accept;

  # "..."

=back';

  $result
});

=feature present_data_for_metadata

The present_data_for_metadata method builds a documentation block for the C<metadata $name> section and returns it as a string.

=signature present_data_for_metadata

  present_data_for_metadata(string $name) (arrayref)

=metadata present_data_for_metadata

introduced: 3.55
deprecated: 4.15

=example-1 present_data_for_metadata

  # =method prepare
  #
  # The prepare method prepares for execution.
  #
  # =cut
  #
  # =metadata prepare
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 prepare
  #
  #   # given: synopsis
  #
  #   my $prepare = $example->prepare;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_metadata = $test->present_data_for_metadata('prepare');

  # undef

=cut

$test->for('example', 1, 'present_data_for_metadata', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;
  is $result, undef;

  !$result
});

=feature present_data_for_method

The present_data_for_method method builds a documentation block for the C<method $name> section and returns it as a string.

=signature present_data_for_method

  present_data_for_method(string $name) (arrayref)

=metadata present_data_for_method

introduced: 3.55
deprecated: 4.15

=example-1 present_data_for_method

  # =method execute
  #
  # The execute method executes the logic.
  #
  # =cut
  #
  # =metadata execute
  #
  # {since => 1.2.3}
  #
  # =cut
  #
  # =example-1 execute
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_method = $test->present_data_for_method('execute');

  # =head2 execute
  #
  #   execute() (boolean)
  #
  # The execute method executes the logic.
  #
  # I<Since C<1.2.3>>
  #
  # =over 4
  #
  # =item execute example 1
  #
  #   # given: synopsis
  #
  #   my $execute = $example->execute;
  #
  #   # "..."
  #
  # =back
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_method', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head2 execute

  execute() (boolean)

The execute method executes the logic.

I<Since C<1.2.3>>

=over 4

=item execute example 1

  # given: synopsis

  my $execute = $example->execute;

  # "..."

=back

=over 4

=item B<may raise> L<Venus::Error> C<on.unknown>

  # given: synopsis

  $example->execute; # throw exception

  # Error (on.unknown)

=back

=cut';

  $result
});

=feature present_data_for_name

The present_data_for_name method builds a documentation block for the C<name> section and returns it as a string.

=signature present_data_for_name

  present_data_for_name() (arrayref)

=metadata present_data_for_name

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_name

  # =name

  # Example

  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_name = $test->present_data_for_name;

  # =head1 NAME
  #
  # Example - Example Class
  #
  # =cut

=cut

$test->for('example', 1, 'present_data_for_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=head1 NAME

Example - Example Class

=cut';

  $result
});

=feature present_data_for_operator

The present_data_for_operator method builds a documentation block for the C<operator $name> section and returns it as a string.

=signature present_data_for_operator

  present_data_for_operator(string $name) (arrayref)

=metadata present_data_for_operator

introduced: 3.55
deprecated: 4.15

=cut

=example-1 present_data_for_operator

  # =operator ("")
  #
  # This package overloads the C<""> operator.
  #
  # =cut
  #
  # =example-1 ("")
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =cut

  package main;

  use Venus::Test 'test';

  my $test = test 't/path/pod/example';

  my $present_data_for_operator = $test->present_data_for_operator('("")');

  # =over 4
  #
  # =item operation: C<("")>
  #
  # This package overloads the C<""> operator.
  #
  # B<example 1>
  #
  #   # given: synopsis
  #
  #   my $string = "$example";
  #
  #   # "..."
  #
  # =back

=cut

$test->for('example', 1, 'present_data_for_operator', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok defined $result;
  is $result, '
=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis

  my $string = "$example";

  # "..."

=back';

  $result
});

=raise new Venus::Test::Error on.new

  package main;

  use Venus::Test;

  my $test = Venus::Test->new('t/data/no-name.t');

  # Error! (on.new)

=cut

$test->for('raise', 'new', 'Venus::Test::Error', 'on.new', sub {
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

$test->render('lib/Venus/Test.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
