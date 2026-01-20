package Venus::Task;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base';

# INHERITS

base 'Venus::Cli';

# HOOKS

sub _stderr {
  require Venus::Os;

  return Venus::Os->new->write('STDERR', join "\n", @_, "");
}

sub _stdout {
  require Venus::Os;

  return Venus::Os->new->write('STDOUT', join "\n", @_, "");
}

# METHODS

sub execute {
  my ($self) = @_;

  my $errors = 0;

  $errors += $self->handle_help;

  $errors += $self->handle_errors_in_arguments if !$errors;

  $errors += $self->handle_errors_in_options if !$errors;

  $self->perform($self->assigned_options, $self->assigned_arguments) if !$errors;

  $errors += $self->handle_errors_in_log_events;

  return $errors ? $self->fail : $self->pass;
}

sub handle {
  my ($self, @args) = @_;

  $self->prepare->reorder->parse(@args ? @args : @{$self->data})->execute;

  return $self;
}

sub handle_errors_in_argument {
  my ($self, $name) = @_;

  my $errors = 0;

  for my $error ($self->argument_errors($name)) {
    if ($error->[0] eq 'required') {
      $self->log_error(qq(The argument "$name" is required));
    }
    elsif ($error->[0] eq 'type') {
      my $type = $error->[1][0];
      $self->log_error(qq(The argument "$name" expects a "$type"));
    }
    else {
      $self->log_error(qq(The argument "$name" is incorrect));
    }
    $errors++;
    last;
  }

  return $errors;
}

sub handle_errors_in_arguments {
  my ($self) = @_;

  my $errors = 0;

  for my $name ($self->argument_names) {
    $errors += $self->handle_errors_in_argument($name);
    last if $errors;
  }

  return $errors;
}

sub handle_errors_in_log_events {
  my ($self) = @_;

  my $errors = 0;

  my $events = $self->log_events;

  for my $event (@{$events}) {
    my ($level, $message) = @{$event};

    if ($level eq 'debug') {
      _stdout($message);
    }

    if ($level eq 'error') {
      _stderr($message); $errors++;
    }

    if ($level eq 'fatal') {
      _stderr($message); $errors++;
    }

    if ($level eq 'info') {
      _stdout($message);
    }

    if ($level eq 'trace') {
      _stdout($message);
    }

    if ($level eq 'warn') {
      _stderr($message); $errors++;
    }
  }

  return $errors;
}

sub handle_errors_in_option {
  my ($self, $name) = @_;

  my $errors = 0;

  for my $error ($self->option_errors($name)) {
    if ($error->[0] eq 'required') {
      $self->log_error(qq(The option "$name" is required));
    }
    elsif ($error->[0] eq 'type') {
      my $type = $error->[1][0];
      $self->log_error(qq(The option "$name" expects a "$type"));
    }
    else {
      $self->log_error(qq(The option "$name" is incorrect));
    }
    $errors++;
    last;
  }

  return $errors;
}

sub handle_errors_in_options {
  my ($self) = @_;

  my $errors = 0;

  for my $name ($self->option_names) {
    $errors += $self->handle_errors_in_option($name);
    last if $errors;
  }

  return $errors;
}

sub handle_help {
  my ($self) = @_;

  my $errors = 0;

  $self->help if $errors += $self->parsed->{help} ? 1 : 0;

  return $errors;
}

sub perform {
  my ($self) = @_;

  my $result = $self->dispatch;

  $self->help if !$result;

  return $self;
}

sub prepare {
  my ($self) = @_;

  my $spec_data = $self->spec_data;

  $self->option('help', {
    name => 'help',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  if ($spec_data && ref $spec_data eq 'HASH') {
    $self->spec($spec_data);
  }

  return $self;
}

sub spec_data {
  my ($self) = @_;

  return undef;
}

sub reorder {
  my ($self) = @_;

  my $option = $self->option('help');

  $option->{index} = $self->option_count + 1 if $option;

  $self->SUPER::reorder;

  return $self;
}

sub run {
  my ($self, $name) = @_;

  $name ||= $0;

  $self = $self->new(name => $name);

  $self->handle if !caller(1);

  return $self;
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

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new;

  # bless({...}, 'Example')

=cut

=head1 DESCRIPTION

This package provides a lightweight superclass and simple framework for
building command-line interfaces (CLIs) in Perl. It defines a consistent
structure and lifecycle for task execution, making it easy to create reusable
and maintainable CLI commands.

The framework operates in the following order:

=over 4

=item *

You assign the task a L<name|Venus::Cli/name>.

=item *

You invoke the L<handle/handle> method.

=item *

The L<handle|/handle> method calls L<prepare|/prepare> and then
L<execute|/execute>.

=item *

The L<prepare|/prepare> method is where CLI arguments and options are
configured. By default, L<prepare|/prepare> registers a single option: the
L<help|/help> flag.

=item *

The L<execute|/execute> method dispatches to the L<perform|/perform> method,
outputs to the terminal, and exits the application. Avoid overridding this
method because this is where automated error handling is done. If you need to
override this method, be sure to invoke C<SUPER> or similar to retain the core
behavior.

=item *

The L<perform|/perform> method is the main method to override in a subclass and
contains the core CLI logic. If the CLI is configured to support routing, be
sure to invoke C<SUPER> or similar to retain the core behavior.

=back

This structure encourages clean separation of configuration, execution, and
logic, making it easier to write and maintain CLI tools.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Cli>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute() (any)

The execute method dispatches to the L<perform> method, outputs to the
terminal, and exits the application.

I<Since C<4.15>>

=over 4

=item execute example 1

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

=back

=over 4

=item execute example 2

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

=back

=over 4

=item execute example 3

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

=back

=cut

=head2 handle

  handle(any @args) (Venus::Task)

The handle method executes the L<prepare|/prepare> method, and then
L<execute|/execute>. Optionally accepting a list of command-line arguments to
be parsed after "prepare" and before "execute", and if not provided will lazy
parse the data in C<@ARGV>.

I<Since C<4.15>>

=over 4

=item handle example 1

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

=back

=cut

=head2 handle_help

  handle_help() (boolean)

The handle_help method calls the L<Venus::Cli/help> method, outputting help
text, if a help flag was found (i.e. provided). This method returns true if a
help flag was found, and false otherwise.

I<Since C<4.15>>

=over 4

=item handle_help example 1

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

=back

=over 4

=item handle_help example 2

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

=back

=cut

=head2 new

  new(any @args) (Venus::Task)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new;

  # bless({...}, 'Example')

=back

=over 4

=item new example 2

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new(name => 'example');

  # bless({...}, 'Example')

=back

=over 4

=item new example 3

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new(name => 'example', version => '0.01');

  # bless({...}, 'Example')

=back

=cut

=head2 perform

  perform() (Venus::Task)

The perform method is the main method to override in a subclass and contains
the core CLI logic. This method returns the invocant.

I<Since C<4.15>>

=over 4

=item perform example 1

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

=back

=over 4

=item perform example 2

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

=back

=cut

=head2 prepare

  prepare() (Venus::Task)

The prepare method is the main method to override in a subclass, and is where
CLI arguments and options are configured. By default, this method registers a
single option: the help flag. This method returns the invocant.

I<Since C<4.15>>

=over 4

=item prepare example 1

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

=back

=over 4

=item prepare example 2

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

=back

=cut

=head2 spec_data

  spec_data() (maybe[hashref])

The spec_data method returns a hashref to be passed to the L<Venus::Cli/spec>
method during L</prepare>. By default, this method returns C<undef>. Subclasses
should override this method to provide CLI configuration data.

I<Since C<4.15>>

=over 4

=item spec_data example 1

  package Example;

  use Venus::Class 'base';

  base 'Venus::Task';

  package main;

  my $task = Example->new;

  my $spec_data = $task->spec_data;

  # undef

=back

=over 4

=item spec_data example 2

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

=back

=over 4

=item spec_data example 3

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