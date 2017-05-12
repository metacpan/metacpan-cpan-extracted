package Video::Info::RIFF;

use strict;
our $VERSION = '1.07';

use base qw(Video::Info);

#is this reasonable?  big fudge factor here.
use constant MAX_HEADER_BYTES => 10240;

use Class::MakeMethods::Emulator::MethodMaker
  get_set => [qw( fourcc )],
;

sub init {
  my $self = shift;
  my %param = @_;
  $self->init_attributes(@_);
  $self->header_size($param{-headersize} || MAX_HEADER_BYTES);
  return $self;
}

##------------------------------------------------------------------------
## header_size()
##
## Set the header size.  Hrm, should this be in the accessor method
## closures above?
##------------------------------------------------------------------------
sub header_size {
  my($self,$arg) = @_;
  return $self->{header_size} unless defined $arg;
  $self->{header_size} = $arg;
}

sub expectedsize {
  my($self,$arg) = @_;
  return $self->{expectedsize} unless defined $arg;
  $self->{expectedsize} = $arg;
}

##------------------------------------------------------------------------
## probe()
##
## Obtain the filehandle from Video::Info and extract the properties from
## the RIFF structure.
##------------------------------------------------------------------------
sub probe {
  my $self = shift;

  my $fh = $self->handle; ## inherited from Video::Info

  my $type;
  sysread($fh,$type,12) or die "probe(): can't read 12 bytes: $!\n";

  (warn "probe(): doesn't look like RIFF data" and return 0)
    if( ($type !~ /^(RIFF)/) && ($type !~ /^(AVI) /) );
  $self->type( $1 );

  $self->expectedsize(unpack("V",substr($type,4,4)));

  #onward
  my $hdrl_data = undef;

  while ( !$hdrl_data ) {
      my $byte;
      sysread($fh,$byte,8) or die "probe(): can't read 8 bytes: $!";
      if ( substr( $byte, 0, 4 ) eq 'LIST' ) {
	  sysread( $fh, $byte, 4 ) or die "probe() can't read 4 bytes: $!\n";
	  
	  if ( substr( $byte, 0, 4 ) eq 'hdrl' ) {
	      sysread( $fh, $hdrl_data, $self->header_size );
	  } elsif ( $byte eq 'movi' ) {
	      ### noop
	  }
      } elsif ( $byte eq 'idx1' ) {
	  ### noop
      }
  }
  
  my $last_tag = 0;
  for ( my $i=0; $i < length($hdrl_data); $i++ ) {
      
      my $t = $i;
      my $window = substr( $hdrl_data, $t, 4 );
 
     if ( $window eq 'strh' ) {

	  $t += 8;
	  $window = substr( $hdrl_data, $t, 4 );
	  
	  if ( $window eq 'vids' ) {
	      $self->fourcc(substr($hdrl_data,$t+4,4));
	      $self->scale(unpack("V",substr($hdrl_data,$t+20,4)));
	      $self->vrate(unpack("V",substr($hdrl_data,$t+24,4)));
	      $self->fps($self->vrate / $self->scale);
	      $self->vframes(unpack("V",substr($hdrl_data,$t+32,4)));
	      $self->vstreams( ($self->vstreams || 0) + 1 );;
	      
              $self->duration($self->vframes / $self->fps) if $self->fps;

              $last_tag = 1;
	      
	  } elsif($window eq 'auds') {
	      $self->astreams( ($self->astreams || 0) + 1);
	      $last_tag = 2;
   
	  }
      } 
      elsif ( $window eq 'strf' ) {
	  
	  $t += 8;
	  $window = substr( $hdrl_data, $t, 4 );
	  
	  if ( $last_tag == 1 ) {
	      $self->width(unpack("V",substr($hdrl_data,$t+4,4)));
	      $self->height(unpack("V",substr($hdrl_data,$t+8,4)));
	      $self->vcodec(substr($hdrl_data,$t+16,4));
	      
	  } elsif( $last_tag == 2 ) {
	      $self->acodecraw(unpack("v",substr($hdrl_data,$t,2)));
	      $self->achans(unpack("v",substr($hdrl_data,$t+2,2)));
	      $self->afrequency(unpack("v",substr($hdrl_data,$t+4,2)));
	      $self->arate(
                           8 * unpack("V",substr($hdrl_data,$t+8,4))
                          );
	      
	  }
	  
	  $last_tag = 0;
      }
  }
  return 1;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Video::Info::RIFF - Probe DivX and AVI files for attributes
like:

 -video codec
 -audio codec
 -frame height
 -frame width
 -frame count

and more!

=head1 SYNOPSIS

  use Video::Info::RIFF;

  my $video;

  $video = Video::Info::RIFF->new(-file=>$filename);                          #like this
  $video = Video::Info::RIFF->new(-file=>$filename,-headersize=>$headersize); #or this

  $video->vcodec;                         #video codec
  $video->acodec;                         #audio codec
  ...

=head1 DESCRIPTION

RIFF stands for Resource Interchange File Format, in case you were wondering.
The morbidly curious can find out more below in I<REFERENCES>.

=head2 METHODS

Video::Info::RIFF has one constructor, new().  It is called as:
  -file       => $filename,   #your RIFF file
  -headersize => $headersize  #optional RIFF header size to parse
Returns a Video::Info::RIFF object if the file was opened successfully.

The Video::Info::RIFF object to parses the file by method probe().  This
does a series of sysread()s on the file to figure out what the
properties are.

Now, call one (or more) of these methods to get the low-down on
your file:

 method              returns
 ---------------------------------------------------
 achans()            number of audio channels
 acodec()            audio codec
 acodecraw()         audio codec numeric ID
 arate()             audio bitrate
 afrequency()        sampling rate of audio streams, in Hertz
 astreams()          number of audio streams
 filename()          path file used to create object
 filesize()          size in bytes of filename()
 expectedsize()      expected size in bytes of filename(),
                     according to the RIFF header
 fourcc()            RIFF Four Character Code
 fps()               frames/second
 height()            frame height in pixels
 probe()             try to determine filetype
 scale()             video bitrate
 type()              type of file data.  RIFF or AVI
 vcodec()            video codec
 vframes()           number of frames
 vrate()             video bitrate
 vstreams()          number of video streams
 width()             frame width in pixels

=head1 BUGS

The default header_size() (10K) may not be large enough to 
successfully extract the video/audio attributes for all RIFF 
files.  If this module fails you, increase the RIFF header size.
If it still fails, let me know.

Audio codec name mapping is incomplete.  If you know the name
that corresponds to an audio codec ID that I don't, tell me.

=head1 AUTHOR

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day <allenday@ucla.edu>

=head1 REFERENCES

Transcode, a linux video stream processing tool:
  http://www.theorie.physik.uni-goettingen.de/~ostreich/transcode/

Microsoft RIFF:
  http://www.oreilly.com/centers/gff/formats/micriff/

=cut
