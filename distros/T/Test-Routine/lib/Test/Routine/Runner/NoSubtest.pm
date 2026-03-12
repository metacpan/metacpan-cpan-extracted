use v5.12.0;
package Test::Routine::Runner::NoSubtest 0.032;
# ABSTRACT: tools for running Test::Routine tests (without using a subtest)

use Moose;
extends 'Test::Routine::Runner';

#pod =head1 OVERVIEW
#pod
#pod This is just a L<Test::Routine::Runner>, but when you call C<run>, it won't
#pod wrap the whole thing in a subtest.  If you use multiple instances of a
#pod Test::Routine object in testing -- constructing it with different parameters
#pod for several runs, for example -- this will lead to heartache.  If your test is
#pod just a single run, though, getting rid of that top-level subtest can simplify
#pod your life.
#pod
#pod Also: if no tests will be run, generally because the C<TEST_METHOD> environment
#pod variable didn't select them, then a "skip all" will be issued.
#pod
#pod =cut

use Test2::API 1.302045 ();

sub run {
  my ($self) = @_;

  my $test_instance = $self->build_test_instance;

  my $ordered_tests = $self->_get_tests($test_instance);

  if (@$ordered_tests == 0) {
    my $ctx = Test2::API::context;
    $ctx->plan(0, 'SKIP', "no tests to run");
    $ctx->release;

    return;
  }

  $self->_run_tests($test_instance, $ordered_tests);
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Runner::NoSubtest - tools for running Test::Routine tests (without using a subtest)

=head1 VERSION

version 0.032

=head1 OVERVIEW

This is just a L<Test::Routine::Runner>, but when you call C<run>, it won't
wrap the whole thing in a subtest.  If you use multiple instances of a
Test::Routine object in testing -- constructing it with different parameters
for several runs, for example -- this will lead to heartache.  If your test is
just a single run, though, getting rid of that top-level subtest can simplify
your life.

Also: if no tests will be run, generally because the C<TEST_METHOD> environment
variable didn't select them, then a "skip all" will be issued.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
