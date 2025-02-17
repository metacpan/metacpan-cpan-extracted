package Venus::Task;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Buildable';

require POSIX;

# ATTRIBUTES

attr 'data';
attr 'tryer';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    data => $data,
  };
}

sub build_args {
  my ($self, $args) = @_;

  my $data = $args->{data};

  $data = defined $data ? (ref $data eq 'ARRAY' ? $data : [$data]) : [@ARGV];

  $args->{data} = $data;

  return $args;
}

sub build_self {
  my ($self, $args) = @_;

  $self->tryer($self->try('execute')->maybe) if !$self->tryer;

  return $self;
}

# HOOKS

sub _exit {
  POSIX::_exit(shift);
}

sub _system {
  local $SIG{__WARN__} = sub {};
  CORE::system(@_) or return 0;
}

sub _print {
  CORE::print(@_);
}

# METHODS

sub args {
  my ($self) = @_;

  return {};
}

sub auto {
  my ($self, $code) = @_;

  my $CAN_RUN
    = $ENV{VENUS_TASK_AUTO} && (not(caller(1)) || scalar(caller(1)) eq 'main');

  return $self if !$CAN_RUN;

  $self = $self->class->new if !ref $self;

  $self->$code if $code;
  $self->tryer->result;

  return $self;
}

sub cli {
  my ($self) = @_;

  require Venus::Cli;

  return $self->{'$cli'} ||= Venus::Cli->new(data => $self->data);
}

sub cmds {
  my ($self) = @_;

  return {};
}

sub execute {
  my ($self) = @_;

  $self->prepare;

  my $parsed = $self->cli->parsed;

  $self->startup($parsed);
  $self->handler($parsed);
  $self->shutdown($parsed);

  return $self;
}

sub exit {
  my ($self, $code, $method, @args) = @_;

  my $result = $self->$method(@args) ? 0 : 1 if $method;

  $code //= $result // 0;

  _exit($code);
}

sub fail {
  my ($self, $method, @args) = @_;

  return $self->exit(1, $method, @args);
}

sub handler {
  my ($self, $data) = @_;

  $self->usage if $data->{help};

  return $self;
}

sub help {
  my ($self) = @_;

  return $self->cli->help;
}

sub log {
  my ($self) = @_;

  require Venus::Log;

  return $self->{'$log'} ||= Venus::Log->new(
    level => $self->log_level,
    handler => $self->defer('output')
  );
}

sub log_debug {
  my ($self, @args) = @_;

  return $self->log->debug(@args);
}

sub log_error {
  my ($self, @args) = @_;

  return $self->log->error(@args);
}

sub log_fatal {
  my ($self, @args) = @_;

  return $self->log->fatal(@args);
}

sub log_info {
  my ($self, @args) = @_;

  return $self->log->info(@args);
}

sub log_level {

  return 'info';
}

sub log_trace {
  my ($self, @args) = @_;

  return $self->log->trace(@args);
}

sub log_warn {
  my ($self, @args) = @_;

  return $self->log->warn(@args);
}

sub name {
  my ($self) = @_;

  return $0;
}

sub okay {
  my ($self, $method, @args) = @_;

  return $self->exit(0, $method, @args);
}

sub opts {
  my ($self) = @_;

  return {};
}

sub output {
  my ($self, $level, @data) = @_;

  local $|=1;

  _print(@data, "\n") if @data;

  return $self;
}

sub prepare {
  my ($self) = @_;

  my $cli = $self->cli;

  $cli->data($self->data);

  my $args = $self->args;
  my $cmds = $self->cmds;
  my $name = $self->name;
  my $opts = $self->opts;

  $cli->set('arg', $_, $args->{$_}) for sort keys %{$args};
  $cli->set('cmd', $_, $cmds->{$_}) for sort keys %{$cmds};
  $cli->set('opt', $_, $opts->{$_}) for sort keys %{$opts};

  $cli->set('str', 'name', $name) if !$cli->str('name') && $name;

  if ($self->can('description') && (my $description = $self->description)) {
    $cli->set('str', 'description', $description) if !$cli->str('description');
  }

  if ($self->can('header') && (my $header = $self->header)) {
    $cli->set('str', 'header', $header) if !$cli->str('header');
  }

  if ($self->can('footer') && (my $footer = $self->footer)) {
    $cli->set('str', 'footer', $footer) if !$cli->str('footer');
  }

  $self->log->do('level' => $self->log_level)->handler($self->defer('output'));

  return $self;
}

sub pass {
  my ($self, $method, @args) = @_;

  return $self->exit(0, $method, @args);
}

sub run {
  my ($self, @args) = @_;

  my $CAN_RUN
    = $ENV{VENUS_TASK_AUTO} && (not(caller(1)) || scalar(caller(1)) eq 'main');

  return $self if !$CAN_RUN;

  $self = $self->class->new if !ref $self;

  $self->tryer->result;

  return $self;
}

sub startup {
  my ($self, $data) = @_;

  return $self;
}

sub shutdown {
  my ($self, $data) = @_;

  return $self;
}

sub system {
  my ($self, @args) = @_;

  (_system(@args) == 0) or $self->error({
    throw => 'error_on_system_call',
    args => [@args],
    error => $?
  });

  return $self;
}

sub test {
  my ($self, @args) = @_;

  return $self->cli->test(@args);
}

sub usage {
  my ($self) = @_;

  $self->fail(sub{$self->log_info($self->help)});

  return $self;
}

# ERRORS

sub error_on_system_call {
  my ($self, $data) = @_;

  my $message = 'Can\'t make system call "{{command}}": {{error}}';

  my $stash = {
    args => $data->{args},
    command => (join ' ', @{$data->{args}}),
    error => $data->{error},
  };

  my $result = {
    name => 'on.system.call',
    raise => true,
    stash => $stash,
    message => $message,
  };

  return $result;
}

1;



=head1 NAME

Venus::Task - Task Class

=cut

=head1 ABSTRACT

Task Class for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use base 'Venus::Task';

  package main;

  my $task = Example->new(['--help']);

  # bless({...}, 'Example')

=cut

=head1 DESCRIPTION

This package provides a superclass, methods, and a simple framework for
creating CLIs (command-line interfaces).

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 data

  data(arrayref $data) (arrayref)

The data attribute is read-write, accepts C<(ArrayRef)> values, and is
optional.

I<Since C<2.91>>

=over 4

=item data example 1

  # given: synopsis

  package main;

  my $set_data = $task->data([1..4]);

  # [1..4]

=back

=over 4

=item data example 2

  # given: synopsis

  # given: example-1 data

  package main;

  my $get_data = $task->data;

  # [1..4]

=back

=cut

=head2 tryer

  tryer(Venus::Try $data) (Venus::Try)

The tryer attribute is read-write, accepts C<(Venus::Try)> values, and is
optional.

I<Since C<4.11>>

=over 4

=item tryer example 1

  # given: synopsis

  package main;

  my $set_tryer = $task->tryer($task->try('execute'));

  # bless(..., "Venus::Try")

=back

=over 4

=item tryer example 2

  # given: synopsis

  # given: example-1 tryer

  package main;

  my $get_tryer = $task->tryer;

  # bless(..., "Venus::Try")

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

=head2 args

  args() (hashref)

The args method can be overridden and returns a hashref suitable to be passed
to the L<Venus::Cli/set> method as type C<"arg">. An C<"arg"> is a CLI
positional argument.

I<Since C<2.91>>

=over 4

=item args example 1

  # given: synopsis

  package main;

  my $args = $task->args;

  # {}

=back

=over 4

=item args example 2

  package Example;

  use base 'Venus::Task';

  sub args {

    return {
      name => {
        help => 'Name of user',
      },
    }
  }

  package main;

  my $task = Example->new;

  my $args = $task->args;

  # {
  #   name => {
  #     help => 'Name of user',
  #   },
  # }

=back

=cut

=head2 auto

  auto(coderef $code) (Venus::Task)

The auto class method is similar to the L</run> method but accepts a callback
which will be invoked with the instansiated class before calling the
L</execute> method. This method is meant to be used directly in package scope
outside of any routine, and will only auto-execute under the conditions that
the caller is the "main" package space and the C<VENUS_TASK_AUTO> environment
variable is truthy.

I<Since C<4.11>>

=over 4

=item auto example 1

  package Example;

  use base 'Venus::Task';

  sub opts {

    return {
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  package main;

  my $task = Example->new(['--help']);

  my $auto = $task->auto(sub{});

  # bless({...}, 'Venus::Task')

=back

=over 4

=item auto example 2

  package Example;

  use base 'Venus::Task';

  sub opts {

    return {
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  auto Example sub {
    my ($self) = @_;
    $self->tryer->no_default;
  };

  # bless({...}, 'Venus::Task')

=back

=cut

=head2 cmds

  cmds() (hashref)

The cmds method can be overridden and returns a hashref suitable to be passed
to the L<Venus::Cli/set> method as type C<"cmd">. A C<"cmd"> is a CLI command
which maps to an positional argument declare by L</args>.

I<Since C<2.91>>

=over 4

=item cmds example 1

  # given: synopsis

  package main;

  my $cmds = $task->cmds;

  # {}

=back

=over 4

=item cmds example 2

  package Example;

  use base 'Venus::Task';

  sub args {

    return {
      op => {
        help => 'Name of operation',
      },
    }
  }

  sub cmds {

    return {
      init => {
        help => 'Initialize the system',
        arg => 'op',
      },
    }
  }

  package main;

  my $task = Example->new;

  my $cmds = $task->cmds;

  # {
  #   init => {
  #     help => 'Initialize the system',
  #     arg => 'op',
  #   },
  # }

=back

=cut

=head2 description

  description() (Venus::Task)

The description method doesn't exist on the L<Venus::Task> superclass but if
defined returns a string that will be used as the CLI "description" (before the
arguments, options, and commands text).

I<Since C<2.91>>

=over 4

=item description example 1

  package Example;

  use base 'Venus::Task';

  sub description {

    "This text used in the description area of the usage text"
  }

  package main;

  my $task = Example->new;

  my $description = $task->description;

  # "..."

=back

=cut

=head2 execute

  execute() (Venus::Task)

The execute method can be overridden and returns the invocant. This method
prepares the L<Venus::Cli> via L</prepare>, and runs the L</startup>,
L</handler>, and L</shutdown> sequences, passing L<Venus::Cli/parsed> to each
method. This method is not typically invoked directly, but instead by the
L</tryer> attribute via the L</run> or L</auto> class methods.

I<Since C<2.91>>

=over 4

=item execute example 1

  # given: synopsis

  package main;

  my $execute = $task->execute;

  # bless({...}, 'Venus::Task')

=back

=over 4

=item execute example 2

  package Example;

  use base 'Venus::Task';

  sub args {

    return {
      name => {
        help => 'Name of user',
      },
    }
  }

  sub opts {

    return {
      sudo => {
        help => 'Elevate user privileges',
        alias => ['s'],
      },
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  sub startup {
    my ($self) = @_;

    $self->{startup} = time;

    return $self;
  }

  sub handler {
    my ($self, $data) = @_;

    $self->{handler} = time;
    $self->{parsed} = $data;

    return $self;
  }

  sub shutdown {
    my ($self) = @_;

    $self->{shutdown} = time;

    return $self;
  }

  package main;

  my $task = Example->new(['admin', '-s']);

  my $execute = $task->execute;

  # bless({...}, 'Venus::Task')

=back

=over 4

=item execute example 3

  package Example;

  use base 'Venus::Task';

  sub args {

    return {
      name => {
        help => 'Name of user',
      },
    }
  }

  sub opts {

    return {
      sudo => {
        help => 'Elevate user privileges',
        alias => ['s'],
      },
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  sub handler {
    my ($self, $data) = @_;

    $self->{handler} = time;
    $self->{parsed} = $data;

    return $self;
  }

  package main;

  my $task = Example->new(['-s']);

  my $execute = $task->execute;

  # bless({...}, 'Venus::Task')

=back

=cut

=head2 exit

  exit(number $code, string | coderef $code, any @args) (any)

The exit method exits the program using the exit code provided. The exit code
defaults to C<0>. Optionally, you can dispatch before exiting by providing a
method name or coderef, and arguments. If an exit code of C<undef> is provided,
the exit code will be determined by the result of the dispatching.

I<Since C<2.91>>

=over 4

=item exit example 1

  # given: synopsis

  package main;

  my $exit = $task->exit;

  # ()

=back

=over 4

=item exit example 2

  # given: synopsis

  package main;

  my $exit = $task->exit(0);

  # ()

=back

=over 4

=item exit example 3

  # given: synopsis

  package main;

  my $exit = $task->exit(1);

  # ()

=back

=over 4

=item exit example 4

  # given: synopsis

  package main;

  my $exit = $task->exit(1, 'log_error', 'oh no');

  # ()

=back

=cut

=head2 fail

  fail(string | coderef $code, any @args) (any)

The fail method exits the program with the exit code C<1>. Optionally, you can
dispatch before exiting by providing a method name or coderef, and arguments.

I<Since C<2.91>>

=over 4

=item fail example 1

  # given: synopsis

  package main;

  my $fail = $task->fail;

  # ()

=back

=over 4

=item fail example 2

  # given: synopsis

  package main;

  my $fail = $task->fail('log_error', 'oh no');

  # ()

=back

=cut

=head2 footer

  footer() (Venus::Task)

The footer method doesn't exist on the L<Venus::Task> superclass but if defined
returns a string that will be used as the CLI "footer" (after the arguments,
options, and commands text).

I<Since C<2.91>>

=over 4

=item footer example 1

  package Example;

  use base 'Venus::Task';

  sub footer {

    "This text used in the footer area of the usage text"
  }

  package main;

  my $task = Example->new;

  my $footer = $task->footer;

  # "..."

=back

=cut

=head2 handler

  handler(hashref $data) (Venus::Task)

The handler method can and should be overridden and returns the invocant. This
method is where the central task operations are meant to happen. By default, if
not overriden this method calls L</usage> if a "help" flag is detected.

I<Since C<2.91>>

=over 4

=item handler example 1

  # given: synopsis

  package main;

  my $handler = $task->handler({});

  # bless({...}, 'Venus::Task')

=back

=over 4

=item handler example 2

  # given: synopsis

  package main;

  my $handler = $task->handler({help => 1});

  # bless({...}, 'Venus::Task')

=back

=over 4

=item handler example 3

  package Example;

  use base 'Venus::Task';

  sub handler {
    my ($self, $data) = @_;

    $self->{handler} = time;
    $self->{parsed} = $data;

    return $self;
  }

  package main;

  my $task = Example->new;

  my $handler = $task->handler({});

  # bless({...}, 'Venus::Task')

=back

=cut

=head2 header

  header() (Venus::Task)

The header method doesn't exist on the L<Venus::Task> superclass but if defined
returns a string that will be used as the CLI "header" (after the title, before
the arguments, options, and commands text).

I<Since C<2.91>>

=over 4

=item header example 1

  package Example;

  use base 'Venus::Task';

  sub header {

    "This text used in the header area of the usage text"
  }

  package main;

  my $task = Example->new;

  my $header = $task->header;

  # "..."

=back

=cut

=head2 help

  help() (string)

The help method can be overridden and returns a string representing "help" text
for the CLI. By default this method returns the result of L<Venus::Cli/help>,
based on the L</cli> object.

I<Since C<2.91>>

=over 4

=item help example 1

  # given: synopsis

  package main;

  my $help = $task->help;

  # "Usage: application"

=back

=over 4

=item help example 2

  package Example;

  use base 'Venus::Task';

  sub name {

    return 'eg';
  }

  package main;

  my $task = Example->new;

  $task->prepare;

  my $help = $task->help;

  # "Usage: application"

=back

=cut

=head2 log_debug

  log_debug(any @log_debug) (Venus::Log)

The log_debug method dispatches to the L<Venus::Log/debug> method and returns the
result.

I<Since C<2.91>>

=over 4

=item log_debug example 1

  # given: synopsis

  package main;

  my $log_debug = $task->log_debug('something' ,'happened');

  # bless({...}, 'Venus::Log')

=back

=cut

=head2 log_error

  log_error(any @log_error) (Venus::Log)

The log_error method dispatches to the L<Venus::Log/error> method and returns the
result.

I<Since C<2.91>>

=over 4

=item log_error example 1

  # given: synopsis

  package main;

  my $log_error = $task->log_error('something' ,'happened');

  # bless({...}, 'Venus::Log')

=back

=cut

=head2 log_fatal

  log_fatal(any @log_fatal) (Venus::Log)

The log_fatal method dispatches to the L<Venus::Log/fatal> method and returns the
result.

I<Since C<2.91>>

=over 4

=item log_fatal example 1

  # given: synopsis

  package main;

  my $log_fatal = $task->log_fatal('something' ,'happened');

  # bless({...}, 'Venus::Log')

=back

=cut

=head2 log_info

  log_info(any @log_info) (Venus::Log)

The log_info method dispatches to the L<Venus::Log/info> method and returns the
result.

I<Since C<2.91>>

=over 4

=item log_info example 1

  # given: synopsis

  package main;

  my $log_info = $task->log_info('something' ,'happened');

  # bless({...}, 'Venus::Log')

=back

=cut

=head2 log_level

  log_level() (string)

The log_level method can be overridden and returns a valid L<Venus::Log/level>
value. This method defaults to returning L<info>.

I<Since C<2.91>>

=over 4

=item log_level example 1

  # given: synopsis

  package main;

  my $log_level = $task->log_level;

  # "info"

=back

=cut

=head2 log_trace

  log_trace(any @log_trace) (Venus::Log)

The log_trace method dispatches to the L<Venus::Log/trace> method and returns the
result.

I<Since C<2.91>>

=over 4

=item log_trace example 1

  # given: synopsis

  package main;

  my $log_trace = $task->log_trace('something' ,'happened');

  # bless({...}, 'Venus::Log')

=back

=cut

=head2 log_warn

  log_warn(any @log_warn) (Venus::Log)

The log_warn method dispatches to the L<Venus::Log/warn> method and returns the
result.

I<Since C<2.91>>

=over 4

=item log_warn example 1

  # given: synopsis

  package main;

  my $log_warn = $task->log_warn('something' ,'happened');

  # bless({...}, 'Venus::Log')

=back

=cut

=head2 name

  name() (Venus::Task)

The name method can be overridden and returns the name of the task (and
application). This method defaults to C<$0> if not overridden.

I<Since C<2.91>>

=over 4

=item name example 1

  # given: synopsis

  package main;

  my $name = $task->name;

  # "/path/to/application"

=back

=over 4

=item name example 2

  package Example;

  use base 'Venus::Task';

  sub name {

    return 'eg';
  }

  package main;

  my $task = Example->new;

  my $name = $task->name;

  # "eg"

=back

=cut

=head2 okay

  okay(string | coderef $code, any @args) (any)

The okay method exits the program with the exit code C<0>. Optionally, you can
dispatch before exiting by providing a method name or coderef, and arguments.

I<Since C<2.91>>

=over 4

=item okay example 1

  # given: synopsis

  package main;

  my $okay = $task->okay;

  # ()

=back

=over 4

=item okay example 2

  # given: synopsis

  package main;

  my $okay = $task->okay('log_info', 'yatta');

  # ()

=back

=cut

=head2 opts

  opts() (hashref)

The opts method can be overridden and returns a hashref suitable to be passed
to the L<Venus::Cli/set> method as type C<"opt">. An C<"opt"> is a CLI option
(or flag).

I<Since C<2.91>>

=over 4

=item opts example 1

  # given: synopsis

  package main;

  my $opts = $task->opts;

  # {}

=back

=over 4

=item opts example 2

  package Example;

  use base 'Venus::Task';

  sub opts {

    return {
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  package main;

  my $task = Example->new;

  my $opts = $task->opts;

  # {
  #   help => {
  #     help => 'Display help',
  #     alias => ['h'],
  #   },
  # }

=back

=cut

=head2 output

  output(string $level, string @messages) (Venus::Task)

The output method is configured as the L<Venus::Log/handler> by L</prepare>,
can be overridden and returns the invocant.

I<Since C<2.91>>

=over 4

=item output example 1

  # given: synopsis

  package main;

  $task->prepare;

  $task = $task->output('info', 'something happened');

  # bless({...}, 'Example')

=back

=cut

=head2 pass

  pass(string | coderef $code, any @args) (any)

The pass method exits the program with the exit code C<0>. Optionally, you can
dispatch before exiting by providing a method name or coderef, and arguments.

I<Since C<3.10>>

=over 4

=item pass example 1

  # given: synopsis

  package main;

  my $pass = $task->pass;

  # ()

=back

=over 4

=item pass example 2

  # given: synopsis

  package main;

  my $pass = $task->pass('log_info', 'yatta');

  # ()

=back

=cut

=head2 prepare

  prepare() (Venus::Task)

The prepare method can be overridden, but typically shouldn't, is responsible
for configuring the L</cli> and L</log> objects, parsing the arguments, and
after returns the invocant.

I<Since C<2.91>>

=over 4

=item prepare example 1

  # given: synopsis

  package main;

  my $prepare = $task->prepare;

  # bless({...}, 'Venus::Task')

=back

=over 4

=item prepare example 2

  package Example;

  use base 'Venus::Task';

  sub args {

    return {
      name => {
        help => 'Name of user',
      },
    }
  }

  sub opts {

    return {
      sudo => {
        help => 'Elevate user privileges',
        alias => ['s'],
      },
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  package main;

  my $task = Example->new;

  my $prepare = $task->prepare;

  # bless({...}, 'Venus::Task')

=back

=over 4

=item prepare example 3

  package Example;

  use base 'Venus::Task';

  sub args {

    return {
      name => {
        help => 'Name of user',
      },
    }
  }

  sub cmds {

    return {
      admin => {
        help => 'Run as an admin',
        arg => 'name',
      },
      user => {
        help => 'Run as a user',
        arg => 'name',
      },
    }
  }

  sub opts {

    return {
      sudo => {
        help => 'Elevate user privileges',
        alias => ['s'],
      },
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  package main;

  my $task = Example->new(['admin', '-s']);

  my $prepare = $task->prepare;

  # bless({...}, 'Venus::Task')

=back

=cut

=head2 run

  run(any @args) (Venus::Task)

The run class method will automatically execute the task class by instansiating
the class and calling the L</execute> method and returns the invocant. This
method is meant to be used directly in package scope outside of any routine,
and will only auto-execute under the conditions that the caller is the "main"
package space and the C<VENUS_TASK_AUTO> environment variable is truthy.

I<Since C<2.91>>

=over 4

=item run example 1

  package Example;

  use base 'Venus::Task';

  sub opts {

    return {
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  package main;

  my $task = Example->new(['--help']);

  my $run = $task->run;

  # bless({...}, 'Venus::Task')

=back

=over 4

=item run example 2

  package Example;

  use base 'Venus::Task';

  sub opts {

    return {
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  run Example;

  # 'Example'

=back

=cut

=head2 shutdown

  shutdown(hashref $data) (Venus::Task)

The shutdown method can be overridden and returns the invocant. This method is
called by L</execute> automatically after L</handler> and is passed the result
of L<Venus::Cli/parsed>.

I<Since C<2.91>>

=over 4

=item shutdown example 1

  # given: synopsis

  package main;

  my $shutdown = $task->shutdown({});

  # bless({...}, 'Venus::Task')

=back

=cut

=head2 startup

  startup(hashref $data) (Venus::Task)

The startup method can be overridden and returns the invocant. This method is
called by L</execute> automatically after L</prepare> and before L</handler>,
and is passed the result of L<Venus::Cli/parsed>.

I<Since C<2.91>>

=over 4

=item startup example 1

  # given: synopsis

  package main;

  my $startup = $task->startup({});

  # bless({...}, 'Venus::Task')

=back

=cut

=head2 system

  system(string @args) (Venus::Task)

The system method attempts to make a L<perlfunc/system> call and returns the
invocant. If the system call is unsuccessful an error is thrown.

I<Since C<2.91>>

=over 4

=item system example 1

  # given: synopsis

  package main;

  my $system = $task->system($^X, '-V');

  # bless({...},  'Example')

=back

=over 4

=item system example 2

  # given: synopsis

  package main;

  my $system = $task->system('/path/to/nowhere');

  # Exception! (isa Example::Error) (see error_on_system_call)

=back

=cut

=head2 test

  test(string $type, string $name) (any)

The test method validates the values for the C<arg> or C<opt> specified and
returns the value(s) associated. This method dispatches to L<Venus::Cli/test>.

I<Since C<3.10>>

=over 4

=item test example 1

  package Example;

  use base 'Venus::Task';

  sub opts {

    return {
      help => {
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  package main;

  my $task = Example->new(['--help']);

  my ($help) = $task->prepare->test('opt', 'help');

  # true

=back

=over 4

=item test example 2

  package Example;

  use base 'Venus::Task';

  sub opts {

    return {
      help => {
        type => 'string',
        help => 'Display help',
        alias => ['h'],
      },
    }
  }

  package main;

  my $task = Example->new(['--help']);

  my ($help) = $task->prepare->test('opt', 'help');

  # Exception! (isa Venus::Cli::Error) (see error_on_arg_validation)

  # Invalid option: help: received (undef), expected (string)

=back

=cut

=head2 usage

  usage() (Venus::Task)

The usage method exits the program with the exit code C<1> after calling
L</log_info> with the result of L</help>. This method makes it easy to output
the default help text and end the program if some condition isn't met.

I<Since C<2.91>>

=over 4

=item usage example 1

  # given: synopsis

  package main;

  my $usage = $task->usage;

  # bless({...}, 'Venus::Task')

=back

=cut

=head1 ERRORS

This package may raise the following errors:

=cut

=over 4

=item error: C<error_on_system_call>

This package may raise an error_on_system_call exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_system_call',
    args => ['/path/to/nowhere', 'arg1', 'arg2'],
    error => $?,
  };

  my $error = $task->catch('error', $input);

  # my $name = $error->name;

  # "on_system_call"

  # my $message = $error->render;

  # "Can't make system call \"/path/to/nowhere arg1 arg2\": $?"

  # my $args = $error->stash('args');

  # []

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut