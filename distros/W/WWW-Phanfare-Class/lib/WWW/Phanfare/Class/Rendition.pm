package WWW::Phanfare::Class::Rendition;
use Moose;
use MooseX::Method::Signatures;
use WWW::Phanfare::Class::Image;

sub _childclass { 'WWW::Phanfare::Class::Image' }

# List of image filenames. They might be full path
#
method _idnames {
  my $imageinfo = $self->parent->_info->{images}{imageinfo};
  return [] unless $imageinfo;
  $imageinfo = [ $imageinfo ] unless ref $imageinfo eq 'ARRAY';

  my @images;
  for my $image ( @$imageinfo ) {
    # Merge imageinfo and rendition info
    $image = {
      %$image,
      %{
        $self->_treesearch(
          $image->{renditions}{rendition},
          [ { rendition_type => $self->name } ]
        )
      }
    };
    push @images, $image;
  }

  return [
    map {{
      id   => $_->{image_id},
      name => $self->_basename( $_->{filename} ),
      attr  => $_,
    }}
    @images
  ];
}

with 'WWW::Phanfare::Class::Role::Branch';

=head1 NAME

WWW::Phanfare::Class::Rendition - Rendition Node

=head1 DESCRIPTION

Child class of Section. Parent class of Image.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
