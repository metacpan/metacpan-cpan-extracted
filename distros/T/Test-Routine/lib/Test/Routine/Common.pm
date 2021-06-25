package Test::Routine::Common;
# ABSTRACT: a role composed by all Test::Routine roles
$Test::Routine::Common::VERSION = '0.028';
use Moose::Role;

#pod =head1 OVERVIEW
#pod
#pod Test::Routine::Common provides the C<run_test> method described in L<the docs
#pod on writing tests in Test::Routine|Test::Routine/Writing Tests>.
#pod
#pod =cut

use Test::Abortable 0.002 ();
use Test2::API 1.302045 ();

use namespace::autoclean;

sub BUILD {
}

sub DEMOLISH {
}

sub run_test {
  my ($self, $test) = @_;

  my $ctx = Test2::API::context();
  my ($file, $line) = @{ $test->_origin }{ qw(file line) };
  $ctx->trace->set_detail("at $file line $line");

  my $name = $test->name;
  Test::Abortable::subtest($test->description, sub { $self->$name });

  $ctx->release;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Common - a role composed by all Test::Routine roles

=head1 VERSION

version 0.028

=head1 OVERVIEW

Test::Routine::Common provides the C<run_test> method described in L<the docs
on writing tests in Test::Routine|Test::Routine/Writing Tests>.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
