package Valiant::NestedError;

use Moo;

extends 'Valiant::Error';

has 'inner_error' => (
  is => 'ro',
  required => 1,
  handles => { message => 'message' }
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $options = $class->$orig(@args);

  return +{ %$options, inner_error=>$options->{options}{inner_error} };
};

1;

=head1 NAME

Valiant::NestedError - An error imported from another object's errors collection

=head1 DESCRIPTION

A subclass of L<Valiant::Error> used by L<Valiant::Errors/import_error> and
L<Valiant::Errors/merge> to wrap errors that originated on another object (for
example when validations on a nested object add errors that need to appear on
the parent).  Its message delegates to the original error so translation happens
against the object the error was created on.

You won't usually create one of these yourself.

=head1 ATTRIBUTES

=head2 inner_error

The original L<Valiant::Error> object this error wraps.

=head1 SEE ALSO

L<Valiant>, L<Valiant::Error>, L<Valiant::Errors>.

=head1 AUTHOR

See L<Valiant>

=head1 COPYRIGHT & LICENSE

See L<Valiant>

=cut
