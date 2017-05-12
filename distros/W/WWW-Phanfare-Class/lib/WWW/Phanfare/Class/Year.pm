package WWW::Phanfare::Class::Year;
use Moose;
use MooseX::Method::Signatures;
use WWW::Phanfare::Class::Album;

sub _childclass { 'WWW::Phanfare::Class::Album' };

# List of album_id=>album_name pairs where start date matches this year
#
method _idnames {
  my $albumlist = $self->api->GetAlbumList(target_uid=>$self->uid);
  $self->_idnamepair(
    $albumlist->{albums}{album},
    'album',
    { album_start_date=>$self->name },
  );
}

# A year can only be deleted if there are no albums in that year
#
method _delete {
  return if $self->list;
  return 1;
}

# Default start and end date for year. Use Phanfare format for date.
#
method start_date { sprintf("%04s-01-01T00:00:00", $self->name) }
method end_date   { sprintf("%04s-12-31T23:59:59", $self->name) }

with 'WWW::Phanfare::Class::Role::Branch';

=head1 NAME

WWW::Phanfare::Class::Year - Year Node

=head1 DESCRIPTION

Child class of Site. Parent class of Album.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
