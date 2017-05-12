package WWW::Phanfare::Class::CacheAPI;
use Carp;
use Data::Dumper;
use Cache::Memory;

use base qw( WWW::Phanfare::API );
our $AUTOLOAD;

our $CACHE = Cache::Memory->new(
  namespace       => 'WWW::Phanfare::Class',
  default_expires => '30 sec',
);

# Load image content, and cache it
#
sub geturl {
  my($self,$url,$post) = @_;

  my $super = "SUPER::geturl";

  # If call comes from SUPER, then use SUPER's own method
  return eval { $self->$super( $url, $post ) } if caller eq 'WWW::Phanfare::API';

  my $cachestring = join ',', 'geturl', grep $_, $url, $post;
  my $result = $CACHE->get( $cachestring );
  unless ( $result ) {
    $result = eval { $self->$super( $url, $post ) };
    $CACHE->set( $cachestring, $result );
  }
  return $result;
}

# Cache the result of all Get* requests
# Delete parent for all Delete* and New* requests
#
sub AUTOLOAD {
  my $self = shift;
  croak "$self is not an object" unless ref($self);

  my $method = $AUTOLOAD;
  $method =~ s/.*://;   # strip fully-qualified portion
  croak "method not defined" unless $method;

  $CACHE->purge();
  my $cachestring = join ',', $method, @_;
  my $result = $CACHE->thaw( $cachestring );
  unless ( $result ) {
    my $super = "SUPER::$method";
    $result = eval { $self->$super( @_ ) };
    $CACHE->freeze( $cachestring, $result ) if substr $method, 0, 3 eq 'Get';

    # Delete cached parent results when creating/deleting objects
    # *** Caching NewAlbum,target_uid,9497612,album_name,Test2,album_start_date,1999-01-01T00:00:00,album_end_date,1999-12-31T23:59:59
    # *** Reusing GetAlbumList,target_uid,9497612
    my $parent;
    if ( $method eq 'NewAlbum' or $method eq 'DeleteAlbum' ) {
      $parent = join ',', 'GetAlbumList', @_[0..1];
    } elsif ( $method eq 'NewSection' or $method eq 'DeleteSection' ) {
      $parent = join ',', 'GetAlbum', @_[0..3];
    }
    if ( $parent ) {
      $CACHE->remove( $parent );
    }
  }
  return $result;
}

# Make sure not caught by AUTOLOAD
#
sub DESTROY {}

=head1 NAME

WWW::Phanfare::Class::CacheAPI - Caching WWW::Phanfare::API wrapper.

=head1 DESCRIPTION

A plugin wrapper for WWW::Phanfare::API class. Caches Get* results
for 30 seconds. Expire cached parent Get* results when adding or deleting
objects.

=head1 METHODs

=head2 geturl($url, $post?)

Load image from URL and cache it.

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
