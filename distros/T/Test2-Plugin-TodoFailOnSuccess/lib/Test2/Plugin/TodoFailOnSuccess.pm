package Test2::Plugin::TodoFailOnSuccess;

use strict;
use warnings;

# ABSTRACT: Report failure if a TODO test unexpectedly passes
our $VERSION = '0.0.2'; # VERSION

our $AUTHORITY = 'cpan:GSG';

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   package My::Tests;
#pod
#pod   use Test2::V0;
#pod
#pod   use Test2::Plugin::TodoFailOnSuccess;  # report unexpected TODO success
#pod
#pod   use Test2::Tools::Basic;    # for "todo" sub
#pod   use Test2::Todo;            # for "todo" object
#pod
#pod   sub test_something
#pod   {
#pod       # Lexical scope TODO:
#pod       #
#pod       {
#pod           my $todo = todo 'Not expected to pass';
#pod           is $value, $expected_value, "Got expected value";
#pod       }
#pod
#pod       # Coderef TODO:
#pod       #
#pod       todo 'Not expected to pass either' => sub {
#pod           is $value, $expected_value, "Got expected value";
#pod       };
#pod
#pod       # Object-oriented TODO:
#pod       #
#pod       my $todo = Test2::Todo->new( reason => 'Still not expected to pass' );
#pod       is $value, $expected_value, "Got expected value";
#pod       $todo->end;
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod Wrapping a test with TODO is a conventient way to avoid being tripped
#pod up by test failures until you have a chance to get the code working.
#pod It normally won't hurt to leave the TODO in place after the tests
#pod start passing, but if you forget to remove the TODO at that point,
#pod a subsequent code change could start causing new test failures which
#pod would then go unreported and possibly unnoticed.
#pod
#pod This module provides a mechanism to trigger explicit test failures
#pod when TODO tests unexpectedly pass, so that you have an opportunity
#pod to remove the TODO.
#pod
#pod If a TODO test passes, a failure will be reported with a message
#pod containing the test description, equivalent to doing:
#pod
#pod   fail "TODO passed unexpectedly: $test_description";
#pod
#pod which might appear in your TAP output along with the TODO reason as
#pod something like:
#pod
#pod   not ok 3 - TODO passed unexpectedly: Got expected value # TODO Not expected to pass
#pod
#pod Note that due to the additional C<fail> being reported, you may
#pod see messages about your planned number of tests being exceeded,
#pod for example:
#pod
#pod   # Did not follow plan: expected 5, ran 6.
#pod
#pod There are no options or arguments, just C<use Test2::Plugin::TodoFailOnSuccess>
#pod in your test file.
#pod
#pod =cut

use Test2::API qw(
    test2_add_callback_context_init
    test2_add_callback_context_release
);

my $PLUGIN_LOADED = 0;

sub import
{
    return if $PLUGIN_LOADED++;

    test2_add_callback_context_init   ( \&on_context_init    );
    test2_add_callback_context_release( \&on_context_release );
}

sub on_context_init
{
    my ($ctx) = @_;

    # Set up a listener on the hub to watch events going by,
    # looking for the ones that indicate a TODO test which passed:
    #
    $ctx->{_TodoFailOnSuccess_hub_listener} = $ctx->hub->listen(
        sub {
            my ($hub, $event, $number) = @_;

            my $facet_data = $event->facet_data;

            # Events inside a TODO will have amnesty (although will
            # need to verify the type of amnesty later):
            #
            my $amnesty_list = $facet_data->{amnesty};
            return unless $amnesty_list && @$amnesty_list;

            # Only interested if the event made an assertion which passed:
            #
            my $assert = $facet_data->{assert};
            return unless $assert && $assert->{pass};

            # Make sure at least one of the amnesty reasons
            # is because of TODO:
            #
            my %todo_reasons;
            foreach my $amnesty (@$amnesty_list) {
                next unless $amnesty->{tag} eq 'TODO';
                $todo_reasons{ $amnesty->{details} } = 1;
            }
            return unless keys %todo_reasons;

            my $details = $assert->{details};

            foreach my $todo_reason (sort keys %todo_reasons) {
                $ctx->fail(
                    qq{TODO passed unexpectedly: $details}
                );
            }
        },
        inherit => 1,
    );
}

sub on_context_release
{
    my ($ctx) = @_;

    my $hub_listener = delete $ctx->{_TodoFailOnSuccess_hub_listener};
    $ctx->hub->unlisten($hub_listener) if $hub_listener;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::TodoFailOnSuccess - Report failure if a TODO test unexpectedly passes

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

  package My::Tests;

  use Test2::V0;

  use Test2::Plugin::TodoFailOnSuccess;  # report unexpected TODO success

  use Test2::Tools::Basic;    # for "todo" sub
  use Test2::Todo;            # for "todo" object

  sub test_something
  {
      # Lexical scope TODO:
      #
      {
          my $todo = todo 'Not expected to pass';
          is $value, $expected_value, "Got expected value";
      }

      # Coderef TODO:
      #
      todo 'Not expected to pass either' => sub {
          is $value, $expected_value, "Got expected value";
      };

      # Object-oriented TODO:
      #
      my $todo = Test2::Todo->new( reason => 'Still not expected to pass' );
      is $value, $expected_value, "Got expected value";
      $todo->end;
  }

=head1 DESCRIPTION

Wrapping a test with TODO is a conventient way to avoid being tripped
up by test failures until you have a chance to get the code working.
It normally won't hurt to leave the TODO in place after the tests
start passing, but if you forget to remove the TODO at that point,
a subsequent code change could start causing new test failures which
would then go unreported and possibly unnoticed.

This module provides a mechanism to trigger explicit test failures
when TODO tests unexpectedly pass, so that you have an opportunity
to remove the TODO.

If a TODO test passes, a failure will be reported with a message
containing the test description, equivalent to doing:

  fail "TODO passed unexpectedly: $test_description";

which might appear in your TAP output along with the TODO reason as
something like:

  not ok 3 - TODO passed unexpectedly: Got expected value # TODO Not expected to pass

Note that due to the additional C<fail> being reported, you may
see messages about your planned number of tests being exceeded,
for example:

  # Did not follow plan: expected 5, ran 6.

There are no options or arguments, just C<use Test2::Plugin::TodoFailOnSuccess>
in your test file.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 CONTRIBUTORS

=for stopwords Larry Leszczynski Mark Flickinger

=over 4

=item *

Larry Leszczynski <Larry.Leszczynski@GrantStreet.com>

=item *

Mark Flickinger <mark.flickinger@grantstreet.com>

=back

=cut
