package FakeAgent;

# Emulate responses from Phanfare using local data files.

use YAML::Syck qw(Load LoadFile);
use Data::Dumper;
use Clone qw(clone);
use base qw(WWW::Phanfare::API);
our $AUTOLOAD;

sub x {
  use Data::Dumper;
  warn Data::Dumper->Dump([$_[1]], ["*** $_[0]"]);
}

sub AUTOLOAD {
  warn "*** FakeAgent $AUTOLOAD not handled\n";
}

# Create an Authentication response
#
sub Authenticate {
  my $self = shift;
  LoadFile 't/data/session.yaml';
}

sub GetAlbumList {
  my $self = shift;
  my $list = LoadFile 't/data/albumlist.yaml';
  push @{ $list->{albums}{album} }, $self->{_albumlist} if $self->{_albumlist};
  return $list;
}

# If a new album is created, then assume to return the one just created.
# Otherwise load from file.
#
sub GetAlbum {
  shift->{_albuminfo} || LoadFile 't/data/albuminfo.yaml';
}

sub NewAlbum {
  my($self, %data) = @_;

  # Clone last albumlist entry
  #
  my $list = $self->GetAlbumList;
  $self->{_albumlist} = clone $list->{albums}{album}[-1];
  while (my($k,$v) = each %data ) {
    $self->{_albumlist}->{$k} = $v;
  }
  ++$self->{_albumlist}{album_id};

  # Clone Album
  my $album = $self->GetAlbum;
  $self->{_albuminfo} = clone $album;
  while (my($k,$v) = each %data ) {
    $self->{_albuminfo}{album}{$k} = $v;
  }
  ++$self->{_albuminfo}{album}{album_id};
}

sub DeleteAlbum {
  my $self = shift;
  delete $self->{_albumlist};
  delete $self->{_albuminfo};
}

# Set an Album Attribute
#
sub UpdateAlbum {
  my($self, %data) = @_;

  $self->{_albuminfo} = clone $self->GetAlbum;
  $self->{_albuminfo}{album}{$data{field_to_update}} = $data{field_value};
}

sub NewSection {
  my($self, %data) = @_;

  my $oldsection = clone $self->GetAlbum->{album}{sections}{section};
  my $section = clone $oldsection;
  $section->{section_name} = $data{section_name};
  ++$section->{section_id};
  $self->{_albuminfo} = clone $self->GetAlbum;
  $self->{_albuminfo}{album}{sections}{section} = [
    $oldsection,
    $section
  ];
}

# Set a Section Attribute
#
sub UpdateSection {
  my($self, %data) = @_;

  $self->{_albuminfo} = clone $self->GetAlbum;
  $self->{_albuminfo}{album}{sections}{section}{$data{field_to_update}}
    = $data{field_value};
}

sub DeleteSection {
  my $self = shift;
  delete $self->{_albuminfo};
}

sub NewImage {
  my($self, %data) = @_;

  return undef if $data{content} eq 'invalid data';
  my $image = clone $self->GetAlbum->{album}{sections}{section}{images}{imageinfo}[-1];
  $image->{filename} = $data{filename};
  ++$image->{image_id};
  #x "Clone image $data{image_name}", $image;
  $self->{_albuminfo} = clone $self->GetAlbum;
  push @{ $self->GetAlbum->{album}{sections}{section}{images}{imageinfo} },
    $image;
}

sub DeleteImage {
  my $self = shift;
  delete $self->{_albuminfo};
}

sub UpdateCaption {
  my($self, %data) = @_;

  $self->{_albuminfo} = clone $self->GetAlbum;
  my $image = $self->GetAlbum->{album}{sections}{section}{images}{imageinfo}[0];
  $image->{caption} = $data{caption};
  return { stat=>'ok' };
}

sub HideImage {
  my($self, %data) = @_;

  $self->{_albuminfo} = clone $self->GetAlbum;
  my $image = $self->GetAlbum->{album}{sections}{section}{images}{imageinfo}[0];
  $image->{hidden} = $data{hide};
  return { stat=>'ok' };
}

# Make sure not caught by AUTOLOAD
sub DESTROY {}

=head1 NAME

FakeAgent - Emulate Phanfare response to test cases

=head1 DESCRIPTION

Generate responses similar to results from Phanfare site. For unit test
use only.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
