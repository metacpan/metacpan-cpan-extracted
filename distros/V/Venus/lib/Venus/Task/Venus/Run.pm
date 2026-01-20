package Venus::Task::Venus::Run;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base';

# IMPORTS

use Venus::Run;

# INHERITS

base 'Venus::Task::Venus';

# REQUIRES

require Venus;

# METHODS

sub name {
  'vns run'
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

  my $run = Venus::Run->new;

  $run->result(@{$self->data});

  return $self;
}

sub prepare {
  my ($self) = @_;

  $self->summary('execute commands in the Venus configuration file');

  # name
  $self->argument('name', {
    name => 'name',
    help => 'The command to execute.',
    range => '0',
    required => 1,
    type => 'string',
    wants => 'string',
  });

  # args
  $self->argument('args', {
    name => 'args',
    help => 'The arguments provide to the command.',
    range => '1:',
    multiples => true,
    type => 'string',
    wants => 'string',
  });

  my $config = Venus::Config->read_file($self->file)->value;

  if ($config->{exec}) {
    for my $name (sort keys %{$config->{exec}}) {
      $self->choice($name, {
        name => $name,
        help => $config->{exec}->{$name},
        argument => 'name'
      });
    }
  }

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

Venus::Task::Venus::Run - vns run

=cut

=head1 ABSTRACT

Task Class for Venus CLI

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Task::Venus::Run;

  my $task = Venus::Task::Venus::Run->new;

  # bless(.., 'Venus::Task::Venus::Run')

=cut

=head1 DESCRIPTION

This package is a task class for the C<vns-run> CLI, and C<vns run>
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

  new(any @args) (Venus::Task::Venus::Run)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Task::Venus::Run;

  my $task = Venus::Task::Venus::Run->new;

  # bless({...}, 'Venus::Task::Venus::Run')

=back

=cut

=head2 perform

  perform() (Venus::Task::Venus::Run)

The perform method executes the CLI logic.

I<Since C<4.15>>

=over 4

=item perform example 1

  # given: synopsis

  package main;

  $task->prepare;

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

=back

=over 4

=item perform example 2

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('brew');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'perlbrew'

=back

=over 4

=item perform example 3

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('cpan', 'Venus');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'cpanm -llocal -qn Venus'

=back

=over 4

=item perform example 4

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('eval', 'say time');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # "perl -Ilib -Ilocal/lib/perl5 -MVenus=true,false,log -E 'say time'"

=back

=over 4

=item perform example 5

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('lint');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'perlcritic'

=back

=over 4

=item perform example 6

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('docs');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'perldoc'

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