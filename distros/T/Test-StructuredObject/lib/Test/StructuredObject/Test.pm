use strict;
use warnings;

package Test::StructuredObject::Test;
BEGIN {
  $Test::StructuredObject::Test::AUTHORITY = 'cpan:KENTNL';
}
{
  $Test::StructuredObject::Test::VERSION = '0.01000010';
}

# ABSTRACT: A L<< C<CodeStub>|Test::StructuredObject::CodeStub >> representing executable test code.

use Moose;
extends 'Test::StructuredObject::CodeStub';
use namespace::autoclean;


has code => ( isa => 'CodeRef', required => 1, is => 'rw' );

## no critic ( ProhibitUnusedPrivateSubroutines )

sub _label {
  my $self = shift;
  return __PACKAGE__ . '(' . shift . ')';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Test::StructuredObject::Test - A L<< C<CodeStub>|Test::StructuredObject::CodeStub >> representing executable test code.

=head1 VERSION

version 0.01000010

=head1 ATTRIBUTES

=head2 code

The C<coderef> to execute during L<< C<run>|Test::StructuredObject::CodeStub/run >>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
