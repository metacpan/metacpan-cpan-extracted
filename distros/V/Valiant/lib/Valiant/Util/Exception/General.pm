package Valiant::Util::Exception::General;

use Moo;
extends 'Valiant::Util::Exception';

has msg => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  return $self->msg;
}

1;

=head1 NAME

Valiant::Util::Exception::General - A non categorized exception

=head1 SYNOPSIS

    throw_exception General => (msg=>'validations argument in unsupported format');

=head1 DESCRIPTION

A non categorized exception

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
