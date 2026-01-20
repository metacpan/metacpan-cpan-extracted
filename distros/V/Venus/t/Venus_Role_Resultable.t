package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Role::Resultable

=cut

$test->for('name');

=tagline

Resultable Role

=cut

$test->for('tagline');

=abstract

Resultable Role for Perl 5

=cut

$test->for('abstract');

=includes

method: result

=cut

$test->for('includes');

=synopsis

  package Example;

  use Venus::Class;

  with 'Venus::Role::Resultable';

  sub fail {
    die 'failed';
  }

  sub pass {
    return 'passed';
  }

  package main;

  my $example = Example->new;

  # $example->result('fail');

  # bless(..., "Venus::Result")

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->does('Venus::Role::Resultable');
  my $returned = $result->result('fail');
  ok $returned->isa('Venus::Result');
  like $returned->issue, qr/failed/;

  $result
});

=description

This package modifies the consuming package and provides a mechanism for
returning dynamically dispatched subroutine calls as L<Venus::Result> objects.

=cut

$test->for('description');

=method result

The result method dispatches to the named method or coderef provided and
returns a L<Venus::Result> object containing the error or return value
encountered.

=signature result

  result(string | coderef $callback, any @args) (Venus::Result)

=metadata result

{
  since => '4.15',
}

=example-1 result

  # given: synopsis;

  my $result = $example->result;

  # bless(..., "Venus::Result")

=cut

$test->for('example', 1, 'result', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, undef;

  $result
});

=example-2 result

  # given: synopsis;

  my $result = $example->result('pass');

  # bless(..., "Venus::Result")

=cut

$test->for('example', 2, 'result', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  is $result->issue, undef;
  is $result->value, 'passed';

  $result
});

=example-3 result

  # given: synopsis;

  my $result = $example->result('fail');

  # bless(..., "Venus::Result")

=cut

$test->for('example', 3, 'result', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Result');
  like $result->issue, qr/failed/;
  is $result->value, undef;

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Role/Resultable.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
