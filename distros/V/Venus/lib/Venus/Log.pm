package Venus::Log;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Buildable';

# ATTRIBUTES

attr 'handler';
attr 'level';
attr 'separator';

# STATE

state $NAME = {trace => 1, debug => 2, info => 3, warn => 4, error => 5, fatal => 6};
state $CODE = {reverse %$NAME};

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    level => $self->level_name($data) || $self->level_name(1),
  };
}

sub build_args {
  my ($self, $data) = @_;

  $data->{level} ||= $self->level_name(1);

  return $data;
}

sub build_self {
  my ($self, $data) = @_;

  $self->handler(sub{CORE::print(STDOUT @_, "\n")}) if !$self->handler;
  $self->separator(" ") if !$self->separator;

  return $self;
}

# METHODS

sub commit {
  my ($self, $level, @args) = @_;

  my $req_level = $self->level_code($level);
  my $set_level = $self->level_code($self->level);

  return ($req_level && $set_level && ($req_level >= $set_level))
    ? $self->write($self->output($self->input(@args)))
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

  return $$NAME{$data} || ($$CODE{$data} && $$NAME{$$CODE{$data}});
}

sub level_name {
  my ($self, $data) = @_;

  $data = $data ? lc $data : $self->level;

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
  my ($self, @args) = @_;

  $self->handler->(@args);

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

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 handler

  handler(CodeRef $code) (CodeRef)

The handler attribute holds the callback that handles logging.

I<Since C<1.68>>

=over 4

=item handler example 1

  # given: synopsis

  package main;

  my $handler = $log->handler;

  my $events = [];

  $handler = $log->handler(sub{push @$events, [@_]});

=back

=cut

=head2 level

  level(Str $name) (Str)

The level attribute holds the current log level.

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

  separator(Any $data) (Any)

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

  debug(Str @data) (Log)

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

  error(Str @data) (Log)

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

  fatal(Str @data) (Log)

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

  info(Str @data) (Log)

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

  input(Str @data) (Str)

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

=head2 output

  output(Str @data) (Str)

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

  string(Any $data) (Str)

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

  trace(Str @data) (Log)

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

  warn(Str @data) (Log)

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

  write(Any @data) (Log)

The write method invokes the log handler, i.e. L</handler>, and returns the invocant.

I<Since C<1.68>>

=over 4

=item write example 1

  # given: synopsis

  package main;

  # $log = $log->write(time, 'Something failed!');

  # bless(..., "Venus::Log")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut