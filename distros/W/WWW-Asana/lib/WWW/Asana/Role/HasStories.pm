package WWW::Asana::Role::HasStories;
BEGIN {
  $WWW::Asana::Role::HasStories::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::HasStories::VERSION = '0.003';
}
# ABSTRACT: Role for Asana classes which have stories

use MooX::Role;


sub stories {
	my ( $self ) = @_;
	$self->do('[Story]', 'GET', $self->own_base_args, 'stories', sub { target => $self });
}


sub create_story {
	my ( $self, @args ) = @_;
	unshift @args, 'text';
	$self->do('Story', 'POST', $self->own_base_args, 'stories', { @args }, sub { target => $self });
}


sub comment { shift->create_story(@_) }

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::HasStories - Role for Asana classes which have stories

=head1 VERSION

version 0.003

=head1 METHODS

=head2 stories

Get an arrayref of L<WWW::Asana::Story> objects from the object

=head2 create_story

Adds the given first parameter as comment to the object, it gives back a
L<WWW::Asana::Story> of the resulting story.

=head2 comment

Shortcut for L</create_story>

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

