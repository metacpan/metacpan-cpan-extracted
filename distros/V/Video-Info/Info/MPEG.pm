##------------------------------------------------------------------------
##  Package: MPEG.pm
##   Author: Benjamin R. Ginter, Allen Day
##   Notice: Copyright (c) 2001 Benjamin R. Ginter, Allen Day
##  Purpose: Extract information about MPEG files.
## Comments: None
##      CVS: $Id: MPEG.pm,v 1.7 2002/11/13 01:05:17 allenday Exp $
##------------------------------------------------------------------------

package Video::Info::MPEG;

use strict;
use IO::File;
#use Video::Info;
use Video::Info::Magic;
use Video::Info::MPEG::Constants;
use Video::Info::MPEG::Audio;
use Video::Info::MPEG::Video;
use Video::Info::MPEG::System;

#use base qw(Video::Info);

use constant DEBUG => 0;

use Class::MakeMethods::Emulator::MethodMaker
  get_set => [
	      'type',
	      'copyright',
	      'comments',
	      
	      'astreams',         #no. of audio streams.  can this clash with achans?
#this has special behavior, method is below
	      'acodec',           #audio codec
	      'acodecraw',        #audio codec (numeric)
	      'arate',            #audio bitrate
	      'achans',           #no. of audio channels.  can this clash with astreams?
	      'afrequency',
	      
	      'vstreams',         #no. of video streams
	      'vcodec',           #video codec
	      'vrate',            #video bitrate
#this has special behavior, method is below
	      #'vframes',          #no. of video frames
	      
	      'fps',              #video frames/second
	      'scale',            #quoeth transcode: if(scale!=0) AVI->fps = (double)rate/(double)scale;
	      'duration',         #duration of video, in seconds
	      
	      'width',            #frame width
	      'height',           #frame height
	      
	      'aspect_raw',       #how to handle this?  16:9 scalar, or 16/9 float?
	      'aspect',           #not sure what this is.  from MPEG
	      
	      '_handle',          #filehandle to bitstream
	      
	      'offset',
	      'last_offset',
	      
	      'header_size',
	      
	      'filesize',
	      'filename',
	      'audio_system_header',
	      'video_system_header',
	      'version',
	      'context',
	      
	      'minutes',
	      'MMSS',
	      'title',
	      'author',
	      'description',
	      'rating',
	      'packets',
	     ],
  new_with_init => 'new',
;

#
### Get the file versions in sync with CVS
#our $VERSION = do { my @r = (q$Version$ =~ /\d+/g); sprintf " %d."."%02d" x $#r, @r };

$| = 1;

sub init {
  my $self = shift;

  $self->offset(0);
  $self->filesize(0);
  $self->audio_system_header(0);
  $self->video_system_header(0);
  $self->version(1);

  $self->init_attributes(@_);

  $self->{audio}  = Video::Info::MPEG::Audio->new( -file => $self->filename);
  $self->{video}  = Video::Info::MPEG::Video->new( -file => $self->filename);
  $self->{system} = Video::Info::MPEG::System->new(-file => $self->filename);
}

sub init_attributes {
  my $self = shift;
  my %raw_param = @_;
  my %param;
  foreach(keys %raw_param){/^-?(.+)/;$param{$1} = $raw_param{$_}};

  foreach my $attr (qw(
					   astreams arate achans vstreams vrate fps
					   scale duration width height aspect aspect_raw
					  )
				   ) {
	$self->$attr(0);
  }

  $self->filename($param{file});
  $self->filesize(-s $self->filename || 0);
  $self->handle($self->filename) if $self->filename;
}

sub handle {
    my($self,$file) = @_;

	if(defined $file){
	  my $fh = new IO::File;
	  $fh->open($file) or die "couldn't open $file";
	  $self->_handle($fh);
	}
    return $self->_handle;
}

##------------------------------------------------------------------------
## Extra methods
##
##------------------------------------------------------------------------
sub minutes {
  my $self = shift;
  my $seconds = int($self->duration) % 60;
  my $minutes = (int($self->duration) - $seconds) / 60;
  return $minutes;
}

sub MMSS {
  my $self = shift;
  my $mm = $self->minutes;
  my $ss = int($self->duration) - ($self->minutes * 60);

  my $return = sprintf( "%02d:%02d",$mm,$ss );
}

##------------------------------------------------------------------------
## probe()
##
## Probe the file for content type
##------------------------------------------------------------------------
sub probe {
    print "probe()\n" if DEBUG;
    my $self      = shift;

    if ( $self->audio->parse ) {
	  print "MPEG Audio Only\n" if DEBUG;
	  $self->type($self->audio->type);
	  $self->acodec($self->audio->acodecraw);
	  $self->astreams(1); #are you sure? could be multiple audio...
	  $self->vstreams(0);
	  $self->arate($self->audio->arate);
	  $self->achans($self->audio->achans);
	  $self->acodecraw($self->audio->acodecraw);
	  $self->acodec(acodec2str($self->acodecraw));
	  return 1;
    }
    elsif ( $self->video->parse ) {
	  print "MPEG Video Only\n" if DEBUG;
	  $self->vstreams(1); #are you sure? could be multiple video...
	  $self->astreams(0);
	  $self->vcodec( 'MPEG1' ) if $self->vcodec eq '';
	  $self->height($self->video->height);
	  $self->width($self->video->width);
	  $self->vrate($self->video->vrate);
	  $self->fps($self->video->fps);
	  $self->type($self->video->type);
	  return 1;
    }
    elsif ( $self->system->parse ) {
	  print "MPEG Audio/Video\n" if DEBUG;
	  $self->astreams(1); #are you sure? could be multiple video...
	  $self->vstreams(1); #are you sure? could be multiple video...
	  $self->type($self->system->video->type);
	  $self->acodecraw($self->system->audio->acodecraw);
	  $self->acodec(acodec2str($self->system->audio->acodecraw));
	  $self->achans($self->system->audio->achans);
	  $self->arate($self->system->audio->arate);
	  $self->fps($self->system->video->fps);
	  $self->height($self->system->video->height);
	  $self->width($self->system->video->width);
	  $self->vcodec( 'MPEG1' ) if $self->vcodec eq '';
      $self->duration($self->system->duration);
	  $self->vrate($self->system->video->vrate);
	  $self->vframes($self->system->video->vframes);
	  $self->comments($self->system->video->comments);
	  return 1;
    }

    return 0;
}

sub audio  { $_[0]->{audio}  };
sub system { $_[0]->{system} };
sub video  { $_[0]->{video}  };
#sub acodecraw { $_[0]->acodec };


##------------------------------------------------------------------------
## parse_system()
##
## Parse a system stream
##------------------------------------------------------------------------
sub parse_system {
    my $self   = shift;
    my $fh     = $self->handle;
    my $offset = 0;

    my ( $pack_start, $pack_len, $pack_head, $packet_size, $packet_type );
    # print '-' x 74, "\n", "Parse System\n", '-' x 74, "\n";

    ## Get the first sequence start code (ssc)
    if ( !$self->next_start_code( PACK_PKT ) ) {
	print "Couldn't find packet start code\n" if DEBUG;
	return 0;
    }

    return 1;
}

##------------------------------------------------------------------------
## parse_user_data()
##
## Parse user data (usually encoder version, etc.)
##
## TODO: Can we use this for annotating video?
##------------------------------------------------------------------------
sub parse_user_data {
    my $self   = shift;
    my $offset = shift;

    # print "\n", '-' x 74, "\nParse User Data\n", '-' x 74, "\n";

    $self->next_start_code( undef, $offset + 1 );

    my $all_printable = 1;
    my $size          = $self->{last_offset} - $offset - 4;

    return 0 if $size <= 0;

    for ( my $i = $offset + 4; $i < $self->{last_offset}; $i++ ) {
	my $char = $self->get_byte( $i );
	if ( $char < 0x20  &&  $char != 0x0A  && $char != 0x0D ) {
	    $all_printable = 0;
	    last;
	}
    }

    if ( $all_printable ) {
	my $data;

	for ( my $i = 0; $i < $size; $i++ ) {
	    $data .= chr( $self->get_byte( $offset + 4 + $i ) );

	}
	$self->{userdata} = $data;
	$self->comments( $data );
	# print $data, "\n";
    }
    return 1;
}

##------------------------------------------------------------------------
## parse_extension()
##
## Parse extensions to MPEG.. hrm, I need some examples to really test
## this. 
##------------------------------------------------------------------------
sub parse_extension {
    my $self   = shift;
    my $offset = ( shift ) + 4;
    
    my $code = $self->get_byte( $offset ) >> 4;
    
    if ( $code == 1 ) {
	return $self->parse_seq_ext( $offset );
    }
    elsif ( $code == 2 ) {
	return $self->parse_seq_display_ext( $offset );
    }
    else {
	die "Unknown Extension: $code\n";
    }
}

##------------------------------------------------------------------------
## parse_seq_ext()
##
## This stuff gets stored in the hashref $self->{sext}.  It will also
## modify width, height, vrate, and fps
##------------------------------------------------------------------------
sub parse_seq_ext {
    my $self   = shift;
    my $offset = shift;
    
    ## We are an MPEG-2 file
    $self->version( 2 );

    my $byte1 = $self->get_byte( $offset + 1 );
    my $byte2 = $self->get_byte( $offset + 2 );

    ## Progressive scan mode?
    if ( $byte1 & 0x08 ) {
	$self->{sext}->{progressive} = 1;
    }
    
    ## Chroma format
    $self->{sext}->{chroma_format} = ( $byte1 & 0x06 ) >> 1;

    ## Width
    my $hsize = ( $byte1 & 0x01 ) << 1;
    $hsize   |= ( $byte2 & 80 ) >> 7;
    $hsize  <<= 12;
    return 0 if !$self->{vstreams};
    $self->{width} |= $hsize;
    
    ## Height
    $self->{height} |= ( $byte2 & 0x60 ) << 7;;
    
    ## Video Bitrate
    my $bitrate = ( $byte2 & 0x1F ) << 7;
    $bitrate   |= ( $self->get_byte( $offset + 3 ) & 0xFE ) >> 1;
    $bitrate  <<= 18;
    $self->{vrate} |= $bitrate;

    ## Delay
    if ( $self->get_byte( $offset + 5 ) & 0x80 ) {
	$self->{sext}->{low_delay} = 1;
    }
    else {
	$self->{sext}->{low_delay} = 0;
    }

    ## Frame Rate
    my $frate_n = ( $self->get_byte( $offset + 5 ) & 0x60 ) >> 5;
    my $frate_d = ( $self->get_byte( $offset + 5 ) & 0x1F );
    
    $frate_n++; 
    $frate_d++;
    
    $self->{fps} = ( $self->{fps} * $frate_n ) / $frate_d;
    
    return 1;
}

##------------------------------------------------------------------------
## parse_seq_display_ext()
## 
## man, some specs would be nice
##------------------------------------------------------------------------
sub parse_seq_display_ext {
    my $self   = shift;
    my $offset = shift;
    
    my @codes = ();
    
    for ( 0..4 ) {
	push @codes, $self->get_byte( $offset + $_ );
    }

    $self->{dext}->{video_format} = ( $codes[0] & 0x0E ) >> 1;
    
    if ( $codes[0] & 0x01 ) {
	$self->{dext}->{colour_prim}   = $codes[1];
	$self->{dext}->{transfer_char} = $codes[2];
	$self->{dext}->{matrix_coeff}  = $codes[3];
	$offset += 3;
    }
    else {
	$self->{dext}->{color_prim}    = 0;
	$self->{dext}->{transfer_char} = 0;
	$self->{dext}->{matrix_coeff}  = 0;
    }

    $self->{dext}->{h_display_size} = $codes[1] << 6;
    $self->{dext}->{h_display_size} |= ( $codes[2] & 0xFC ) >> 2;
    
    $self->{dext}->{v_display_size} = ( $codes[2] & 0x01 ) << 13;
    $self->{dext}->{v_display_size} |= $codes[3] << 5;
    $self->{dext}->{v_display_size} |= ( $codes[4] & 0xF8 ) >> 3;

    return 1;
}

##------------------------------------------------------------------------
## next_start_code()
##
## Find the next sequence start code
##------------------------------------------------------------------------
sub next_start_code {
    my $self       = shift;
    my $start_code = shift;
    my $offset     = shift;
    my $debug      = shift || 0;

    my $fh         = $self->handle;

## huh?
    $offset = $self->{offset} if !defined $offset;
    my $skip = 4;
    if ( !$offset ) {
	  $skip = 1 if !defined $offset;
    }

	if ( DEBUG ) {
	  print "Bytes Per Iteration: $skip\n";
	  print "Got $start_code $offset $debug\n" if defined $start_code;
	  print "Offsets: $offset $self->{offset}\n";
	  print "Seeking to $offset\n" if $offset != $self->{offset};
	}

    seek $fh, $offset, 0;

    ## die "CALLER: ", ref( $self ), " OFFSET: $offset\n";
    while ( $offset <= $self->filesize - 4 ) {

	  #print "Grabbing 4 bytes from $offset\n";
	  #my $code = $self->grab( 4, $offset );
	  #my ( $a, $b, $c, $d ) = unpack( 'C4', pack( "N", $code ) );

	my $a = $self->get_byte( $offset );
	if ( $a != 0x00 ) { $offset++; next; }
	
	my $b = $self->get_byte( $offset + 1 );
	if ( $b != 0x00 ) { $offset += 2; next; };

	my $c = $self->get_byte( $offset + 2 );
	if ( $c != 0x01 ) { $offset += 3; next; };

	my $d = $self->get_byte( $offset + 3 );

	# printf "Found 0x%02x @ %d\n", $d, $offset + 3;
#	if ( $a == 0x00 && $b == 0x00 && $c == 0x01 ) {
	if ( defined $start_code ) {
	    if ( ref( $start_code ) eq 'ARRAY' ) {
		foreach my $sc ( @$start_code ) {
		    if ( $sc == $d ) {
#			    print "Got it @ $offset!\n" if DEBUG;
			$self->{last_offset} = $offset;
			return 1;
		    }
		}
	    } 
	    else {
		if ( $d == $start_code ) {
#			print "Got it @ $offset!\n" if DEBUG;
		    $self->{last_offset} = $offset;
		    return 1;
		}
	    }
	}
	else {
	    $self->{last_offset} = $offset;
	    return $d;
	}
	
	# printf "Skipping 0x%02x 0x%02x 0x%02x 0x%02x @ offset %d\n", $a, $b, $c, $d, $offset;
	$offset++;
    }	
	
    
    return 0 if defined $start_code;
    
    die "No More Sequence Start Codes Found!\n";
}

##------------------------------------------------------------------------
## _last_offset
##
## Return the last_offset from a search 
##------------------------------------------------------------------------
sub _last_offset {
    my $self = shift;
    return $self->{last_offset};
}

##------------------------------------------------------------------------
## grab()
##
## Grab n bytes from current offset
##------------------------------------------------------------------------
sub grab {
    my $self   = shift;
    my $bytes  = shift || 1;
    my $offset = shift;
    my $debug  = shift || 0;

    my $data;
    my $fh     = $self->handle or die "$self: Can't get filehandle: $!\n";

    $offset = $self->{offset} if !defined $offset;

    # print "GRAB: $offset $bytes bytes called from ", ref( $self ), "\n";

    ## Would it be good to cache the bytes we've read to avoid the penalty
    ## of a seek() and read() at the expense of memory?

    # print "grab: seeking to $offset to grab $bytes bytes\n";
    if ( tell( $fh ) != $offset ) {
	seek( $fh, $offset, 0 );
    }
    
    read( $fh, $data, $bytes );

    my $type;

    if ( $bytes == 1 ) {
	$type = 'C';
	# return unpack( 'C', $data );
    }
    elsif ( $bytes == 2 ) {
	$type = 'n';
	# return unpack( 'n', $data );
    }
    elsif ( $bytes == 4 ) {
	$type = 'N';
	# return unpack( 'N', $data );
    }
    else {
	return $data;
    }

    $data = unpack( $type, $data );
#      if ( defined $START_CODE->{ $data } ) {
#  	print "START CODE: $START_CODE->{ $data }\n";
#      }
#      elsif ( defined $STREAM_ID->{$data} ) {
#  	print "STREAM ID: $STREAM_ID->{ $data }\n";
#      }

    return $data;
}

##------------------------------------------------------------------------
## get_byte()
##
## Return a byte from the specified offset
##------------------------------------------------------------------------
sub get_byte {
    my $self = shift;
    return $self->grab( 1, shift );
}

##------------------------------------------------------------------------
## get_header()
##
## Grab the four bytes we need for the header
##------------------------------------------------------------------------
sub get_header {
    my $self = shift;

    ## we only need these four bytes
    ## should do this differently though :|
    return [ $self->get_byte( $self->{offset} ),
	     $self->get_byte( $self->{offset} + 1 ),
	     $self->get_byte( $self->{offset} + 2 ),
	     $self->get_byte( $self->{offset} + 3 ) ];
}

##------------------------------------------------------------------------
## vframes()
## this is just calculated given fps and duration.  MPEG doesn't contain
## this information in the file directly
##------------------------------------------------------------------------
sub vframes {
  my $self = shift;
  return int($self->duration * $self->fps) if $self->duration;
  return 0;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Video::Info::MPEG - Basic MPEG bitstream attribute parser.

=head1 SYNOPSIS

  use strict;
  use Video::Info::MPEG;

  my $video = Video::Info::MPEG->new( -file => $filename );
  $video->probe();

  print $file->type;          ## MPEG

  ## Audio information
  print $file->acodec;        ## MPEG Layer 1/2
  print $file->acodecraw;     ## 80
  print $file->achans;        ## 1
  print $file->arate;         ## 128000 (bits/sec)
  print $file->astreams       ## 1

  ## Video information
  printf "%0.2f", $file->fps  ## 29.97
  print $file->height         ## 240
  print $file->width          ## 352
  print $file->vstreams       ## 1
  print $file->vcodec         ## MPEG1
  print $file->vframes        ## 529
  print $file->vrate          ## 1000000 (bits/sec)

  

=head1 DESCRIPTION

The Moving Picture Experts Group (MPEG) is a working group in 
charge of the development of standards for coded representation 
of digital audio and video.

MPEG audio and video clips are ubiquitous but using Perl to 
programmatically collect information about these bitstreams 
has to date been a kludge at best.  

This module parses the raw bitstreams and extracts information 
from the packet headers.  It supports Audio, Video, and System 
(multiplexed audio and video) packets so it can be used on nearly
every MPEG you encounter.

=head1 METHODS

Video::Info::MPEG is a derived class of Video::Info, a factory module 
C<designed to meet your multimedia needs for many types of files>.  

=over 4

=item new( -file => FILE )

Constructor.  Requires the -file argument and returns an Video::Info::MPEG object.

=item probe()

Parses the bitstreams in the FILE provided to the constructor.  
Returns 1 on success or 0 if the FILE could not be parsed as a valid
MPEG audio, video, or system stream.

=back

=head1 INHERITED METHODS

These methods are inherited from Video::Info.  While Video::Info may have
changed since this documentation was written, they are provided here
for convenience.

=item type()

Returns the type of file.  This should always be MPEG.

=item comments()

Returns the contents of the userdata MPEG extension.  This often contains
information about the encoder software.

=head2 Audio Methods

=over 4

=item astreams()

Returns the number of audio bitstreams in the file.  Usually 0 or 1.


=item acodec()

Returns the audio codec 


=item acodecraw()

Returns the hexadecimal audio codec.


=item achans()

Returns the number of audio channels.


=item arate()

Returns the audio rate in bits per second.

=back


=head2 Video Methods

=over 4

=item vstreams()

Returns the number of video bitstreams in the file.  Usually 0 or 1.

=item fps()

Returns the floating point number of frames per second.

=item height()

Returns the number of vertical pixels (the video height).

=item width()

Returns the number of horizontal pixels (the video width).

=item vcodec()

Returns the video codec (e.g. MPEG1 or MPEG2).

=item vframes()

Returns the number of video frames.

=item vrate()

Returns the video bitrate in bits per second.

=back


=head1 EVIL DIRECT ACCESS TO CLASS DATA

So you secretly desire to be the evil Spock, eh?  Well rub your goatee and
read on.

There are some MPEG-specific attributes that don't yet fit nicely
into Video::Info.  I am documenting them here for the sake of
completeness.  

Note that if you use these, you may have to make changes when 
new versions of this package are released.  There will be elegant
ways to access them in the future but we wanted to get this out there.


=over 4

These apply to audio bitstreams:

=item version

The MPEG version.  e.g. 1, 2, or 2.5

=item layer

The MPEG layer.  e.g. 1, 2, 3.

=item mode

The audio mode.  This is one of:

  Mono
  Stereo
  Dual Channel
  Intensity stereo on bands 4-31/32
  Intensity stereo on bands 8-31/32
  Intensity stereo on bands 12-31/32
  Intensity stereo on bands 16-31/32
  Intensity stereo off, M/S stereo off
  Intensity stereo on, M/S stereo off
  Intensity stereo off, M/S stereo on
  Intensity stereo on, M/S stereo on


=item emphasis

The audio emphasis, if any.

  No Emphasis
  50/15us
  Unknown
  CCITT J 17
  Undefined

=item sampling

The sampling rate (e.g. 22050, 44100, etc.)


=item protect

The value of the protection bit.  This is used to indicate copying
is prohibited but is different than copyright().


These apply to video:

=item aspect 

The aspect ratio if the ratio falls into one of the defined standards.
Otherwise, it's Reserved.

  Forbidden
  1/1 (VGA)
  4/3 (TV)
  16/9 (Large TV)
  2.21/1 (Cinema)
  Reserved

=head1 AUTHORS

Benjamin R. Ginter, <bginter@asicommunications.com>
Allen Day, <allenday@ucla.edu>

=head1 COPYRIGHT

 Copyright (c) 2001-2002
 Aladdin Free Public License (see LICENSE for details)
 Benjamin R. Ginter <bginter@asicommunications.com>, Allen Day <allenday@ucla.edu>

=head1 SEE ALSO

Video::Info
Video::Info::RIFF
Video::Info::ASF

=cut
