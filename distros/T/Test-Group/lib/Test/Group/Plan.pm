package Test::Group::Plan;
use strict;
use warnings;

=head1 NAME

Test::Group::Plan - test plans for test groups

=head1 SYNOPSIS

  use Test::Group;
  use Test::Group::Plan;

  test_plan 3, mytest => sub {
      ok 1, "one";
      ok 2, "two";
      ok 3, "three";
  };

=head1 DESCRIPTION

This module is an extension for L<Test::Group>.  It allows you to
declare the number of tests that a particular group will run.

If you are not already familiar with L<Test::Group> now would be
a good time to go take a look.

By default, L<Test::Group> doesn't care how many tests you run within
each group.  This is convenient, but sometimes you know how many tests
should be run, and a plan provides a useful extra check that your test
script is doing what you think it is.

=head1 EXPORTS

The following function is exported by default.

=head2 test_plan ($plan, $name, $groupsub)

As the test() function exported by L<Test::Group>, but with an additional
I<$plan> parameter.  The value of I<$plan> must be numeric.

An extra test will be run after I<$groupsub> returns, to check that
the number of tests run was as expected.  Note that you should B<not>
add 1 to the plan to account for this extra test.

=cut

use Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA     = qw(Exporter);
@EXPORT  = qw(test_plan);
$VERSION = '0.01';

use Test::Builder;
use Test::Group (); # keep this namespace clean

sub test_plan ($$&) {
    my $plan = shift;

    Test::Group::next_test_plugin {
        my $next = shift;

        my $before = Test::Group::_Runner->current->subtests;
        $next->();
        my $after = Test::Group::_Runner->current->subtests;
        my $count = $after - $before;

        my $T = Test::Builder->new;
        unless ($T->ok($count == $plan, "group test plan")) {
            $T->diag("  group planned $plan tests but ran $count");
        }
    };

    goto &Test::Group::test;
}

=head1 SEE ALSO

L<Test::Group>

=head1 AUTHORS

Nick Cleaton <ncleaton@cpan.org>

Dominique Quatravaux <domq@cpan.org>

=head1 LICENSE

Copyright (c) 2009 by Nick Cleaton and Dominique Quatravaux

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
