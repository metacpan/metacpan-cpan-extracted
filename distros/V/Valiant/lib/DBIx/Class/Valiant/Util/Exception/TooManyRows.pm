package DBIx::Class::Valiant::Util::Exception::TooManyRows;

use Moo;
extends 'Valiant::Util::Exception';

has [qw/limit attempted related me/] => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  return "Relationship @{[ $self->related]} on @{[ $self->me]} can't create more that @{[ $self->limit]} rows; attempted @{[ $self->attempted]}";
  return $self->msg;
}

1;

=head1 NAME

DBIx::Class::Valiant::Util::Exception - More rows attempted than you are permitted to create

=head1 SYNOPSIS

     DBIx::Class::Valiant::Util::Exception->throw(msg=>'validations argument in unsupported format');

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
