package WWW::Google::Notebook::Note;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors(qw/id created_on last_modified/);
__PACKAGE__->mk_accessors(qw/content notebook/);

sub delete {
    my $self = shift;
    $self->notebook->_delete_note($self);
}

sub edit {
    my ($self, $content) = @_;
    $self->content($content);
    $self->update;
}

sub update {
    my $self = shift;
    $self->notebook->_update_note($self);
}

1;
__END__

=head1 NAME

WWW::Google::Notebook::Note - Note object for WWW::Google::Notebook

=head1 SYNOPSIS

  use WWW::Google::Notebook;
  my $google = WWW::Google::Notebook->new(
      username => $username,
      password => $password,
  );
  $google->login;
  my $notebook = $google->add_notebook('title');
  my $note = $notebook->add_note('note');
  print $note->content;
  print $note->created_on;
  $note->edit('note2');
  $note->delete;

=head1 DESCRIPTION

Google Notebook note class.

=head1 METHODS

=head2 edit($content)

Edit content.

=head2 update

Updates note.

=head2 delete

Deletes note.

=head2 notebook

Returns a parent notebook object.

=head1 ACCESSOR

=over 4

=item id

=item content

=item created_on

Returns created date as epoch.

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
