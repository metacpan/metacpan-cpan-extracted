##------------------------------------------------------------------------
##  Package: Info.pm
##   Author: Benjamin R. Ginter, Allen Day
##   Notice: Copyright (c) 2002 Benjamin R. Ginter, Allen Day
##  Purpose: Retrieve Video Properties
## Comments: None
##      CVS: $Id
##------------------------------------------------------------------------

package Video::Info;

use strict;
use Video::Info::Magic;
use IO::File;

our $VERSION = '0.993';

use Class::MakeMethods::Emulator::MethodMaker
  get_set => [
			  'type',             #ASF,MPEG,RIFF...
			  'title',            #ASF media title
			  'author',           #ASF author
			  'date',             #ASF date (units???)
			  'copyright',        #ASF copyright
			  'description',      #ASF description (freetext)
			  'rating',           #ASF MPAA rating
			  'packets',          #ASF ???
			  'comments',         #MPEG

			  'astreams',         #no. of audio streams.  can this clash with achans?
#this has special behavior, method is below
#			  'acodec',           #audio codec
			  'acodecraw',        #audio codec (numeric)
			  'arate',            #audio bitrate
			  'afrequency',       #audio sampling frequency, in Hz
			  'achans',           #no. of audio channels.  can this clash with astreams?

			  'vstreams',         #no. of video streams
			  'vcodec',           #video codec
			  'vrate',            #video bitrate
			  'vframes',          #no. of video frames

			  'fps',              #video frames/second
			  'scale',            #quoeth transcode: if(scale!=0) AVI->fps = (double)rate/(double)scale;
			  'duration',         #duration of video, in seconds

			  'width',            #frame width
			  'height',           #frame height

			  'aspect_raw',       #how to handle this?  16:9 scalar, or 16/9 float?
			  'aspect',           #not sure what this is.  from MPEG

			  'filename',         #the sourcefile name
			  'filesize',         #the size of the source file

			  '_handle',          #filehandle to bitstream
			 ],
;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = bless {}, $class;

  $self = $self->init(@_);

  return $self;
}

sub init {
  my($self,%raw) = @_;
#  my($proto,%raw) = @_;
#  my $class = ref($proto) || $proto;
#  my $self = bless {}, $class;

  my %param;
  foreach(keys %raw){/^-?(.+)/;$param{$1} = $raw{$_}};

  if($param{file}){
	my($filetype,$handler) = @{ divine($param{file}) };

	if($handler){
	  my $class = __PACKAGE__ . '::' . $handler;

	  $class = 'MP3::Info' if $handler eq 'MP3';

	  my $has_class = eval "require $class";
	  $param{subtype} = $filetype;

	  if($has_class){
		if($handler eq 'MP3'){
		  $self = $class->new( $param{file} );
		  return $self;
		} else {
		  $self = $class->new(%param);
		  $self->probe( $param{file}, [ $filetype, $handler ] );
		}
	  }
	}
  }

  $self->{$_} = $param{$_} foreach(keys %param);

  $self->init_attributes(%param) ;

  $self->probe( $param{file} );

  return $self;
}

sub init_attributes {
  my $self = shift;
  my %raw = @_;
  my %param;
  foreach(keys %raw){/^-?(.+)/;$param{$1} = $raw{$_}};

  foreach my $attr (qw(
					   astreams arate achans vstreams vrate vframes fps
					   scale duration width height aspect aspect_raw
					  )
				   ) {
	$self->$attr(0);
  }

  $self->filename($param{file});
  $self->filesize(-s $param{file});
  $self->handle($param{file}) if $param{file};
}

##------------------------------------------------------------------------
## Extra methods
##
##------------------------------------------------------------------------
sub acodec {
  my($self,$arg) = @_;
  if($arg){
	$self->{acodec} = acodec2str($arg);
  } elsif(!$self->{acodec}){
	$self->{acodec} = acodec2str($self->acodecraw);
  }
  return $self->{acodec};
}

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
## handle()
##
## Open a file handle or return an existing one
##------------------------------------------------------------------------
sub handle {
    my($self,$file) = @_;

	if(defined $file){
	  my $fh = new IO::File;
	  $fh->open($file);
	  $self->_handle($fh);
	}
    return $self->_handle;
}

##------------------------------------------------------------------------
## probe()
##
## Open a video file and gather the stats
##------------------------------------------------------------------------
sub probe {
    my $self = shift;
    my $file = shift || die "probe(): A filename argument is required.\n";
    my $type = shift || divine($file) || die "probe(): Couldn't divine $file";

    my $warn;
    if ( $type->[1] ) {
	$warn .= "s of type $type->[1]\n";
    }
    else {
	$warn .= " type $type->[0]\n";
    }
    warn( ref( $self ),
	  '::probe() abstract method -- Create a child class for file',
	  $warn );
	  
}

1;

__END__

=head1 NAME

Video::Info - Retrieve video properties
such as:
 height
 width
 codec
 fps

=head1 SYNOPSIS

  use Video::Info;

  my $info = Video::Info->new(-file=>'my.mpg');

  $info->fps();
  $info->aspect();
  ## ... see methods below

=head1 DESCRIPTION

Video::Info is a factory class for working with video files.
When you create a new Video::Info object (see methods), 
something like this will happen:
 1) open file, determine type. See L<Video::Info::Magic>.
 2) attempt to create object of appropriate class
    (ie, MPEG::Info for MPEG files, RIFF::Info for AVI
    files).
 3) Probe the file for various attributes
 4) return the created object, or a Video::Info object
    if the appropriate class is unavailable.

Currently, Video::Info can create objects for the
following filetypes:

  Module                 Filetype
  -------------------------------------------------
  Video::Info::ASF              ASF
  MP3::Info              MPEG Layer 2, MPEG Layer 3
  Video::Info::MPEG      MPEG1, MPEG2, MPEG 2.5
  Video::Info::RIFF      AVI, DivX
  Video::Info::Quicktime MOV, MOOV, MDAT, QT

And support is planned for:

  Module                 Filetype
  -------------------------------------------------
  Video::Info::Real      RealNetworks formats

=head1 METHODS

=head2 CONSTRUCTORS AND FRIENDS

new(): Constructor for a Video::Info object.  new() is called
with the following arguments:

  Argument    Default    Description
  ------------------------------------------------------------
  -file       none        path/to/file to create an object for
  -headersize 10240       how many bytes of -file should be
                          sysread() to determine attributes?

probe(): The core of each of the manufactured modules 
(with the exception of MP3::Info, which we manufacture 
only as courtesy), is in the probe() method.  probe() 
does a (series of) sysread() to determine various attributes 
of the file.  You don't need to call probe() yourself, it is 
done for you by the constructor, new().

=head2 METHODS

These methods should be available for all manufactured classes
(except MP3::Info):

=head2 Audio Methods

=over 4

=item achans()

Number of audio channels. 0 for no sound, 1 for mono,2 for 
stereo.  A higher value is possible, in principle.

=item acodec()

Name of the audio codec.

=item arate()

bits/second dedicated to an audio stream.

=item astreams()

Number of audio streams.  This is often >1 for files with 
multiple audio tracks (usually in different languages).

=item afrequency()

Sampling rate of the audio stream, in Hertz.

=back

=head2 Video Methods

=over 4

=item vcodec()

Name of the video codec.

=item vframes()

Number of video frames.

=item vrate()

average bits/second dedicated to a video stream.

=item vstreams()

Number of video streams.  0 for audio only.  This may be 
>1 for multi-angle video and the like, but I haven't seen
it yet.

=item fps()

How many frames/second are displayed.

=item width()

video frame width, in pixels.

=item height()

video frame height, in pixels.

=back

=head2 Other Methods

=over 4

=item filename()

path to the file used to create the video object

=item filesize()

size in bytes of filename()

=item type()

file type (RIFF, ASF, etc).

=item duration()

file length in seconds

=item minutes()

file length in minutes, rounded down

=item MMSS()

file length in minutes + seconds, in the format MM:SS

=item geometry()

Ben?

=item title()

Title of the file content.  Not the filename.

=item author()

Author of the file content.

=item copyright()

Copyright, if any.

=item description()

Freetext description of the content.

=item rating()

This is for an MPAA rating (PG, G, etc).

=item packets()

Number of data packets in the file.


=head1 AUTHORS

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day, <allenday@ucla.edu>
 Benjamin R. Ginter <bginter@asicommunications.com>

=head1 SEE ALSO

L<Video::Info::Magic>
L<Video::Info::ASF>
L<Video::Info::MPEG>
L<Video::Info::Quicktime>
L<Video::Info::RIFF>

=cut
