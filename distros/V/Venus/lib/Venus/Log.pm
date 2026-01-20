package Venus::Log;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';

# STATE

state $NAME = {trace => 1, debug => 2, info => 3, warn => 4, error => 5, fatal => 6};
state $CODE = {reverse %$NAME};

# ATTRIBUTES

attr 'handler';
attr 'level';
attr 'separator';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    level => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  require Venus::Os;

  $self->level($self->level_name($self->level) || $self->level_name(1));
  $self->handler(sub{shift; Venus::Os->new->write('STDOUT', join '', @_, "\n")}) if !$self->handler;
  $self->separator(" ") if !$self->separator;

  return $self;
}

# METHODS

sub commit {
  my ($self, $level, @args) = @_;

  my $req_level = $self->level_code($level);
  my $set_level = $self->level_code($self->level);

  return ($req_level && $set_level && ($req_level >= $set_level))
    ? $self->write($level, $self->output($self->input(@args)))
    : $self;
}

sub debug {
  my ($self, @args) = @_;

  return $self->commit('debug', @args);
}

sub error {
  my ($self, @args) = @_;

  return $self->commit('error', @args);
}

sub fatal {
  my ($self, @args) = @_;

  return $self->commit('fatal', @args);
}

sub info {
  my ($self, @args) = @_;

  return $self->commit('info', @args);
}

sub input {
  my ($self, @args) = @_;

  return (@args);
}

sub level_code {
  my ($self, $data) = @_;

  $data = $data ? lc $data : $self->level;

  return undef if !defined $data;

  return $$NAME{$data} || ($$CODE{$data} && $$NAME{$$CODE{$data}});
}

sub level_name {
  my ($self, $data) = @_;

  $data = $data ? lc $data : $self->level;

  return undef if !defined $data;

  return $$CODE{$data} || ($$NAME{$data} && $$CODE{$$NAME{$data}});
}

sub output {
  my ($self, @args) = @_;

  return (join $self->separator, map $self->string($_), @args);
}

sub string {
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

sub trace {
  my ($self, @args) = @_;

  return $self->commit('trace', @args);
}

sub warn {
  my ($self, @args) = @_;

  return $self->commit('warn', @args);
}

sub write {
  my ($self, $level, @args) = @_;

  $self->handler->($level, @args);

  return $self;
}

1;



=head1 NAME

Venus::Log - Log Class

=cut

=head1 ABSTRACT

Log Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Log;

  my $log = Venus::Log->new;

  # $log->trace(time, 'Something failed!');

  # "0000000000 Something failed!"

  # $log->error(time, 'Something failed!');

  # "0000000000 Something failed!"

=cut

=head1 DESCRIPTION

This package provides methods for logging information using various log levels.
The default log level is L<trace>. Acceptable log levels are C<trace>,
C<debug>, C<info>, C<warn>, C<error>, and C<fatal>, and the set log level will
handle events for its level and any preceding levels in the order specified.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 handler

  handler(coderef $code) (coderef)

The handler attribute holds the callback that handles logging. The handler is
passed the log level and the log messages.

I<Since C<1.68>>

=over 4

=item handler example 1

  # given: synopsis

  package main;

  my $handler = $log->handler;

  my $events = [];

  $handler = $log->handler(sub{shift; push @$events, [@_]});

=back

=cut

=head2 level

  level(string $name) (string)

The level attribute holds the current log level. Valid log levels are C<trace>,
C<debug>, C<info>, C<warn>, C<error> and C<fatal>, and will emit log messages
in that order. Invalid log levels effectively disable logging.

I<Since C<1.68>>

=over 4

=item level example 1

  # given: synopsis

  package main;

  my $level = $log->level;

  # "trace"

  $level = $log->level('fatal');

  # "fatal"

=back

=cut

=head2 separator

  separator(any $data) (any)

The separator attribute holds the value used to join multiple log message arguments.

I<Since C<1.68>>

=over 4

=item separator example 1

  # given: synopsis

  package main;

  my $separator = $log->separator;

  # ""

  $separator = $log->separator("\n");

  # "\n"

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

=head2 debug

  debug(string @data) (Venus::Log)

The debug method logs C<debug> information and returns the invocant.

I<Since C<1.68>>

=over 4

=item debug example 1

  # given: synopsis

  package main;

  # $log = $log->debug(time, 'Something failed!');

  # "0000000000 Something failed!"

=back

=over 4

=item debug example 2

  # given: synopsis

  package main;

  # $log->level('info');

  # $log = $log->debug(time, 'Something failed!');

  # noop

=back

=cut

=head2 error

  error(string @data) (Venus::Log)

The error method logs C<error> information and returns the invocant.

I<Since C<1.68>>

=over 4

=item error example 1

  # given: synopsis

  package main;

  # $log = $log->error(time, 'Something failed!');

  # "0000000000 Something failed!"

=back

=over 4

=item error example 2

  # given: synopsis

  package main;

  # $log->level('fatal');

  # $log = $log->error(time, 'Something failed!');

  # noop

=back

=cut

=head2 fatal

  fatal(string @data) (Venus::Log)

The fatal method logs C<fatal> information and returns the invocant.

I<Since C<1.68>>

=over 4

=item fatal example 1

  # given: synopsis

  package main;

  # $log = $log->fatal(time, 'Something failed!');

  # "0000000000 Something failed!"

=back

=over 4

=item fatal example 2

  # given: synopsis

  package main;

  # $log->level('unknown');

  # $log = $log->fatal(time, 'Something failed!');

  # noop

=back

=cut

=head2 info

  info(string @data) (Venus::Log)

The info method logs C<info> information and returns the invocant.

I<Since C<1.68>>

=over 4

=item info example 1

  # given: synopsis

  package main;

  # $log = $log->info(time, 'Something failed!');

  # "0000000000 Something failed!"

=back

=over 4

=item info example 2

  # given: synopsis

  package main;

  # $log->level('warn');

  # $log = $log->info(time, 'Something failed!');

  # noop

=back

=cut

=head2 input

  input(string @data) (string)

The input method returns the arguments provided to the log level methods, to
the L</output>, and can be overridden by subclasses.

I<Since C<1.68>>

=over 4

=item input example 1

  # given: synopsis

  package main;

  my @input = $log->input(1, 'Something failed!');

  # (1, 'Something failed!')

=back

=cut

=head2 new

  new(string $level | any %args | hashref $args) (Venus::Log)

The new method returns a new instance of this package.

I<Since C<1.68>>

=over 4

=item new example 1

  package main;

  use Venus::Log;

  my $log = Venus::Log->new;

  # bless(..., "Venus::Log")

  # $log->level;

  # "trace"

=back

=over 4

=item new example 2

  package main;

  use Venus::Log;

  my $log = Venus::Log->new('error');

  # bless(..., "Venus::Log")

  # $log->level;

  # "error"

=back

=over 4

=item new example 3

  package main;

  use Venus::Log;

  my $log = Venus::Log->new(5);

  # bless(..., "Venus::Log")

  # $log->level;

  # "error"

=back

=cut

=head2 output

  output(string @data) (string)

The output method returns the arguments returned by the L</input> method, to
the log handler, and can be overridden by subclasses.

I<Since C<1.68>>

=over 4

=item output example 1

  # given: synopsis

  package main;

  my $output = $log->output(time, 'Something failed!');

  # "0000000000 Something failed!"

=back

=cut

=head2 string

  string(any $data) (string)

The string method returns a stringified representation of any argument provided
and is used by the L</output> method.

I<Since C<1.68>>

=over 4

=item string example 1

  # given: synopsis

  package main;

  my $string = $log->string;

  # ""

=back

=over 4

=item string example 2

  # given: synopsis

  package main;

  my $string = $log->string('Something failed!');

  # "Something failed!"

=back

=over 4

=item string example 3

  # given: synopsis

  package main;

  my $string = $log->string([1,2,3]);

  # [1,2,3]

=back

=over 4

=item string example 4

  # given: synopsis

  package main;

  my $string = $log->string(bless({}));

  # "bless({}, 'main')"

=back

=cut

=head2 trace

  trace(string @data) (Venus::Log)

The trace method logs C<trace> information and returns the invocant.

I<Since C<1.68>>

=over 4

=item trace example 1

  # given: synopsis

  package main;

  # $log = $log->trace(time, 'Something failed!');

  # "0000000000 Something failed!"

=back

=over 4

=item trace example 2

  # given: synopsis

  package main;

  # $log->level('debug');

  # $log = $log->trace(time, 'Something failed!');

  # noop

=back

=cut

=head2 warn

  warn(string @data) (Venus::Log)

The warn method logs C<warn> information and returns the invocant.

I<Since C<1.68>>

=over 4

=item warn example 1

  # given: synopsis

  package main;

  # $log = $log->warn(time, 'Something failed!');

  # "0000000000 Something failed!"

=back

=over 4

=item warn example 2

  # given: synopsis

  package main;

  # $log->level('error');

  # $log = $log->warn(time, 'Something failed!');

  # noop

=back

=cut

=head2 write

  write(string $level, any @data) (Venus::Log)

The write method invokes the log handler, i.e. L</handler>, and returns the invocant.

I<Since C<1.68>>

=over 4

=item write example 1

  # given: synopsis

  package main;

  # $log = $log->write('info', time, 'Something failed!');

  # bless(..., "Venus::Log")

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