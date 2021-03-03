package Valiant::Util::Exception::MissingCountKey;

use Moo;
extends 'Valiant::Util::Exception';

has tag => (is=>'ro', required=>1);
has count => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  return "Translation tag '@{[ $self->tag ]}' has no count subkey matching '@{[ $self->count ]}'.";
}

1;

=head1 NAME

Valiant::Util::Exception::MissingCountKey - Not count subkey for the translation tag

=head1 SYNOPSIS

    throw_exception('MissingCountKey', tag=>$original, count=>$count);

=head1 DESCRIPTION

Your translation tag defines count subkeys but there's nothing matching the current count

=head1 ATTRIBUTES

=head2 tag

=head2 count

The original tag whose count we cannot translate.  This usually means you are missing a count
key.

=head2 message

The actual exception message

=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
