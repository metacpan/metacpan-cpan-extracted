package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus::Cli;
use Venus::Space;
use Venus::Task;
use Venus;

# _stderr
our $TEST_VENUS_TASK_STDERR = [];
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Task::_stderr"} = sub {
    $TEST_VENUS_TASK_STDERR = [@_]
  };
}

# _stdout
our $TEST_VENUS_TASK_STDOUT = [];
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Task::_stdout"} = sub {
    $TEST_VENUS_TASK_STDOUT = [@_]
  };
}

# _exit
our $TEST_VENUS_CLI_EXIT = 0;
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Cli::_exit"} = sub {
    $TEST_VENUS_CLI_EXIT = $_[0]
  };
}

# _print
our $TEST_VENUS_CLI_PRINT = [];
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Cli::_print"} = sub {
    push @{$TEST_VENUS_CLI_PRINT}, [@_]
  };
}

# _prompt
our $TEST_VENUS_CLI_PROMPT = '';
{
  no strict 'refs';
  no warnings 'redefine';
  *{"Venus::Cli::_prompt"} = sub {
    $TEST_VENUS_CLI_PROMPT
  };
}

my $test = test(__FILE__);

=name

Venus::Task

=cut

$test->for('name');

=tagline

Task Class

=cut

$test->for('tagline');

=abstract

Task Class for Perl 5

=cut

$test->for('abstract');

=includes

method: execute
method: handle
method: handle_help
method: new
method: perform
method: prepare
method: spec_data
routine: run

=cut

$test->for('includes');

=synopsis

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new;

  # bless({...}, 'Example')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->isa('Venus::Task');

  Venus::Space->new('Example')->purge;
  $result
});

=description

This package provides a lightweight superclass and simple framework for
building command-line interfaces (CLIs) in Perl. It defines a consistent
structure and lifecycle for task execution, making it easy to create reusable
and maintainable CLI commands.

The framework operates in the following order:

+=over 4

+=item *

You assign the task a L<name|Venus::Cli/name>.

+=item *

You invoke the L<handle/handle> method.

+=item *

The L<handle|/handle> method calls L<prepare|/prepare> and then
L<execute|/execute>.

+=item *

The L<prepare|/prepare> method is where CLI arguments and options are
configured. By default, L<prepare|/prepare> registers a single option: the
L<help|/help> flag.

+=item *

The L<execute|/execute> method dispatches to the L<perform|/perform> method,
outputs to the terminal, and exits the application. Avoid overridding this
method because this is where automated error handling is done. If you need to
override this method, be sure to invoke C<SUPER> or similar to retain the core
behavior.

+=item *

The L<perform|/perform> method is the main method to override in a subclass and
contains the core CLI logic. If the CLI is configured to support routing, be
sure to invoke C<SUPER> or similar to retain the core behavior.

+=back

This structure encourages clean separation of configuration, execution, and
logic, making it easier to write and maintain CLI tools.

=cut

$test->for('description');

=inherits

Venus::Cli

=cut

$test->for('inherits');

=method execute

The execute method dispatches to the L<perform> method, outputs to the
terminal, and exits the application.

=signature execute

  execute() (any)

=metadata execute

{
  since => '4.15',
}

=example-1 execute

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  package main;

  my $task = Example->new;

  my $execute = $task->execute;

  # 0

=cut

$test->for('example', 1, 'execute', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_TASK_STDOUT = [];
  local $TEST_VENUS_CLI_EXIT;
  my $result = $tryable->result;
  is $result, 0;
  is $TEST_VENUS_CLI_EXIT, 0;
  is_deeply $TEST_VENUS_TASK_STDOUT, ['Usage: mycli'];

  Venus::Space->new('Example')->purge;
  !$result
});

=example-2 execute

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  sub perform {
    my ($self) = @_;

    $self->log_info('hello world');

    return $self;
  }

  package main;

  my $task = Example->new;

  my $execute = $task->execute;

  # 0

=cut

$test->for('example', 2, 'execute', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_TASK_STDOUT = [];
  local $TEST_VENUS_CLI_EXIT;
  my $result = $tryable->result;
  is $result, 0;
  is $TEST_VENUS_CLI_EXIT, 0;
  is_deeply $TEST_VENUS_TASK_STDOUT, ['hello world'];

  Venus::Space->new('Example')->purge;
  !$result
});

=example-3 execute

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  sub perform {
    my ($self) = @_;

    $self->log_error('oh no');

    return $self;
  }

  package main;

  my $task = Example->new;

  my $execute = $task->execute;

  # 1

=cut

$test->for('example', 3, 'execute', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_TASK_STDERR = [];
  local $TEST_VENUS_TASK_STDOUT = [];
  local $TEST_VENUS_CLI_EXIT;
  my $result = $tryable->result;
  is $result, 1;
  is $TEST_VENUS_CLI_EXIT, 1;
  is_deeply $TEST_VENUS_TASK_STDERR, ['oh no'];
  is_deeply $TEST_VENUS_TASK_STDOUT, [];

  Venus::Space->new('Example')->purge;
  $result
});

=method handle

The handle method executes the L<prepare|/prepare> method, and then
L<execute|/execute>. Optionally accepting a list of command-line arguments to
be parsed after "prepare" and before "execute", and if not provided will lazy
parse the data in C<@ARGV>.

=signature handle

  handle(any @args) (Venus::Task)

=metadata handle

{
  since => '4.15',
}

=example-1 handle

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  sub handle {
    my ($self) = @_;

    $self->SUPER::handle; # prepare and execute

    return $self;
  }

  package main;

  my $task = Example->new;

  my $handle = $task->handle;

  # bless(..., 'Example')

=cut

$test->for('example', 1, 'handle', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');

  Venus::Space->new('Example')->purge;
  $result
});

=method handle_help

The handle_help method calls the L<Venus::Cli/help> method, outputting help
text, if a help flag was found (i.e. provided). This method returns true if a
help flag was found, and false otherwise.

=signature handle_help

  handle_help() (boolean)

=metadata handle_help

{
  since => '4.15',
}

=example-1 handle_help

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  package main;

  my $task = Example->new;

  $task->prepare;

  my $handle_help = $task->handle_help;

  # false

=cut

$test->for('example', 1, 'handle_help', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, false;

  Venus::Space->new('Example')->purge;
  !$result
});

=example-2 handle_help

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  package main;

  my $task = Example->new;

  $task->prepare;

  $task->parse('--help');

  my $handle_help = $task->handle_help;

  # true

=cut

$test->for('example', 2, 'handle_help', sub {
  my ($tryable) = @_;
  local $TEST_VENUS_TASK_STDOUT = [];
  my $result = $tryable->result;
  is $result, true;
  is_deeply $TEST_VENUS_TASK_STDOUT, [];
  my $task = Example->new;
  $task->prepare;
  $task->parse('--help');
  $task->handle_help;
  my $expects = <<'EOF';
Usage: mycli [--help]

Options:
  [--help]
    Expects a boolean value
    (optional)
EOF
  chomp $expects;
  my $output = $task->output;
  is $output, $expects;

  Venus::Space->new('Example')->purge;
  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Task)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new;

  # bless({...}, 'Example')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  ok !$result->name;
  ok !$result->version;

  $result
});

=example-2 new

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new(name => 'example');

  # bless({...}, 'Example')

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is $result->name, 'example';
  ok !$result->version;

  $result
});

=example-3 new

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new(name => 'example', version => '0.01');

  # bless({...}, 'Example')

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  is $result->name, 'example';
  is $result->version, '0.01';

  $result
});

=method perform

The perform method is the main method to override in a subclass and contains
the core CLI logic. This method returns the invocant.

=signature perform

  perform() (Venus::Task)

=metadata perform

{
  since => '4.15',
}

=example-1 perform

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  sub perform {
    my ($self) = @_;

    $self->log_info('hello world');

    return $self;
  }

  package main;

  my $task = Example->new;

  my $execute = $task->perform;

  # bless(..., 'Example')

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->isa('Venus::Task');
  my $output = $result->output_info_events;
  is_deeply $output, ['hello world'];

  Venus::Space->new('Example')->purge;
  $result
});

=example-2 perform

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  sub perform {
    my ($self) = @_;

    $self->log_error('oh no');

    return $self;
  }

  package main;

  my $task = Example->new;

  my $execute = $task->perform;

  # bless(..., 'Example')

=cut

$test->for('example', 2, 'perform', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->isa('Venus::Task');
  my $output = $result->output_error_events;
  is_deeply $output, ['oh no'];

  Venus::Space->new('Example')->purge;
  $result
});

=method prepare

The prepare method is the main method to override in a subclass, and is where
CLI arguments and options are configured. By default, this method registers a
single option: the help flag. This method returns the invocant.

=signature prepare

  prepare() (Venus::Task)

=metadata prepare

{
  since => '4.15',
}

=example-1 prepare

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  package main;

  my $task = Example->new;

  my $prepare = $task->prepare;

  # bless(..., 'Example')

=cut

$test->for('example', 1, 'prepare', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->isa('Venus::Task');
  my $options = $result->options;
  is_deeply $options, {
    'help' => {
      'aliases' => [],
      'default' => undef,
      'help' => 'Expects a boolean value',
      'index' => 0,
      'label' => undef,
      'multiples' => 0,
      'name' => 'help',
      'prompt' => undef,
      'range' => undef,
      'required' => 0,
      'type' => 'boolean',
      'wants' => 'boolean',
    }
  };

  Venus::Space->new('Example')->purge;
  $result
});

=example-2 prepare

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub name {
    'mycli'
  }

  sub prepare {
    my ($self) = @_;

    $self->option('help', {
      name => 'help',
      type => 'boolean',
    });

    $self->option('version', {
      name => 'version',
      aliases => ['v'],
      type => 'boolean',
    });

    return $self;
  }

  package main;

  my $task = Example->new;

  my $prepare = $task->prepare;

  # bless(..., 'Example')

=cut

$test->for('example', 2, 'prepare', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->isa('Venus::Task');
  my $options = $result->options;
  is_deeply $options, {
    'help' => {
      'aliases' => [],
      'default' => undef,
      'help' => 'Expects a boolean value',
      'index' => 0,
      'label' => undef,
      'multiples' => 0,
      'name' => 'help',
      'prompt' => undef,
      'range' => undef,
      'required' => 0,
      'type' => 'boolean',
      'wants' => 'boolean',
    },
    'version' => {
      'aliases' => ['v'],
      'default' => undef,
      'help' => 'Expects a boolean value',
      'index' => 1,
      'label' => undef,
      'multiples' => 0,
      'name' => 'version',
      'prompt' => undef,
      'range' => undef,
      'required' => 0,
      'type' => 'boolean',
      'wants' => 'boolean',
    },
  };

  Venus::Space->new('Example')->purge;
  $result
});

=method spec_data

The spec_data method returns a hashref to be passed to the L<Venus::Cli/spec>
method during L</prepare>. By default, this method returns C<undef>. Subclasses
should override this method to provide CLI configuration data.

=signature spec_data

  spec_data() (maybe[hashref])

=metadata spec_data

{
  since => '4.15',
}

=example-1 spec_data

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new;

  my $spec_data = $task->spec_data;

  # undef

=cut

$test->for('example', 1, 'spec_data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  Venus::Space->new('Example')->purge;
  !$result
});

=example-2 spec_data

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub spec_data {
    {
      name => 'example',
      version => '1.0.0',
      summary => 'Example CLI',
      options => [
        {
          name => 'verbose',
          type => 'boolean',
          aliases => ['v'],
        },
      ],
      commands => [
        ['command', 'run', 'handle_run'],
      ],
    }
  }

  sub handle_run {
    my ($self, $args, $opts) = @_;
    return 'running';
  }

  package main;

  my $task = Example->new;

  my $spec_data = $task->spec_data;

  # {
  #   name => 'example',
  #   version => '1.0.0',
  #   ...
  # }

=cut

$test->for('example', 2, 'spec_data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is ref($result), 'HASH';
  is $result->{name}, 'example';
  is $result->{version}, '1.0.0';

  Venus::Space->new('Example')->purge;
  $result
});

=example-3 spec_data

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  sub spec_data {
    {
      name => 'example',
      commands => [
        ['command', 'hello', 'handle_hello'],
      ],
    }
  }

  sub handle_hello {
    my ($self, $args, $opts) = @_;
    return 'hello world';
  }

  package main;

  my $task = Example->new;

  $task->prepare;

  my $result = $task->dispatch('hello');

  # "hello world"

=cut

$test->for('example', 3, 'spec_data', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'hello world';

  Venus::Space->new('Example')->purge;
  $result
});

=routine run

The run routine constructs a new class object using the name provided. This
routine automatically calls the L</handle> method if invoked from the
command-line.

=signature run

  run(string $name) (Venus::Task)

=metadata run

{
  since => '4.15',
}

=example-1 run

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->run('mycli');

  # bless(..., 'Example')

=cut

$test->for('example', 1, 'run', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Example');
  ok $result->isa('Venus::Task');
  is $result->name, 'mycli';

  Venus::Space->new('Example')->purge;
  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Task.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
