package Win32::IEFavorites;

use strict;
use warnings;

our $VERSION = '0.06';

use Win32::TieRegistry;
use File::Find::Rule ();
use File::Spec;

use Win32::IEFavorites::Item;

sub folder {
  my $class = shift;

  my $folders = $Registry->{
    q{CUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders}
  } or die "Can't open registry $^E";;
  my $value = $folders->{Favorites} or die "No Favorites: $^E";

  return $value;
}

sub find {
  my ($class, @expr) = @_;

  @expr = ( '*.url' ) unless @expr;

  my $dir = $class->folder;

  my @files = File::Find::Rule->file()->name( @expr )->in( $dir );

  my @items;
  foreach my $file (@files) {
    my $path = File::Spec->canonpath( $file );
    push @items, Win32::IEFavorites::Item->new($path);
  }

  return @items;
}

1;
__END__

=head1 NAME

Win32::IEFavorites - handles Internet Explorer's Favorites

=head1 SYNOPSIS

  use Win32::IEFavorites;

  my @items = Win32::IEFavorites->find('*del.icio.us');
  foreach my $item (@items) {
    print $item->url,"\n";
  }

=head1 DESCRIPTION

This module is to handle Internet Explorer's Favorites items
(Internet shortcuts). For now it only can grab shortcuts and
provide their properties (url, modified, iconfile, iconindex).
You may want to use this with some aggregator like Plagger.

=head1 CLASS METHODS

=head2 folder

Returns your IE's Favorites folder.

=head2 find ( some rules )

Returns your IE's Favorites as an array of ::Item objects.
Each object has url, modified, iconfile, iconindex properties.
Also accepts L<File::Find::Rule>'s matching rules for ->name().
The default rule is '*.url' (matches every favorite items).

=head1 CAVEATS FOR JAPANESE USERS

You *can* use shiftjis characters for matching rules as well,
though you might want to wrap it with quotemeta (or qr/\Q ... \E/)
to avoid the notorious 0x5c (\) problem.

=head1 SEE ALSO

L<File::Find::Rule>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
