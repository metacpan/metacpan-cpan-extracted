package notice;

use 5.014;

use strict;
use warnings;

use Carp;
use Time::Piece;

our $VERSION = '0.01'; # VERSION

# FUNCTIONS

sub import {
  my ($class, %args) = @_;

  return if exists $ENV{ACK_NOTICE};

  notice(scalar(caller), %args);

  return;
}

sub check {
  my ($class, %args) = @_;

  for my $name (sort keys %args) {
    my %config = %{$args{$name}};
    my $until = $config{until} or next;
    my $varname = envvar($config{space} || $class, $name);
    next if time > timepiece($until)->epoch;
    next if exists $ENV{$varname};
    return [$class, $name, $varname, $until, $config{notes}];
  }

  return;
}

sub envvar {
  my ($class, $name) = @_;

  my $string = join '_', 'ack', 'notice', map {s/[^a-zA-Z0-9]+/_/gr} $class, $name;

  return uc($string);
}

sub message {
  my ($class, $name, $varname, $expiry, $notes) = @_;

  return "Unacknowledged notice for $class ($name):\n".
  ($notes ? (ref($notes) ? (join("", map "- $_\n", @$notes)) : "- $notes\n") : "").
  "- Notice can be supressed by setting the \"$varname\" environment variable\n".
  "- Notice expires after $expiry\n"
}

sub notice {
  my ($class, %args) = @_;

  my $found = check($class, %args) or return;

  croak(message(@$found));

  return;
}

sub timepiece {
  my ($time) = @_;

  return Time::Piece->strptime($time, timeformat());
}

sub timeformat {
  return '%Y-%m-%d';
}

1;
=encoding utf8

=head1 NAME

notice - Breaking-Change Acknowledgement

=cut

=head1 ABSTRACT

Breaking-Change Acknowledgement Enforcement

=cut

=head1 SYNOPSIS

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

=head1 DESCRIPTION

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

=head1 FUNCTIONS

This package implements the following functions:

=cut

=head2 check

  check(ClassName $name, Any %args) : Maybe[Tuple[Str, Str, Str, Str, Str | ArrayRef]]

The check method returns truthy or falsy based upon whether the notice criteria
is met. When met, this function returns details about the trigger engaged.

=over 4

=item check example #1

  # given: synopsis

  delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

  # notice: triggered (not acknowledged)

  notice::check('Example', (
    unstable => {
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));

=back

=over 4

=item check example #2

  # given: synopsis

  delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

  # notice: not triggered (notice expired)

  notice::check('Example', (
    unstable => {
      until => '2000-09-01',
      notes => 'see changelog',
    },
  ));

=back

=over 4

=item check example #3

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

=back

=over 4

=item check example #4

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

=back

=over 4

=item check example #5

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

=back

=over 4

=item check example #6

  # given: synopsis

  $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;

  # notice: triggered (wrong namespace ackowledged)

  notice::check('Example::Agent', (
    unstable => {
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));

=back

=over 4

=item check example #7

  # given: synopsis

  $ENV{ACK_NOTICE_EXAMPLE_AGENT_UNSTABLE} = 1;

  # notice: not triggered (notice ackowledged)

  notice::check('Example::Agent', (
    unstable => {
      until => '9999-09-01',
      notes => 'see changelog',
    },
  ));

=back

=over 4

=item check example #8

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

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/notice/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/notice/wiki>

L<Project|https://github.com/iamalnewkirk/notice>

L<Initiatives|https://github.com/iamalnewkirk/notice/projects>

L<Milestones|https://github.com/iamalnewkirk/notice/milestones>

L<Contributing|https://github.com/iamalnewkirk/notice/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/notice/issues>

=cut