# -*- Mode: cperl; cperl-indent-level: 4 -*-
package Test::Run::Straps_GplArt;

use strict;
use warnings;

=head1 NAME

Test::Run::Straps - detailed analysis of test results

=head1 WARNING

This module contains nothing but old (and possibly out of date) documentation.
All the code-wise functionality was moved to the MIT X11-licensed
L<Test::Run::Straps> and other modules.

Don't use this module, but you may wish to consult its documentation for
reference.

=head1 SYNOPSIS

  use Test::Run::Straps;

  my $strap = Test::Run::Straps->new;

  # Various ways to interpret a test
  my $results = $strap->analyze($name, \@test_output);
  my $results = $strap->analyze_fh($name, $test_filehandle);
  my $results = $strap->analyze_file($test_file);

  # UNIMPLEMENTED
  my %total = $strap->total_results;

  # Altering the behavior of the strap  UNIMPLEMENTED
  my $verbose_output = $strap->dump_verbose();
  $strap->dump_verbose_fh($output_filehandle);


=head1 DESCRIPTION

B<THIS IS ALPHA SOFTWARE> in that the interface is subject to change
in incompatible ways.  It is otherwise stable.

Test::Run is limited to printing out its results.  This makes
analysis of the test results difficult for anything but a human.  To
make it easier for programs to work with test results, we provide
Test::Run::Straps.  Instead of printing the results, straps
provide them as raw data.  You can also configure how the tests are to
be run.

The interface is currently incomplete.  I<Please> contact the author
if you'd like a feature added or something change or just have
comments.

=head1 ANALYSIS

=cut



=head1 Parsing

Methods for identifying what sort of line you're looking at.

=cut

=head1 Results

The C<%results> returned from C<analyze()> contain the following
information:

  passing           true if the whole test is considered a pass
                    (or skipped), false if its a failure

  exit              the exit code of the test run, if from a file
  wait              the wait code of the test run, if from a file

  max               total tests which should have been run
  seen              total tests actually seen
  skip_all          if the whole test was skipped, this will
                      contain the reason.

  ok                number of tests which passed
                      (including todo and skips)

  todo              number of todo tests seen
  bonus             number of todo tests which
                      unexpectedly passed

  skip              number of tests skipped

So a successful test should have max == seen == ok.


There is one final item, the details.

  details           an array ref reporting the result of
                    each test looks like this:

    $results{details}[$test_num - 1] =
            { ok          => is the test considered ok?
              actual_ok   => did it literally say 'ok'?
              name        => name of the test (if any)
              diagnostics => test diagnostics (if any)
              type        => 'skip' or 'todo' (if any)
              reason      => reason for the above (if any)
            };

Element 0 of the details is test #1.  I tried it with element 1 being
#1 and 0 being empty, this is less awkward.

=head1 EXAMPLES

See F<examples/mini_harness.plx> for an example of use.

=head1 AUTHOR

Michael G Schwern C<< <schwern@pobox.com> >>, later maintained by
Andy Lester C<< <andy@petdance.com> >>.

Converted to Test::Run::Straps by Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 LICENSE

This file is distributed under the same terms as perl. (GPL2 or Later +
Artistic 1).

=head1 SEE ALSO

L<Test::Run> ,  L<Test::Run::Straps>

=cut

1;
