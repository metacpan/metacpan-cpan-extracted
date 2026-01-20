package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Cli

=cut

$test->for('name');

=tagline

Cli Class

=cut

$test->for('tagline');

=abstract

Cli Class for Perl 5

=cut

$test->for('abstract');

=includes

method: args
method: argument
method: argument_choice
method: argument_choices
method: argument_count
method: argument_default
method: argument_errors
method: argument_help
method: argument_label
method: argument_list
method: argument_multiples
method: argument_name
method: argument_names
method: argument_prompt
method: argument_range
method: argument_required
method: argument_type
method: argument_validate
method: argument_value
method: argument_wants
method: assigned_arguments
method: assigned_options
method: boolean
method: choice
method: choice_argument
method: choice_count
method: choice_default
method: choice_errors
method: choice_help
method: choice_label
method: choice_list
method: choice_multiples
method: choice_name
method: choice_names
method: choice_prompt
method: choice_range
method: choice_required
method: choice_type
method: choice_validate
method: choice_value
method: choice_wants
method: command
method: dispatch
method: exit
method: fail
method: float
method: has_input
method: has_input_arguments
method: has_input_options
method: has_output
method: has_output_debug_events
method: has_output_error_events
method: has_output_fatal_events
method: has_output_info_events
method: has_output_trace_events
method: has_output_warn_events
method: help
method: input
method: input_argument_count
method: input_argument_list
method: input_arguments
method: input_arguments_defined
method: input_arguments_defined_count
method: input_arguments_defined_list
method: input_option_count
method: input_option_list
method: input_options
method: input_options_defined
method: input_options_defined_count
method: input_options_defined_list
method: lines
method: log
method: log_debug
method: log_error
method: log_events
method: log_fatal
method: log_flush
method: log_handler
method: log_info
method: log_level
method: log_trace
method: log_warn
method: multiple
method: new
method: no_input
method: no_input_arguments
method: no_input_options
method: no_output
method: no_output_debug_events
method: no_output_error_events
method: no_output_fatal_events
method: no_output_info_events
method: no_output_trace_events
method: no_output_warn_events
method: number
method: okay
method: option
method: option_aliases
method: option_count
method: option_default
method: option_errors
method: option_help
method: option_label
method: option_list
method: option_multiples
method: option_name
method: option_names
method: option_prompt
method: option_range
method: option_required
method: option_type
method: option_validate
method: option_value
method: option_wants
method: optional
method: opts
method: output
method: output_debug_events
method: output_error_events
method: output_fatal_events
method: output_info_events
method: output_trace_events
method: output_warn_events
method: parse
method: parse_specification
method: parsed
method: parsed_arguments
method: parsed_options
method: pass
method: reorder
method: reorder_arguments
method: reorder_choices
method: reorder_options
method: reorder_routes
method: route
method: route_argument
method: route_choice
method: route_count
method: route_handler
method: route_help
method: route_label
method: route_list
method: route_name
method: route_names
method: route_range
method: required
method: reset
method: single
method: spec
method: string
method: usage
method: usage_argument_default
method: usage_argument_help
method: usage_argument_label
method: usage_argument_required
method: usage_argument_token
method: usage_arguments
method: usage_choice_help
method: usage_choice_label
method: usage_choice_required
method: usage_choices
method: usage_description
method: usage_footer
method: usage_gist
method: usage_header
method: usage_line
method: usage_name
method: usage_option_default
method: usage_option_help
method: usage_option_label
method: usage_option_required
method: usage_option_token
method: usage_options
method: usage_summary
method: usage_version
method: vars
method: yesno

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  # $cli->usage;

  # ...

  # $cli->parsed;

  # {help => 1}

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Cli');

  $result
});

=description

This package provides a superclass and methods for creating simple yet robust
command-line interfaces.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Printable

=cut

$test->for('integrates');

=attribute name

The name attribute is read-write, accepts C<(string)> values, and is optional.

=signature name

  name(string $name) (string)

=metadata name

{
  since => '4.15',
}

=cut

=example-1 name

  # given: synopsis

  package main;

  my $name = $cli->name("mycli");

  # "mycli"

=cut

$test->for('example', 1, 'name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "mycli";

  $result
});

=example-2 name

  # given: synopsis

  # given: example-1 name

  package main;

  $name = $cli->name;

  # "mycli"

=cut

$test->for('example', 2, 'name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "mycli";

  $result
});

=attribute version

The version attribute is read-write, accepts C<(string)> values, and is
optional.

=signature version

  version(string $version) (string)

=metadata version

{
  since => '4.15',
}

=cut

=example-1 version

  # given: synopsis

  package main;

  my $version = $cli->version("0.0.1");

  # "0.0.1"

=cut

$test->for('example', 1, 'version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "0.0.1";

  $result
});

=example-2 version

  # given: synopsis

  # given: example-1 version

  package main;

  $version = $cli->version;

  # "0.0.1"

=cut

$test->for('example', 2, 'version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "0.0.1";

  $result
});

=attribute summary

The summary attribute is read-write, accepts C<(string)> values, and is
optional.

=signature summary

  summary(string $summary) (string)

=metadata summary

{
  since => '4.15',
}

=cut

=example-1 summary

  # given: synopsis

  package main;

  my $summary = $cli->summary("Example summary");

  # "Example summary"

=cut

$test->for('example', 1, 'summary', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example summary";

  $result
});

=example-2 summary

  # given: synopsis

  # given: example-1 summary

  package main;

  $summary = $cli->summary;

  # "Example summary"

=cut

$test->for('example', 2, 'summary', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example summary";

  $result
});

=attribute description

The description attribute is read-write, accepts C<(string)> values, and is
optional.

=signature description

  description(string $description) (string)

=metadata description

{
  since => '4.15',
}

=cut

=example-1 description

  # given: synopsis

  package main;

  my $description = $cli->description("Example description");

  # "Example description"

=cut

$test->for('example', 1, 'description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example description";

  $result
});

=example-2 description

  # given: synopsis

  # given: example-1 description

  package main;

  $description = $cli->description;

  # "Example description"

=cut

$test->for('example', 2, 'description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example description";

  $result
});

=attribute header

The header attribute is read-write, accepts C<(string)> values, and is
optional.

=signature header

  header(string $header) (string)

=metadata header

{
  since => '4.15',
}

=cut

=example-1 header

  # given: synopsis

  package main;

  my $header = $cli->header("Example header");

  # "Example header"

=cut

$test->for('example', 1, 'header', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example header";

  $result
});

=example-2 header

  # given: synopsis

  # given: example-1 header

  package main;

  $header = $cli->header;

  # "Example header"

=cut

$test->for('example', 2, 'header', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example header";

  $result
});

=attribute footer

The footer attribute is read-write, accepts C<(string)> values, and is
optional.

=signature footer

  footer(string $footer) (string)

=metadata footer

{
  since => '4.15',
}

=cut

=example-1 footer

  # given: synopsis

  package main;

  my $footer = $cli->footer("Example footer");

  # "Example footer"

=cut

$test->for('example', 1, 'footer', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example footer";

  $result
});

=example-2 footer

  # given: synopsis

  # given: example-1 footer

  package main;

  $footer = $cli->footer;

  # "Example footer"

=cut

$test->for('example', 2, 'footer', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, "Example footer";

  $result
});

=attribute arguments

The arguments attribute is read-write, accepts C<(hashref)> values, and is
optional.

=signature arguments

  arguments(hashref $arguments) (hashref)

=metadata arguments

{
  since => '4.15',
}

=cut

=example-1 arguments

  # given: synopsis

  package main;

  my $arguments = $cli->arguments({});

  # {}

=cut

$test->for('example', 1, 'arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 arguments

  # given: synopsis

  # given: example-1 arguments

  package main;

  $arguments = $cli->arguments;

  # {}

=cut

$test->for('example', 2, 'arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=attribute options

The options attribute is read-write, accepts C<(hashref)> values, and is
optional.

=signature options

  options(hashref $options) (hashref)

=metadata options

{
  since => '4.15',
}

=cut

=example-1 options

  # given: synopsis

  package main;

  my $options = $cli->options({});

  # {}

=cut

$test->for('example', 1, 'options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 options

  # given: synopsis

  # given: example-1 options

  package main;

  $options = $cli->options;

  # {}

=cut

$test->for('example', 2, 'options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=attribute choices

The choices attribute is read-write, accepts C<(hashref)> values, and is
optional.

=signature choices

  choices(hashref $choices) (hashref)

=metadata choices

{
  since => '4.15',
}

=cut

=example-1 choices

  # given: synopsis

  package main;

  my $choices = $cli->choices({});

  # {}

=cut

$test->for('example', 1, 'choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 choices

  # given: synopsis

  # given: example-1 choices

  package main;

  $choices = $cli->choices;

  # {}

=cut

$test->for('example', 2, 'choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=attribute data

The data attribute is read-write, accepts C<(hashref)> values, and is
optional.

=signature data

  data(hashref $data) (hashref)

=metadata data

{
  since => '4.15',
}

=cut

=example-1 data

  # given: synopsis

  package main;

  my $data = $cli->data({});

  # {}

=cut

$test->for('example', 1, 'data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 data

  # given: synopsis

  # given: example-1 data

  package main;

  $data = $cli->data;

  # {}

=cut

$test->for('example', 2, 'data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=method args

The args method returns the list of parsed command-line arguments as a
L<Venus::Args> object.

=signature args

  args() (Venus::Args)

=metadata args

{
  since => '4.15',
}

=cut

=example-1 args

  # given: synopsis

  package main;

  my $args = $cli->args;

  # bless(..., "Venus::Args")

=cut

$test->for('example', 1, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Args');

  $result
});

=example-2 args

  # given: synopsis

  package main;

  $cli->parse('hello', 'world');

  my $args = $cli->args;

  # bless(..., "Venus::Args")

  # $args->get(0);

  # $args->get(1);

=cut

$test->for('example', 2, 'args', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Args');
  is $result->get(0), 'hello';
  is $result->get(1), 'world';

  $result
});

=method argument

The argument method registers and returns the configuration for the argument
specified. The method takes a name (argument name) and a hashref of
configuration values. The possible configuration values are as follows:

+=over 4

+=item *

The C<name> key holds the name of the argument.

+=item *

The C<label> key holds the name of the argument as it should be displayed in
the CLI help text.

+=item *

The C<help> key holds the help text specific to this argument.

+=item *

The C<default> key holds the default value that should used if no value for
this argument is provided to the CLI.

+=item *

The C<multiples> key denotes whether this argument can be used more than once,
to collect multiple values, and holds a C<1> if multiples are allowed and a C<0>
otherwise.

+=item *

The C<prompt> key holds the question or statement that should be presented to
the user of the CLI if no value has been provided for this argument and no
default value has been set.

+=item *

The C<range> key holds a two-value arrayref where the first value is the
starting index and the second value is the ending index. These values are used
to select values from the parsed arguments array as the value(s) for this
argument. This value is ignored if the C<multiples> key is set to C<0>.

+=item *

The C<required> key denotes whether this argument is required or not, and holds
a C<1> if required and a C<0> otherwise.

+=item *

The C<type> key holds the data type of the argument expected. Valid values are
"number", "string", "float", "boolean", or "yesno". B<Note:> Valid boolean
values are C<1>, C<0>, C<"true">, and C<"false">.

+=back

=signature argument

  argument(string $name, hashref $data) (maybe[hashref])

=metadata argument

{
  since => '4.15',
}

=cut

=example-1 argument

  # given: synopsis

  package main;

  my $argument = $cli->argument('name', {
    label => 'Name',
    help => 'The name of the user',
    default => 'Unknown',
    required => 1,
    type => 'string'
  });

  # {
  #   name => 'name',
  #   label => 'Name',
  #   help => 'The name of the user',
  #   default => 'Unknown',
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 1, 'argument', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'name',
    label => 'Name',
    help => 'The name of the user',
    default => 'Unknown',
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 1,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method argument_choice

The argument_choice method returns the parsed argument value only if it
corresponds to a registered choice associated with the named argument. If the
value (or any of the values) doesn't map to a choice, this method will return
an empty arrayref. Returns a list in list context.

=signature argument_choice

  argument_choice(string $name) (arrayref)

=metadata argument_choice

{
  since => '4.15',
}

=cut

=example-1 argument_choice

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_choice = $cli->argument_choice;

  # []

=cut

$test->for('example', 1, 'argument_choice', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 argument_choice

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->parse('stdin');

  my $argument_choice = $cli->argument_choice('input');

  # []

=cut

$test->for('example', 2, 'argument_choice', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-3 argument_choice

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('stdout', {
    argument => 'input',
  });

  $cli->parse('stdin');

  my $argument_choice = $cli->argument_choice('input');

  # ['stdin']

=cut

$test->for('example', 3, 'argument_choice', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['stdin'];

  $result
});

=example-4 argument_choice

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('stdout', {
    argument => 'input',
  });

  $cli->parse('stdin', 'stdout');

  my $argument_choice = $cli->argument_choice('input');

  # ['stdin', 'stdout']

=cut

$test->for('example', 4, 'argument_choice', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['stdin', 'stdout'];

  $result
});

=method argument_choices

The argument_choices method returns all registered choices associated with
the argument named. Returns a list in list context.

=signature argument_choices

  argument_choices(string $name) (arrayref)

=metadata argument_choices

{
  since => '4.15',
}

=cut

=example-1 argument_choices

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_choices = $cli->argument_choices;

  # []

=cut

$test->for('example', 1, 'argument_choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 argument_choices

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  my $argument_choices = $cli->argument_choices('input');

  # []

=cut

$test->for('example', 2, 'argument_choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-3 argument_choices

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $argument_choices = $cli->argument_choices('input');

  # [{
  #   name => 'stdin',
  #   label => undef,
  #   help => 'Expects a string value',
  #   argument => 'input',
  #   index => 0,
  #   wants => 'string',
  # }]

=cut

$test->for('example', 3, 'argument_choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [{
    name => 'stdin',
    label => undef,
    help => 'Expects a string value',
    argument => 'input',
    index => 0,
    wants => 'string',
  }];

  $result
});

=method argument_count

The argument_count method returns the count of registered arguments.

=signature argument_count

  argument_count() (number)

=metadata argument_count

{
  since => '4.15',
}

=example-1 argument_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_count = $cli->argument_count;

  # 0

=cut

$test->for('example', 1, 'argument_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 argument_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $argument_count = $cli->argument_count;

  # 2

=cut

$test->for('example', 2, 'argument_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=method argument_default

The argument_default method returns the C<default> configuration value for the
named argument.

=signature argument_default

  argument_default(string $name) (string)

=metadata argument_default

{
  since => '4.15',
}

=example-1 argument_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_default = $cli->argument_default;

  # ""

=cut

$test->for('example', 1, 'argument_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => 'stdin',
  });

  my $argument_default = $cli->argument_default('input');

  # "stdin"

=cut

$test->for('example', 2, 'argument_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'stdin';

  $result
});

=method argument_errors

The argument_errors method returns a list of L<"issues"|Venus::Validate/issue>,
if any, for each value returned by L</argument_value> for the named argument.
Returns a list in list context.

=signature argument_errors

  argument_errors(string $name) (within[arrayref, Venus::Validate])

=metadata argument_errors

{
  since => '4.15',
}

=example-1 argument_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_errors = $cli->argument_errors;

  # []

=cut

$test->for('example', 1, 'argument_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 argument_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->parse('hello');

  my $argument_errors = $cli->argument_errors('input');

  # []

=cut

$test->for('example', 2, 'argument_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-3 argument_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'number',
  });

  $cli->parse('hello');

  my $argument_errors = $cli->argument_errors('input');

  # [['type', ['number']]]

=cut

$test->for('example', 3, 'argument_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['type', ['number']]];

  $result
});

=method argument_help

The argument_help method returns the C<help> configuration value for the named
argument.

=signature argument_help

  argument_help(string $name) (string)

=metadata argument_help

{
  since => '4.15',
}

=example-1 argument_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_help = $cli->argument_help;

  # ""

=cut

$test->for('example', 1, 'argument_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Example help text',
  });

  my $argument_help = $cli->argument_help('input');

  # "Example help text"

=cut

$test->for('example', 2, 'argument_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example help text";

  $result
});

=method argument_label

The argument_label method returns the C<label> configuration value for the
named argument.

=signature argument_label

  argument_label(string $name) (string)

=metadata argument_label

{
  since => '4.15',
}

=example-1 argument_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_label = $cli->argument_label;

  # ""

=cut

$test->for('example', 1, 'argument_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input',
  });

  my $argument_label = $cli->argument_label('input');

  # "Input"

=cut

$test->for('example', 2, 'argument_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Input";

  $result
});

=method argument_list

The argument_list method returns a list of registered argument configurations.
Returns a list in list context.

=signature argument_list

  argument_list(string $name) (within[arrayref, hashref])

=metadata argument_list

{
  since => '4.15',
}

=example-1 argument_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_list = $cli->argument_list;

  # []

=cut

$test->for('example', 1, 'argument_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 argument_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  my $argument_list = $cli->argument_list;

  # [{
  #   name => 'input',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => false,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }]

=cut

$test->for('example', 2, 'argument_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [{
    name => 'input',
    label => undef,
    help => 'Expects a string value',
    default => undef,
    multiples => 0,
    prompt => undef,
    range => undef,
    required => false,
    type => 'string',
    index => 0,
    wants => 'string',
  }];

  $result
});

=method argument_multiples

The argument_multiples method returns the C<multiples> configuration value for
the named argument.

=signature argument_multiples

  argument_multiples(string $name) (boolean)

=metadata argument_multiples

{
  since => '4.15',
}

=example-1 argument_multiples

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_multiples = $cli->argument_multiples;

  # false

=cut

$test->for('example', 1, 'argument_multiples', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 argument_multiples

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
  });

  my $argument_multiples = $cli->argument_multiples('input');

  # true

=cut

$test->for('example', 2, 'argument_multiples', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method argument_name

The argument_name method returns the C<name> configuration value for the named
argument.

=signature argument_name

  argument_name(string $name) (string)

=metadata argument_name

{
  since => '4.15',
}

=example-1 argument_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_name = $cli->argument_name;

  # ""

=cut

$test->for('example', 1, 'argument_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    name => 'INPUT',
  });

  my $argument_name = $cli->argument_name('input');

  # ""

=cut

$test->for('example', 2, 'argument_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-3 argument_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    name => 'INPUT',
  });

  my $argument_name = $cli->argument_name('INPUT');

  # "INPUT"

=cut

$test->for('example', 3, 'argument_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "INPUT";

  $result
});

=method argument_names

The argument_names method returns the names (keys) of registered arguments in
the order declared. Returns a list in list context.

=signature argument_names

  argument_names(string $name) (within[arrayref, string])

=metadata argument_names

{
  since => '4.15',
}

=example-1 argument_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_names = $cli->argument_names;

  # []

=cut

$test->for('example', 1, 'argument_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 argument_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $argument_names = $cli->argument_names;

  # ['input', 'output']

=cut

$test->for('example', 2, 'argument_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['input', 'output'];

  $result
});

=example-3 argument_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('output', {
    type => 'string',
  });

  $cli->argument('input', {
    type => 'string',
  });

  my $argument_names = $cli->argument_names;

  # ['output', 'input']

=cut

$test->for('example', 3, 'argument_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['output', 'input'];

  $result
});

=method argument_prompt

The argument_prompt method returns the C<prompt> configuration value for the
named argument.

=signature argument_prompt

  argument_prompt(string $name) (string)

=metadata argument_prompt

{
  since => '4.15',
}

=example-1 argument_prompt

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_prompt = $cli->argument_prompt;

  # ""

=cut

$test->for('example', 1, 'argument_prompt', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_prompt

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    prompt => 'Example prompt',
  });

  my $argument_prompt = $cli->argument_prompt('input');

  # "Example prompt"

=cut

$test->for('example', 2, 'argument_prompt', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example prompt";

  $result
});

=method argument_range

The argument_range method returns the C<range> configuration value for the
named argument.

=signature argument_range

  argument_range(string $name) (string)

=metadata argument_range

{
  since => '4.15',
}

=example-1 argument_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_range = $cli->argument_range;

  # ""

=cut

$test->for('example', 1, 'argument_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
  });

  my $argument_range = $cli->argument_range('input');

  # "0"

=cut

$test->for('example', 2, 'argument_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "0";

  !$result
});

=example-3 argument_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0:5',
  });

  my $argument_range = $cli->argument_range('input');

  # "0:5"

=cut

$test->for('example', 3, 'argument_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "0:5";

  $result
});

=method argument_required

The argument_required method returns the C<required> configuration value for
the named argument.

=signature argument_required

  argument_required(string $name) (boolean)

=metadata argument_required

{
  since => '4.15',
}

=example-1 argument_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_required = $cli->argument_required;

  # false

=cut

$test->for('example', 1, 'argument_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 argument_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  my $argument_required = $cli->argument_required('input');

  # true

=cut

$test->for('example', 2, 'argument_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method argument_type

The argument_type method returns the C<type> configuration value for the named
argument. Valid values are as follows:

+=over 4

+=item *

C<number>

+=item *

C<string>

+=item *

C<float>

+=item *

C<boolean> - B<Note:> Valid boolean values are C<1>, C<0>, C<"true">, and C<"false">.

+=item *

C<yesno>

+=back

=signature argument_type

  argument_type(string $name) (string)

=metadata argument_type

{
  since => '4.15',
}

=example-1 argument_type

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_type = $cli->argument_type;

  # ""

=cut

$test->for('example', 1, 'argument_type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_type

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'boolean',
  });

  my $argument_type = $cli->argument_type('input');

  # "boolean"

=cut

$test->for('example', 2, 'argument_type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "boolean";

  $result
});

=method argument_validate

The argument_validate method returns a L<Venus::Validate> object for each value
returned by L</argument_value> for the named argument. Returns a list in list
context.

=signature argument_validate

  argument_validate(string $name) (Venus::Validate | within[arrayref, Venus::Validate])

=metadata argument_validate

{
  since => '4.15',
}

=example-1 argument_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_validate = $cli->argument_validate;

  # []

=cut

$test->for('example', 1, 'argument_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 argument_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0',
    type => 'string',
  });

  my $argument_validate = $cli->argument_validate('input');

  # [bless(..., "Venus::Validate")]

=cut

$test->for('example', 2, 'argument_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 1;
  ok $result->[0]->isa('Venus::Validate');

  $result
});

=example-3 argument_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0',
    type => 'string',
  });

  my $argument_validate = $cli->argument_validate('input');

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 3, 'argument_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');

  $result
});

=example-4 argument_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->parse('hello', 'world');

  my $argument_validate = $cli->argument_validate('input');

  # [bless(..., "Venus::Validate"), bless(..., "Venus::Validate")]

=cut

$test->for('example', 4, 'argument_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 2;
  ok $result->[0]->isa('Venus::Validate');
  ok $result->[1]->isa('Venus::Validate');

  $result
});

=method argument_value

The argument_value method returns the parsed argument value for the named
argument.

=signature argument_value

  argument_value(string $name) (any)

=metadata argument_value

{
  since => '4.15',
}

=example-1 argument_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_value = $cli->argument_value;

  # undef

=cut

$test->for('example', 1, 'argument_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 argument_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0:',
    type => 'string',
  });

  $cli->parse('hello', 'world');

  my $argument_value = $cli->argument_value('input');

  # "hello"

=cut

$test->for('example', 2, 'argument_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "hello";

  $result
});

=example-3 argument_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->parse('hello', 'world');

  my $argument_value = $cli->argument_value('input');

  # ["hello", "world"]

=cut

$test->for('example', 3, 'argument_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ["hello", "world"];

  $result
});

=method argument_wants

The argument_wants method returns the C<wants> configuration value for the
named argument.

=signature argument_wants

  argument_wants(string $name) (string)

=metadata argument_wants

{
  since => '4.15',
}

=example-1 argument_wants

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $argument_wants = $cli->argument_wants;

  # ""

=cut

$test->for('example', 1, 'argument_wants', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 argument_wants

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    wants => 'string',
  });

  my $argument_wants = $cli->argument_wants('input');

  # "string"

=cut

$test->for('example', 2, 'argument_wants', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "string";

  $result
});

=method assigned_arguments

The assigned_arguments method gets the values for the registered arguments.

=signature assigned_arguments

  assigned_arguments() (hashref)

=metadata assigned_arguments

{
  since => '4.15',
}

=example-1 assigned_arguments

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_arguments = $cli->assigned_arguments;

  # {extra => 'hello'}

=cut

$test->for('example', 1, 'assigned_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {extra => 'hello'};

  $result
});

=example-2 assigned_arguments

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_arguments = $cli->assigned_arguments;

  # {extra => ['hello', 'world']}

=cut

$test->for('example', 2, 'assigned_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {extra => ['hello', 'world']};

  $result
});

=method assigned_options

The assigned_options method gets the values for the registered options.

=signature assigned_options

  assigned_options() (hashref)

=metadata assigned_options

{
  since => '4.15',
}

=example-1 assigned_options

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_options = $cli->assigned_options;

  # {input => 'stdin', output => 'stdout'}

=cut

$test->for('example', 1, 'assigned_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {input => 'stdin', output => 'stdout'};

  $result
});

=example-2 assigned_options

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->option('output', {
    multiples => true,
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $assigned_options = $cli->assigned_options;

  # {input => ['stdin'], output => ['stdout']}

=cut

$test->for('example', 2, 'assigned_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {input => ['stdin'], output => ['stdout']};

  $result
});

=method boolean

The boolean method is a configuration dispatcher and shorthand for C<{'type',
'boolean'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

=signature boolean

  boolean(string $method, any @args) (any)

=metadata boolean

{
  since => '4.15',
}

=cut

=example-1 boolean

  # given: synopsis

  package main;

  my $boolean = $cli->boolean;

  # {type => 'boolean'}

=cut

$test->for('example', 1, 'boolean', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'boolean'};

  $result
});

=example-2 boolean

  # given: synopsis

  package main;

  my $boolean = $cli->boolean(undef, {required => true});

  # {type => 'boolean', required => true}

=cut

$test->for('example', 2, 'boolean', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'boolean', required => true};

  $result
});

=example-3 boolean

  # given: synopsis

  package main;

  my $boolean = $cli->boolean('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a boolean value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'boolean',
  #   index => 0,
  #   wants => 'boolean',
  # }

=cut

$test->for('example', 3, 'boolean', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a boolean value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'boolean',
    index => 0,
    wants => 'boolean',
  };

  $result
});

=method choice

The choice method registers and returns the configuration for the choice
specified. The method takes a name (choice name) and a hashref of
configuration values. The possible configuration values are as follows:

+=over 4

+=item *

The C<name> key holds the name of the argument.

+=item *

The C<label> key holds the name of the argument as it should be displayed in
the CLI help text.

+=item *

The C<help> key holds the help text specific to this argument.

+=item *

The C<argument> key holds the name  of the argument that this choice is a
value for.

+=item *

The C<wants> key holdd the text to be used as a value placeholder in the CLI
help text.

+=back

=signature choice

  choice(string $name, hashref $data) (maybe[hashref])

=metadata choice

{
  since => '4.15',
}

=example-1 choice

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  my $choice = $cli->choice('stdin', {
    argument => 'input',
  });

  # {
  #   name => 'stdin',
  #   label => undef,
  #   help => undef,
  #   argument => 'input',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 1, 'choice', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'stdin',
    label => undef,
    help => 'Expects a string value',
    argument => 'input',
    index => 0,
    wants => 'string',
  };

  $result
});

=method choice_argument

The choice_argument method returns the argument configuration corresponding
with the C<argument> value of the named choice.

=signature choice_argument

  choice_argument(string $name) (hashref)

=metadata choice_argument

{
  since => '4.15',
}

=example-1 choice_argument

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_argument = $cli->choice_argument('stdin');

  # {
  #   name => 'input',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 0,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 1, 'choice_argument', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'input',
    label => undef,
    help => 'Expects a string value',
    default => undef,
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method choice_count

The choice_count method returns the count of registered choices.

=signature choice_count

  choice_count() (number)

=metadata choice_count

{
  since => '4.15',
}

=example-1 choice_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_count = $cli->choice_count;

  # 0

=cut

$test->for('example', 1, 'choice_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 choice_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0:',
    type => 'string',
  });

  $cli->choice('file', {
    argument => 'input',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_count = $cli->choice_count;

  # 2

=cut

$test->for('example', 2, 'choice_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=method choice_default

The choice_default method returns the C<default> configuration value for the
argument corresponding to the named choice.

=signature choice_default

  choice_default(string $name) (string)

=metadata choice_default

{
  since => '4.15',
}

=example-1 choice_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => 'file',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_default = $cli->choice_default('stdin');

  # "file"

=cut

$test->for('example', 1, 'choice_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "file";

  $result
});

=method choice_errors

The choice_errors method returns a list of L<"issues"|Venus::Validate/issue>,
if any, for each value returned by L</choice_value> for the named choice.
Returns a list in list context.

=signature choice_errors

  choice_errors(string $name) (within[arrayref, Venus::Validate])

=metadata choice_errors

{
  since => '4.15',
}

=example-1 choice_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_errors = $cli->choice_errors;

  # []

=cut

$test->for('example', 1, 'choice_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 choice_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello');

  my $choice_errors = $cli->choice_errors('stdin');

  # []

=cut

$test->for('example', 2, 'choice_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-3 choice_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0',
    type => 'number',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello');

  my $choice_errors = $cli->choice_errors('stdin');

  # [['type', ['number']]]

=cut

$test->for('example', 3, 'choice_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['type', ['number']]];

  $result
});

=method choice_help

The choice_help method returns the C<help> configuration value the named
choice.

=signature choice_help

  choice_help(string $name) (string)

=metadata choice_help

{
  since => '4.15',
}

=example-1 choice_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_help = $cli->choice_help;

  # ""

=cut

$test->for('example', 1, 'choice_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 choice_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
    help => 'Example help',
  });

  my $choice_help = $cli->choice_help('stdin');

  # "Example help"

=cut

$test->for('example', 2, 'choice_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example help";

  $result
});

=method choice_label

The choice_label method returns the C<label> configuration value for the named
choice.

=signature choice_label

  choice_label(string $name) (string)

=metadata choice_label

{
  since => '4.15',
}

=example-1 choice_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_label = $cli->choice_label;

  # ""

=cut

$test->for('example', 1, 'choice_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 choice_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
    label => 'Standard input',
  });

  my $choice_label = $cli->choice_label('stdin');

  # "Standard input"

=cut

$test->for('example', 2, 'choice_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Standard input";

  $result
});

=method choice_list

The choice_list method returns a list of registered choice configurations.
Returns a list in list context.

=signature choice_list

  choice_list(string $name) (within[arrayref, hashref])

=metadata choice_list

{
  since => '4.15',
}

=example-1 choice_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_list = $cli->choice_list;

  # []

=cut

$test->for('example', 1, 'choice_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 choice_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_list = $cli->choice_list;

  # [{
  #   name => 'stdin',
  #   label => undef,
  #   help => 'Expects a string value',
  #   argument => 'input',
  #   index => 0,
  #   wants => 'string',
  # }]

=cut

$test->for('example', 2, 'choice_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [{
    name => 'stdin',
    label => undef,
    help => 'Expects a string value',
    argument => 'input',
    index => 0,
    wants => 'string',
  }];

  $result
});

=method choice_multiples

The choice_multiples method returns the C<multiples> configuration value for
the argument corresponding to the named choice.

=signature choice_multiples

  choice_multiples(string $name) (boolean)

=metadata choice_multiples

{
  since => '4.15',
}

=example-1 choice_multiples

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_multiples = $cli->choice_multiples;

  # false

=cut

$test->for('example', 1, 'choice_multiples', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 choice_multiples

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_multiples = $cli->choice_multiples('stdin');

  # true

=cut

$test->for('example', 2, 'choice_multiples', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method choice_name

The choice_name method returns the C<name> configuration value for the named
choice.

=signature choice_name

  choice_name(string $name) (string)

=metadata choice_name

{
  since => '4.15',
}

=example-1 choice_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_name = $cli->choice_name;

  # ""

=cut

$test->for('example', 1, 'choice_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 choice_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    name => 'STDIN',
    argument => 'input',
  });

  my $choice_name = $cli->choice_name('stdin');

  # "STDIN"

=cut

$test->for('example', 2, 'choice_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "STDIN";

  $result
});

=method choice_names

The choice_names method returns the names (keys) of registered choices in
the order declared. Returns a list in list context.

=signature choice_names

  choice_names(string $name) (within[arrayref, string])

=metadata choice_names

{
  since => '4.15',
}

=example-1 choice_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_names = $cli->choice_names;

  # []

=cut

$test->for('example', 1, 'choice_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 choice_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('file', {
    argument => 'input',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_names = $cli->choice_names;

  # ['file', 'stdin']

=cut

$test->for('example', 2, 'choice_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['file', 'stdin'];

  $result
});

=example-3 choice_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('file', {
    argument => 'input',
  });

  my $choice_names = $cli->choice_names;

  # ['stdin', 'file']

=cut

$test->for('example', 3, 'choice_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['stdin', 'file'];

  $result
});

=method choice_prompt

The choice_prompt method returns the C<prompt> configuration value for the
argument corresponding to the named choice.

=signature choice_prompt

  choice_prompt(string $name) (string)

=metadata choice_prompt

{
  since => '4.15',
}

=example-1 choice_prompt

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_prompt = $cli->choice_prompt;

  # ""

=cut

$test->for('example', 1, 'choice_prompt', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 choice_prompt

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    prompt => 'Example prompt',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_prompt = $cli->choice_prompt('stdin');

  # "Example prompt"

=cut

$test->for('example', 2, 'choice_prompt', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example prompt";

  $result
});

=method choice_range

The choice_range method returns the C<range> configuration value for the
argument corresponding to the named choice.

=signature choice_range

  choice_range(string $name) (string)

=metadata choice_range

{
  since => '4.15',
}

=example-1 choice_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_range = $cli->choice_range;

  # ""

=cut

$test->for('example', 1, 'choice_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 choice_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_range = $cli->choice_range('stdin');

  # "0:"

=cut

$test->for('example', 2, 'choice_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "0:";

  $result
});

=method choice_required

The choice_required method returns the C<required> configuration value for the
argument corresponding to the named choice.

=signature choice_required

  choice_required(string $name) (boolean)

=metadata choice_required

{
  since => '4.15',
}

=example-1 choice_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_required = $cli->choice_required;

  # false

=cut

$test->for('example', 1, 'choice_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 choice_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_required = $cli->choice_required('stdin');

  # true

=cut

$test->for('example', 2, 'choice_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method choice_type

The choice_type method returns the C<type> configuration value for the
argument corresponding to the named choice.

=signature choice_type

  choice_type(string $name) (string)

=metadata choice_type

{
  since => '4.15',
}

=example-1 choice_type

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_type = $cli->choice_type;

  # ""

=cut

$test->for('example', 1, 'choice_type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 choice_type

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_type = $cli->choice_type('stdin');

  # "string"

=cut

$test->for('example', 2, 'choice_type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "string";

  $result
});

=method choice_validate

The choice_validate method returns a L<Venus::Validate> object for each value
returned by L</choice_value> for the named choice. Returns a list in list
context.

=signature choice_validate

  choice_validate(string $name) (within[arrayref, Venus::Validate])

=metadata choice_validate

{
  since => '4.15',
}

=example-1 choice_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_validate = $cli->choice_validate;

  # []

=cut

$test->for('example', 1, 'choice_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 choice_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_validate = $cli->choice_validate('stdin');

  # [bless(..., "Venus::Validate")]

=cut

$test->for('example', 2, 'choice_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 1;
  ok $result->[0]->isa('Venus::Validate');

  $result
});

=example-3 choice_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_validate = $cli->choice_validate('stdin');

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 3, 'choice_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');

  $result
});

=example-4 choice_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello', 'world');

  my $choice_validate = $cli->choice_validate('stdin');

  # [bless(..., "Venus::Validate"), bless(..., "Venus::Validate")]

=cut

$test->for('example', 4, 'choice_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 2;
  ok $result->[0]->isa('Venus::Validate');
  ok $result->[1]->isa('Venus::Validate');

  $result
});

=method choice_value

The choice_value method returns the parsed choice value for the named
choice.

=signature choice_value

  choice_value(string $name) (any)

=metadata choice_value

{
  since => '4.15',
}

=example-1 choice_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_value = $cli->choice_value;

  # undef

=cut

$test->for('example', 1, 'choice_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 choice_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => false,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello', 'world');

  my $choice_value = $cli->choice_value('stdin');

  # "hello"

=cut

$test->for('example', 2, 'choice_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "hello";

  $result
});

=example-3 choice_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->parse('hello', 'world');

  my $choice_value = $cli->choice_value('stdin');

  # ["hello", "world"]

=cut

$test->for('example', 3, 'choice_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ["hello", "world"];

  $result
});

=method choice_wants

The choice_wants method returns the C<wants> configuration value for the
argument corresponding to the named choice.

=signature choice_wants

  choice_wants(string $name) (string)

=metadata choice_wants

{
  since => '4.15',
}

=example-1 choice_wants

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $choice_wants = $cli->choice_wants;

  # ""

=cut

$test->for('example', 1, 'choice_wants', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 choice_wants

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    wants => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $choice_wants = $cli->choice_wants('stdin');

  # "string"

=cut

$test->for('example', 2, 'choice_wants', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "string";

  $result
});

=method command

The command method creates and associates an argument, choice, and route. It
takes an argument name, a choice name (string or arrayref of parts), and a
handler (method name or coderef). The method returns the route configuration
for the command.

=signature command

  command(string $argument, string | arrayref $choice, string | coderef $handler) (maybe[hashref])

=metadata command

{
  since => '4.15',
}

=example-1 command

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $command = $cli->command('command', ['user', 'create'], 'handle_user_create');

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => 'command',
  #   choice => 'user create',
  #   handler => 'handle_user_create',
  #   range => ':1',
  #   index => 0,
  # }

=cut

$test->for('example', 1, 'command', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'user create',
    label => undef,
    help => undef,
    argument => 'command',
    choice => 'user create',
    handler => 'handle_user_create',
    range => ':1',
    index => 0,
  };

  $result
});

=example-2 command

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $command = $cli->command('command', 'user create', 'handle_user_create');

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => 'command',
  #   choice => 'user create',
  #   handler => 'handle_user_create',
  #   range => ':1',
  #   index => 0,
  # }

=cut

$test->for('example', 2, 'command', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'user create',
    label => undef,
    help => undef,
    argument => 'command',
    choice => 'user create',
    handler => 'handle_user_create',
    range => ':1',
    index => 0,
  };

  $result
});

=example-3 command

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $command = $cli->command('command', ['user'], 'handle_user');

  # {
  #   name => 'user',
  #   label => undef,
  #   help => undef,
  #   argument => 'command',
  #   choice => 'user',
  #   handler => 'handle_user',
  #   range => ':0',
  #   index => 0,
  # }

=cut

$test->for('example', 3, 'command', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'user',
    label => undef,
    help => undef,
    argument => 'command',
    choice => 'user',
    handler => 'handle_user',
    range => ':0',
    index => 0,
  };

  $result
});

=example-4 command

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], 'handle_user_create');
  $cli->command('command', ['user', 'delete'], 'handle_user_delete');

  my $argument = $cli->argument('command');

  # {
  #   name => 'command',
  #   ...
  #   range => ':1',
  # }

=cut

$test->for('example', 4, 'command', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result->{name}, 'command';
  is $result->{range}, ':1';

  $result
});

=method dispatch

The dispatch method parses CLI arguments, matches them against registered
routes, and invokes the appropriate handler. If the handler is a coderef, it is
called with the CLI instance, L</assigned_arguments>, and L</assigned_options>.
If the handler is a local method name, it is called with </assigned_arguments>,
and L</assigned_options>. If the handler is a package name, the package is
loaded and instantiated. If the package is a L<Venus::Task>, its
L<Venus::Task/handle> method is called. If the package is a L<Venus::Cli>, its
L</dispatch> method is called. When dispatching to a package, only the relevant
portion of the command line arguments (after the matched command) is passed.

=signature dispatch

  dispatch(any @args) (any)

=metadata dispatch

{
  since => '4.15',
}

=example-1 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $dispatch = $cli->dispatch;

  # undef

=cut

$test->for('example', 1, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], 'handle_user_create');

  my $dispatch = $cli->dispatch('user', 'create');

  # undef (no handler method exists)

=cut

$test->for('example', 2, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-3 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $handler_called = 0;
  my $handler_args;

  $cli->command('command', ['user', 'create'], sub {
    my ($self, $args, $opts) = @_;
    $handler_called = 1;
    $handler_args = [$args, $opts];
    return 'handler result';
  });

  my $dispatch = $cli->dispatch('user', 'create');

  # "handler result"

=cut

$test->for('example', 3, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'handler result';

  $result
});

=example-4 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], sub {'user_create'});
  $cli->command('command', ['user', 'delete'], sub {'user_delete'});
  $cli->command('command', ['user'], sub {'user'});

  my $dispatch = $cli->dispatch('user', 'create');

  # "user_create"

=cut

$test->for('example', 4, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'user_create';

  $result
});

=example-5 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], sub {'user_create'});
  $cli->command('command', ['user', 'delete'], sub {'user_delete'});
  $cli->command('command', ['user'], sub {'user'});

  my $dispatch = $cli->dispatch('user');

  # "user"

=cut

$test->for('example', 5, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'user';

  $result
});

=example-6 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['user', 'create'], sub {'user_create'});
  $cli->command('command', ['user', 'delete'], sub {'user_delete'});
  $cli->command('command', ['user'], sub {'user'});

  my $dispatch = $cli->dispatch('user', 'delete');

  # "user_delete"

=cut

$test->for('example', 6, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'user_delete';

  $result
});

=example-7 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('verbose', {
    type => 'boolean',
    alias => 'v',
  });

  $cli->command('command', ['user', 'create'], sub {
    my ($self, $args, $opts) = @_;
    return $opts->{verbose} ? 'verbose' : 'quiet';
  });

  my $dispatch = $cli->dispatch('user', 'create', '--verbose');

  # "verbose"

=cut

$test->for('example', 7, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'verbose';

  $result
});

=example-8 dispatch

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->command('command', ['unknown'], sub {'unknown'});

  my $dispatch = $cli->dispatch('other');

  # undef (no matching route)

=cut

$test->for('example', 8, 'dispatch', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=method exit

The exit method terminates the program with a specified exit code. If no exit
code is provided, it defaults to C<0>, indicating a successful exit. This
method can be used to end the program explicitly, either after a specific task
is completed or when an error occurs that requires halting execution. This
method can dispatch to another method or callback before exiting.

=signature exit

  exit(number $expr, string | coderef $code, any @args) (any)

=metadata exit

{
  since => '4.15',
}

=cut

=example-1 exit

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->exit;

  # 0

=cut

$test->for('example', 1, 'exit', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 0;

  $space->unpatch;

  !$result
});

=example-2 exit

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->exit(1);

  # 1

=cut

$test->for('example', 2, 'exit', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 1;

  $space->unpatch;

  $result
});

=example-3 exit

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->exit(5, sub{
    $cli->{dispatched} = 1;
  });

  # 5

=cut

$test->for('example', 3, 'exit', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 5;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->exit(5, sub{
    $cli->{dispatched} = 1;
  });

  is $cli->{dispatched}, 1;

  $space->unpatch;

  $result
});

=method fail

The fail method terminates the program with a the exit code C<1>, indicating a
failure on exit. This method can be used to end the program explicitly, either
after a specific task is completed or when an error occurs that requires
halting execution. This method can dispatch to another method or callback
before exiting.

=signature fail

  fail(string | coderef $code, any @args) (any)

=metadata fail

{
  since => '4.15',
}

=cut

=example-1 fail

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->fail;

  # 1

=cut

$test->for('example', 1, 'fail', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 1;

  $space->unpatch;

  $result
});

=example-2 fail

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->fail(sub{
    $cli->{dispatched} = 1;
  });

  # 1

=cut

$test->for('example', 2, 'fail', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 1;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->fail(sub{
    $cli->{dispatched} = 1;
  });

  is $cli->{dispatched}, 1;

  $space->unpatch;

  $result
});

=method float

The float method is a configuration dispatcher and shorthand for C<{'type',
'float'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

=signature float

  float(string $method, any @args) (any)

=metadata float

{
  since => '4.15',
}

=cut

=example-1 float

  # given: synopsis

  package main;

  my $float = $cli->float;

  # {type => 'float'}

=cut

$test->for('example', 1, 'float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'float'};

  $result
});

=example-2 float

  # given: synopsis

  package main;

  my $float = $cli->float(undef, {required => true});

  # {type => 'float', required => true}

=cut

$test->for('example', 2, 'float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'float', required => true};

  $result
});

=example-3 float

  # given: synopsis

  package main;

  my $float = $cli->float('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a float value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'float',
  #   index => 0,
  #   wants => 'float',
  # }

=cut

$test->for('example', 3, 'float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a float value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'float',
    index => 0,
    wants => 'float',
  };

  $result
});

=method has_input

The has_input method returns true if input arguments and/or options are found,
and otherwise returns false.

=signature has_input

  has_input() (boolean)

=metadata has_input

{
  since => '4.15',
}

=example-1 has_input

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_input = $cli->has_input;

  # false

=cut

$test->for('example', 1, 'has_input', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_input

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin');

  my $has_input = $cli->has_input;

  # true

=cut

$test->for('example', 2, 'has_input', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_input_arguments

The has_input_arguments method returns true if input arguments are found, and
otherwise returns false.

=signature has_input_arguments

  has_input_arguments() (boolean)

=metadata has_input_arguments

{
  since => '4.15',
}

=example-1 has_input_arguments

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_input_arguments = $cli->has_input_arguments;

  # false

=cut

$test->for('example', 1, 'has_input_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_input_arguments

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('example');

  my $has_input_arguments = $cli->has_input_arguments;

  # true

=cut

$test->for('example', 2, 'has_input_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_input_options

The has_input_options method returns true if input options are found, and
otherwise returns false.

=signature has_input_options

  has_input_options() (boolean)

=metadata has_input_options

{
  since => '4.15',
}

=example-1 has_input_options

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_input_options = $cli->has_input_options;

  # false

=cut

$test->for('example', 1, 'has_input_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_input_options

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdout');

  my $has_input_options = $cli->has_input_options;

  # true

=cut

$test->for('example', 2, 'has_input_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_output

The has_output method returns true if output events are found, and otherwise
returns false.

=signature has_output

  has_output() (boolean)

=metadata has_output

{
  since => '4.15',
}

=example-1 has_output

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $has_output = $cli->has_output;

  # false

=cut

$test->for('example', 1, 'has_output', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_output

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output = $cli->has_output;

  # true

=cut

$test->for('example', 2, 'has_output', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_output_debug_events

The has_output_debug_events method returns true if debug output events are
found, and otherwise returns false.

=signature has_output_debug_events

  has_output_debug_events() (boolean)

=metadata has_output_debug_events

{
  since => '4.15',
}

=example-1 has_output_debug_events

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_debug_events = $cli->has_output_debug_events;

  # false

=cut

$test->for('example', 1, 'has_output_debug_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_output_debug_events

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_debug('example output');

  my $has_output_debug_events = $cli->has_output_debug_events;

  # true

=cut

$test->for('example', 2, 'has_output_debug_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_output_error_events

The has_output_error_events method returns true if error output events are
found, and otherwise returns false.

=signature has_output_error_events

  has_output_error_events() (boolean)

=metadata has_output_error_events

{
  since => '4.15',
}

=example-1 has_output_error_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_error_events = $cli->has_output_error_events;

  # false

=cut

$test->for('example', 1, 'has_output_error_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_output_error_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_error('example output');

  my $has_output_error_events = $cli->has_output_error_events;

  # true

=cut

$test->for('example', 2, 'has_output_error_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_output_fatal_events

The has_output_fatal_events method returns true if fatal output events are
found, and otherwise returns false.

=signature has_output_fatal_events

  has_output_fatal_events() (boolean)

=metadata has_output_fatal_events

{
  since => '4.15',
}

=example-1 has_output_fatal_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_fatal_events = $cli->has_output_fatal_events;

  # false

=cut

$test->for('example', 1, 'has_output_fatal_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_output_fatal_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_fatal('example output');

  my $has_output_fatal_events = $cli->has_output_fatal_events;

  # true

=cut

$test->for('example', 2, 'has_output_fatal_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_output_info_events

The has_output_info_events method returns true if info output events are found,
and otherwise returns false.

=signature has_output_info_events

  has_output_info_events() (boolean)

=metadata has_output_info_events

{
  since => '4.15',
}

=example-1 has_output_info_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_info_events = $cli->has_output_info_events;

  # true

=cut

$test->for('example', 1, 'has_output_info_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 has_output_info_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_error('example output');

  my $has_output_info_events = $cli->has_output_info_events;

  # false

=cut

$test->for('example', 2, 'has_output_info_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method has_output_trace_events

The has_output_trace_events method returns true if trace output events are
found, and otherwise returns false.

=signature has_output_trace_events

  has_output_trace_events() (boolean)

=metadata has_output_trace_events

{
  since => '4.15',
}

=example-1 has_output_trace_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_trace_events = $cli->has_output_trace_events;

  # false

=cut

$test->for('example', 1, 'has_output_trace_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_output_trace_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_trace('example output');

  my $has_output_trace_events = $cli->has_output_trace_events;

  # true

=cut

$test->for('example', 2, 'has_output_trace_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method has_output_warn_events

The has_output_warn_events method returns true if warn output events are found,
and otherwise returns false.

=signature has_output_warn_events

  has_output_warn_events() (boolean)

=metadata has_output_warn_events

{
  since => '4.15',
}

=example-1 has_output_warn_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_info('example output');

  my $has_output_warn_events = $cli->has_output_warn_events;

  # false

=cut

$test->for('example', 1, 'has_output_warn_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 has_output_warn_events

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->log_warn('example output');

  my $has_output_warn_events = $cli->has_output_warn_events;

  # true

=cut

$test->for('example', 2, 'has_output_warn_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method help

The help method uses L</log_info> method to output CLI usage/help text.

=signature help

  help() (Venus::Cli)

=metadata help

{
  since => '4.15',
}

=example-1 help

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $help = $cli->help;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  ok $result->has_output_info_events;

  $result
});

=method input

The input method returns input arguments in scalar context, and returns
arguments and options in list context. Arguments and options are returned as
hashrefs.

=signature input

  input() (hashref)

=metadata input

{
  since => '4.15',
}

=example-1 input

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input = $cli->input;

  # {args => undef}

=cut

$test->for('example', 1, 'input', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {args => undef};

  $result
});

=example-2 input

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input = $cli->input;

  # {args => ['arg1', 'arg2']}

=cut

$test->for('example', 2, 'input', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {args => ['arg1', 'arg2']};

  $result
});

=method input_argument_count

The input_argument_count method returns the number of arguments provided to the
CLI.

=signature input_argument_count

  input_argument_count() (number)

=metadata input_argument_count

{
  since => '4.15',
}

=example-1 input_argument_count

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_argument_count = $cli->input_argument_count;

  # 1

=cut

$test->for('example', 1, 'input_argument_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 input_argument_count

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_argument_count = $cli->input_argument_count;

  # 1

=cut

$test->for('example', 2, 'input_argument_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method input_argument_list

The input_argument_list method returns the list of argument names as an
arrayref in scalar context, and as a list in list context.

=signature input_argument_list

  input_argument_list() (arrayref)

=metadata input_argument_list

{
  since => '4.15',
}

=example-1 input_argument_list

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_argument_list = $cli->input_argument_list;

  # ['args']

=cut

$test->for('example', 1, 'input_argument_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['args'];

  $result
});

=example-2 input_argument_list

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my @input_argument_list = $cli->input_argument_list;

  # ('args')

=cut

$test->for('example', 2, 'input_argument_list', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['args'];

  @result
});

=method input_arguments

The input_arguments method returns the list of argument names and values as a
hashref.

=signature input_arguments

  input_arguments() (hashref)

=metadata input_arguments

{
  since => '4.15',
}

=example-1 input_arguments

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments = $cli->input_arguments;

  # {args => []}

=cut

$test->for('example', 1, 'input_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {args => []};

  $result
});

=example-2 input_arguments

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments = $cli->input_arguments;

  # {args => ['arg1', 'arg2']}

=cut

$test->for('example', 2, 'input_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {args => ['arg1', 'arg2']};

  $result
});

=method input_arguments_defined

The input_arguments_defined method returns the list of argument names and
values as a hashref, excluding undefined and empty arrayref values.

=signature input_arguments_defined

  input_arguments_defined() (hashref)

=metadata input_arguments_defined

{
  since => '4.15',
}

=example-1 input_arguments_defined

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments_defined = $cli->input_arguments_defined;

  # {}

=cut

$test->for('example', 1, 'input_arguments_defined', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 input_arguments_defined

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments_defined = $cli->input_arguments_defined;

  # {args => ['arg1', 'arg2']}

=cut

$test->for('example', 2, 'input_arguments_defined', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {args => ['arg1', 'arg2']};

  $result
});

=method input_arguments_defined_count

The input_arguments_defined_count method returns the number of arguments found
using L</input_arguments_defined>.

=signature input_arguments_defined_count

  input_arguments_defined_count() (number)

=metadata input_arguments_defined_count

{
  since => '4.15',
}

=example-1 input_arguments_defined_count

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments_defined_count = $cli->input_arguments_defined_count;

  # 0

=cut

$test->for('example', 1, 'input_arguments_defined_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 input_arguments_defined_count

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments_defined_count = $cli->input_arguments_defined_count;

  # 1

=cut

$test->for('example', 2, 'input_arguments_defined_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method input_arguments_defined_list

The input_arguments_defined_list method returns the list of argument names
found, using L</input_arguments_defined>, as an arrayref in scalar context, and
as a list in list context.

=signature input_arguments_defined_list

  input_arguments_defined_list() (arrayref)

=metadata input_arguments_defined_list

{
  since => '4.15',
}

=example-1 input_arguments_defined_list

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_arguments_defined_list = $cli->input_arguments_defined_list;

  # []

=cut

$test->for('example', 1, 'input_arguments_defined_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 input_arguments_defined_list

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2');

  my $input_arguments_defined_list = $cli->input_arguments_defined_list;

  # ['args']

=cut

$test->for('example', 2, 'input_arguments_defined_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['args'];

  $result
});

=method input_option_count

The input_option_count method returns the number of options provided to the
CLI.

=signature input_option_count

  input_option_count() (number)

=metadata input_option_count

{
  since => '4.15',
}

=example-1 input_option_count

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_option_count = $cli->input_option_count;

  # 2

=cut

$test->for('example', 1, 'input_option_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=example-2 input_option_count

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin');

  my $input_option_count = $cli->input_option_count;

  # 2

=cut

$test->for('example', 2, 'input_option_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=method input_option_list

The input_option_list method returns the list of option names as an arrayref in
scalar context, and as a list in list context.

=signature input_option_list

  input_option_list() (arrayref)

=metadata input_option_list

{
  since => '4.15',
}

=example-1 input_option_list

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_option_list = $cli->input_option_list;

  # ['input', 'output']

=cut

$test->for('example', 1, 'input_option_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply [sort @{$result}], ['input', 'output'];

  $result
});

=example-2 input_option_list

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_option_list = $cli->input_option_list;

  # ['input', 'output']

=cut

$test->for('example', 2, 'input_option_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply [sort @{$result}], ['input', 'output'];

  $result
});

=method input_options

The input_options method returns the list of option names and values as a
hashref.

=signature input_options

  input_options() (hashref)

=metadata input_options

{
  since => '4.15',
}

=example-1 input_options

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options = $cli->input_options;

  # {input => undef, output => undef}

=cut

$test->for('example', 1, 'input_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {input => undef, output => undef};

  $result
});

=example-2 input_options

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options = $cli->input_options;

  # {input => undef, output => undef}

=cut

$test->for('example', 2, 'input_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {input => 'stdin', output => 'stdout'};

  $result
});

=method input_options_defined

The input_options_defined method returns the list of option names and values as
a hashref, excluding undefined and empty arrayref values.

=signature input_options_defined

  input_options_defined() (hashref)

=metadata input_options_defined

{
  since => '4.15',
}

=example-1 input_options_defined

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options_defined = $cli->input_options_defined;

  # {}

=cut

$test->for('example', 1, 'input_options_defined', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 input_options_defined

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options_defined = $cli->input_options_defined;

  # {input => 'stdin', output => 'stdout'}

=cut

$test->for('example', 2, 'input_options_defined', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {input => 'stdin', output => 'stdout'};

  $result
});

=method input_options_defined_count

The input_options_defined_count method returns the number of options found
using L</input_options_defined>.

=signature input_options_defined_count

  input_options_defined_count() (number)

=metadata input_options_defined_count

{
  since => '4.15',
}

=example-1 input_options_defined_count

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options_defined_count = $cli->input_options_defined_count;

  # 0

=cut

$test->for('example', 1, 'input_options_defined_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 input_options_defined_count

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options_defined_count = $cli->input_options_defined_count;

  # 2

=cut

$test->for('example', 2, 'input_options_defined_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=method input_options_defined_list

The input_options_defined_list method returns the list of option names found,
using L</input_options_defined>, as an arrayref in scalar context, and as a
list in list context.

=signature input_options_defined_list

  input_options_defined_list() (arrayref)

=metadata input_options_defined_list

{
  since => '4.15',
}

=example-1 input_options_defined_list

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $input_options_defined_list = $cli->input_options_defined_list;

  # []

=cut

$test->for('example', 1, 'input_options_defined_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 input_options_defined_list

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $input_options_defined_list = $cli->input_options_defined_list;

  # ['input', 'output']

=cut

$test->for('example', 2, 'input_options_defined_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply [sort @{$result}], ['input', 'output'];

  $result
});

=example-3 input_options_defined_list

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--output', 'stdout');

  my $input_options_defined_list = $cli->input_options_defined_list;

  # ['output']

=cut

$test->for('example', 3, 'input_options_defined_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['output'];

  $result
});

=method lines

The lines method takes a string of text, a maximum character length for
each line, and an optional number of spaces to use for indentation
(defaulting to C<0>). It returns the text formatted as a string where each
line wraps at the specified length and is indented with the given number
of spaces. The default lenght is C<80>.

=signature lines

  lines(string $text, number $length, number $indent) (string)

=metadata lines

{
  since => '4.15',
}

=cut

=example-1 lines

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $message = join(' ',
    'This is an example of a long line of text that needs',
    'to be wrapped and formatted.'
  );

  my $string = $cli->lines($message, 40, 2);

  # "  This is an example of a long line of
  #   text that needs to be wrapped and
  #   formatted."

=cut

$test->for('example', 1, 'lines', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  like $result, qr/^  /;
  like $result, qr/.{1,40}/;
  is $result, join "\n",
  "  This is an example of a long line of",
  "  text that needs to be wrapped and",
  "  formatted.";

  $result
});

=method log

The log method returns a L<Venus::Log> object passing L</log_handler> and
L</log_level> to its constructor.

=signature log

  log() (Venus::Log)

=metadata log

{
  since => '4.15',
}

=cut

=example-1 log

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log = $cli->log;

  # bless(..., "Venus::Log")

=cut

$test->for('example', 1, 'log', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  $result
});

=method log_debug

The log_debug method dispatches to the C<debug> method on the object returned
by L</log>.

=signature log_debug

  log_debug(any @args) (Venus::Log)

=metadata log_debug

{
  since => '4.15',
}

=example-1 log_debug

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_debug = $cli->log_debug('Example debug');

  # bless(..., "Venus::Log")

=cut

$test->for('example', 1, 'log_debug', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  my $cli = Venus::Cli->new(name => 'mycli');
  $cli->log_debug('Example debug');
  is_deeply $cli->{logs}, [['debug', 'Example debug']];

  $result
});

=method log_error

The log_error method dispatches to the C<error> method on the object returned
by L</log>.

=signature log_error

  log_error(any @args) (Venus::Log)

=metadata log_error

{
  since => '4.15',
}

=example-1 log_error

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_error = $cli->log_error('Example error');

  # bless(..., "Venus::Log")

=cut

$test->for('example', 1, 'log_error', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  my $cli = Venus::Cli->new(name => 'mycli');
  $cli->log_error('Example error');
  is_deeply $cli->{logs}, [['error', 'Example error']];

  $result
});

=method log_events

The log_events method returns the log messages collected by the default
L</log_handler>.

=signature log_events

  log_events() (arrayref)

=metadata log_events

{
  since => '4.15',
}

=example-1 log_events

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->log_debug('Example debug');

  $cli->log_error('Example error');

  my $log_events = $cli->log_events;

  # [['debug', 'Example debug'], ['debug', 'Example error']]

=cut

$test->for('example', 1, 'log_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['debug', 'Example debug'], ['error', 'Example error']];

  $result
});

=method log_fatal

The log_fatal method dispatches to the C<fatal> method on the object returned
by L</log>.

=signature log_fatal

  log_fatal(any @args) (Venus::Log)

=metadata log_fatal

{
  since => '4.15',
}

=example-1 log_fatal

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_fatal = $cli->log_fatal('Example fatal');

  # bless(..., "Venus::Log")

=cut

$test->for('example', 1, 'log_fatal', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  my $cli = Venus::Cli->new(name => 'mycli');
  $cli->log_fatal('Example fatal');
  is_deeply $cli->{logs}, [['fatal', 'Example fatal']];

  $result
});

=method log_flush

The log_flush method dispatches to the method or callback provided for each
L<"log event"|/log_event>, then purges all log events.

=signature log_flush

  log_flush(string | coderef $code) (Venus::Cli)

=metadata log_flush

{
  since => '4.15',
}

=example-1 log_flush

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->log_debug('Example debug 1');

  $cli->log_debug('Example debug 2');

  my $log_flush = $cli->log_flush(sub{
    push @{$cli->{flushed} ||= []}, $_;
  });

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'log_flush', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa("Venus::Cli");
  is_deeply $result->{flushed}, [
    ['debug', 'Example debug 1'],
    ['debug', 'Example debug 2'],
  ];
  is_deeply $result->{logs}, [];

  $result
});

=example-2 log_flush

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->log_debug('Example debug 1');

  $cli->log_debug('Example debug 2');

  my $log_flush = $cli->log_flush(sub{
    my ($self, $event) = @_;
    push @{$cli->{flushed} ||= []}, $event;
  });

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 2, 'log_flush', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa("Venus::Cli");
  is_deeply $result->{flushed}, [
    ['debug', 'Example debug 1'],
    ['debug', 'Example debug 2'],
  ];
  is_deeply $result->{logs}, [];

  $result
});

=method log_handler

The log_handler method is passed to the L<Venus::Log> constructor in L</log>
and by default handles log events by recording them to be
L<"flushed"|/log_flush> later.

=signature log_handler

  log_handler() (coderef)

=metadata log_handler

{
  since => '4.15',
}

=example-1 log_handler

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_handler = $cli->log_handler;

  # sub{...}

=cut

$test->for('example', 1, 'log_handler', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result, 'CODE';

  $result
});

=method log_info

The log_info method dispatches to the C<info> method on the object returned
by L</log>.

=signature log_info

  log_info(any @args) (Venus::Log)

=metadata log_info

{
  since => '4.15',
}

=example-1 log_info

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_info = $cli->log_info('Example info');

  # bless(..., "Venus::Log")

=cut

$test->for('example', 1, 'log_info', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  my $cli = Venus::Cli->new(name => 'mycli');
  $cli->log_info('Example info');
  is_deeply $cli->{logs}, [['info', 'Example info']];

  $result
});

=method log_level

The log_level method is passed to the L<Venus::Log> constructor in L</log> and
by default specifies a log-level of C<debug>.

=signature log_level

  log_level() (string)

=metadata log_level

{
  since => '4.15',
}

=example-1 log_level

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_level = $cli->log_level;

  # "trace"

=cut

$test->for('example', 1, 'log_level', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "trace";

  $result
});

=method log_trace

The log_trace method dispatches to the C<trace> method on the object returned
by L</log>.

=signature log_trace

  log_trace(any @args) (Venus::Log)

=metadata log_trace

{
  since => '4.15',
}

=example-1 log_trace

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_trace = $cli->log_trace('Example trace');

  # bless(..., "Venus::Log")

=cut

$test->for('example', 1, 'log_trace', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  my $cli = Venus::Cli->new(name => 'mycli');
  $cli->log_trace('Example trace');
  is_deeply $cli->{logs}, [['trace', 'Example trace']];

  $result
});

=method log_warn

The log_warn method dispatches to the C<warn> method on the object returned
by L</log>.

=signature log_warn

  log_warn(any @args) (Venus::Log)

=metadata log_warn

{
  since => '4.15',
}

=example-1 log_warn

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $log_warn = $cli->log_warn('Example warn');

  # bless(..., "Venus::Log")

=cut

$test->for('example', 1, 'log_warn', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Log');

  my $cli = Venus::Cli->new(name => 'mycli');
  $cli->log_warn('Example warn');
  is_deeply $cli->{logs}, [['warn', 'Example warn']];

  $result
});

=method multiple

The multiple method is a configuration dispatcher and shorthand for
C<{'multiples', true}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

=signature multiple

  multiple(string $method, any @args) (any)

=metadata multiple

{
  since => '4.15',
}

=cut

=example-1 multiple

  # given: synopsis

  package main;

  my $multiple = $cli->multiple;

  # {multiples => true}

=cut

$test->for('example', 1, 'multiple', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {multiples => true};

  $result
});

=example-2 multiple

  # given: synopsis

  package main;

  my $multiple = $cli->multiple(undef, {required => true});

  # {multiples => true, required => true}

=cut

$test->for('example', 2, 'multiple', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {multiples => true, required => true};

  $result
});

=example-3 multiple

  # given: synopsis

  package main;

  my $multiple = $cli->multiple('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 1,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 3, 'multiple', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a string value',
    default => undef,
    aliases => [],
    multiples => 1,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Cli)

=metadata new

{
  since => '4.15',
}

=example-1 new

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new('mycli');

  # bless(..., "Venus::Cli")

  # $cli->name;

  # "mycli"

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is $result->name, 'mycli';

  $result
});

=example-2 new

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  # bless(..., "Venus::Cli")

  # $cli->name;

  # "mycli"

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is $result->name, 'mycli';

  $result
});

=method no_input

The no_input method returns true if no arguments or options are provided to the
CLI, and false otherwise.

=signature no_input

  no_input() (boolean)

=metadata no_input

{
  since => '4.15',
}

=example-1 no_input

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $no_input = $cli->no_input;

  # true

=cut

$test->for('example', 1, 'no_input', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_input

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $no_input = $cli->no_input;

  # false

=cut

$test->for('example', 2, 'no_input', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_input_arguments

The no_input_arguments method returns true if no arguments are provided to the
CLI, and false otherwise.

=signature no_input_arguments

  no_input_arguments() (boolean)

=metadata no_input_arguments

{
  since => '4.15',
}

=example-1 no_input_arguments

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $no_input_arguments = $cli->no_input_arguments;

  # true

=cut

$test->for('example', 1, 'no_input_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_input_arguments

  # given: synopsis

  package main;

  $cli->argument('args', {
    range => '0:',
    multiples => 1,
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('arg1', 'arg2', '--output', 'stdout');

  my $no_input_arguments = $cli->no_input_arguments;

  # false

=cut

$test->for('example', 2, 'no_input_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_input_options

The no_input_options method returns true if no options are provided to the CLI,
and false otherwise.

=signature no_input_options

  no_input_options() (boolean)

=metadata no_input_options

{
  since => '4.15',
}

=example-1 no_input_options

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $no_input_options = $cli->no_input_options;

  # true

=cut

$test->for('example', 1, 'no_input_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_input_options

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin');

  my $no_input_options = $cli->no_input_options;

  # false

=cut

$test->for('example', 2, 'no_input_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_output

The no_output method returns true if no output events are found, and false
otherwise.

=signature no_output

  no_output() (boolean)

=metadata no_output

{
  since => '4.15',
}

=example-1 no_output

  # given: synopsis

  package main;

  my $no_output = $cli->no_output;

  # true

=cut

$test->for('example', 1, 'no_output', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_output

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output = $cli->no_output;

  # false

=cut

$test->for('example', 2, 'no_output', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_output_debug_events

The no_output_debug_events method returns true if no debug output events are
found, and false otherwise.

=signature no_output_debug_events

  no_output_debug_events() (boolean)

=metadata no_output_debug_events

{
  since => '4.15',
}

=example-1 no_output_debug_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_debug_events = $cli->no_output_debug_events;

  # true

=cut

$test->for('example', 1, 'no_output_debug_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_output_debug_events

  # given: synopsis

  package main;

  $cli->log_debug('example output');

  my $no_output_debug_events = $cli->no_output_debug_events;

  # false

=cut

$test->for('example', 2, 'no_output_debug_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_output_error_events

The no_output_error_events method returns true if no error output events are
found, and false otherwise.

=signature no_output_error_events

  no_output_error_events() (boolean)

=metadata no_output_error_events

{
  since => '4.15',
}

=example-1 no_output_error_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_error_events = $cli->no_output_error_events;

  # true

=cut

$test->for('example', 1, 'no_output_error_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_output_error_events

  # given: synopsis

  package main;

  $cli->log_error('example output');

  my $no_output_error_events = $cli->no_output_error_events;

  # false

=cut

$test->for('example', 2, 'no_output_error_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_output_fatal_events

The no_output_fatal_events method returns true if no fatal output events are
found, and false otherwise.

=signature no_output_fatal_events

  no_output_fatal_events() (boolean)

=metadata no_output_fatal_events

{
  since => '4.15',
}

=example-1 no_output_fatal_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_fatal_events = $cli->no_output_fatal_events;

  # true

=cut

$test->for('example', 1, 'no_output_fatal_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_output_fatal_events

  # given: synopsis

  package main;

  $cli->log_fatal('example output');

  my $no_output_fatal_events = $cli->no_output_fatal_events;

  # false

=cut

$test->for('example', 2, 'no_output_fatal_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_output_info_events

The no_output_info_events method returns true if no info output events are
found, and false otherwise.

=signature no_output_info_events

  no_output_info_events() (boolean)

=metadata no_output_info_events

{
  since => '4.15',
}

=example-1 no_output_info_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_info_events = $cli->no_output_info_events;

  # false

=cut

$test->for('example', 1, 'no_output_info_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 no_output_info_events

  # given: synopsis

  package main;

  $cli->log_error('example output');

  my $no_output_info_events = $cli->no_output_info_events;

  # true

=cut

$test->for('example', 2, 'no_output_info_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method no_output_trace_events

The no_output_trace_events method returns true if no trace output events are
found, and false otherwise.

=signature no_output_trace_events

  no_output_trace_events() (boolean)

=metadata no_output_trace_events

{
  since => '4.15',
}

=example-1 no_output_trace_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_trace_events = $cli->no_output_trace_events;

  # true

=cut

$test->for('example', 1, 'no_output_trace_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_output_trace_events

  # given: synopsis

  package main;

  $cli->log_trace('example output');

  my $no_output_trace_events = $cli->no_output_trace_events;

  # false

=cut

$test->for('example', 2, 'no_output_trace_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method no_output_warn_events

The no_output_warn_events method returns true if no warn output events are
found, and false otherwise.

=signature no_output_warn_events

  no_output_warn_events() (boolean)

=metadata no_output_warn_events

{
  since => '4.15',
}

=example-1 no_output_warn_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $no_output_warn_events = $cli->no_output_warn_events;

  # true

=cut

$test->for('example', 1, 'no_output_warn_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=example-2 no_output_warn_events

  # given: synopsis

  package main;

  $cli->log_warn('example output');

  my $no_output_warn_events = $cli->no_output_warn_events;

  # false

=cut

$test->for('example', 2, 'no_output_warn_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=method number

The number method is a configuration dispatcher and shorthand for C<{'type',
'number'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

=signature number

  number(string $method, any @args) (any)

=metadata number

{
  since => '4.15',
}

=cut

=example-1 number

  # given: synopsis

  package main;

  my $number = $cli->number;

  # {type => 'number'}

=cut

$test->for('example', 1, 'number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'number'};

  $result
});

=example-2 number

  # given: synopsis

  package main;

  my $number = $cli->number(undef, {required => true});

  # {type => 'number', required => true}

=cut

$test->for('example', 2, 'number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'number', required => true};

  $result
});

=example-3 number

  # given: synopsis

  package main;

  my $number = $cli->number('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a number value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'number',
  #   index => 0,
  #   wants => 'number',
  # }

=cut

$test->for('example', 3, 'number', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a number value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'number',
    index => 0,
    wants => 'number',
  };

  $result
});

=method okay

The okay method terminates the program with a the exit code C<0>,
indicating a successful exit. This method can be used to end the program
explicitly, either after a specific task is completed or when an error
occurs that requires halting execution. This method can dispatch to
another method or callback before exiting.

=signature okay

  okay(string | coderef $code, any @args) (any)

=metadata okay

{
  since => '4.15',
}

=cut

=example-1 okay

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->okay;

  # 0

=cut

$test->for('example', 1, 'okay', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 0;

  $space->unpatch;

  !$result
});

=example-2 okay

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->okay(sub{
    $cli->{dispatched} = 1;
  });

  # 0

=cut

$test->for('example', 2, 'okay', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 0;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->okay(sub{
    $cli->{dispatched} = 1;
  });

  is $cli->{dispatched}, 1;

  $space->unpatch;

  !$result
});

=method option

The option method registers and returns the configuration for the option
specified. The method takes a name (option name) and a hashref of
configuration values. The possible configuration values are as follows:

+=over 4

+=item *

The C<name> key holds the name of the option.

+=item *

The C<label> key holds the name of the option as it should be displayed in
the CLI help text.

+=item *

The C<help> key holds the help text specific to this option.

+=item *

The C<default> key holds the default value that should used if no value for
this option is provided to the CLI.

+=item *

The C<aliases> (or C<alias>) key holds the arrayref of aliases that can be
provided to the CLI to specify a value (or values) for this option.

+=item *

The C<multiples> key denotes whether this option can be used more than once,
to collect multiple values, and holds a C<1> if multiples are allowed and a C<0>
otherwise.

+=item *

The C<prompt> key holds the question or statement that should be presented to
the user of the CLI if no value has been provided for this option and no
default value has been set.

+=item *

The C<range> key holds a two-value arrayref where the first value is the
starting index and the second value is the ending index. These values are used
to select values from the parsed arguments array as the value(s) for this
argument. This value is ignored if the C<multiples> key is set to C<0>.

+=item *

The C<required> key denotes whether this option is required or not, and holds
a C<1> if required and a C<0> otherwise.

+=item *

The C<type> key holds the data type of the option expected. Valid values are
"number", "string", "float", "boolean", or "yesno". B<Note:> Valid boolean
values are C<1>, C<0>, C<"true">, and C<"false">.

+=item *

The C<wants> key holds the text to be used as a value being assigned to the
option in the usage text. This value defaults to the type specified, or
C<"string">.

+=back

=signature option

  option(string $name, hashref $data) (maybe[hashref])

=metadata option

{
  since => '4.15',
}

=cut

=example-1 option

  # given: synopsis

  package main;

  my $option = $cli->option('name', {
    label => 'Name',
    help => 'The name of the user',
    default => 'Unknown',
    required => 1,
    type => 'string'
  });

  # {
  #   name => 'name',
  #   label => 'Name',
  #   help => 'The name of the user',
  #   default => 'Unknown',
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 1, 'option', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'name',
    label => 'Name',
    help => 'The name of the user',
    default => 'Unknown',
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 1,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method option_aliases

The option_aliases method returns the C<aliases> configuration value for the
named option.

=signature option_aliases

  option_aliases(string $name) (arrayref)

=metadata option_aliases

{
  since => '4.15',
}

=example-1 option_aliases

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_aliases = $cli->option_aliases;

  # []

=cut

$test->for('example', 1, 'option_aliases', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 option_aliases

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    alias => 'i',
    type => 'string',
  });

  my $option_aliases = $cli->option_aliases('input');

  # ['i']

=cut

$test->for('example', 2, 'option_aliases', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['i'];

  $result
});

=example-3 option_aliases

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    aliases => 'i',
    type => 'string',
  });

  my $option_aliases = $cli->option_aliases('input');

  # ['i']

=cut

$test->for('example', 3, 'option_aliases', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['i'];

  $result
});

=example-4 option_aliases

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    aliases => ['i'],
    type => 'string',
  });

  my $option_aliases = $cli->option_aliases('input');

  # ['i']

=cut

$test->for('example', 4, 'option_aliases', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['i'];

  $result
});

=method option_count

The option_count method returns the count of registered options.

=signature option_count

  option_count() (number)

=metadata option_count

{
  since => '4.15',
}

=example-1 option_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_count = $cli->option_count;

  # 0

=cut

$test->for('example', 1, 'option_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 option_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $option_count = $cli->option_count;

  # 2

=cut

$test->for('example', 2, 'option_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=method option_default

The option_default method returns the C<default> configuration value for the
named option.

=signature option_default

  option_default(string $name) (string)

=metadata option_default

{
  since => '4.15',
}

=example-1 option_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_default = $cli->option_default;

  # ""

=cut

$test->for('example', 1, 'option_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => 'stdin',
  });

  my $option_default = $cli->option_default('input');

  # "stdin"

=cut

$test->for('example', 2, 'option_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'stdin';

  $result
});

=method option_errors

The option_errors method returns a list of L<"issues"|Venus::Validate/issue>,
if any, for each value returned by L</option_value> for the named option.
Returns a list in list context.

=signature option_errors

  option_errors(string $name) (within[arrayref, Venus::Validate])

=metadata option_errors

{
  since => '4.15',
}

=example-1 option_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_errors = $cli->option_errors;

  # []

=cut

$test->for('example', 1, 'option_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 option_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->parse('--input hello');

  my $option_errors = $cli->option_errors('input');

  # []

=cut

$test->for('example', 2, 'option_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-3 option_errors

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => 'hello',
    type => 'number',
  });

  $cli->parse('--input hello');

  my $option_errors = $cli->option_errors('input');

  # [['type', ['number']]]

=cut

$test->for('example', 3, 'option_errors', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [['type', ['number']]];

  $result
});

=method option_help

The option_help method returns the C<help> configuration value for the named
option.

=signature option_help

  option_help(string $name) (string)

=metadata option_help

{
  since => '4.15',
}

=example-1 option_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_help = $cli->option_help;

  # ""

=cut

$test->for('example', 1, 'option_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    help => 'Example help text',
  });

  my $option_help = $cli->option_help('input');

  # "Example help text"

=cut

$test->for('example', 2, 'option_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example help text";

  $result
});

=method option_label

The option_label method returns the C<label> configuration value for the
named option.

=signature option_label

  option_label(string $name) (string)

=metadata option_label

{
  since => '4.15',
}

=example-1 option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_label = $cli->option_label;

  # ""

=cut

$test->for('example', 1, 'option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    label => 'Input',
  });

  my $option_label = $cli->option_label('input');

  # "Input"

=cut

$test->for('example', 2, 'option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Input";

  $result
});

=method option_list

The option_list method returns a list of registered option configurations.
Returns a list in list context.

=signature option_list

  option_list(string $name) (within[arrayref, hashref])

=metadata option_list

{
  since => '4.15',
}

=example-1 option_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_list = $cli->option_list;

  # []

=cut

$test->for('example', 1, 'option_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 option_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  my $option_list = $cli->option_list;

  # [{
  #   name => 'input',
  #   label => undef,
  #   help => 'Expects a string value',
  #   aliases => [],
  #   default => undef,
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => false,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }]

=cut

$test->for('example', 2, 'option_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [{
    name => 'input',
    label => undef,
    help => 'Expects a string value',
    aliases => [],
    default => undef,
    multiples => 0,
    prompt => undef,
    range => undef,
    required => false,
    type => 'string',
    index => 0,
    wants => 'string',
  }];

  $result
});

=method option_multiples

The option_multiples method returns the C<multiples> configuration value for
the named option.

=signature option_multiples

  option_multiples(string $name) (boolean)

=metadata option_multiples

{
  since => '4.15',
}

=example-1 option_multiples

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_multiples = $cli->option_multiples;

  # false

=cut

$test->for('example', 1, 'option_multiples', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 option_multiples

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
  });

  my $option_multiples = $cli->option_multiples('input');

  # true

=cut

$test->for('example', 2, 'option_multiples', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method option_name

The option_name method returns the C<name> configuration value for the named
option.

=signature option_name

  option_name(string $name) (string)

=metadata option_name

{
  since => '4.15',
}

=example-1 option_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_name = $cli->option_name;

  # ""

=cut

$test->for('example', 1, 'option_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    name => 'INPUT',
  });

  my $option_name = $cli->option_name('input');

  # ""

=cut

$test->for('example', 2, 'option_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-3 option_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    name => 'INPUT',
  });

  my $option_name = $cli->option_name('INPUT');

  # "INPUT"

=cut

$test->for('example', 3, 'option_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "INPUT";

  $result
});

=method option_names

The option_names method returns the names (keys) of registered options in
the order declared. Returns a list in list context.

=signature option_names

  option_names(string $name) (within[arrayref, string])

=metadata option_names

{
  since => '4.15',
}

=example-1 option_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_names = $cli->option_names;

  # []

=cut

$test->for('example', 1, 'option_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 option_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $option_names = $cli->option_names;

  # ['input', 'output']

=cut

$test->for('example', 2, 'option_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['input', 'output'];

  $result
});

=example-3 option_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('output', {
    type => 'string',
  });

  $cli->option('input', {
    type => 'string',
  });

  my $option_names = $cli->option_names;

  # ['output', 'input']

=cut

$test->for('example', 3, 'option_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['output', 'input'];

  $result
});

=method option_prompt

The option_prompt method returns the C<prompt> configuration value for the
named option.

=signature option_prompt

  option_prompt(string $name) (string)

=metadata option_prompt

{
  since => '4.15',
}

=example-1 option_prompt

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_prompt = $cli->option_prompt;

  # ""

=cut

$test->for('example', 1, 'option_prompt', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_prompt

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    prompt => 'Example prompt',
  });

  my $option_prompt = $cli->option_prompt('input');

  # "Example prompt"

=cut

$test->for('example', 2, 'option_prompt', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example prompt";

  $result
});

=method option_range

The option_range method returns the C<range> configuration value for the
named option.

=signature option_range

  option_range(string $name) (string)

=metadata option_range

{
  since => '4.15',
}

=example-1 option_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_range = $cli->option_range;

  # ""

=cut

$test->for('example', 1, 'option_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    range => '0',
  });

  my $option_range = $cli->option_range('input');

  # "0"

=cut

$test->for('example', 2, 'option_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "0";

  !$result
});

=example-3 option_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    range => '0:5',
  });

  my $option_range = $cli->option_range('input');

  # "0:5"

=cut

$test->for('example', 3, 'option_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "0:5";

  $result
});

=method option_required

The option_required method returns the C<required> configuration value for
the named option.

=signature option_required

  option_required(string $name) (boolean)

=metadata option_required

{
  since => '4.15',
}

=example-1 option_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_required = $cli->option_required;

  # false

=cut

$test->for('example', 1, 'option_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  !$result
});

=example-2 option_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $option_required = $cli->option_required('input');

  # true

=cut

$test->for('example', 2, 'option_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, true;

  $result
});

=method option_type

The option_type method returns the C<type> configuration value for the named
option. Valid values are as follows:

+=over 4

+=item *

C<number>

+=item *

C<string>

+=item *

C<float>

+=item *

C<boolean> - B<Note:> Valid boolean values are C<1>, C<0>, C<"true">, and C<"false">.

+=item *

C<yesno>

+=back

=signature option_type

  option_type(string $name) (string)

=metadata option_type

{
  since => '4.15',
}

=example-1 option_type

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_type = $cli->option_type;

  # ""

=cut

$test->for('example', 1, 'option_type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_type

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'boolean',
  });

  my $option_type = $cli->option_type('input');

  # "boolean"

=cut

$test->for('example', 2, 'option_type', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "boolean";

  $result
});

=method option_validate

The option_validate method returns a L<Venus::Validate> object for each value
returned by L</option_value> for the named option. Returns a list in list
context.

=signature option_validate

  option_validate(string $name) (Venus::Validate | within[arrayref, Venus::Validate])

=metadata option_validate

{
  since => '4.15',
}

=example-1 option_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_validate = $cli->option_validate;

  # []

=cut

$test->for('example', 1, 'option_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 option_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  my $option_validate = $cli->option_validate('input');

  # [bless(..., "Venus::Validate")]

=cut

$test->for('example', 2, 'option_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 1;
  ok $result->[0]->isa('Venus::Validate');

  $result
});

=example-3 option_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => false,
    type => 'string',
  });

  my $option_validate = $cli->option_validate('input');

  # bless(..., "Venus::Validate")

=cut

$test->for('example', 3, 'option_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Validate');

  $result
});

=example-4 option_validate

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->parse('--input', 'hello', '--input', 'world');

  my $option_validate = $cli->option_validate('input');

  # [bless(..., "Venus::Validate"), bless(..., "Venus::Validate")]

=cut

$test->for('example', 4, 'option_validate', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;
  ok @{$result} == 2;
  ok $result->[0]->isa('Venus::Validate');
  ok $result->[1]->isa('Venus::Validate');

  $result
});

=method option_value

The option_value method returns the parsed option value for the named
option.

=signature option_value

  option_value(string $name) (any)

=metadata option_value

{
  since => '4.15',
}

=example-1 option_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_value = $cli->option_value;

  # undef

=cut

$test->for('example', 1, 'option_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 option_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => false,
    type => 'string',
  });

  $cli->parse('--input', 'hello', '--input', 'world');

  my $option_value = $cli->option_value('input');

  # "world"

=cut

$test->for('example', 2, 'option_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "world";

  $result
});

=example-3 option_value

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->parse('--input', 'hello', '--input', 'world');

  my $option_value = $cli->option_value('input');

  # ["hello", "world"]

=cut

$test->for('example', 3, 'option_value', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ["hello", "world"];

  $result
});

=method option_wants

The option_wants method returns the C<wants> configuration value for the
named option.

=signature option_wants

  option_wants(string $name) (string)

=metadata option_wants

{
  since => '4.15',
}

=example-1 option_wants

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $option_wants = $cli->option_wants;

  # ""

=cut

$test->for('example', 1, 'option_wants', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 option_wants

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    wants => 'string',
  });

  my $option_wants = $cli->option_wants('input');

  # "string"

=cut

$test->for('example', 2, 'option_wants', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "string";

  $result
});

=method optional

The optional method is a configuration dispatcher and shorthand for
C<{'required', false}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

=signature optional

  optional(string $method, any @args) (any)

=metadata optional

{
  since => '4.15',
}

=cut

=example-1 optional

  # given: synopsis

  package main;

  my $optional = $cli->optional;

  # {required => false}

=cut

$test->for('example', 1, 'optional', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {required => false};

  $result
});

=example-2 optional

  # given: synopsis

  package main;

  my $optional = $cli->optional(undef, {type => 'boolean'});

  # {required => false, type => 'boolean'}

=cut

$test->for('example', 2, 'optional', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {required => false, type => 'boolean'};

  $result
});

=example-3 optional

  # given: synopsis

  package main;

  my $optional = $cli->optional('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 0,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 3, 'optional', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a string value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method opts

The opts method returns the list of parsed command-line options as a
L<Venus::Opts> object.

=signature opts

  opts() (Venus::Opts)

=metadata opts

{
  since => '4.15',
}

=example-1 opts

  # given: synopsis

  package main;

  my $opts = $cli->opts;

  # bless(..., "Venus::Opts")

=cut

$test->for('example', 1, 'opts', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Opts');

  $result
});

=example-2 opts

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->parse('--input', 'hello world');

  my $opts = $cli->opts;

  # bless(..., "Venus::Opts")

  # $opts->input;

=cut

$test->for('example', 2, 'opts', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Opts');
  is $result->input, 'hello world';

  $result
});

=method output

The output method returns the list of output events as an arrayref in scalar
context, and a list in list context. The method optionally takes a log-level
and if provided will only return output events for that log-level.

=signature output

  output(string $level) (any)

=metadata output

{
  since => '4.15',
}

=example-1 output

  # given: synopsis

  package main;

  my $output = $cli->output;

  # undef

=cut

$test->for('example', 1, 'output', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, undef;

  !$result
});

=example-2 output

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output = $cli->output;

  # "example output"

=cut

$test->for('example', 2, 'output', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'example output';

  $result
});

=example-3 output

  # given: synopsis

  package main;

  $cli->log_info('example output 1');

  $cli->log_info('example output 2');

  my @output = $cli->output;

  # ('example output 1', 'example output 2')

=cut

$test->for('example', 3, 'output', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['example output 1', 'example output 2'];

  @result
});

=method output_debug_events

The output_debug_events method returns the list of debug output events as an
arrayref in scalar context, and a list in list context.

=signature output_debug_events

  output_debug_events() (arrayref)

=metadata output_debug_events

{
  since => '4.15',
}

=example-1 output_debug_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_debug_events = $cli->output_debug_events;

  # []

=cut

$test->for('example', 1, 'output_debug_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 output_debug_events

  # given: synopsis

  package main;

  $cli->log_debug('example output');

  my $output_debug_events = $cli->output_debug_events;

  # ['example output']

=cut

$test->for('example', 2, 'output_debug_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output'];

  $result
});

=example-3 output_debug_events

  # given: synopsis

  package main;

  $cli->log_debug('example output 1');

  $cli->log_debug('example output 2');

  my $output_debug_events = $cli->output_debug_events;

  # ['example output 1', 'example output 2']

=cut

$test->for('example', 3, 'output_debug_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output 1', 'example output 2'];

  $result
});

=example-4 output_debug_events

  # given: synopsis

  package main;

  $cli->log_debug('example output 1');

  $cli->log_debug('example output 2');

  my @output_debug_events = $cli->output_debug_events;

  # ('example output 1', 'example output 2')

=cut

$test->for('example', 4, 'output_debug_events', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['example output 1', 'example output 2'];

  @result
});

=method output_error_events

The output_error_events method returns the list of error output events as an
arrayref in scalar context, and a list in list context.

=signature output_error_events

  output_error_events() (arrayref)

=metadata output_error_events

{
  since => '4.15',
}

=example-1 output_error_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_error_events = $cli->output_error_events;

  # []

=cut

$test->for('example', 1, 'output_error_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 output_error_events

  # given: synopsis

  package main;

  $cli->log_error('example output');

  my $output_error_events = $cli->output_error_events;

  # ['example output']

=cut

$test->for('example', 2, 'output_error_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output'];

  $result
});

=example-3 output_error_events

  # given: synopsis

  package main;

  $cli->log_error('example output 1');

  $cli->log_error('example output 2');

  my $output_error_events = $cli->output_error_events;

  # ['example output 1', 'example output 2']

=cut

$test->for('example', 3, 'output_error_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output 1', 'example output 2'];

  $result
});

=example-4 output_error_events

  # given: synopsis

  package main;

  $cli->log_error('example output 1');

  $cli->log_error('example output 2');

  my @output_error_events = $cli->output_error_events;

  # ('example output 1', 'example output 2')

=cut

$test->for('example', 4, 'output_error_events', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['example output 1', 'example output 2'];

  @result
});

=method output_fatal_events

The output_fatal_events method returns the list of fatal output events as an
arrayref in scalar context, and a list in list context.

=signature output_fatal_events

  output_fatal_events() (arrayref)

=metadata output_fatal_events

{
  since => '4.15',
}

=example-1 output_fatal_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_fatal_events = $cli->output_fatal_events;

  # []

=cut

$test->for('example', 1, 'output_fatal_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 output_fatal_events

  # given: synopsis

  package main;

  $cli->log_fatal('example output');

  my $output_fatal_events = $cli->output_fatal_events;

  # ['example output']

=cut

$test->for('example', 2, 'output_fatal_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output'];

  $result
});

=example-3 output_fatal_events

  # given: synopsis

  package main;

  $cli->log_fatal('example output 1');

  $cli->log_fatal('example output 2');

  my $output_fatal_events = $cli->output_fatal_events;

  # ['example output 1', 'example output 2']

=cut

$test->for('example', 3, 'output_fatal_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output 1', 'example output 2'];

  $result
});

=example-4 output_fatal_events

  # given: synopsis

  package main;

  $cli->log_fatal('example output 1');

  $cli->log_fatal('example output 2');

  my @output_fatal_events = $cli->output_fatal_events;

  # ('example output 1', 'example output 2')

=cut

$test->for('example', 4, 'output_fatal_events', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['example output 1', 'example output 2'];

  @result
});

=method output_info_events

The output_info_events method returns the list of info output events as an
arrayref in scalar context, and a list in list context.

=signature output_info_events

  output_info_events() (arrayref)

=metadata output_info_events

{
  since => '4.15',
}

=example-1 output_info_events

  # given: synopsis

  package main;

  $cli->log_warn('example output');

  my $output_info_events = $cli->output_info_events;

  # []

=cut

$test->for('example', 1, 'output_info_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 output_info_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_info_events = $cli->output_info_events;

  # ['example output']

=cut

$test->for('example', 2, 'output_info_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output'];

  $result
});

=example-3 output_info_events

  # given: synopsis

  package main;

  $cli->log_info('example output 1');

  $cli->log_info('example output 2');

  my $output_info_events = $cli->output_info_events;

  # ['example output 1', 'example output 2']

=cut

$test->for('example', 3, 'output_info_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output 1', 'example output 2'];

  $result
});

=example-4 output_info_events

  # given: synopsis

  package main;

  $cli->log_info('example output 1');

  $cli->log_info('example output 2');

  my @output_info_events = $cli->output_info_events;

  # ('example output 1', 'example output 2')

=cut

$test->for('example', 4, 'output_info_events', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['example output 1', 'example output 2'];

  @result
});

=method output_trace_events

The output_trace_events method returns the list of trace output events as an
arrayref in scalar context, and a list in list context.

=signature output_trace_events

  output_trace_events() (arrayref)

=metadata output_trace_events

{
  since => '4.15',
}

=example-1 output_trace_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_trace_events = $cli->output_trace_events;

  # []

=cut

$test->for('example', 1, 'output_trace_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 output_trace_events

  # given: synopsis

  package main;

  $cli->log_trace('example output');

  my $output_trace_events = $cli->output_trace_events;

  # ['example output']

=cut

$test->for('example', 2, 'output_trace_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output'];

  $result
});

=example-3 output_trace_events

  # given: synopsis

  package main;

  $cli->log_trace('example output 1');

  $cli->log_trace('example output 2');

  my $output_trace_events = $cli->output_trace_events;

  # ['example output 1', 'example output 2']

=cut

$test->for('example', 3, 'output_trace_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output 1', 'example output 2'];

  $result
});

=example-4 output_trace_events

  # given: synopsis

  package main;

  $cli->log_trace('example output 1');

  $cli->log_trace('example output 2');

  my @output_trace_events = $cli->output_trace_events;

  # ('example output 1', 'example output 2')

=cut

$test->for('example', 4, 'output_trace_events', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['example output 1', 'example output 2'];

  @result
});

=method output_warn_events

The output_warn_events method returns the list of warn output events as an
arrayref in scalar context, and a list in list context.

=signature output_warn_events

  output_warn_events() (arrayref)

=metadata output_warn_events

{
  since => '4.15',
}

=example-1 output_warn_events

  # given: synopsis

  package main;

  $cli->log_info('example output');

  my $output_warn_events = $cli->output_warn_events;

  # []

=cut

$test->for('example', 1, 'output_warn_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=example-2 output_warn_events

  # given: synopsis

  package main;

  $cli->log_warn('example output');

  my $output_warn_events = $cli->output_warn_events;

  # ['example output']

=cut

$test->for('example', 2, 'output_warn_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output'];

  $result
});

=example-3 output_warn_events

  # given: synopsis

  package main;

  $cli->log_warn('example output 1');

  $cli->log_warn('example output 2');

  my $output_warn_events = $cli->output_warn_events;

  # ['example output 1', 'example output 2']

=cut

$test->for('example', 3, 'output_warn_events', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['example output 1', 'example output 2'];

  $result
});

=example-4 output_warn_events

  # given: synopsis

  package main;

  $cli->log_warn('example output 1');

  $cli->log_warn('example output 2');

  my @output_warn_events = $cli->output_warn_events;

  # ('example output 1', 'example output 2')

=cut

$test->for('example', 4, 'output_warn_events', sub {
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ['example output 1', 'example output 2'];

  @result
});

=method parse

The parse method accepts arbitrary input (typically strings or arrayrefs of
strings) and parses out the arguments and options made available via
L</parsed_arguments> and L</parsed_options> respectively. If no arguments are
provided C<@ARGV> is used as a default.

=signature parse

  parse(any @args) (Venus::Cli)

=metadata parse

{
  since => '4.15',
}

=example-1 parse

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $parse = $cli->parse;

  # bless(..., "Venus::Cli")

  # $cli->parsed_arguments

  # []

  # $result->parsed_options

  # {}

=cut

$test->for('example', 1, 'parse', sub {
  my ($tryable) = @_;
  local @ARGV = ('hello', 'world');
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply $result->parsed_arguments, ['hello', 'world'];
  is_deeply $result->parsed_options, {};

  $result
});

=example-2 parse

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $parse = $cli->parse('hello', 'world');

  # bless(..., "Venus::Cli")

  # $cli->parsed_arguments

  # ['hello', 'world']

  # $result->parsed_options

  # {}

=cut

$test->for('example', 2, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply $result->parsed_arguments, ['hello', 'world'];
  is_deeply $result->parsed_options, {};

  $result
});

=example-3 parse

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  my $parse = $cli->parse('--input', 'stdin', '--output', 'stdout', 'hello', 'world');

  # bless(..., "Venus::Cli")

  # $cli->parsed_arguments

  # ['hello', 'world']

  # $result->parsed_options

  # {input => 'stdin', output => 'stdout'}

=cut

$test->for('example', 3, 'parse', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply $result->parsed_arguments, ['hello', 'world'];
  is_deeply $result->parsed_options, {input => 'stdin', output => 'stdout'};

  $result
});

=method parsed

The parsed method is shorthand for calling the L</parsed_arguments> and/or
L</parsed_options> method directly. In scalar context this method returns
L</parsed_options>. In list context returns L</parsed_options> and
L</parsed_arguments> in that order.

=signature parsed

  parsed() (arrayref | hashref)

=metadata parsed

{
  since => '4.15',
}

=example-1 parsed

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $parsed = $cli->parsed;

  # {}

=cut

$test->for('example', 1, 'parsed', sub {
  my ($tryable) = @_;
  local @ARGV = ('hello', 'world');
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 parsed

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->parse('hello world');

  my $parsed = $cli->parsed;

  # {}

=cut

$test->for('example', 2, 'parsed', sub {
  my ($tryable) = @_;
  local @ARGV = ('hello', 'world');
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-3 parsed

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->parse('hello', 'world');

  my ($options, $arguments) = $cli->parsed;

  # ({}, ['hello', 'world'])

=cut

$test->for('example', 3, 'parsed', sub {
  my ($tryable) = @_;
  local @ARGV = ('hello', 'world');
  my $result = [$tryable->result];
  is_deeply $result, [{}, ['hello', 'world']];

  $result
});

=example-4 parsed

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  my $parse = $cli->parse('--input', 'stdin', '--output', 'stdout', 'hello world');

  my $parsed = $cli->parsed;

  # {input => 'stdin', output => 'stdout'}

=cut

$test->for('example', 4, 'parsed', sub {
  my ($tryable) = @_;
  local @ARGV = ('hello', 'world');
  my $result = $tryable->result;
  is_deeply $result, {input => 'stdin', output => 'stdout'};

  $result
});

=example-5 parsed

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  my $parse = $cli->parse('--input', 'stdin', '--output', 'stdout', 'hello', 'world');

  my ($options, $arguments) = $cli->parsed;

  # ({input => 'stdin', output => 'stdout'}, ['hello', 'world'])

=cut

$test->for('example', 5, 'parsed', sub {
  my ($tryable) = @_;
  local @ARGV = ('hello', 'world');
  my $result = [$tryable->result];
  is_deeply $result, [{input => 'stdin', output => 'stdout'}, ['hello', 'world']];

  $result
});

=method parsed_arguments

The parsed_arguments method gets or sets the set of parsed arguments. This
method calls L</parse> if no data has been set.

=signature parsed_arguments

  parsed_arguments(arrayref $data) (arrayref)

=metadata parsed_arguments

{
  since => '4.15',
}

=example-1 parsed_arguments

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $parsed_arguments = $cli->parsed_arguments;

  # ['hello', 'world']

=cut

$test->for('example', 1, 'parsed_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ['hello', 'world'];

  $result
});

=method parsed_options

The parsed_options method method gets or sets the set of parsed options. This
method calls L</parse> if no data has been set.

=signature parsed_options

  parsed_options(hashref $data) (hashref)

=metadata parsed_options

{
  since => '4.15',
}

=example-1 parsed_options

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('extra', {
    range => '0:',
    type => 'string',
  });

  local @ARGV = qw(--input stdin --output stdout hello world);

  my $parsed_options = $cli->parsed_options;

  # {input => 'stdin', output => 'stdout'}

=cut

$test->for('example', 1, 'parsed_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {input => 'stdin', output => 'stdout'};

  $result
});

=method pass

The pass method terminates the program with a the exit code C<0>, indicating a
successful exit. This method can be used to end the program explicitly, either
after a specific task is completed or when an error occurs that requires
halting execution. This method can dispatch to another method or callback
before exiting.

=signature pass

  pass(string | coderef $code, any @args) (any)

=metadata pass

{
  since => '4.15',
}

=cut

=example-1 pass

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->pass;

  # 0

=cut

$test->for('example', 1, 'pass', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 0;

  $space->unpatch;

  !$result
});

=example-2 pass

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->pass(sub{
    $cli->{dispatched} = 1;
  });

  # 0

=cut

$test->for('example', 2, 'pass', sub {
  my ($tryable) = @_;

  require Venus::Space;
  my $space = Venus::Space->new('Venus::Cli');
  $space->patch('_exit', sub{
    $_[1]
  });

  my $result = $tryable->result;
  is $result, 0;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->pass(sub{
    $cli->{dispatched} = 1;
  });

  is $cli->{dispatched}, 1;

  $space->unpatch;

  !$result
});

=method reorder

The reorder method re-indexes the L<"arguments"|/argument_list>,
L<"choices"|/choice_list>, and L<"options"|/option_list>, based on the order
they were declared.

=signature reorder

  reorder() (Venus::Cli)

=metadata reorder

{
  since => '4.15',
}

=example-1 reorder

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
    index => 1,
  });

  $cli->argument('output', {
    type => 'string',
    index => 3,
  });

  $cli->option('file', {
    type => 'string',
    index => 1,
  });

  $cli->option('directory', {
    type => 'string',
    index => 3,
  });

  $cli->choice('stdin', {
    argument => 'input',
    type => 'string',
    index => 1,
  });

  $cli->choice('stdout', {
    argument => 'output',
    type => 'string',
    index => 3,
  });

  my $reorder = $cli->reorder;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'reorder', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply [map $$_{index}, $result->argument_list], [0, 1];
  is_deeply [map $$_{index}, $result->option_list], [0, 1];
  is_deeply [map $$_{index}, $result->choice_list], [0, 1];

  $result
});

=method reorder_arguments

The reorder_arguments method re-indexes the L<"arguments"|/argument_list> based
on the order they were declared.

=signature reorder_arguments

  reorder_arguments() (Venus::Cli)

=metadata reorder_arguments

{
  since => '4.15',
}

=example-1 reorder_arguments

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
    index => 1,
  });

  $cli->argument('output', {
    type => 'string',
    index => 3,
  });

  my $reorder_arguments = $cli->reorder_arguments;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'reorder_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply [map $$_{index}, $result->argument_list], [0, 1];

  $result
});

=method reorder_choices

The reorder_choices method re-indexes the L<"choices"|/choice_list> based on
the order they were declared.

=signature reorder_choices

  reorder_choices() (Venus::Cli)

=metadata reorder_choices

{
  since => '4.15',
}

=example-1 reorder_choices

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
    index => 1,
  });

  $cli->argument('output', {
    type => 'string',
    index => 3,
  });

  $cli->choice('stdin', {
    argument => 'input',
    type => 'string',
    index => 1,
  });

  $cli->choice('stdout', {
    argument => 'output',
    type => 'string',
    index => 3,
  });

  my $reorder_choices = $cli->reorder_choices;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'reorder_choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply [map $$_{index}, $result->choice_list], [0, 1];

  $result
});

=method reorder_options

The reorder_options method re-indexes the L<"options"|/option_list> based on
the order they were declared.

=signature reorder_options

  reorder_options() (Venus::Cli)

=metadata reorder_options

{
  since => '4.15',
}

=example-1 reorder_options

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('file', {
    type => 'string',
    index => 1,
  });

  $cli->option('directory', {
    type => 'string',
    index => 3,
  });

  my $reorder_options = $cli->reorder_options;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'reorder_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply [map $$_{index}, $result->option_list], [0, 1];

  $result
});

=method reorder_routes

The reorder_routes method reorders the registered routes based on their
indices. This method returns the invocant.

=signature reorder_routes

  reorder_routes() (Venus::Cli)

=metadata reorder_routes

{
  since => '4.15',
}

=example-1 reorder_routes

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    index => 1,
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
    index => 0,
  });

  my $reorder_routes = $cli->reorder_routes;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'reorder_routes', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is_deeply [map $$_{index}, $result->route_list], [0, 1];

  $result
});

=method route

The route method registers and returns the configuration for the route
specified. The method takes a name (route name) and a hashref of configuration
values. The possible configuration values are as follows:

+=over 4

+=item *

The C<name> key holds the name of the route.

+=item *

The C<label> key holds the name of the route as it should be displayed in the
CLI help text.

+=item *

The C<help> key holds the help text specific to this route.

+=item *

The C<argument> key holds the name of the argument that this route is
associated with.

+=item *

The C<choice> key holds the name of the choice that this route is associated
with.

+=item *

The C<handler> key holds the (local) method name, or L<Venus::Cli> derived
package, or coderef to execute when this route is matched.

+=item *

The C<range> key holds the range specification for the argument.

+=item *

The C<wants> key holds the text to be used as a value placeholder in the CLI
help text.

+=back

=signature route

  route(string $name, hashref $data) (maybe[hashref])

=metadata route

{
  since => '4.15',
}

=example-1 route

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route = $cli->route('user create');

  # undef

=cut

$test->for('example', 1, 'route', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 route

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route = $cli->route('user create', {
    handler => 'handle_user_create',
  });

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => undef,
  #   choice => undef,
  #   handler => 'handle_user_create',
  #   range => undef,
  #   index => 0,
  # }

=cut

$test->for('example', 2, 'route', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'user create',
    label => undef,
    help => undef,
    argument => undef,
    choice => undef,
    handler => 'handle_user_create',
    range => undef,
    index => 0,
  };

  $result
});

=example-3 route

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route = $cli->route('user create');

  # {
  #   name => 'user create',
  #   label => undef,
  #   help => undef,
  #   argument => undef,
  #   choice => undef,
  #   handler => 'handle_user_create',
  #   range => undef,
  #   index => 0,
  # }

=cut

$test->for('example', 3, 'route', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'user create',
    label => undef,
    help => undef,
    argument => undef,
    choice => undef,
    handler => 'handle_user_create',
    range => undef,
    index => 0,
  };

  $result
});

=example-4 route

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route = $cli->route('user create', undef);

  # {
  #   name => 'user create',
  #   ...
  # }

=cut

$test->for('example', 4, 'route', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result->{name}, 'user create';

  $result
});

=method route_argument

The route_argument method returns the argument configuration for the named
route.

=signature route_argument

  route_argument(string $name) (maybe[hashref])

=metadata route_argument

{
  since => '4.15',
}

=example-1 route_argument

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_argument = $cli->route_argument;

  # ""

=cut

$test->for('example', 1, 'route_argument', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 route_argument

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('command', {
    range => ':1',
  });

  $cli->route('user create', {
    argument => 'command',
    handler => 'handle_user_create',
  });

  my $route_argument = $cli->route_argument('user create');

  # {
  #   name => 'command',
  #   ...
  # }

=cut

$test->for('example', 2, 'route_argument', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result->{name}, 'command';

  $result
});

=method route_choice

The route_choice method returns the choice configuration for the named route.

=signature route_choice

  route_choice(string $name) (maybe[hashref])

=metadata route_choice

{
  since => '4.15',
}

=example-1 route_choice

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_choice = $cli->route_choice;

  # ""

=cut

$test->for('example', 1, 'route_choice', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 route_choice

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('command', {
    range => ':1',
  });

  $cli->choice('user create', {
    argument => 'command',
  });

  $cli->route('user create', {
    argument => 'command',
    choice => 'user create',
    handler => 'handle_user_create',
  });

  my $route_choice = $cli->route_choice('user create');

  # {
  #   name => 'user create',
  #   ...
  # }

=cut

$test->for('example', 2, 'route_choice', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result->{name}, 'user create';

  $result
});

=method route_count

The route_count method returns the number of registered routes.

=signature route_count

  route_count() (number)

=metadata route_count

{
  since => '4.15',
}

=example-1 route_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_count = $cli->route_count;

  # 0

=cut

$test->for('example', 1, 'route_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 route_count

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
  });

  my $route_count = $cli->route_count;

  # 2

=cut

$test->for('example', 2, 'route_count', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 2;

  $result
});

=method route_handler

The route_handler method returns the handler for the named route.

=signature route_handler

  route_handler(string $name) (maybe[string | coderef])

=metadata route_handler

{
  since => '4.15',
}

=example-1 route_handler

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_handler = $cli->route_handler;

  # undef

=cut

$test->for('example', 1, 'route_handler', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-2 route_handler

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route_handler = $cli->route_handler('user create');

  # "handle_user_create"

=cut

$test->for('example', 2, 'route_handler', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "handle_user_create";

  $result
});

=example-3 route_handler

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $handler = sub { ... };

  $cli->route('user create', {
    handler => $handler,
  });

  my $route_handler = $cli->route_handler('user create');

  # sub { ... }

=cut

$test->for('example', 3, 'route_handler', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is ref($result), 'CODE';

  $result
});

=method route_help

The route_help method returns the help text for the named route.

=signature route_help

  route_help(string $name) (string)

=metadata route_help

{
  since => '4.15',
}

=example-1 route_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_help = $cli->route_help;

  # ""

=cut

$test->for('example', 1, 'route_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 route_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    help => 'Create a new user',
  });

  my $route_help = $cli->route_help('user create');

  # "Create a new user"

=cut

$test->for('example', 2, 'route_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Create a new user";

  $result
});

=method route_label

The route_label method returns the label for the named route.

=signature route_label

  route_label(string $name) (string)

=metadata route_label

{
  since => '4.15',
}

=example-1 route_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_label = $cli->route_label;

  # ""

=cut

$test->for('example', 1, 'route_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 route_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    label => 'User Create',
  });

  my $route_label = $cli->route_label('user create');

  # "User Create"

=cut

$test->for('example', 2, 'route_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "User Create";

  $result
});

=method route_list

The route_list method returns a list of all registered route configurations in
insertion order.

=signature route_list

  route_list() (arrayref[hashref])

=metadata route_list

{
  since => '4.15',
}

=example-1 route_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_list = $cli->route_list;

  # []

=cut

$test->for('example', 1, 'route_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  !@{$result}
});

=example-2 route_list

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
  });

  my $route_list = $cli->route_list;

  # [
  #   { name => 'user create', ... },
  #   { name => 'user delete', ... },
  # ]

=cut

$test->for('example', 2, 'route_list', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is scalar(@{$result}), 2;
  is $result->[0]->{name}, 'user create';
  is $result->[1]->{name}, 'user delete';

  $result
});

=method route_name

The route_name method returns the name of the named route.

=signature route_name

  route_name(string $name) (string)

=metadata route_name

{
  since => '4.15',
}

=example-1 route_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_name = $cli->route_name;

  # ""

=cut

$test->for('example', 1, 'route_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 route_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  my $route_name = $cli->route_name('user create');

  # "user create"

=cut

$test->for('example', 2, 'route_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "user create";

  $result
});

=method route_names

The route_names method returns a list of all registered route names in
insertion order.

=signature route_names

  route_names() (arrayref[string])

=metadata route_names

{
  since => '4.15',
}

=example-1 route_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_names = $cli->route_names;

  # []

=cut

$test->for('example', 1, 'route_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  !@{$result}
});

=example-2 route_names

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
  });

  $cli->route('user delete', {
    handler => 'handle_user_delete',
  });

  my $route_names = $cli->route_names;

  # ["user create", "user delete"]

=cut

$test->for('example', 2, 'route_names', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, ["user create", "user delete"];

  $result
});

=method route_range

The route_range method returns the range for the named route.

=signature route_range

  route_range(string $name) (string)

=metadata route_range

{
  since => '4.15',
}

=example-1 route_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $route_range = $cli->route_range;

  # ""

=cut

$test->for('example', 1, 'route_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 route_range

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->route('user create', {
    handler => 'handle_user_create',
    range => ':1',
  });

  my $route_range = $cli->route_range('user create');

  # ":1"

=cut

$test->for('example', 2, 'route_range', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, ":1";

  $result
});

=method required

The required method is a configuration dispatcher and shorthand for
C<{'required', true}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

=signature required

  required(string $method, any @args) (any)

=metadata required

{
  since => '4.15',
}

=cut

=example-1 required

  # given: synopsis

  package main;

  my $required = $cli->required;

  # {required => true}

=cut

$test->for('example', 1, 'required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {required => true};

  $result
});

=example-2 required

  # given: synopsis

  package main;

  my $required = $cli->required(undef, {type => 'boolean'});

  # {required => true, type => 'boolean'}

=cut

$test->for('example', 2, 'required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {required => true, type => 'boolean'};

  $result
});

=example-3 required

  # given: synopsis

  package main;

  my $required = $cli->required('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 3, 'required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a string value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 1,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method reset

The reset method clears the argument and option configurations, cached parsed
values, and returns the invocant.

=signature reset

  reset() (Venus::Cli)

=metadata reset

{
  since => '4.15',
}

=example-1 reset

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $reset = $cli->reset;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result->data, [];
  is_deeply $result->arguments, {};
  is_deeply $result->options, {};
  is_deeply $result->parsed_arguments, [];
  is_deeply $result->parsed_options, {};
  is_deeply $result->{logs}, [];

  $result
});

=example-2 reset

  # given: synopsis

  package main;

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->parse('--input', 'stdin', '--output', 'stdout');

  my $reset = $cli->reset;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 2, 'reset', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result->data, [];
  is_deeply $result->arguments, {};
  is_deeply $result->options, {};
  is_deeply $result->parsed_arguments, [];
  is_deeply $result->parsed_options, {};
  is_deeply $result->{logs}, [];

  $result
});

=method single

The single method is a configuration dispatcher and shorthand for
C<{'multiples', false}>. It returns the data or dispatches to the next
configuration dispatcher based on the name provided and merges the
configurations produced.

=signature single

  single(string $method, any @args) (any)

=metadata single

{
  since => '4.15',
}

=cut

=example-1 single

  # given: synopsis

  package main;

  my $single = $cli->single;

  # {multiples => false}

=cut

$test->for('example', 1, 'single', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {multiples => false};

  $result
});

=example-2 single

  # given: synopsis

  package main;

  my $single = $cli->single(undef, {type => 'boolean'});

  # {multiples => false, type => 'boolean'}

=cut

$test->for('example', 2, 'single', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {multiples => false, type => 'boolean'};

  $result
});

=example-3 single

  # given: synopsis

  package main;

  my $single = $cli->single('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 0,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 3, 'single', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a string value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method spec

The spec method configures the CLI instance from a hashref specification. It
accepts a hashref containing any of the following keys: C<name>, C<version>,
C<summary>, C<description>, C<header>, C<footer>, C<arguments>, C<options>,
C<choices>, C<routes>, and C<commands>. The method returns the invocant.

=signature spec

  spec(hashref $data) (Venus::Cli)

=metadata spec

{
  since => '4.15',
}

=example-1 spec

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec;

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 1, 'spec', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');

  $result
});

=example-2 spec

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    version => '1.0.0',
    summary => 'My CLI application',
  });

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 2, 'spec', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is $result->name, 'mycli';
  is $result->version, '1.0.0';
  is $result->summary, 'My CLI application';

  $result
});

=example-3 spec

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    options => [
      {
        name => 'verbose',
        type => 'boolean',
        aliases => ['v'],
        help => 'Enable verbose output',
      },
      {
        name => 'config',
        type => 'string',
        aliases => ['c'],
        help => 'Path to config file',
      },
    ],
  });

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 3, 'spec', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is $result->option_count, 2;
  is $result->option('verbose')->{type}, 'boolean';
  is $result->option('config')->{type}, 'string';

  $result
});

=example-4 spec

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    arguments => [
      {
        name => 'input',
        type => 'string',
        help => 'Input file path',
      },
    ],
  });

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 4, 'spec', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is $result->argument_count, 1;
  is $result->argument('input')->{type}, 'string';

  $result
});

=example-5 spec

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    commands => [
      ['command', 'user', 'create', 'handle_user_create'],
      ['command', 'user', 'delete', 'handle_user_delete'],
    ],
  });

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 5, 'spec', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is $result->route_count, 2;
  is $result->route('user create')->{handler}, 'handle_user_create';
  is $result->route('user delete')->{handler}, 'handle_user_delete';
  is $result->argument('command')->{range}, ':1';

  $result
});

=example-6 spec

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $spec = $cli->spec({
    name => 'mycli',
    version => '1.0.0',
    summary => 'User management CLI',
    description => 'A command-line tool for managing users',
    header => 'Welcome to mycli',
    footer => 'For more info, visit example.com',
    arguments => [
      {
        name => 'action',
        type => 'string',
        range => '0',
      },
    ],
    options => [
      {
        name => 'verbose',
        type => 'boolean',
        aliases => ['v'],
      },
    ],
    choices => [
      {
        name => 'create',
        argument => 'action',
        help => 'Create a new user',
      },
      {
        name => 'delete',
        argument => 'action',
        help => 'Delete a user',
      },
    ],
    routes => [
      {
        name => 'create',
        argument => 'action',
        choice => 'create',
        handler => 'handle_create',
      },
      {
        name => 'delete',
        argument => 'action',
        choice => 'delete',
        handler => 'handle_delete',
      },
    ],
  });

  # bless(..., "Venus::Cli")

=cut

$test->for('example', 6, 'spec', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Cli');
  is $result->name, 'mycli';
  is $result->version, '1.0.0';
  is $result->summary, 'User management CLI';
  is $result->description, 'A command-line tool for managing users';
  is $result->header, 'Welcome to mycli';
  is $result->footer, 'For more info, visit example.com';
  is $result->argument_count, 1;
  is $result->option_count, 1;
  is $result->choice_count, 2;
  is $result->route_count, 2;
  is $result->route('create')->{handler}, 'handle_create';
  is $result->route('delete')->{handler}, 'handle_delete';

  $result
});

=method string

The string method is a configuration dispatcher and shorthand for C<{'type',
'string'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

=signature string

  string(string $method, any @args) (any)

=metadata string

{
  since => '4.15',
}

=cut

=example-1 string

  # given: synopsis

  package main;

  my $string = $cli->string;

  # {type => 'string'}

=cut

$test->for('example', 1, 'string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'string'};

  $result
});

=example-2 string

  # given: synopsis

  package main;

  my $string = $cli->string(undef, {required => true});

  # {type => 'string', required => true}

=cut

$test->for('example', 2, 'string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'string', required => true};

  $result
});

=example-3 string

  # given: synopsis

  package main;

  my $string = $cli->string('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a string value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'string',
  #   index => 0,
  #   wants => 'string',
  # }

=cut

$test->for('example', 3, 'string', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a string value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'string',
    index => 0,
    wants => 'string',
  };

  $result
});

=method usage

The usage method provides the command-line usage information for the CLI. It
outputs details such as available choices, arguments, options, and a general
summary of how to use the CLI. This method is useful for users needing guidance
on the various arguments, options, and choices available, and how they work.

=signature usage

  usage() (string)

=metadata usage

{
  since => '4.15',
}

=example-1 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage = $cli->usage;

  # "Usage: mycli"

=cut

$test->for('example', 1, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Usage: mycli";
  $result
});

=example-2 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
  );

  my $usage = $cli->usage;

  # "mycli - Example summary
  #
  # Usage: mycli"

=cut

$test->for('example', 2, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli - Example summary

Usage: mycli
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-3 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  my $usage = $cli->usage;

  # "mycli version 0.0.1 - Example summary
  #
  # Usage: mycli"

=cut

$test->for('example', 3, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli version 0.0.1 - Example summary

Usage: mycli
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-4 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output>]
  #
  # Arguments:
  #   [<input>]
  #     Expects a string value
  #     (optional)
  #   [<output>]
  #     Expects a string value
  #     (optional)

=cut

$test->for('example', 4, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli version 0.0.1 - Example summary

Usage: mycli [<input>] [<output>]

Arguments:
  [<input>]
    Expects a string value
    (optional)
  [<output>]
    Expects a string value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-5 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    default => 'file',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli <input> [<output>]
  #
  # Arguments:
  #   <input>
  #     Expects a string value
  #     (required)
  #   [<output>]
  #     Expects a string value
  #     (optional)
  #     Default: file

=cut

$test->for('example', 5, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli version 0.0.1 - Example summary

Usage: mycli <input> [<output>]

Arguments:
  <input>
    Expects a string value
    (required)
  [<output>]
    Expects a string value
    (optional)
    Default: file
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-6 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'INPUT',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'OUTPUT',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<INPUT>] [<OUTPUT>]
  #
  # Arguments:
  #   [<INPUT>]
  #     Expects a string value
  #     (optional)
  #   [<OUTPUT>]
  #     Expects a string value
  #     (optional)

=cut

$test->for('example', 6, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli version 0.0.1 - Example summary

Usage: mycli [<INPUT>] [<OUTPUT>]

Arguments:
  [<INPUT>]
    Expects a string value
    (optional)
  [<OUTPUT>]
    Expects a string value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-7 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'input',
    label => 'Input.',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'output',
    label => 'Output.',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output>]
  #
  # Arguments:
  #   Input.
  #     Expects a string value
  #     (optional)
  #   Output.
  #     Expects a string value
  #     (optional)

=cut

$test->for('example', 7, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli version 0.0.1 - Example summary

Usage: mycli [<input>] [<output>]

Arguments:
  Input.
    Expects a string value
    (optional)
  Output.
    Expects a string value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-8 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'input',
    help => 'Provide the input device to use',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'output',
    help => 'Provide the output device to use',
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output>]
  #
  # Arguments:
  #   [<input>]
  #     Provide the input device to use
  #     (optional)
  #   [<output>]
  #     Provide the output device to use
  #     (optional)

=cut

$test->for('example', 8, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli version 0.0.1 - Example summary

Usage: mycli [<input>] [<output>]

Arguments:
  [<input>]
    Provide the input device to use
    (optional)
  [<output>]
    Provide the output device to use
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-9 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
    summary => 'Example summary',
    version => '0.0.1',
  );

  $cli->argument('input', {
    name => 'input',
    help => 'Provide the input device to use',
    type => 'string',
  });

  $cli->argument('output', {
    name => 'output',
    help => 'Provide the output device to use',
    multiples => true,
    type => 'string',
  });

  my $usage = $cli->usage;

  # mycli version 0.0.1 - Example summary
  #
  # Usage: mycli [<input>] [<output> ...]
  #
  # Arguments:
  #   [<input>]
  #     Provide the input device to use
  #     (optional)
  #   [<output> ...]
  #     Provide the output device to use
  #     (optional)

=cut

$test->for('example', 9, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
mycli version 0.0.1 - Example summary

Usage: mycli [<input>] [<output> ...]

Arguments:
  [<input>]
    Provide the input device to use
    (optional)
  [<output> ...]
    Provide the output device to use
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-10 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] [--input] [--output]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   [--input=<string>]
  #     Expects a string value
  #     (optional)
  #   [--output=<string>]
  #     Expects a string value
  #     (optional)

=cut

$test->for('example', 10, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli [<lines> ...] [--input] [--output]

Arguments:
  [<lines> ...]
    Expects a string value
    (optional)

Options:
  [--input=<string>]
    Expects a string value
    (optional)
  [--output=<string>]
    Expects a string value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-11 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  $cli->option('verbose', {
    type => 'boolean',
  });

  $cli->option('help', {
    alias => 'h',
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] [--input] [--output] [--verbose] [--help]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   [--input=<string>]
  #     Expects a string value
  #     (optional)
  #   [--output=<string>]
  #     Expects a string value
  #     (optional)
  #   [--verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)

=cut

$test->for('example', 11, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli [<lines> ...] [--input] [--output] [--verbose] [--help]

Arguments:
  [<lines> ...]
    Expects a string value
    (optional)

Options:
  [--input=<string>]
    Expects a string value
    (optional)
  [--output=<string>]
    Expects a string value
    (optional)
  [--verbose]
    Expects a boolean value
    (optional)
  [-h, --help]
    Expects a boolean value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-12 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    multiples => true,
    type => 'string',
  });

  $cli->option('output', {
    multiples => true,
    type => 'string',
  });

  $cli->option('verbose', {
    type => 'boolean',
  });

  $cli->option('help', {
    alias => 'h',
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] [--input ...] [--output ...] [--verbose] [--help]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   [--input=<string> ...]
  #     Expects a string value
  #     (optional)
  #   [--output=<string> ...]
  #     Expects a string value
  #     (optional)
  #   [--verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)

=cut

$test->for('example', 12, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli [<lines> ...] [--input ...] [--output ...] [--verbose] [--help]

Arguments:
  [<lines> ...]
    Expects a string value
    (optional)

Options:
  [--input=<string> ...]
    Expects a string value
    (optional)
  [--output=<string> ...]
    Expects a string value
    (optional)
  [--verbose]
    Expects a boolean value
    (optional)
  [-h, --help]
    Expects a boolean value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-13 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    alias => 'i',
    multiples => true,
    required => true,
    type => 'string',
    wants => 'input',
  });

  $cli->option('output', {
    alias => 'o',
    multiples => true,
    type => 'string',
    wants => 'output',
  });

  $cli->option('verbose', {
    aliases => ['v'],
    type => 'boolean',
  });

  $cli->option('help', {
    aliases => ['h'],
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] --input ... [--output ...] [--verbose] [--help]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   -i, --input=<input> ...
  #     Expects a string value
  #     (required)
  #   [-o, --output=<output> ...]
  #     Expects a string value
  #     (optional)
  #   [-v, --verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)

=cut

$test->for('example', 13, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli [<lines> ...] --input ... [--output ...] [--verbose] [--help]

Arguments:
  [<lines> ...]
    Expects a string value
    (optional)

Options:
  -i, --input=<input> ...
    Expects a string value
    (required)
  [-o, --output=<output> ...]
    Expects a string value
    (optional)
  [-v, --verbose]
    Expects a boolean value
    (optional)
  [-h, --help]
    Expects a boolean value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-14 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->option('input', {
    alias => 'i',
    multiples => true,
    required => true,
    type => 'string',
    wants => 'input',
  });

  $cli->option('output', {
    alias => 'o',
    multiples => true,
    type => 'string',
    wants => 'output',
  });

  $cli->option('verbose', {
    aliases => ['v'],
    type => 'boolean',
  });

  $cli->option('help', {
    aliases => ['h'],
    type => 'boolean',
  });

  $cli->argument('lines', {
    multiples => true,
    range => '0:',
    type => 'string',
  });

  $cli->option('exit-code', {
    alias => 'ec',
    type => 'number',
    default => 0,
  });

  my $usage = $cli->usage;

  # Usage: mycli [<lines> ...] --input ... [--output ...] [--verbose] [--help]
  #              [--exit-code]
  #
  # Arguments:
  #   [<lines> ...]
  #     Expects a string value
  #     (optional)
  #
  # Options:
  #   -i, --input=<input> ...
  #     Expects a string value
  #     (required)
  #   [-o, --output=<output> ...]
  #     Expects a string value
  #     (optional)
  #   [-v, --verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)
  #   [--ec, --exit-code=<number>]
  #     Expects a number value
  #     (optional)
  #     Default: 0

=cut

$test->for('example', 14, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli [<lines> ...] --input ... [--output ...] [--verbose] [--help]
             [--exit-code]

Arguments:
  [<lines> ...]
    Expects a string value
    (optional)

Options:
  -i, --input=<input> ...
    Expects a string value
    (required)
  [-o, --output=<output> ...]
    Expects a string value
    (optional)
  [-v, --verbose]
    Expects a boolean value
    (optional)
  [-h, --help]
    Expects a boolean value
    (optional)
  [--ec, --exit-code=<number>]
    Expects a number value
    (optional)
    Default: 0
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-15 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->argument('input', {
    type => 'string',
    default => 'stdin',
  });

  $cli->argument('output', {
    type => 'string',
    default => 'stdout',
  });

  $cli->option('verbose', {
    aliases => ['v'],
    type => 'boolean',
  });

  $cli->option('help', {
    aliases => ['h'],
    type => 'boolean',
  });

  $cli->option('exit-code', {
    alias => 'ec',
    type => 'number',
    default => 0,
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->choice('in-file', {
    argument => 'input',
  });

  $cli->choice('stdout', {
    argument => 'output',
  });

  $cli->choice('out-file', {
    argument => 'output',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<input>] [<output>] [--verbose] [--help] [--exit-code]
  #
  # Arguments:
  #   [<input>]
  #     Expects a string value
  #     (optional)
  #     Default: stdin
  #   [<output>]
  #     Expects a string value
  #     (optional)
  #     Default: stdout
  #
  # Options:
  #   [-v, --verbose]
  #     Expects a boolean value
  #     (optional)
  #   [-h, --help]
  #     Expects a boolean value
  #     (optional)
  #   [--ec, --exit-code=<number>]
  #     Expects a number value
  #     (optional)
  #     Default: 0
  #
  # Choices for [<input>]:
  #   stdin
  #     Expects a string value
  #     [<input>]
  #   in-file
  #     Expects a string value
  #     [<input>]
  #
  # Choices for [<output>]:
  #   stdout
  #     Expects a string value
  #     [<output>]
  #   out-file
  #     Expects a string value
  #     [<output>]

=cut

$test->for('example', 15, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli [<input>] [<output>] [--verbose] [--help] [--exit-code]

Arguments:
  [<input>]
    Expects a string value
    (optional)
    Default: stdin
  [<output>]
    Expects a string value
    (optional)
    Default: stdout

Options:
  [-v, --verbose]
    Expects a boolean value
    (optional)
  [-h, --help]
    Expects a boolean value
    (optional)
  [--ec, --exit-code=<number>]
    Expects a number value
    (optional)
    Default: 0

Choices for [<input>]:
  stdin
    Expects a string value
    [<input>]
  in-file
    Expects a string value
    [<input>]

Choices for [<output>]:
  stdout
    Expects a string value
    [<output>]
  out-file
    Expects a string value
    [<output>]
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-16 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->argument('choice', {
    help => 'See "choices" below',
    type => 'string',
    default => 'open',
  });

  $cli->choice('open', {
    argument => 'choice',
  });

  $cli->choice('close', {
    argument => 'choice',
  });

  $cli->choice('read', {
    argument => 'choice',
  });

  $cli->choice('write', {
    argument => 'choice',
  });

  my $usage = $cli->usage;

  # Usage: mycli [<choice>]
  #
  # Arguments:
  #   [<choice>]
  #     See "choices" below
  #     (optional)
  #     Default: open
  #
  # Choices for [<choice>]:
  #   open
  #     Expects a string value
  #     [<choice>]
  #   close
  #     Expects a string value
  #     [<choice>]
  #   read
  #     Expects a string value
  #     [<choice>]
  #   write
  #     Expects a string value
  #     [<choice>]

=cut

$test->for('example', 16, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli [<choice>]

Arguments:
  [<choice>]
    See "choices" below
    (optional)
    Default: open

Choices for [<choice>]:
  open
    Expects a string value
    [<choice>]
  close
    Expects a string value
    [<choice>]
  read
    Expects a string value
    [<choice>]
  write
    Expects a string value
    [<choice>]
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=example-17 usage

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(
    name => 'mycli',
  );

  $cli->argument('choice', {
    help => 'See "choices" below',
    type => 'string',
    required => true,
  });

  $cli->choice('open', {
    argument => 'choice',
  });

  $cli->choice('close', {
    argument => 'choice',
  });

  $cli->choice('read', {
    argument => 'choice',
  });

  $cli->choice('write', {
    argument => 'choice',
  });

  my $usage = $cli->usage;

  # Usage: mycli <choice>
  #
  # Arguments:
  #   <choice>
  #     See "choices" below
  #     (required)
  #
  # Choices for <choice>:
  #   open
  #     Expects a string value
  #     <choice>
  #   close
  #     Expects a string value
  #     <choice>
  #   read
  #     Expects a string value
  #     <choice>
  #   write
  #     Expects a string value
  #     <choice>

=cut

$test->for('example', 17, 'usage', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Usage: mycli <choice>

Arguments:
  <choice>
    See "choices" below
    (required)

Choices for <choice>:
  open
    Expects a string value
    <choice>
  close
    Expects a string value
    <choice>
  read
    Expects a string value
    <choice>
  write
    Expects a string value
    <choice>
EOF
  chomp $expect;
  is $result, $expect;
  $result
});

=method usage_argument_default

The usage_argument_default method renders the C<default> configuration value
for the named argument for use in the CLI L</usage> text.

=signature usage_argument_default

  usage_argument_default(string $name) (string)

=metadata usage_argument_default

{
  since => '4.15',
}

=example-1 usage_argument_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_default = $cli->usage_argument_default;

  # ""

=cut

$test->for('example', 1, 'usage_argument_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_argument_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => 'stdin',
  });

  my $usage_argument_default = $cli->usage_argument_default('input');

  # "Default: stdin"

=cut

$test->for('example', 2, 'usage_argument_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Default: stdin";

  $result
});

=example-3 usage_argument_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    default => ['stdin', 'file'],
  });

  my $usage_argument_default = $cli->usage_argument_default('input');

  # "Default: stdin, file"

=cut

$test->for('example', 3, 'usage_argument_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Default: stdin, file";

  $result
});

=method usage_argument_help

The usage_argument_help method renders the C<help> configuration value for the
named argument for use in the CLI L</usage> text.

=signature usage_argument_help

  usage_argument_help(string $name) (string)

=metadata usage_argument_help

{
  since => '4.15',
}

=example-1 usage_argument_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_help = $cli->usage_argument_help;

  # ""

=cut

$test->for('example', 1, 'usage_argument_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_argument_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Provide input.',
  });

  my $usage_argument_help = $cli->usage_argument_help('input');

  # "Provide input."

=cut

$test->for('example', 2, 'usage_argument_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Provide input.";

  $result
});

=method usage_argument_label

The usage_argument_label method renders the C<label> configuration value for
the named argument for use in the CLI L</usage> text.

=signature usage_argument_label

  usage_argument_label(string $name) (string)

=metadata usage_argument_label

{
  since => '4.15',
}

=example-1 usage_argument_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_label = $cli->usage_argument_label;

  # ""

=cut

$test->for('example', 1, 'usage_argument_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_argument_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input.',
  });

  my $usage_argument_label = $cli->usage_argument_label('input');

  # "Input."

=cut

$test->for('example', 2, 'usage_argument_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Input.";

  $result
});

=method usage_argument_required

The usage_argument_required method renders the C<required> configuration value
for the named argument for use in the CLI L</usage> text.

=signature usage_argument_required

  usage_argument_required(string $name) (string)

=metadata usage_argument_required

{
  since => '4.15',
}

=example-1 usage_argument_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_required = $cli->usage_argument_required;

  # "(optional)"

=cut

$test->for('example', 1, 'usage_argument_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "(optional)";

  $result
});

=example-2 usage_argument_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  my $usage_argument_required = $cli->usage_argument_required('input');

  # "(required)"

=cut

$test->for('example', 2, 'usage_argument_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "(required)";

  $result
});

=example-3 usage_argument_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
  });

  my $usage_argument_required = $cli->usage_argument_required('input');

  # "(optional)"

=cut

$test->for('example', 3, 'usage_argument_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "(optional)";

  $result
});

=method usage_argument_token

The usage_argument_token method renders the C<token> configuration value for
the named argument for use in the CLI L</usage> text.

=signature usage_argument_token

  usage_argument_token(string $name) (string)

=metadata usage_argument_token

{
  since => '4.15',
}

=example-1 usage_argument_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_argument_token = $cli->usage_argument_token;

  # ""

=cut

$test->for('example', 1, 'usage_argument_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_argument_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    multiples => false,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "<input>"

=cut

$test->for('example', 2, 'usage_argument_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "<input>";

  $result
});

=example-3 usage_argument_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    multiples => true,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "<input> ..."

=cut

$test->for('example', 3, 'usage_argument_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "<input> ...";

  $result
});

=example-4 usage_argument_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
    multiples => false,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "[<input>]"

=cut

$test->for('example', 4, 'usage_argument_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[<input>]";

  $result
});

=example-5 usage_argument_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
    multiples => true,
    type => 'string',
  });

  my $usage_argument_token = $cli->usage_argument_token('input');

  # "[<input> ...]"

=cut

$test->for('example', 5, 'usage_argument_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[<input> ...]";

  $result
});

=method usage_arguments

The usage_arguments method renders all registered arguments for use in the CLI
L</usage> text.

=signature usage_arguments

  usage_arguments() (string)

=metadata usage_arguments

{
  since => '4.15',
}

=example-1 usage_arguments

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $usage_arguments = $cli->usage_arguments;

  # Arguments:
  #   [<input>]
  #     Expects a string value
  #     (optional)
  #   [<output>]
  #     Expects a string value
  #     (optional)

=cut

$test->for('example', 1, 'usage_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Arguments:
  [<input>]
    Expects a string value
    (optional)
  [<output>]
    Expects a string value
    (optional)
EOF

  chomp $expect;
  is $result, $expect;

  $result
});

=example-2 usage_arguments

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    required => true,
    type => 'string',
  });

  my $usage_arguments = $cli->usage_arguments;

  # Arguments:
  #   <input>
  #     Expects a string value
  #     (required)
  #   <output>
  #     Expects a string value
  #     (required)

=cut

$test->for('example', 2, 'usage_arguments', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Arguments:
  <input>
    Expects a string value
    (required)
  <output>
    Expects a string value
    (required)
EOF

  chomp $expect;
  is $result, $expect;

  $result
});

=method usage_choice_help

The usage_choice_help method renders the C<help> configuration value for the
named choice for use in the CLI L</usage> text.

=signature usage_choice_help

  usage_choice_help(string $name) (string)

=metadata usage_choice_help

{
  since => '4.15',
}

=example-1 usage_choice_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_choice_help = $cli->usage_choice_help;

  # ""

=cut

$test->for('example', 1, 'usage_choice_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_choice_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Example help',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_help = $cli->usage_choice_help('stdin');

  # "Expects a string value"

=cut

$test->for('example', 2, 'usage_choice_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Expects a string value";

  $result
});

=example-3 usage_choice_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    help => 'Example help',
  });

  $cli->choice('stdin', {
    argument => 'input',
    help => 'Example help',
  });

  my $usage_choice_help = $cli->usage_choice_help('stdin');

  # "Example help"

=cut

$test->for('example', 3, 'usage_choice_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example help";

  $result
});

=method usage_choice_label

The usage_choice_label method renders the C<label> configuration value for the
named choice for use in the CLI L</usage> text.

=signature usage_choice_label

  usage_choice_label(string $name) (string)

=metadata usage_choice_label

{
  since => '4.15',
}

=example-1 usage_choice_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_choice_label = $cli->usage_choice_label;

  # ""

=cut

$test->for('example', 1, 'usage_choice_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_choice_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input.',
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_label = $cli->usage_choice_label('stdin');

  # "stdin"

=cut

$test->for('example', 2, 'usage_choice_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "stdin";

  $result
});

=example-3 usage_choice_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    label => 'Input.',
    type => 'string',
  });

  $cli->choice('stdin', {
    label => 'Stdin',
    argument => 'input',
  });

  my $usage_choice_label = $cli->usage_choice_label('stdin');

  # "Stdin"

=cut

$test->for('example', 3, 'usage_choice_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Stdin";

  $result
});

=method usage_choice_required

The usage_choice_required method renders the C<required> configuration value
for the named choice for use in the CLI L</usage> text.

=signature usage_choice_required

  usage_choice_required(string $name) (string)

=metadata usage_choice_required

{
  since => '4.15',
}

=example-1 usage_choice_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_choice_required = $cli->usage_choice_required;

  # ""

=cut

$test->for('example', 1, 'usage_choice_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_choice_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_required = $cli->usage_choice_required('stdin');

  # "<input>"

=cut

$test->for('example', 2, 'usage_choice_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "<input>";

  $result
});

=example-3 usage_choice_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => false,
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  my $usage_choice_required = $cli->usage_choice_required('stdin');

  # "[<input>]"

=cut

$test->for('example', 3, 'usage_choice_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[<input>]";

  $result
});

=method usage_choices

The usage_choices method renders all registered choices for use in the CLI
L</usage> text.

=signature usage_choices

  usage_choices() (string)

=metadata usage_choices

{
  since => '4.15',
}

=example-1 usage_choices

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->choice('stdin', {
    argument => 'input',
  });

  $cli->argument('output', {
    type => 'string',
  });

  $cli->choice('stdout', {
    argument => 'output',
  });

  my $usage_choices = $cli->usage_choices;

  # Choices for [<input>]:
  #   stdin
  #     Expects a string value
  #     [<input>]
  #
  # Choices for [<output>]:
  #   stdout
  #     Expects a string value
  #     [<output>]

=cut

$test->for('example', 1, 'usage_choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Choices for [<input>]:
  stdin
    Expects a string value
    [<input>]

Choices for [<output>]:
  stdout
    Expects a string value
    [<output>]
EOF

  chomp $expect;
  is $result, $expect;

  $result
});

=example-2 usage_choices

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
  });

  $cli->choice('stdin', {
    argument => 'input',
    help => 'Use STDIN',
  });

  $cli->argument('output', {
    default => 'stdout',
  });

  $cli->choice('stdout', {
    argument => 'output',
    help => 'Use STDOUT',
  });

  my $usage_choices = $cli->usage_choices;

  # Choices for <input>:
  #   stdin
  #     Use STDIN
  #     <input>
  #
  # Choices for [<output>]:
  #   stdout
  #     Use STDOUT
  #     [<output>]

=cut

$test->for('example', 2, 'usage_choices', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Choices for <input>:
  stdin
    Use STDIN
    <input>

Choices for [<output>]:
  stdout
    Use STDOUT
    [<output>]
EOF

  chomp $expect;
  is $result, $expect;

  $result
});

=method usage_description

The usage_description method renders the description for use in the CLI
L</usage> text.

=signature usage_description

  usage_description() (string)

=metadata usage_description

{
  since => '4.15',
}

=example-1 usage_description

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $description = $cli->description('Example description');

  my $usage_description = $cli->usage_description;

  # "Example description"

=cut

$test->for('example', 1, 'usage_description', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example description";

  $result
});

=method usage_footer

The usage_footer method renders the footer for use in the CLI L</usage> text.

=signature usage_footer

  usage_footer() (string)

=metadata usage_footer

{
  since => '4.15',
}

=example-1 usage_footer

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $footer = $cli->footer('Example footer');

  my $usage_footer = $cli->usage_footer;

  # "Example footer"

=cut

$test->for('example', 1, 'usage_footer', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example footer";

  $result
});

=method usage_gist

The usage_gist method renders the CLI top-line describing the name, version,
and/or summary.

=signature usage_gist

  usage_gist() (string)

=metadata usage_gist

{
  since => '4.15',
}

=example-1 usage_gist

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_gist = $cli->usage_gist;

  # ""

=cut

$test->for('example', 1, 'usage_gist', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_gist

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->version('0.0.1');

  my $usage_gist = $cli->usage_gist;

  # "mycli version 0.0.1"

=cut

$test->for('example', 2, 'usage_gist', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "mycli version 0.0.1";

  $result
});

=example-3 usage_gist

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->summary('Example summary');

  my $usage_gist = $cli->usage_gist;

  # "mycli - Example summary"

=cut

$test->for('example', 3, 'usage_gist', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "mycli - Example summary";

  $result
});

=example-4 usage_gist

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->version('0.0.1');

  $cli->summary('Example summary');

  my $usage_gist = $cli->usage_gist;

  # "mycli version 0.0.1 - Example summary"

=cut

$test->for('example', 4, 'usage_gist', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "mycli version 0.0.1 - Example summary";

  $result
});

=method usage_header

The usage_header method renders the header for use in the CLI L</usage> text.

=signature usage_header

  usage_header() (string)

=metadata usage_header

{
  since => '4.15',
}

=example-1 usage_header

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $header = $cli->header('Example header');

  my $usage_header = $cli->usage_header;

  # "Example header"

=cut

$test->for('example', 1, 'usage_header', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example header";

  $result
});

=method usage_line

The usage_line method renders the CLI usage line for use in the CLI L</usage>
text.

=signature usage_line

  usage_line() (string)

=metadata usage_line

{
  since => '4.15',
}

=example-1 usage_line

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_line = $cli->usage_line;

  # "Usage: mycli"

=cut

$test->for('example', 1, 'usage_line', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Usage: mycli";

  $result
});

=example-2 usage_line

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli [<input>]"

=cut

$test->for('example', 2, 'usage_line', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Usage: mycli [<input>]";

  $result
});

=example-3 usage_line

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    type => 'string',
  });

  $cli->argument('output', {
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli [<input>] [<output>]"

=cut

$test->for('example', 3, 'usage_line', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Usage: mycli [<input>] [<output>]";

  $result
});

=example-4 usage_line

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    required => true,
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli <input> <output>"

=cut

$test->for('example', 4, 'usage_line', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Usage: mycli <input> <output>";

  $result
});

=example-5 usage_line

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->argument('input', {
    required => true,
    type => 'string',
  });

  $cli->argument('output', {
    multiples => true,
    required => false,
    type => 'string',
  });

  my $usage_line = $cli->usage_line;

  # "Usage: mycli <input> [<output> ...]"

=cut

$test->for('example', 5, 'usage_line', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Usage: mycli <input> [<output> ...]";

  $result
});

=method usage_name

The usage_name method renders the CLI name for use in the CLI L</usage> text.

=signature usage_name

  usage_name() (string)

=metadata usage_name

{
  since => '4.15',
}

=example-1 usage_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new;

  my $usage_name = $cli->usage_name;

  # ""

=cut

$test->for('example', 1, 'usage_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_name

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_name = $cli->usage_name;

  # "mycli"

=cut

$test->for('example', 2, 'usage_name', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "mycli";

  $result
});

=method usage_option_default

The usage_option_default method renders the C<default> configuration value for
the named option for use in the CLI L</usage> text.

=signature usage_option_default

  usage_option_default(string $name) (string)

=metadata usage_option_default

{
  since => '4.15',
}

=example-1 usage_option_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_default = $cli->usage_option_default;

  # ""

=cut

$test->for('example', 1, 'usage_option_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_option_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => 'stdin',
  });

  my $usage_option_default = $cli->usage_option_default('input');

  # "Default: stdin"

=cut

$test->for('example', 2, 'usage_option_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Default: stdin";

  $result
});

=example-3 usage_option_default

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    default => ['stdin', 'file'],
  });

  my $usage_option_default = $cli->usage_option_default('input');

  # "Default: stdin, file"

=cut

$test->for('example', 3, 'usage_option_default', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Default: stdin, file";

  $result
});

=method usage_option_help

The usage_option_help method renders the C<help> configuration value for the
named option for use in the CLI L</usage> text.

=signature usage_option_help

  usage_option_help(string $name) (string)

=metadata usage_option_help

{
  since => '4.15',
}

=example-1 usage_option_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_help = $cli->usage_option_help;

  # ""

=cut

$test->for('example', 1, 'usage_option_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_option_help

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    help => 'Example help',
  });

  my $usage_option_help = $cli->usage_option_help('input');

  # "Example help"

=cut

$test->for('example', 2, 'usage_option_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example help";

  $result
});

=method usage_option_label

The usage_option_label method renders the C<label> configuration value for the
named option for use in the CLI L</usage> text.

=signature usage_option_label

  usage_option_label(string $name) (string)

=metadata usage_option_label

{
  since => '4.15',
}

=example-1 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_label = $cli->usage_option_label;

  # ""

=cut

$test->for('example', 1, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<string>"

=cut

$test->for('example', 2, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "--input=<string>";

  $result
});

=example-3 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<string> ..."

=cut

$test->for('example', 3, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "--input=<string> ...";

  $result
});

=example-4 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
    type => 'number',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<number> ..."

=cut

$test->for('example', 4, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "--input=<number> ...";

  $result
});

=example-5 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
    type => 'number',
    wants => 'input',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "--input=<input> ..."

=cut

$test->for('example', 5, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "--input=<input> ...";

  $result
});

=example-6 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => false,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<string>]"

=cut

$test->for('example', 6, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[--input=<string>]";

  $result
});

=example-7 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<string> ...]"

=cut

$test->for('example', 7, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[--input=<string> ...]";

  $result
});

=example-8 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
    type => 'number',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<number> ...]"

=cut

$test->for('example', 8, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[--input=<number> ...]";

  $result
});

=example-9 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
    type => 'number',
    wants => 'input',
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input=<input> ...]"

=cut

$test->for('example', 9, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[--input=<input> ...]";

  $result
});

=example-10 usage_option_label

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
    type => 'boolean',
    wants => undef,
  });

  my $usage_option_label = $cli->usage_option_label('input');

  # "[--input ...]"

=cut

$test->for('example', 10, 'usage_option_label', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[--input ...]";

  $result
});

=method usage_option_required

The usage_option_required method renders the C<required> configuration value
for the named option for use in the CLI L</usage> text.

=signature usage_option_required

  usage_option_required(string $name) (string)

=metadata usage_option_required

{
  since => '4.15',
}

=example-1 usage_option_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_required = $cli->usage_option_required;

  # "(optional)"

=cut

$test->for('example', 1, 'usage_option_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "(optional)";

  $result
});

=example-2 usage_option_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $usage_option_required = $cli->usage_option_required('input');

  # "(required)"

=cut

$test->for('example', 2, 'usage_option_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "(required)";

  $result
});

=example-3 usage_option_required

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => false,
  });

  my $usage_option_required = $cli->usage_option_required('input');

  # "(optional)"

=cut

$test->for('example', 3, 'usage_option_required', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "(optional)";

  $result
});

=method usage_option_token

The usage_option_token method renders the C<token> configuration value for the
named option for use in the CLI L</usage> text.

=signature usage_option_token

  usage_option_token(string $name) (string)

=metadata usage_option_token

{
  since => '4.15',
}

=example-1 usage_option_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $usage_option_token = $cli->usage_option_token;

  # ""

=cut

$test->for('example', 1, 'usage_option_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "";

  !$result
});

=example-2 usage_option_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "--input"

=cut

$test->for('example', 2, 'usage_option_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "--input";

  $result
});

=example-3 usage_option_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => true,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "--input ..."

=cut

$test->for('example', 3, 'usage_option_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "--input ...";

  $result
});

=example-4 usage_option_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => false,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "[--input]"

=cut

$test->for('example', 4, 'usage_option_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[--input]";

  $result
});

=example-5 usage_option_token

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    multiples => true,
    required => false,
  });

  my $usage_option_token = $cli->usage_option_token('input');

  # "[--input ...]"

=cut

$test->for('example', 5, 'usage_option_token', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "[--input ...]";

  $result
});

=method usage_options

The usage_options method renders all registered options for use in the CLI
L</usage> text.

=signature usage_options

  usage_options() (string)

=metadata usage_options

{
  since => '4.15',
}

=example-1 usage_options

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    type => 'string',
  });

  $cli->option('output', {
    type => 'string',
  });

  my $usage_options = $cli->usage_options;

  # Options:
  #   [--input=<string>]
  #     Expects a string value
  #     (optional)
  #   [--output=<string>]
  #     Expects a string value
  #     (optional)

=cut

$test->for('example', 1, 'usage_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<EOF;
Options:
  [--input=<string>]
    Expects a string value
    (optional)
  [--output=<string>]
    Expects a string value
    (optional)
EOF
  chomp $expect;
  is $result, $expect;

  $result
});

=example-2 usage_options

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  $cli->option('input', {
    required => true,
    type => 'string',
  });

  $cli->option('output', {
    required => true,
    type => 'string',
  });

  my $usage_options = $cli->usage_options;

  # Options:
  #   --input=<string>
  #     Expects a string value
  #     (required)
  #   --output=<string>
  #     Expects a string value
  #     (required)

=cut

$test->for('example', 2, 'usage_options', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $expect = <<'EOF';
Options:
  --input=<string>
    Expects a string value
    (required)
  --output=<string>
    Expects a string value
    (required)
EOF
  chomp $expect;
  is $result, $expect;

  $result
});

=method usage_summary

The usage_summary method renders the summary for use in the CLI L</usage> text.

=signature usage_summary

  usage_summary() (string)

=metadata usage_summary

{
  since => '4.15',
}

=example-1 usage_summary

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $summary = $cli->summary('Example summary');

  my $usage_summary = $cli->usage_summary;

  # "Example summary"

=cut

$test->for('example', 1, 'usage_summary', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "Example summary";

  $result
});

=method usage_version

The usage_version method renders the description for use in the CLI L</usage>
text.

=signature usage_version

  usage_version() (string)

=metadata usage_version

{
  since => '4.15',
}

=example-1 usage_version

  package main;

  use Venus::Cli;

  my $cli = Venus::Cli->new(name => 'mycli');

  my $version = $cli->version('0.0.1');

  my $usage_version = $cli->usage_version;

  # "0.0.1"

=cut

$test->for('example', 1, 'usage_version', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, '0.0.1';

  $result
});

=method vars

The vars method returns the list of parsed command-line options as a
L<Venus::Vars> object.

=signature vars

  vars() (Venus::Vars)

=metadata vars

{
  since => '4.15',
}

=example-1 vars

  # given: synopsis

  package main;

  my $vars = $cli->vars;

  # bless(..., "Venus::Vars")

=cut

$test->for('example', 1, 'vars', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Vars');

  $result
});

=method yesno

The yesno method is a configuration dispatcher and shorthand for C<{'type',
'yesno'}>. It returns the data or dispatches to the next configuration
dispatcher based on the name provided and merges the configurations produced.

=signature yesno

  yesno(string $method, any @args) (any)

=metadata yesno

{
  since => '4.15',
}

=cut

=example-1 yesno

  # given: synopsis

  package main;

  my $yesno = $cli->yesno;

  # {type => 'yesno'}

=cut

$test->for('example', 1, 'yesno', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'yesno'};

  $result
});

=example-2 yesno

  # given: synopsis

  package main;

  my $yesno = $cli->yesno(undef, {required => true});

  # {type => 'yesno', required => true}

=cut

$test->for('example', 2, 'yesno', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {type => 'yesno', required => true};

  $result
});

=example-3 yesno

  # given: synopsis

  package main;

  my $yesno = $cli->yesno('option', 'example');

  # {
  #   name => 'example',
  #   label => undef,
  #   help => 'Expects a yesno value',
  #   default => undef,
  #   aliases => [],
  #   multiples => 0,
  #   prompt => undef,
  #   range => undef,
  #   required => 1,
  #   type => 'yesno',
  #   index => 0,
  #   wants => 'yesno',
  # }

=cut

$test->for('example', 3, 'yesno', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {
    name => 'example',
    label => undef,
    help => 'Expects a yesno value',
    default => undef,
    aliases => [],
    multiples => 0,
    prompt => undef,
    range => undef,
    required => 0,
    type => 'yesno',
    index => 0,
    wants => 'yesno',
  };

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Cli.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
