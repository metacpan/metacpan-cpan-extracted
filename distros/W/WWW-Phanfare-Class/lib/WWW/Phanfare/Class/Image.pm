package WWW::Phanfare::Class::Image;
use Moose;
use MooseX::Method::Signatures;

# Image caption
#
method _caption ( Str $value? ) {
  # Read
  return $self->attribute('caption') unless defined $value;

  # Write
  $self->api->UpdateCaption(
    target_uid => $self->uid,
    album_id   => $self->album->id,
    section_id => $self->section->id,
    image_id   => $self->id,
    caption    => $value,
  ) or return undef;
  return $self->_set_attr('caption', $value);
}

# Let photo be hidden
#
method _hidden ( Bool $value? ) {
  # Read
  return $self->attribute('hidden') unless defined $value;

  # Write
  $self->api->HideImage(
    target_uid => $self->uid,
    album_id   => $self->album->id,
    section_id => $self->section->id,
    image_id   => $self->id,
    hidden     => $value,
  ) or return undef;
  return $self->_set_attr('hidden', $value);
}

# Image content
#
has _imagedata => ( isa=>'Str', is=>'rw' );
method value ( Str $value? ) {
  # Write
  return $self->_imagedata( $value ) if $value;

  # Read
  my $content = $self->api->geturl( $self->attribute('url') );
  $self->size( length $content );
  return $content;
}

# Which album, section and rendition does photo belong to
#
method album     { $self->parent->parent->parent }
method section   { $self->parent->parent         }
method rendition { $self->parent                 }

# Upload image content
# Can only upload inside Full rendition
#
method _write {
  if ( $self->rendition->name eq 'Full' ) {
    return $self->api->NewImage(
      target_uid => $self->uid,
      album_id   => $self->album->id,
      section_id => $self->section->id,
      filename   => $self->name,
      content    => $self->_imagedata,
      ( $self->attribute('image_date')
        ? ( image_date => $self->attribute('image_date') )
        : ()
      ),
    );
  }
  return undef;
}

# Delete image
# Can only delete inside Full rendition
#
method _delete {
  return unless $self->parent->name eq 'Full';
  $self->api->DeleteImage(
    target_uid => $self->uid,
    album_id => $self->album->id,
    section_id => $self->section->id,
    image_id => $self->id,
  );
}

# 'hidden' and 'caption' are the only attributes that can be updated through API
#
method _update ( Str $key, Str $value ) {
  if ( $key eq 'caption' ) {
    return $self->_caption( $value );
  } elsif ( $key eq 'hidden' ) {
    return $self->_hidden( $value );
  }
  return undef;
}

with 'WWW::Phanfare::Class::Role::Leaf';
with 'WWW::Phanfare::Class::Role::Attributes';

=head1 NAME

WWW::Phanfare::Class::Image - Image Node

=head1 DESCRIPTION

Child class of Rendition.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
