package WWW::Phanfare::Class::Album;
use Moose;
use MooseX::Method::Signatures;
use WWW::Phanfare::Class::Section;

sub _childclass { 'WWW::Phanfare::Class::Section' }

method _info {
  $self->api->GetAlbum(
    target_uid => $self->uid,
    album_id   => $self->id,
  )->{album};
}

method _idnames {
  $self->_idnamepair( $self->_info->{sections}{section}, 'section' );
}

# Create this as new node on Phanfare
#
method _write { 
  my $year = $self->parent->name;
  $self->api->NewAlbum(
     target_uid       => $self->uid,
     album_name       => $self->name,
     album_start_date => $self->parent->start_date,
     album_end_date   => $self->parent->end_date,
  );
}

method _delete {
  my $res = $self->api->DeleteAlbum(
     target_uid => $self->uid,
     album_id   => $self->id,
  );
  use Data::Dumper;
  return $res;
}

# Write an attribute
#
method _update ( Str $field, Str $value ) {
  $self->api->UpdateAlbum(
     target_uid      => $self->uid,
     album_id        => $self->id,
     field_to_update => $field,
     field_value     => $value,
  );
}

with 'WWW::Phanfare::Class::Role::Branch';
with 'WWW::Phanfare::Class::Role::Attributes';

=head1 NAME

WWW::Phanfare::Class::Album - Album Node

=head1 DESCRIPTION

Child class of Site. Parent class of Section.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
