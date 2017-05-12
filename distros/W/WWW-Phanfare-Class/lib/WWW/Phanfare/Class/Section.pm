package WWW::Phanfare::Class::Section;
use Moose;
use MooseX::Method::Signatures;
use WWW::Phanfare::Class::Rendition;

sub _childclass { 'WWW::Phanfare::Class::Rendition' }

# List of possible rendition
#
method _idnames {
  return [
    map {{
      id=>$_,
      name=>$_,
    }}
    qw(Full WebLarge Web WebSmall Thumbnail ThumbnailSmall Caption )
  ];
}

# Find attributes about section in album info
#
method _info {
   $self->_treesearch(
     $self->parent->_info->{sections}{section},
     [ { section_name => $self->name } ],
   );
}

# Extract section attributes from albuminfo
#
method buildattributes {
  $self->setattributes( $self->_info );
    
}

# Create this section as new section on Phanfare
#
method _write {  
  $self->api->NewSection(
    target_uid   => $self->uid,
    album_id     => $self->parent->id,
    section_name => $self->name,
  );
}

# Delete this section on Phanfare
#
method _delete  {
  $self->api->DeleteSection(
     target_uid => $self->uid,
     album_id   => $self->parent->id,
     section_id => $self->id,
  );
}

# Write an attribute
#
method _update ( Str $field, Str $value ) {
  $self->api->UpdateSection(
    target_uid      => $self->uid,
    album_id        => $self->parent->id,
    section_id      => $self->id,
    field_to_update => $field,
    field_value     => $value,
  );
}

with 'WWW::Phanfare::Class::Role::Branch';
with 'WWW::Phanfare::Class::Role::Attributes';

=head1 NAME

WWW::Phanfare::Class::Section - Section Node

=head1 DESCRIPTION

Child class of Album. Parent class of Rendition.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
