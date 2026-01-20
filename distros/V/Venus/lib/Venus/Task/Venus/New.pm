package Venus::Task::Venus::New;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

# IMPORTS

use Venus::Path;

# INHERITS

base 'Venus::Task::Venus';

# REQUIRES

require Venus;

# METHODS

sub name {
  'vns new'
}

sub execute {
  my ($self) = @_;

  return $self->Venus::Task::execute;
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

  my $type = $self->argument_value('type');

  my $file = $type ? ".vns.$type" : $self->file;

  my $path = Venus::Path->new($file)->absolute;

  $type = $path->extension;

  my $supported = grep {$type eq $_} qw(yaml yml json js perl pl);

  if (!$supported) {
    $self->log_error("$path invalid");

    return $self;
  }

  if ($path->exists) {
    $self->log_error("$path exists");

    return $self;
  }

  require Venus::Config;

  Venus::Config->new($self->init)->write_file($path);

  $self->log_info("$path created");

  return $self;
}

sub prepare {
  my ($self) = @_;

  $self->summary('initialize a new Venus configuration file');

  # type
  $self->argument('type', {
    name => 'type',
    help => 'Configuration file type. See "types" below.',
    multiples => 0,
    required => 0,
    type => 'string',
    wants => 'string',
  });

  # json
  $self->choice('json', {
    name => 'json',
    help => 'A JSON configuration file. E.g. .vns.json.',
    argument => 'type',
  });

  # js
  $self->choice('js', {
    name => 'js',
    help => 'A JSON configuration file. E.g. .vns.js.',
    argument => 'type',
  });

  # perl
  $self->choice('perl', {
    name => 'perl',
    help => 'A Perl configuration file. E.g. .vns.perl.',
    argument => 'type',
  });

  # pl
  $self->choice('pl', {
    name => 'pl',
    help => 'A Perl configuration file. E.g. .vns.pl.',
    argument => 'type',
  });

  # yaml
  $self->choice('yaml', {
    name => 'yaml',
    help => 'A YAML configuration file. E.g. .vns.yaml.',
    argument => 'type',
  });

  # yml
  $self->choice('yml', {
    name => 'yml',
    help => 'A YAML configuration file. E.g. .vns.yml.',
    argument => 'type',
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

Venus::Task::Venus::New - vns new

=cut

=head1 ABSTRACT

Task Class for Venus CLI

=cut

=head1 SYNOPSIS

  use Venus::Task::Venus::New;

  my $task = Venus::Task::Venus::New->new;

  # bless(.., 'Venus::Task::Venus::New')

=cut

=head1 DESCRIPTION

This package is a task class for the C<vns-new> CLI, and C<vns new>
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

  new(any @args) (Venus::Task::Venus::New)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Task::Venus::New;

  my $task = Venus::Task::Venus::New->new;

  # bless({...}, 'Venus::Task::Venus::New')

=back

=cut

=head2 perform

  perform() (Venus::Task::Venus::New)

The perform method executes the CLI logic.

I<Since C<4.15>>

=over 4

=item perform example 1

  # given: synopsis

  package main;

  $task->prepare;

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.pl file

=back

=over 4

=item perform example 2

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('pl');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.pl file

=back

=over 4

=item perform example 3

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.perl file

=back

=over 4

=item perform example 4

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('json');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.json file

=back

=over 4

=item perform example 5

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('js');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.js file

=back

=over 4

=item perform example 6

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('yaml');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.yaml file

=back

=over 4

=item perform example 7

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('yml');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.yml file

=back

=over 4

=item perform example 8

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('toml');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # Error: type "toml" invalid

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