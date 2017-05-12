
package WWW::EchoNest::Track;

use 5.010;
use strict;
use warnings;
use Carp;

BEGIN {
    our @EXPORT      = qw(  );
    our @EXPORT_OK   = qw(
                             _get_attrs
                             track_from_file
                             track_from_url
                             track_from_id
                             track_from_md5
                             track_from_reanalyzing_id
                             track_from_reanalyzing_md5
                        );
    our %EXPORT_TAGS =
        (
         all => [ qw(
                        track_from_file
                        track_from_url
                        track_from_id
                        track_from_md5
                        track_from_reanalyzing_id
                        track_from_reanalyzing_md5
                   ) ]
        );
}
use parent qw( WWW::EchoNest::TrackProxy Exporter );

use WWW::EchoNest::Util qw(
                              md5
                              call_api
                              user_agent
                         );

use WWW::EchoNest::Functional qw(
                                    update
                                    make_stupid_accessor
                               );

# Required CPAN modules
eval {
    use JSON;
};
croak "$@" if $@;


use overload
    '""' => '_stringify',
    ;



# FUNCTIONS ##################################################################
#
sub _stringify {
    my($self) = @_;
    return '<Track - ' . $self->get_title() . '>';
}

my @attrs = qw(
                  analysis_channels
                  analysis_sample_rate
                  analyzer_version
                  artist
                  bars
                  beats
                  bitrate
                  danceability
                  duration
                  energy
                  end_of_fade_in
                  id
                  key
                  key_confidence
                  loudness
                  md5
                  meta
                  mode
                  mode_confidence
                  num_samples
                  release
                  sample_md5
                  samplerate
                  sections
                  segments
                  start_of_fade_out
                  status
                  tatums
                  tempo
                  tempo_confidence
                  title
             );

sub _get_attrs { @attrs }

make_stupid_accessor(@attrs);
    
sub _track_from_response {
    my $result = $_[0]->{response};
    croak 'No result' if ! $result;

    my $status = lc ( $result->{track}{status} );
    croak 'No status' if ! $status;

    return track_from_reanalyzing_id($result->{track}{id})
        if ($status eq 'unavailable');

    my %error_for =
        (
         error        => 'There was an error analyzing the track.',
         pending      => 'The track is still being analyzed.',
         forbidden    => 'Analysis of the track is forbidden.',
        );

    my $error = $error_for{$status};
    croak "$error" if $error;

    my $track             = $result->{track};
    my $audio_summary     = $track->{audio_summary};
    my $json_url          = $audio_summary->{analysis_url};
    my $json_response     = user_agent()->get($json_url);
    my $json_string;
    
    if ( $json_response->is_success() ) {
        $json_string = $json_response->decoded_content()
    } else {
        croak "Could not get $json_url: $json_response->status_line()";
    }

    my $analysis          = decode_json( $json_string );
    my $nested_track      = delete $analysis->{track};

    $track->{energy}            = $audio_summary->{energy}        // 0;
    $track->{danceability}      = $audio_summary->{danceability}  // 0;

    update( $track, $analysis )     if $analysis;
    update( $track, $nested_track ) if $nested_track;

    return WWW::EchoNest::Track->SUPER::new($track);
}

# First arg should be a HASH-ref
sub _profile {
    $_[0]->{format} = 'json';
    $_[0]->{bucket} = 'audio_summary';
    
    return _track_from_response(
                                call_api(
                                         {
                                          method   => 'track/profile',
                                          params   => $_[0],
                                         }
                                        )
                               );
}

# Calls upload either with a local audio file, or a url. Returns a track object.
sub _upload {
    my $param_ref     = $_[0];
    my $data          = $_[1];

    $param_ref->{wait}       = 'true';
    $param_ref->{format}     = 'json';
    $param_ref->{bucket}     = 'audio_summary';
    
    my $api_call = call_api(
                            {
                             method        => q[track/upload],
                             params        => $param_ref,
                             post          => 1,
                             timeout       => 300,
                             data          => $data,
                            }
                           );
    return _track_from_response($api_call);
}

sub _analyze {
    $_[0]->{wait}       = 'true';
    $_[0]->{format}     = 'json';
    $_[0]->{bucket}     = 'audio_summary';
    
    return _track_from_response(
                                call_api(
                                         {
                                          method      => 'track/analyze',
                                          params      => $_[0],
                                          post        => 1,
                                          timeout     => 500,
                                         }
                                        )
                               );
}

# Get a Track object from a path string.
# I'm having a hard time getting track/upload to work when I include
# audio data in the request body. So I'm going to try with just a pathname.
sub _track_from_string {
    #
    # - First arg is a scalar containing audio data.
    # - Second arg is the filetype.
    #
    return _upload(
                   { filetype => $_[1], },
                   $_[0],
                  );
}

sub track_from_file {
    # my $logger = get_logger;

    # - First arg is either a filename, a filehandle, or an instance of IO::File.
    # - Second arg is a string indicating the filetype. This is optional if you're
    #   creating a track from a filename string.
    #
    my $arg_type     = ref( $_[0] );
    my $filetype     = $_[1];
    
    my %audio_for =
        (
         'IO::File' => sub { local $/ = q[];
                             $_[0]->binmode();
                             $_[0]->read( my $data, 100_000_000 );
                             return $data;
                         },
         
         GLOB => sub { local $/ = q[];
                       binmode( $_[0] );
                       read ( $_[0], my $data, 100_000_000 );
                       return $data;
                   },
         
         q[] => sub { local $/ = q[];
                      open ( my $fh, '<', $_[0] )
                          or croak "Could not open $_[0]: $!";
                      binmode($fh);
                      return <$fh>;
                  },
        );

    # If we were only provided with a single filename argument and no filetype,
    # try parsing the filetype from the filename.
    if (! ($filetype || $arg_type)) {
        my($ext)    = ($_[0] =~ m[^.*\.(\w*)$]);
        $filetype   = $ext;
    }
    my @acceptable_filetypes = qw( wav mp3 au ogg m4a mp4 );
    croak 'No filetype' if ! $filetype;
    croak "Unrecognized filetype: $filetype\nAcceptable types: "
          . join( ', ', @acceptable_filetypes ) . "\n"
              if ! grep { $filetype eq $_ } @acceptable_filetypes;
    
    # Slurp the audio data into a scalar and generate an md5
    my $audio_data = $audio_for{$arg_type}->( $_[0] );
    croak 'No audio data' if ! $audio_data;
    my $md5        = md5( $audio_data );

    # Try to return a WWW::EchoNest::Track instance
    # Use _track_from_string if we can't get a track from the md5
    my $track;
    $@ = q[];
    
    eval {
        $track = track_from_md5( $md5 );
    };
    
    $track = _track_from_string( $audio_data, $filetype ) if $@;
    return $track if $track;
    croak 'track_from_file failed';
}

sub track_from_url {
    return _upload(
                   {
                    # First arg is an audio file publicly accessible via HTTP
                    url => $_[0],
                   }
                  );
}

sub track_from_id {
    return _profile(
                    {
                     # First arg is the Echo Nest track ID
                     id => $_[0],
                    }
                   );
}

sub track_from_md5 {
    return _profile(
                    {
                     # First arg is a hex md5
                     md5 => $_[0],
                    }
                   )
}

sub track_from_reanalyzing_id {
    return _analyze(
                    {
                     # First arg is the Echo Nest track ID
                     id => $_[0],
                    }
                   );
}

sub track_from_reanalyzing_md5 {
    return _analyze(
                    {
                     # First arg is a hex md5
                     md5 => $_[0],
                    }
                   )
}

1;

__END__



=head1 NAME

WWW::EchoNest::Track

=head1 SYNOPSIS
    
    Represents an audio analysis from The Echo Nest.
    All the functions exportable from this module return
    Track objects.

=head1 METHODS

  This module's interface is purely functional. No methods.

=head1 FUNCTIONS

=head2 track_from_file

  Creates a new Track object from a filehandle or filename.

  ARGUMENTS:
    file           => filename or filehandle-reference
    filetype       => type of the file (e.g. mp3, wav, flac)
  
  RETURNS:
    A new Track object.

  EXAMPLE:
    use WWW::EchoNest::Track qw( track_from_file );
    my @tracks
    my @tracks[0] = track_from_file('path/to/audio.mp3');

    open ( my $AUDIO_FH, '<', 'path/to/other.mp3' );
    my @tracks[1] = track_from_file($AUDIO_FH);



=head2 track_from_filename

  Creates a new Track object from a filename.

  ARGUMENTS:
    filename       => filename
    filetype       => type of the file (e.g. mp3, wav, flac)
  
  RETURNS:
    A new Track object.

  EXAMPLE:
    # Insert helpful example here!



=head2 track_from_url

  Creates a new Track object from a url.

  ARGUMENTS:
    url     => A string giving the URL to read from.
               This must be on a public machine accessible via HTTP.
  
  RETURNS:
    A new Track object.

  EXAMPLE:
    # Insert helpful example here!



=head2 track_from_id

  Creates a new Track object from an Echo Nest track ID.

  ARGUMENTS:
    id       => A string containing the ID of a previously analyzed track.
  
  RETURNS:
    A new Track object.

  EXAMPLE:
    # Insert helpful example here!



=head2 track_from_md5

  Creates a new Track object from an md5 hash.

  ARGUMENTS:
    md5       => A string 32 characters long giving the md5 checksum of a track already analyzed.
  
  RETURNS:
    A new Track object.

  EXAMPLE:
    # Insert helpful example here!



=head2 track_from_reanalyzing_id

  Create a track object from an Echo Nest track ID, reanalyzing the track first.

  ARGUMENTS:
    identifier   => A string containing the ID of a previously analyzed track
  
  RETURNS:
    A new Track object.

  EXAMPLE:
    # Insert helpful example here!



=head2 track_from_reanalyzing_md5

  Create a track object from an md5 hash, reanalyzing the track first.

  ARGUMENTS:
    md5     => A string containing the md5 of a previously analyzed track
  
  RETURNS:
    A new Track object.

  EXAMPLE:
    # Insert helpful example here!



=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
