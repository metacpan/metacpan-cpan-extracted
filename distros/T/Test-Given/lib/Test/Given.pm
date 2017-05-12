package Test::Given;
use strict;
use warnings;

use Test::Given::Context;
use Test::Given::Builder;

BEGIN {
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(describe context Given When Then And Invariant onDone has_failed);
}

use version; our $VERSION = qv('0.3.1');

my $context = Test::Given::Context->new('** TOPLEVEL **');
sub describe {
  my ($description, $sub) = @_;
  $context = $context->add_context($description);
  $sub->();
  $context = $context->parent();
}
*context = \&describe;

sub Given     { $context->add_given(@_) }
sub When      { $context->add_when(@_) }
sub Invariant { $context->add_invariant(@_) }
sub Then      { $context->add_then(@_) }
sub onDone    { $context->add_done(@_) }
sub And       { $context->add_and(@_) }

sub has_failed {
  my ($exceptions, $re) = @_;
  return '' unless $exceptions and $re;
  grep { $_ =~ $re } @$exceptions;
}

END {
  plan(tests => $context->test_count());
  $context->run_tests();
}

1;

__END__

=head1 NAME

Test::Given - Given/When/Then style testing for Perl.

=head1 SYNOPSIS

Given/When/Then style of testing inspired by L<rspec-given|https://github.com/jimweirich/rspec-given> and L<jasmine-given|https://github.com/searls/jasmine-given>.

Example:

    # t/example.t
    use Test::Given;
    use strict;
    use warnings;

    use Subject;

    # or no strict 'vars';
    our ($subject, $result);

    describe 'Subject Under Test' => sub {
      Given subject => sub { Subject->new() };

      When result => sub { $subject->state() };

      Invariant sub { defined $subject };

      Then sub { $result eq 'uninitialized' };

      context 'When used' => {
        Given sub { $subject->init() };

        When sub { $subject->use() };
        And result => sub { $subject->state() };

        Then sub { $result eq 'passed' };
        And sub { $result ne 'failed' };

        context 'and re-used' => sub {
          When sub { $subject->use() };

          Then sub { has_failed(shift, qr/cannot re-use/i) };
        };
      };
    };

    # prove -v --lib t/example.t

=head1 EXPORT

=head2 context

  describe 'description', \&sub
  context 'description', \&sub

Group and nest test steps.

=head2 Given

  Given \&sub
  Given 'name', \&sub

Code to run before each test. Use to setup test.

If name is given, assign result to symbol in current package. Assumes name is scalar unless a [@%&] sigil is included.

    Given name => sub { 1 };
    Given 'name' => sub { 1 };  # same as above
    Given '$name' => sub { 1 }; # same as above
    Given '@name' => sub { (1, 2, 3) };
    Given '%name' => sub { (a=>1, b=>2) };
    Given '&name' => sub { sub {1} };

Givens within a context are run in the order declared. Givens in outer contexts are run before ones in inner contexts.

Givens are run once per Then in the current and nested contexts.

Exceptions in a Given cause test script to abort.

=head2 When

  When \&sub
  When 'name', \&sub

Code to run before each test. Use to perform action under test.

Whens are run after all Givens of current and ancestor contexts.

The optional name parameter behaves the same as for Given.

Whens within a context are run in the order declared. Whens in outer contexts are run before ones in inner contexts.

Whens are run once per Then in the current and nested contexts.

Exceptions in a When are are caught, saved, and passed to each check.

=head2 Invariant

  Invariant \&sub

Check to include in each test. Use to reduce duplicate code within tests.

A false result or exception will cause the associated test to report failure.

Invariants within a context are run in the order declared. Invariants in outer contexts are run before ones in inner contexts.

Invariants are run once per Then in the current and nested contexts. They are run after the Then and its associated Ands.

See L</has_failed> for checking for exceptions.

=head2 Then

  Then \&sub

The main code of each test. Use to check state is as expected.

A false result or exception will cause the test to report failure.

Thens are run after all Whens of current and ancestor contexts.

Thens within a context are run in the order declared. Thens in outer contexts are run before ones in inner contexts.

Thens are run once and count as one test in the TAP output.

See L</has_failed> for checking for exceptions.

=head2 onDone

  onDone \&sub

Code to run after all tests complete within context. Use to clean up after tests.

onDones are run once in the order declared.

=head2 And

=head3 Given ...; And ...

=head3 When ...; And ...

=head3 Invariant ...; And ...

After a Given, When, or Invariant, 'And' is synonymous with the preceding term. In these cases, there is no difference between using the generic And and the more specific term.

=head3 Then ...; And ...

After a Then, 'And' adds a check to the preceding Then. It does not create a new test.

Ands after Thens are run once in the order declared. They run after the Then and before Invariants.

A false result or exception will cause the associated test to report failure.

See L</has_failed> for checking for exceptions.

=head2 has_failed

  has_failed \@exceptions, qr//

Helper method for Invariant, Then, and And (after Then) to check for exceptions thrown during execution of Whens. E.g.

    Invariant sub { has_failed(shift, qr/.../) };
    Then sub { has_failed(shift, qr/.../) };
    And sub { has_failed(shift, qr/.../) };

=head1 OUTPUT

Test output conforms to TAP (Test::Builder used under the hood).

Output includes describe/context descriptions when verbose is enabled (-v to prove).

Tests are named after the last line of the Then. The code has been decompiled at this point and may differ from the actual source. Contributions welcome.

To aid diagnosing failing tests, the output includes the decompiled source code of the failing Then, And, or Invariant with the starting line number and filename. If the last line looks like a comparison, an attempt is made to display the value of each side. Values of subexpressions are not included. Contributions welcome.

=head1 AUTHOR

Robert Juliano, C<< <rojuvano at gmail dot com> >>

=head1 CONTRIBUTING

Source code repository at L<https://github.com/rovjuvano/Test-Given>

Please report any bugs or feature requests via L<GitHub Issues|https://github.com/rovjuvano/Test-Given/issues> or L<CPAN RT|http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Given> or C<bug-test-given at rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Inspired by Jim Weirich's L<rspec-given|https://github.com/jimweirich/rspec-given> and Justin Searls's L<jasmine-given|https://github.com/searls/jasmine-given> and Matthew Boston's L<Test::More::Behaviour|https://github.com/bostonaholic/test-more-behaviour>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Robert Juliano.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
