package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Task::Venus::New

=cut

$test->for('name');

=tagline

vns new

=cut

$test->for('tagline');

=abstract

Task Class for Venus CLI

=cut

$test->for('abstract');

=includes

method: new
method: perform

=cut

=synopsis

  use Venus::Task::Venus::New;

  my $task = Venus::Task::Venus::New->new;

  # bless(.., 'Venus::Task::Venus::New')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::New');

  $result
});

=description

This package is a task class for the C<vns-new> CLI, and C<vns new>
sub-command.

=cut

$test->for('description');

=inherits

Venus::Task::Venus

=cut

$test->for('inherits');

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Task::Venus::New)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Task::Venus::New;

  my $task = Venus::Task::Venus::New->new;

  # bless({...}, 'Venus::Task::Venus::New')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::New');
  ok $result->isa('Venus::Task');

  $result
});

=method perform

The perform method executes the CLI logic.

=signature perform

  perform() (Venus::Task::Venus::New)

=metadata perform

{
  since => '4.15',
}

=example-1 perform

  # given: synopsis

  package main;

  $task->prepare;

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.pl file

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  my $file = '.vns.pl';
  my $exists = -f $file ? true : false;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::New');
  my $log_events = $result->log_events;
  ok @{$log_events};
  if ($exists) {
    is $log_events->[0][0], 'error';
    like $log_events->[0][1], qr/$file exists/;
  }
  else {
    is $log_events->[0][0], 'info';
    like $log_events->[0][1], qr/$file created/;
  }
  require Venus::Path;
  Venus::Path->new($file)->unlink if !$exists;

  $result
});

=example-2 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('pl');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.pl file

=cut

$test->for('example', 2, 'perform', sub {
  my ($tryable) = @_;
  my $file = '.vns.pl';
  my $exists = -f $file ? true : false;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::New');
  my $log_events = $result->log_events;
  ok @{$log_events};
  if ($exists) {
    is $log_events->[0][0], 'error';
    like $log_events->[0][1], qr/$file exists/;
  }
  else {
    is $log_events->[0][0], 'info';
    like $log_events->[0][1], qr/$file created/;
  }
  require Venus::Path;
  Venus::Path->new($file)->unlink if !$exists;

  $result
});

=example-3 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('perl');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.perl file

=cut

$test->for('example', 3, 'perform', sub {
  my ($tryable) = @_;
  my $file = '.vns.perl';
  my $exists = -f $file ? true : false;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::New');
  my $log_events = $result->log_events;
  ok @{$log_events};
  if ($exists) {
    is $log_events->[0][0], 'error';
    like $log_events->[0][1], qr/$file exists/;
  }
  else {
    is $log_events->[0][0], 'info';
    like $log_events->[0][1], qr/$file created/;
  }
  require Venus::Path;
  Venus::Path->new($file)->unlink if !$exists;

  $result
});

=example-4 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('json');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.json file

=cut

$test->for('example', 4, 'perform', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Json && not Venus::Json->package) {
    diag 'No suitable JSON library found' if $ENV{VENUS_DEBUG};
    $result = true;
    ok 1;
  }
  else {
    my $file = '.vns.json';
    my $exists = -f $file ? true : false;
    $result = $tryable->result;
    ok $result->isa('Venus::Task::Venus::New');
    my $log_events = $result->log_events;
    ok @{$log_events};
    if ($exists) {
      is $log_events->[0][0], 'error';
      like $log_events->[0][1], qr/$file exists/;
    }
    else {
      is $log_events->[0][0], 'info';
      like $log_events->[0][1], qr/$file created/;
    }
    require Venus::Path;
    Venus::Path->new($file)->unlink if !$exists;
  }

  $result
});

=example-5 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('js');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.js file

=cut

$test->for('example', 5, 'perform', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Json && not Venus::Json->package) {
    diag 'No suitable JSON library found' if $ENV{VENUS_DEBUG};
    $result = true;
    ok 1;
  }
  else {
    my $file = '.vns.js';
    my $exists = -f $file ? true : false;
    $result = $tryable->result;
    ok $result->isa('Venus::Task::Venus::New');
    my $log_events = $result->log_events;
    ok @{$log_events};
    if ($exists) {
      is $log_events->[0][0], 'error';
      like $log_events->[0][1], qr/$file exists/;
    }
    else {
      is $log_events->[0][0], 'info';
      like $log_events->[0][1], qr/$file created/;
    }
    require Venus::Path;
    Venus::Path->new($file)->unlink if !$exists;
  }

  $result
});

=example-6 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('yaml');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.yaml file

=cut

$test->for('example', 6, 'perform', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Yaml && not Venus::Yaml->package) {
    diag 'No suitable YAML library found' if $ENV{VENUS_DEBUG};
    $result = true;
    ok 1;
  }
  else {
    my $file = '.vns.yaml';
    my $exists = -f $file ? true : false;
    $result = $tryable->result;
    ok $result->isa('Venus::Task::Venus::New');
    my $log_events = $result->log_events;
    ok @{$log_events};
    if ($exists) {
      is $log_events->[0][0], 'error';
      like $log_events->[0][1], qr/$file exists/;
    }
    else {
      is $log_events->[0][0], 'info';
      like $log_events->[0][1], qr/$file created/;
    }
    require Venus::Path;
    Venus::Path->new($file)->unlink if !$exists;
  }

  $result
});

=example-7 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('yml');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # creates a .vns.yml file

=cut

$test->for('example', 7, 'perform', sub {
  my ($tryable) = @_;
  my $result;
  if (require Venus::Yaml && not Venus::Yaml->package) {
    diag 'No suitable YAML library found' if $ENV{VENUS_DEBUG};
    $result = true;
    ok 1;
  }
  else {
    my $file = '.vns.yml';
    my $exists = -f $file ? true : false;
    $result = $tryable->result;
    ok $result->isa('Venus::Task::Venus::New');
    my $log_events = $result->log_events;
    ok @{$log_events};
    if ($exists) {
      is $log_events->[0][0], 'error';
      like $log_events->[0][1], qr/$file exists/;
    }
    else {
      is $log_events->[0][0], 'info';
      like $log_events->[0][1], qr/$file created/;
    }
    require Venus::Path;
    Venus::Path->new($file)->unlink if !$exists;
  }

  $result
});

=example-8 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('toml');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::New')

  # Error: type "toml" invalid

=cut

$test->for('example', 8, 'perform', sub {
  my ($tryable) = @_;
  my $file = '.vns.toml';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::New');
  my $log_events = $result->log_events;
  ok @{$log_events};
  is $log_events->[0][0], 'error';
  like $log_events->[0][1], qr/$file invalid/;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Task/Venus/New.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;