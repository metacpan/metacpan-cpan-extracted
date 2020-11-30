use 5.014;

use strict;
use warnings;

use Test::Auto;
use Test::More;

=name

notice

=cut

=tagline

Breaking-Change Acknowledgement

=cut

=abstract

Breaking-Change Acknowledgement Enforcement

=cut

=includes

function: check

=cut

=synopsis

  package Example;

  BEGIN {
    $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;
  }

  use notice unstable => {
    space => 'Example',
    until => '2020-09-01',
    notes => 'See https://example.com/latest/release-notes',
  };

  1;

=cut

=description

This package provides a mechanism for enforcing breaking-change
acknowledgements. When configured under a module namespace, a fatal error
(notice) will be thrown prompting the operator to acknowledge the notice
(unless the notice has already been ackowledged). Notices are acknowledged by
setting a predetermined environment variable. The environment variable always
takes the form of C<ACK_NOTICE_CLASS_NOTICENAME>. The fatal error (notice) is
thrown whenever, the encapsulating package is I<"used">, the notice criteria is
met, and the environment variable is missing. Multiple notices can be
configured and each can have a time-based expiry aftewhich the notice will
never be triggered.

=cut

=function check

The check method returns truthy or falsy based upon whether the notice criteria
is met. When met, this function returns details about the trigger engaged.

=signature check

check(ClassName $name, Any %args) : Maybe[Tuple[Str, Str, Str, Str, Str | ArrayRef]]

=example-1 check

  # given: synopsis

  delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

  # notice: triggered (not acknowledged)

  notice::check('Example', (
    unstable => {
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));

=example-2 check

  # given: synopsis

  delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

  # notice: not triggered (notice expired)

  notice::check('Example', (
    unstable => {
      until => '2000-09-01',
      notes => 'see changelog',
    },
  ));

=example-3 check

  # given: synopsis

  delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

  # notice: triggered (not ackowledged)

  notice::check('Example::Agent', (
    unstable => {
      space => 'Example',
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));

=example-4 check

  # given: synopsis

  $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;

  # notice: triggered (refactor not ackowledged)

  notice::check('Example::Agent', (
    refactor => {
      space => 'Example',
      until => '9999-09-01',
      notes => 'see refactor',
    },
    unstable => {
      space => 'Example',
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));


=example-5 check

  # given: synopsis

  $ENV{ACK_NOTICE_EXAMPLE_REFACTOR} = 1;
  $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;

  # notice: not triggered (unstable and refactor ackowledged)

  notice::check('Example::Agent', (
    refactor => {
      space => 'Example',
      until => '9999-09-01',
      notes => 'see changelog',
    },
    unstable => {
      space => 'Example',
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));


=example-6 check

  # given: synopsis

  $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;

  # notice: triggered (wrong namespace ackowledged)

  notice::check('Example::Agent', (
    unstable => {
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));

=example-7 check

  # given: synopsis

  $ENV{ACK_NOTICE_EXAMPLE_AGENT_UNSTABLE} = 1;

  # notice: not triggered (notice ackowledged)

  notice::check('Example::Agent', (
    unstable => {
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));

=example-8 check

  # given: synopsis

  delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

  # notice: triggered (not ackowledged)

  notice::check('Example', (
    unstable => {
      until => '9999-09-01',
      notes => [
        'see release notes for details',
        'see https://example.com/latest/release-notes',
      ],
    },
  ));

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(sub {
  my $tryable = shift;

  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'check', 'function', sub {
  my $tryable = shift;

  ok my $result = $tryable->result;

  is_deeply $result, [
    'Example',
    'unstable',
    'ACK_NOTICE_EXAMPLE_UNSTABLE',
    '9999-09-01',
    'see changelog',
  ];

  $result
});

$subs->example(-2, 'check', 'function', sub {
  my $tryable = shift;

  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-3, 'check', 'function', sub {
  my $tryable = shift;

  ok my $result = $tryable->result;

  is_deeply $result, [
    'Example::Agent',
    'unstable',
    'ACK_NOTICE_EXAMPLE_UNSTABLE',
    '9999-09-01',
    'see changelog',
  ];

  $result
});

$subs->example(-4, 'check', 'function', sub {
  my $tryable = shift;

  ok my $result = $tryable->result;

  is_deeply $result, [
    'Example::Agent',
    'refactor',
    'ACK_NOTICE_EXAMPLE_REFACTOR',
    '9999-09-01',
    'see refactor',
  ];

  $result
});

$subs->example(-5, 'check', 'function', sub {
  my $tryable = shift;

  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-6, 'check', 'function', sub {
  my $tryable = shift;

  ok my $result = $tryable->result;

  is_deeply $result, [
    'Example::Agent',
    'unstable',
    'ACK_NOTICE_EXAMPLE_AGENT_UNSTABLE',
    '9999-09-01',
    'see changelog',
  ];

  $result
});

$subs->example(-7, 'check', 'function', sub {
  my $tryable = shift;

  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-8, 'check', 'function', sub {
  my $tryable = shift;

  ok my $result = $tryable->result;

  is_deeply $result, [
    'Example',
    'unstable',
    'ACK_NOTICE_EXAMPLE_UNSTABLE',
    '9999-09-01',
    [
      'see release notes for details',
      'see https://example.com/latest/release-notes',
    ],
  ];

  $result
});

ok 1 and done_testing;
