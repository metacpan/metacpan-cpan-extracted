
package WWW::EchoNest;

use 5.010;
use strict;
use warnings;
use Carp;

BEGIN {
    our $VERSION = '0.0.2';
    our @EXPORT    = ();
    our @EXPORT_OK =
        (
         # Convenience methods
         'get_artist',
         'get_catalog',
         'get_playlist',
         'get_song',
         'get_track',
         'pretty_json',
         'set_log_level',
         'set_codegen_path',
         'set_api_key',
        );
    our %EXPORT_TAGS =
        (
         all => [ @EXPORT_OK ],
        );
}
use parent qw( Exporter );

use WWW::EchoNest::Id qw( is_id );

use WWW::EchoNest::Config;
sub set_codegen_path {
    WWW::EchoNest::Config::set_codegen_binary_override( $_[0] );
}
sub set_api_key {
    WWW::EchoNest::Config::set_api_key( $_[0] );
}

use JSON;
sub pretty_json { to_json( $_[0], { utf8 => 1, pretty => 1 } ) }

use WWW::EchoNest::Logger;
sub set_log_level {
    WWW::EchoNest::Logger::set_log_level( $_[0] );
}


# Convenience Functions ######################################################

use WWW::EchoNest::Artist;
sub get_artist {
    return WWW::EchoNest::Artist->new($_[0]) if ref($_[0]) eq 'HASH';
    # Assume the arg is a string
    return WWW::EchoNest::Artist->new( { id   => $_[0] } ) if is_id( $_[0] );
    return WWW::EchoNest::Artist->new( { name => $_[0] } );
}

use WWW::EchoNest::Catalog;
sub get_catalog {
    return WWW::EchoNest::Catalog->new($_[0]) if ref($_[0]) eq 'HASH';
    # Assume the arg is a string
    return WWW::EchoNest::Catalog->new( { name => $_[0] } );
}

use WWW::EchoNest::Playlist;
sub get_playlist {
    return WWW::EchoNest::Playlist->new($_[0]) if ref($_[0]) eq 'HASH';
    # Assume the arg is either a string or an array ref,
    # and that we're creating an 'artist' playlist
    return WWW::EchoNest::Playlist->new( { artist => $_[0] } );
}

use WWW::EchoNest::Song qw( search_song );
sub get_song {
    if ( ref($_[0]) eq 'HASH' ) {
        # Song constructor expects an id field, so we use search_song if there
        # isn't one
        return WWW::EchoNest::Song->new( $_[0] ) if ( exists $_[0]->{id} );
        return search_song( $_[0] );
    }
    # Assume the arg is a string
    if (is_id( $_[0] )) {
        return WWW::EchoNest::Song->new( { id => $_[0] } );
    }
    return search_song( { title => $_[0] } );
}

use WWW::EchoNest::Track qw( track_from_file );
sub get_track {
    # Assume the arg is a filename
    return track_from_file( $_[0] );
}

1;

__END__

=head1 NAME

WWW::EchoNest 0.0.1 - Perl module for accessing the Echo Nest API.

=head1 SYNOPSIS

use WWW::EchoNest qw(:all);
# Imports:
# - get_artist
# - get_catalog
# - get_playlist
# - get_song
# - get_track
# - pretty_json
# - set_log_level
# - set_codegen_path
# - set_api_key
# Each of which can also be imported individually.

use WWW::EchoNest::Artist; # So we can call Artist methods
my $talking_heads = get_artist('talking heads');
my $audio_docs_list = $talking_heads->get_audio;
my 

=head1 FUNCTIONS

=head2 get_artist

  Convenience function for creating Artist objects.

  ARGUMENTS:
    Either a hash ref that will be relayed as-is to WWW::EchoNest::Artist->new,
    or a string that is either an artist name or an Echo Nest artist ID.

  RETURNS:
    A new instance of WWW::EchoNest::Artist.

  EXAMPLE:
    use WWW::EchoNest qw( get_artist );
    my $blondie = get_artist( { name => 'blondie' } );

    # or
    my $blondie = get_artist('blondie');

    # or
    my $blondie = get_artist('ARM7YQQ1187B9A84E7');

=head2 get_catalog

  Convenience function for creating Catalog objects.

  ARGUMENTS:
    A hash-ref that will be passed as-is to the WWW::EchoNest::Catalog
    constructor, or a string that will be used as the name of the new catalog.

  RETURNS:
    A new instance of WWW::EchoNest::Catalog.

  EXAMPLE:
    use WWW::EchoNest qw( get_catalog );
    my $artist_catalog = get_catalog({ name => 'my_artists', type => 'artist' });

    my $catalog = get_catalog( { name => 'my_songs', type => 'song' } );

    # or, because 'type' defaults to 'song'...
    my $catalog = get_catalog('my_songs');

=head2 get_playlist

  Convenience function for creating Playlist objects.

  ARGUMENTS:
    A HASH-ref that will be relayed as-is to the Playlist constructor, or
    an ARRAY-ref of artist names, or
    an artist name.

  RETURNS:
    A new instance of WWW::EchoNest::Playlist.

  EXAMPLE:
    use WWW::EchoNest qw( get_playlist );
    my $plist = get_playlist( { artist => [ qw( Blondie Curve ) ] } ); # Yuck!

    # or just an ARRAY ref...
    my $plist = get_playlist( [ qw( Blondie Curve ) ] );

    # or a string...
    my $plist = get_playlist('Tom Waits');

=head2 get_song

  Convenience function for creating Song objects.

  ARGUMENTS:
    An ARRAY-ref that will be relayed as-is to the Song constructor, or
    an Echo Nest song ID, or
    a song title.

  RETURNS:
    A new instance of WWW::EchoNest::Song.

  EXAMPLE:
    use WWW::EchoNest qw( get_song );
    my $clap = get_song( { title => 'clap hands', artist => 'tom waits' } );

    # or just a song title (which may not give you the results you expect!)
    # this usage actually calls WWW::EchoNest::Song::search
    my $clap = get_song('clap hands');

    # or an Echo Nest song ID (much more reliable)
    my $clap = get_song('SODZTUL12AF72A0780');

=head2 get_track

  Convenience function for creating Track objects.

  ARGUMENTS:
    A filename.

  RETURNS:
    A new instance of WWW::EchoNest::Track.

  EXAMPLE:
    use WWW::EchoNest qw( get_track );
    my $new_track = get_track('path/to/audio/file.mp3');

=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc WWW::EchoNest

Also, join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
