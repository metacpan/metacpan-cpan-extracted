package WWW::Phanfare::Class::Site;
use Moose;
use MooseX::Method::Signatures;
use WWW::Phanfare::Class::Year;

sub _childclass { 'WWW::Phanfare::Class::Year' };

# List of years in start dates
#
method _idnames {
  my $albumlist =
    $self->api->GetAlbumList(target_uid=>$self->uid)->{albums}{album};
  $albumlist = [ $albumlist ] unless ref $albumlist eq 'ARRAY';

  # Scan albums for years. List each year only once.
  my %year;
  for my $album ( @$albumlist ) {
    my $num = substr $album->{album_start_date}, 0, 4;
    ++$year{$num};
  }
  return [ map {{ id=>$_, name=>$_ }} keys %year ];
}

with 'WWW::Phanfare::Class::Role::Branch';

=head1 NAME

WWW::Phanfare::Class::Site - Site Node

=head1 DESCRIPTION

Child class of Account. Parent class of Year.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
