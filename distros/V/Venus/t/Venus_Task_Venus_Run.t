package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Task::Venus::Run

=cut

$test->for('name');

=tagline

vns run

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

  package main;

  use Venus::Task::Venus::Run;

  my $task = Venus::Task::Venus::Run->new;

  # bless(.., 'Venus::Task::Venus::Run')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result;

  $result
});

=description

This package is a task class for the C<vns-run> CLI, and C<vns run>
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

  new(any @args) (Venus::Task::Venus::Run)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Task::Venus::Run;

  my $task = Venus::Task::Venus::Run->new;

  # bless({...}, 'Venus::Task::Venus::Run')

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Run');
  ok $result->isa('Venus::Task');

  $result
});

=method perform

The perform method executes the CLI logic.

=signature perform

  perform() (Venus::Task::Venus::Run)

=metadata perform

{
  since => '4.15',
}

=example-1 perform

  # given: synopsis

  package main;

  $task->prepare;

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

=cut

$test->for('example', 1, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Space;
  my $called;
  my $patched = Venus::Space->new('Venus::Run')->patch('_system', sub {
    my ($code, @args) = @_; $called = [@args]
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Run');
  is $called, undef;
  $patched->unpatch;

  $result
});

=example-2 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('brew');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'perlbrew'

=cut

$test->for('example', 2, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Space;
  my $called;
  my $patched = Venus::Space->new('Venus::Run')->patch('_system', sub {
    my ($code, @args) = @_; $called = [@args]
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Run');
  ok ref $called eq 'ARRAY';
  like $called->[0], qr/perlbrew/;
  $patched->unpatch;

  $result
});

=example-3 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('cpan', 'Venus');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'cpanm -llocal -qn Venus'

=cut

$test->for('example', 3, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Space;
  my $called;
  my $patched = Venus::Space->new('Venus::Run')->patch('_system', sub {
    my ($code, @args) = @_; $called = [@args]
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Run');
  ok ref $called eq 'ARRAY';
  like $called->[0], qr/cpanm/;
  like $called->[0], qr/-llocal/;
  like $called->[0], qr/-qn/;
  like $called->[0], qr/Venus/;
  $patched->unpatch;

  $result
});

=example-4 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('eval', 'say time');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # "perl -Ilib -Ilocal/lib/perl5 -MVenus=true,false,log -E 'say time'"

=cut

$test->for('example', 4, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Space;
  my $called;
  my $patched = Venus::Space->new('Venus::Run')->patch('_system', sub {
    my ($code, @args) = @_; $called = [@args]
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Run');
  ok ref $called eq 'ARRAY';
  like $called->[0], qr/perl/;
  like $called->[0], qr/-Ilib/;
  like $called->[0], qr/-Ilocal\/lib\/perl5/;
  like $called->[0], qr/-MVenus=true,false,log/;
  like $called->[0], qr/-E/;
  like $called->[0], qr/say time/;
  $patched->unpatch;

  $result
});

=example-5 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('lint');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'perlcritic'

=cut

$test->for('example', 5, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Space;
  my $called;
  my $patched = Venus::Space->new('Venus::Run')->patch('_system', sub {
    my ($code, @args) = @_; $called = [@args]
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Run');
  ok ref $called eq 'ARRAY';
  like $called->[0], qr/perlcritic/;
  $patched->unpatch;

  $result
});

=example-6 perform

  # given: synopsis

  package main;

  $task->prepare;

  $task->parse('docs');

  my $perform = $task->perform;

  # bless(.., 'Venus::Task::Venus::Run')

  # 'perldoc'

=cut

$test->for('example', 6, 'perform', sub {
  my ($tryable) = @_;
  require Venus::Space;
  my $called;
  my $patched = Venus::Space->new('Venus::Run')->patch('_system', sub {
    my ($code, @args) = @_; $called = [@args]
  });
  local $ENV{VENUS_FILE} = 't/conf/.vns.pl';
  my $result = $tryable->result;
  ok $result->isa('Venus::Task::Venus::Run');
  ok ref $called eq 'ARRAY';
  like $called->[0], qr/perldoc/;
  $patched->unpatch;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

$test->render('lib/Venus/Task/Venus/Run.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;