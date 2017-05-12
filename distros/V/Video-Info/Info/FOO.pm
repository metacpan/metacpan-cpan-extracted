package Video::Info::FOO;

use strict;
our $VERSION = '0.00';

use base qw(Video::Info);

#######################################
# use this to define your custom
# get/set methods.  if they really
# belong in Video::Info, let me know
#######################################
use Class::MakeMethods::Emulator::MethodMaker
  get_set => [qw( )],
;

#######################################
# leave this intact, add any extra
# init stuff you need (maybe a get/set
# method?).  feel free to override
# init_attributes()
#######################################
sub init {
  my $self = shift;
  my %param = @_;
  $self->init_attributes(@_);
  return $self;
}

#######################################
# Obtain the filehandle and extract the
# properties from the file.  this is
# the core function of the module
#######################################
sub probe {
  my $self = shift;

  my $fh = $self->handle; ## inherited from Video::Info

  while(<$fh>){
    #parse it!
  }

  #####################################
  #return 1 for a successful parse
  #####################################
  return 1;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Video::Info::FOO - what is it useful for?  an example list:

 -video codec
 -audio codec
 -frame height
 -frame width
 -frame count

and more!

=head1 SYNOPSIS

  use Video::Info::FOO;

  my $video;

  $video->vcodec;                         #video codec
  $video->acodec;                         #audio codec
  ...

=head1 DESCRIPTION

What does the module do?  What are it's limitations?  Is it built
on top of other code?  If so, what are the details and where can
I get it?

=head2 METHODS

Video::Info::FOO has one constructor, new().  It is called as:
  -file       => $filename,   #your RIFF file
  -headersize => $headersize  #optional RIFF header size to parse
Returns a Video::Info::FOO object if the file was opened successfully.

The Video::Info::FOO object to parses the file by method probe().  This
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
 ...                 ...
 and_so_on()         ...

=head1 BUGS

Audio codec name mapping is incomplete.  If you know the name
that corresponds to an audio codec ID that I don't, tell
the Video::Info::Magic author, Allen Day <allenday@ucla.edu>.

=head1 AUTHOR

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Your Name <your.name@email.address>

=head1 REFERENCES

 List any references that were used to write Video::Info::FOO,
 preferrably with URLs.

=cut
