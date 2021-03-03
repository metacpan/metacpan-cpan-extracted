package Valiant::Util::Exception::Strict;

use Moo;
extends 'Valiant::Util::Exception';

has msg => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  return $self->msg;
}

1;

=head1 NAME

Valiant::Util::Exception::Strict - A Validation error that throws strictly

=head1 SYNOPSIS

    throw_exception('Strict' => (msg=>$message))

=head1 DESCRIPTION

If you mark a validation as strict then instead of returning error messages we get an
immediate exception thrown.

=head1 ATTRIBUTES

=head2 msg 

Message that the exception will stringify to.

=head2 message

The actual exception message

=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
