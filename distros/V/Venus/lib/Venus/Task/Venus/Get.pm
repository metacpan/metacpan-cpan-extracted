package Venus::Task::Venus::Get;

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
  'vns get'
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

  $self->log_info($value) if defined $value;

  return $self;
}

sub prepare {
  my ($self) = @_;

  $self->summary('get values in the Venus configuration file');

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

Venus::Task::Venus::Get - vns get

=cut

=head1 ABSTRACT

Task Class for Venus CLI

=cut

=head1 SYNOPSIS

  use Venus::Task::Venus::Get;

  my $task = Venus::Task::Venus::Get->new;

  # bless(..., "Venus::Task::Venus::Get")

=cut

=head1 DESCRIPTION

This package is a task class for the C<vns-get> CLI, and C<vns get>
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

  new(any @args) (Venus::Task::Venus::Get)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Task::Venus::Get;

  my $task = Venus::Task::Venus::Get->new;

  # bless({...}, 'Venus::Task::Venus::Get')

=back

=cut

=head2 perform

  perform() (Venus::Task::Venus::Get)

The perform method executes the CLI logic.

I<Since C<4.15>>

=over 4

=item perform example 1

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.perl');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Get')

=back

=over 4

=item perform example 2

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl.prove');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Get')

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