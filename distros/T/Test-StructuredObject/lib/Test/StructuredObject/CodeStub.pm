use strict;
use warnings;

package Test::StructuredObject::CodeStub;
BEGIN {
  $Test::StructuredObject::CodeStub::AUTHORITY = 'cpan:KENTNL';
}
{
  $Test::StructuredObject::CodeStub::VERSION = '0.01000010';
}

# ABSTRACT: The base class of all executable tests.

use Moose;
use namespace::autoclean;

use Carp qw( carp );


sub _label {
  my $self = shift;
  return __PACKAGE__ . '(' . shift . ')';
}


sub dcode {
  my $self = shift;
  require B::Deparse;
  my $c = B::Deparse->new(qw( -x10  -p  -l ));
  $c->ambient_pragmas( strict => 'all', 'warnings' => 'all' );
  return $c->coderef2text( $self->code );
}


sub run {
  ## no critic ( ProhibitPunctuationVars )
  my $i;
  my $self = shift;
  my $evalresult = eval { $i = $self->code->(); 1 };
  if ( not $evalresult ) {
    carp($@);
  }
  return $i;
}


sub to_s {
  my $self = shift;
  return $self->_label( $self->dcode );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Test::StructuredObject::CodeStub - The base class of all executable tests.

=head1 VERSION

version 0.01000010

=head1 DESCRIPTION

This class is basically a C<functor>. At least, all derived packages are. This top level class has
no implicit code storage part, and this module really B<should> be reimplemented as a role. But laziness.

This top level provides few basic utilities to inheriting packages, largely L<< C<dcode>|/dcode >> , L<< C<run>|/run >> and L<< C<to_s>|/to_s >>.

=head1 METHODS

=head2 C<dcode>

Return the source-code of this objects C<coderef> using L< B::Deparse|B::Deparse >.
Will not work on the base class as it needs C<< ->code >> to work.

=head2 C<run>

Execute this objects C<coderef> inside an C< eval { } > block.

In the event of a failure emanating from the C<eval>'d code, that error is passed to L<carp|Carp/carp>

Return value of the C<coderef> is passed to the caller.

Will not work on the base class as it needs C<< ->code >> to work.

=head2 C<to_s>

Pretty-print this object in a serialisation-like format showing the source for the C<coderef>.

Will not work on the base class as it needs L<<< C<< ->dcode >>|/dcode >>> and thus C<< ->code >> to work.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
