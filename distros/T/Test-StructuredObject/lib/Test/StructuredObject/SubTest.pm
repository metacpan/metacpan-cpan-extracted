use strict;
use warnings;

package Test::StructuredObject::SubTest;
BEGIN {
  $Test::StructuredObject::SubTest::AUTHORITY = 'cpan:KENTNL';
}
{
  $Test::StructuredObject::SubTest::VERSION = '0.01000010';
}

# ABSTRACT: A Nested group of tests.

use Moose;
use Test::More;
extends 'Test::StructuredObject::TestSuite';
use namespace::autoclean;


has name => ( isa => 'Str', required => 1, is => 'rw' );


sub run {
  my $self = shift;
  my $result;
  subtest $self->name, sub {
    $result = $self->_run_items();
  };
  return $result;
}

## no critic (ProhibitUnusedPrivateSubroutines)

sub _label {
  my $self   = shift;
  my $string = shift;
  return __PACKAGE__ . '(' . $self->name . ' => (' . $string . ') )';
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Test::StructuredObject::SubTest - A Nested group of tests.

=head1 VERSION

version 0.01000010

=head1 METHODS

=head2 run

Execute all the child items inside a L<< C<Test::More> C<subtest>|Test::More/subtest >>
named after L<<< C<< ->name >>|/name >>>

=head1 ATTRIBUTES

=head2 name

A descriptive name for this batch of C<subtests>.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
