package Venus::Task::Venus::Set;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

# IMPORTS

use Venus::Config;
use Venus::Hash;

# INHERITS

base 'Venus::Task::Venus';

# REQUIRES

require Venus;

# METHODS

sub name {
  'vns set'
}

sub footer {

  return <<"EOF";
Copyright 2022-2023, Vesion $Venus::VERSION, The Venus "AUTHOR" and "CONTRIBUTORS"

More information on "vns" and/or the "Venus" standard library, visit
https://p3rl.org/vns.
EOF
}

sub perform {
  my ($self) = @_;

  my $file = $self->file;

  my $path = $self->argument_value('path');

  my $config = Venus::Hash->new(Venus::Config->read_file($file)->value);

  my ($value) = $config->gets($path);

  if (defined $value && ref $value) {
    $self->log_error("invalid path \"$path\"");

    return $self;
  }

  $value = $self->argument_value('value');

  if (defined $value) {
    $config->sets($path, $value);

    Venus::Config->new($config->value)->write_file($file);

    $self->log_info($value);
  }

  return $self;
}

sub prepare {
  my ($self) = @_;

  $self->summary('set values in the Venus configuration file');

  # path
  $self->argument('path', {
    name => 'path',
    help => 'Value path. Use dot-natotion. E.g. "perl.repl".',
    range => '0',
    multiples => 0,
    required => 1,
    type => 'string',
    wants => 'string',
  });

  # value
  $self->argument('value', {
    name => 'value',
    help => 'Path value. E.g. "perl -Ilib -dE0".',
    range => '1',
    multiples => 0,
    required => 1,
    type => 'string',
    wants => 'string',
  });

  # help
  $self->option('help', {
    name => 'help',
    help => 'Display the help text.',
    multiples => 0,
    required => 0,
    type => 'boolean',
    wants => 'boolean',
  });

  return $self;
}

1;


=head1 NAME

Venus::Task::Venus::Set - vns set

=cut

=head1 ABSTRACT

Task Class for Venus CLI

=cut

=head1 SYNOPSIS

  use Venus::Task::Venus::Set;

  my $task = Venus::Task::Venus::Set->new;

  # bless(..., "Venus::Task::Venus::Set")

=cut

=head1 DESCRIPTION

This package is a task class for the C<vns-set> CLI, and C<vns set>
sub-command.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Task::Venus>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 new

  new(any @args) (Venus::Task::Venus::Set)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Task::Venus::Set;

  my $task = Venus::Task::Venus::Set->new;

  # bless({...}, 'Venus::Task::Venus::Set')

=back

=cut

=head2 perform

  perform() (Venus::Task::Venus::Set)

The perform method executes the CLI logic.

I<Since C<4.15>>

=over 4

=item perform example 1

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.perl', '$PERL');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Set')

=back

=over 4

=item perform example 2

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.prove', '$PROVE');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Set')

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