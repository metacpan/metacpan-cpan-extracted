package WWW::Google::Notebook::Notebook;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors(qw/id api/);
__PACKAGE__->mk_accessors(qw/title/);

sub notes {
    my $self = shift;
    $self->api->_notes($self);
}

sub delete {
    my $self = shift;
    $self->api->_delete_notebook($self);
}

sub rename {
    my ($self, $title) = @_;
    $self->title($title);
    $self->update;
}

sub update {
    my $self = shift;
    $self->api->_update_notebook($self);
}

sub add_note {
    my ($self, $content) = @_;
    $self->api->_add_note($self, $content);
}

sub _delete_note {
    my ($self, $note) = @_;
    $self->api->_delete_note($note);
}

sub _update_note {
    my ($self, $note) = @_;
    $self->api->_update_note($note);
}

1;
__END__

=head1 NAME

WWW::Google::Notebook::Notebook - Notebook object for WWW::Google::Notebook

=head1 SYNOPSIS

  use WWW::Google::Notebook;
  my $google = WWW::Google::Notebook->new(
      username => $username,
      password => $password,
  );
  $google->login;
  my $notebook = $google->add_notebook('title');
  print $notebook->title;
  $notebook->rename('title2');
  my $note = $notebook->add_note('note');
  $notebook->delete;

=head1 DESCRIPTION

Google Notebook notebook class.

=head1 METHODS

=head2 add_note($content);

Adds note.

=head2 notes

Returns your notes as L<WWW::Google::Notebook::Note> objects.

=head2 rename($title)

Rename notebook.

=head2 update

Updates notebook.

=head2 delete

Deletes notebook.

=head1 ACCESSOR

=over 4

=item id

=item title

=back

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<WWW::Google::Notebook>

=item * L<http://www.google.com/notebook/>

=back

=cut
