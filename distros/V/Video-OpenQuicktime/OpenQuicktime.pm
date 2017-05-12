package Video::OpenQuicktime;

our $VERSION = '1.02';

BEGIN {
  local $/;
  my $var = <DATA>;
#  use Inline Info;
  use Inline C => (
				   Config => (
							  LIBS    => '-lopenquicktime ',
							  NAME    => 'Video::OpenQuicktime',
							  VERSION => '1.02',
							 ),
				  );
  use Inline C => $var;
}

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->init(@_);
  return $self;
}

sub init {
  my $self = shift;
  my %raw = @_;
  my %param;
  foreach(keys %raw){/^-?(.+)/;$param{$1} = $raw{$_}};

  $self->filename($param{file});
  $self->_oqt( $self->init_file() );
}

sub filename {
  my $self = shift;
  $self->{filename} = shift if @_;
  return $self->{filename};
}

sub _oqt {
  my $self = shift;
  $self->{_oqt} = shift if @_;
  return $self->{_oqt};
}

sub init_file {
  my $self = shift;

  # there are some problems with the loading codec code
  # throwing diagnostics to STDERR... we trap STDERR here
  # to shut it up.

  #<SHUTUP>
  open(TERR,">&STDERR");
  close(STDERR);
  open(STDERR,'>/dev/null');
  #</SHUTUP>

  my $oqt_address = $self->new_oqt($self->filename);

warn $oqt_address;

  #<SPEAK>
  close(STDERR);
  open(STDERR,">&TERR");
  close(TERR);
  #</SPEAK>

  return $oqt_address;  #returns an int pointer
}

sub get_audio_bits { return $_[0]->_get_audio_bits( $_[0]->_oqt , 0 ); }
sub get_audio_channels { return $_[0]->_get_audio_channels( $_[0]->_oqt , 0 ); }
sub get_audio_codec { return $_[0]->_get_audio_codec( $_[0]->_oqt , 0 ); }

sub get_audio_compressor { 
  if($_[0]->get_audio_bits( $_[0]->_oqt , 0 )){
	return $_[0]->_get_audio_compressor( $_[0]->_oqt , 0 );
  } else {
	return undef;
  }
}

sub get_audio_length { return $_[0]->_get_audio_length( $_[0]->_oqt , 0 ); }
sub get_audio_samplerate { return $_[0]->_get_audio_samplerate( $_[0]->_oqt , 0 ); }
sub get_audio_track_count { return $_[0]->_get_audio_track_count( $_[0]->_oqt ); }

sub get_info { return $_[0]->_get_info( $_[0]->_oqt ); }
sub get_name { return $_[0]->_get_name( $_[0]->_oqt ); }
sub get_copyright { return $_[0]->_get_copyright( $_[0]->_oqt ); }

sub get_video_codec { return $_[0]->_get_video_codec( $_[0]->_oqt, 0 ); }
sub get_video_compressor { return $_[0]->_get_video_compressor( $_[0]->_oqt , 0 ); }
sub get_video_depth { return $_[0]->_get_video_depth( $_[0]->_oqt , 0 ); }
sub get_video_framerate { return $_[0]->_get_video_framerate( $_[0]->_oqt , 0); }
sub get_video_framesize { return $_[0]->_get_video_framesize( $_[0]->_oqt , 0); }
sub get_video_height { return $_[0]->_get_video_height( $_[0]->_oqt , 0); }
sub get_video_keyframe_after { return $_[0]->_get_video_keyframe_after( $_[0]->_oqt ); }
sub get_video_keyframe_before { return $_[0]->_get_video_keyframe_before( $_[0]->_oqt ); }
sub get_video_length { return $_[0]->_get_video_length( $_[0]->_oqt , 0); }
sub get_video_param { return $_[0]->_get_video_param( $_[0]->_oqt ); }
sub get_video_position { return $_[0]->_get_video_position( $_[0]->_oqt ); }
sub get_video_track_count { return $_[0]->_get_video_track_count( $_[0]->_oqt ); }
sub get_video_width { return $_[0]->_get_video_width( $_[0]->_oqt , 0); }
sub length { return $_[0]->_get_video_length( $_[0]->_oqt , 0 ) / $_[0]->_get_video_framerate( $_[0]->_oqt , 0 ); }




1;

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Video::OpenQuicktime - An interface to the OpenQuicktime library.

=head1 SYNOPSIS

  use Video::OpenQuicktime;

  my $qt = Video::OpenQuicktime->new(file=>"sample.mov");
  $qt->get_video_height;
  $qt->get_audio_compression;
  $qt->get_audio_samplerate;

=head1 DESCRIPTION

From the OpenQuicktime site, http://www.openquicktime.org:

"OpenQuicktime aims to be a portable library for handling Apple's
QuickTime(TM) popular media files on Unix-like environments. It is
aim is to provide encoding, authoring and editing support as well
as video playback."

OpenQuicktime is currently able to decode as well as encode video
and audio streams.  The Video::OpenQuicktime library currently
only supports extracting diagnostic information from Quicktime files,
such as video dimensions, codecs used, and play length.

I would like to add support for video and audio demux at some point,
but don't have the time to develop it right now.  Given sufficient
user interest or free time, I'll do it.  Patches are also welcome
in case anyone else wants to help me out, see the contact information
below.

=head2 METHODS

A subset of the OpenQuicktime API is currently supported.  Listed
below are the supported methods, details are available at:

  http://www.openquicktime.org/docs/

The methods in the API are prefixed by oqt_.  I've dropped the prefix
for the Video::OpenQuicktime module.  So get_audio_bits() is an internal
call to oqt_get_audio_bits().

 get_audio_bits
 get_audio_channels
 get_audio_compressor
 get_audio_length
 get_audio_samplerate
 get_audio_track_count
 get_copyright
 get_info
 get_name
 get_video_compressor
 get_video_depth
 get_video_framerate
 get_video_height
 get_video_length
 get_video_track_count
 get_video_width

=head1 AUTHOR

Allen Day <allenday@ucla.edu>
Copyright (c) 2002, Allen Day

=head1 LICENSE

Aladdin Free Public License, Version 8
(see LICENSE file in distribution)

=head1 REFERENCES

OpenQuicktime: documentation for openquicktime.h
  http://www.openquicktime.org/docs/

=cut

__DATA__
__C__
#include "openquicktime/openquicktime.h"
#include "openquicktime/codecs.h"
//#include "openquicktime/structs.h"
//#include "openquicktime/plugin.h"
#include "openquicktime/colormodels.h"
#include "openquicktime/config.h"

int long_display = 1;

int _get_audio_bits(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_audio_bits(qtfile,track);
}

int _get_audio_channels(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_track_channels(qtfile,track);
}

int _get_audio_codec(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_init_acodec(qtfile, (quicktime_audio_map_t *) track);
}

//char* _get_audio_codec(char *self, int address, int track){
//  quicktime_t *qtfile = (quicktime_t *) address;
//  return quicktime_audio_codec(qtfile,track);
//}
//
char* _get_audio_compressor(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_audio_compressor(qtfile,track);
}

int _get_audio_length(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_audio_length(qtfile,track);
}

int _get_audio_samplerate(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_sample_rate(qtfile,track);
}
int _get_audio_track_count(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_audio_tracks(qtfile);
}

////int quicktime_audio_channel_loc(char *self, int address){}
////int quicktime_audio_frames_to_bytes(char *self, int address){}
////int quicktime_audio_param(char *self, int address){}
//// quicktime_audio_position(char *self, int address){}
//
//int _get_info_count(char *self, int address){
//  quicktime_t *qtfile = address;
//  return quicktime_info_count(qtfile);
//}

char* _get_info(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_get_info(qtfile);
}

char* _get_name(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_get_name(qtfile);
}

char* _get_copyright(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_get_copyright(qtfile);
}

char* _get_video_compressor(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_compressor(qtfile, track);
}

int _get_video_depth(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_depth(qtfile, track);
}

int _get_video_framerate(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_frame_rate(qtfile, track);
}

/*
#########################
int _get_info_list(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_info_list(qtfile);
}

int _get_info_name(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_info_name(qtfile);
}

int _get_info_value(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_info_value(qtfile);
}

int _get_video_codec(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_codec(qtfile, track);
}

int _get_video_framesize(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_framesize(qtfile, track);
}

int _get_video_keyframe_after(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_keyframe_after(qtfile);
}

int _get_video_keyframe_before(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_keyframe_before(qtfile);
}

int _get_video_param(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_param(qtfile);
}

int _get_video_position(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_position(qtfile);
}
#########################
*/


int _get_video_height(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_height(qtfile, track);
}

int _get_video_length(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
//ad  return oqt_get_video_length(qtfile, track);
  return quicktime_video_length(qtfile, track);
}

int _get_video_track_count(char *self, int address){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_tracks(qtfile);
}


int _get_video_width(char *self, int address, int track){
  quicktime_t *qtfile = (quicktime_t *) address;
  return quicktime_video_width(qtfile, track);
}

int new_oqt(char *self, char *filename) {

  int *qtfile = malloc(sizeof(quicktime_t));
  qtfile = quicktime_open(filename,1,0); //filename, read, write
  if(!qtfile) {
	return -1; //couldn\'t open *filename
  }

  // Read headers
  //if(oqt_read_headers(qtfile)) {
  //  oqt_close(qtfile);
  //  return -1; //couldn\'t read movie headers
  //}

  return (int) qtfile;
}
//
//char* get_oqt(char *self, int address) {
////ad  quicktime_t *qtfile = address;
//  quicktime_t *qtfile = address;
//  return "asdf";
//}
//
//void display_file_annotations(quicktime_t* file) {
//  int i,n = quicktime_info_count(file);
//  oqt_udta_t* info = quicktime_info_list(file);
//
//  if (!long_display) printf("  %d annotations.\n", n);
//  for(i=0;i<n;i++) {
//	const char* name = quicktime_info_name(info[i].code);
//	if (!long_display) printf("  ");
//	
//	if (name)       printf("  %s:", name);
//	else            printf("  %.4s:", info[i].code);
//	
//	if (info[i].value)      printf(" %s\n", info[i].value);
//	else printf(" \n");
//  }
//}
//
//void file_info(char *filename) {
//  quicktime_t* qtfile;
//  int i, n;
//
//  // Open the file
//  qtfile = oqt_open(filename);
//  if(!qtfile) {
//	fprintf(stderr, "Couldn't open file %s.\n", filename);
//	return;
//  }
//
//  // Display I/O inforamtion
//  printf("\nStream Type: %s\n", qtfile->stream_type);
//  printf(  "Reference: %s\n", qtfile->stream_reference);
//
//  // Read headers
//  if(oqt_read_headers(qtfile)) {
//	oqt_close(qtfile);
//	printf("Could not read movie headers.\n");
//	return;
//  }
//
//  display_file_annotations(qtfile);
//
//  // Loop through all the audio tracks
//  n = quicktime_audio_track_count(qtfile);
//  if (!long_display) printf("  %d audio tracks.\n", n);
//  for(i = 0; i < n; i++) {
//	char* codec_code = quicktime_audio_compressor(qtfile, i);
//	oqt_int64 audio_length = quicktime_audio_length(qtfile, i);
//	int audio_rate = quicktime_audio_samplerate(qtfile, i);
//	
//	if (long_display) {
//	  printf("  Audio Track %d.\n", i);
//	  printf("    Channels: %d\n", quicktime_audio_channels(qtfile, i));
//	  printf("    Bits: %d\n", quicktime_audio_bits(qtfile, i));
//	  printf("    Sample Rate: %d\n", audio_rate);
//	  printf("    Length: %lld\n", audio_length);
//	  printf("    Duration: %.2f\n", (float)audio_length/audio_rate);
//	  printf("    Hex: 0x%.8x\n", *((int*)codec_code));
//	  printf("    Signature: %.4s\n", codec_code);
//	} else {
//	  printf("    %d channels. %d bits. sample rate %d. length %lld. duration %.2f secs.\n",
//			 quicktime_audio_channels(qtfile, i),
//			 quicktime_audio_bits(qtfile, i),
//			 audio_rate, audio_length,
//			 (float)audio_length/audio_rate);
//	}
//
//	// Is the audio codec supported ?
//	if (oqt_supported_audio(qtfile, i)) {
//	  const oqt_codec_info_t* codec_info = quicktime_audio_codec(qtfile, i);
//	  if (long_display) {
//		printf("    Supported: Yes\n");
//		printf("    Codec Name: %s\n", codec_info->name);
//		printf("    Codec Version: %s\n", codec_info->version);
//	  } else {
//		printf("    Supported using '%s' codec [%.4s] version %s.\n",
//			   codec_info->name,
//			   codec_code,
//			   codec_info->version);
//	  }
//	} else {
//	  if (long_display)       printf("    Supported: No\n");
//	  else printf("    Compressor not supported [%.4s].\n", codec_code);
//	}
//  }
//
//  // Loop through all the Video tracks
//  n = quicktime_video_track_count(qtfile);
//  if (!long_display) printf("  %d video tracks.\n", n);
//  for(i = 0; i < n; i++) {
//	char* codec_code = quicktime_video_compressor(qtfile, i);
//	float video_rate = quicktime_video_framerate(qtfile, i);
//	oqt_int64 video_length = quicktime_video_length(qtfile, i);
//	
//	if (long_display) {
//	  printf("  Video Track %d.\n", i);
//	  printf("    Width: %d\n", quicktime_video_width(qtfile, i));
//	  printf("    Height: %d\n", quicktime_video_height(qtfile, i));
//	  printf("    Depth: %d\n", quicktime_video_depth(qtfile, i));
//	  printf("    Rate: %f\n", video_rate);
//	  printf("    Length: %lld\n", video_length);
//	  printf("    Duration: %.2f\n", video_length/video_rate);
//	  printf("    Hex: 0x%.8x\n", *((int*)codec_code));
//	  printf("    Signature: %.4s\n", codec_code);
//	} else {
//	  printf("    %dx%d. depth %d. rate %f. length %lld. duration %.2f secs.\n",
//			 quicktime_video_width(qtfile, i),
//			 quicktime_video_height(qtfile, i),
//			 quicktime_video_depth(qtfile, i),
//			 video_rate, video_length,
//			 video_length/video_rate);
//	}
//
//	// Is the video codec supported ?
//	  if (oqt_supported_video(qtfile, i)) {
//		const oqt_codec_info_t* codec_info = quicktime_video_codec(qtfile, i);
//		if (long_display) {
//		  printf("    Supported: Yes\n");
//		  printf("    Codec Name: %s\n", codec_info->name);
//		  printf("    Codec Version: %s\n", codec_info->version);
//		} else {
//		  printf("    Supported using '%s' codec [%.4s] version %s.\n",
//				 codec_info->name,
//				 codec_code,
//				 codec_info->version);
//		}
//	  } else {
//		if (long_display)       printf("    Supported: No\n");
//		else printf("    Compressor not supported [%.4s].\n", codec_code);
//	  }
//  }
//
//  // Close the file
//  oqt_close(qtfile);
//}
//
