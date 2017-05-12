package Video::FFmpeg::AVFormat;
use Video::FFmpeg;
use Switch;

our $VERSION = '0.47';

sub new {
	$i = Video::FFmpeg::AVFormat::open($_[1]);
}

sub streams {
    my ($self) = @_;
    my @streams;
	for(0 .. $self->nb_streams-1){
		my $stream = $self->get_stream($_);
		switch($stream->codec_type){
			case "video" {
				bless $stream, 'Video::FFmpeg::AVStream::Video';
				push @streams, $stream;
			}
			case "audio" {
				bless $stream, 'Video::FFmpeg::AVStream::Audio';
				push @streams, $stream;
			}
			case "subtitle" {
				bless $stream, 'Video::FFmpeg::AVStream::Subtitle';
				push @streams, $stream;
			}
			else {
				push @streams, $stream;
			}
		}
	};
    return @streams;
}
	
sub audio {
    my ($self) = @_;
    my @streams;
    for(0 .. $self->nb_streams-1){
		my $stream = $self->get_stream($_);
		if($stream->codec_type eq "audio"){
			bless $stream, Video::FFmpeg::AVStream::Audio;
			return $stream if(!wantarray);
	        push @streams, $stream;
		};
    };
    return @streams;
};

sub video {
    my ($self) = @_;
    my @streams;
    for(0 .. $self->nb_streams-1){
		my $stream = $self->get_stream($_);
		if($stream->codec_type eq "video"){
			bless $stream, Video::FFmpeg::AVStream::Video;
			return $stream if(!wantarray);
	        push @streams, $stream;
		};
    };
    return @streams;
};

sub subtitle {
    my ($self) = @_;
    my @streams;
    for(0 .. $self->nb_streams-1){
		my $stream = $self->get_stream($_);
		if($stream->codec_type eq "subtitle"){
			bless $stream, Video::FFmpeg::AVStream::Subtitle;
			return $stream if(!wantarray);
	        push @streams, $stream;
		};
    };
    return @streams;
};

1;
__END__

=head1 NAME

Video::FFmpeg::AVFormat - Retrieve video properties using libavformat such as: height width codec fps

=head1 SYNOPSIS

  use Video::FFmpeg;
  use Switch;

  my $info = Video::FFmpeg::AVFormat->new($ARGV[0]);

  print "Duration: ",$info->duration,"\n";

  my @video = $info->video;
  print "num video streams: ",$#video+1,"\n";
  my @audio = $info->audio;
  print "num audio streams: ",$#audio+1,"\n";
  my @sub = $info->subtitle;
  print "num sub streams: ",$#sub+1,"\n";

  my @streams = $info->streams;
  for my $id (0 .. $#streams){
    my $stream = $streams[$id];
    print $stream->codec_type,"stream $id\n";
    print "\ttype: ",$stream->codec_type,"\n";
    print "\tcodec: ",$stream->codec,"\n";
    print "\tlanguage: ",$stream->lang,"\n";
    switch($stream->codec_type){
      case "video" {
        print "\tfps: ",$stream->fps,"\n";
        print "\tDAR: ",$stream->display_aspect,"\n";
      }
      case "audio" {
        print "\tsample rate: ",$stream->sample_rate,"hz\n";
        print "\taudio language: ",$stream->lang,"\n";
      }
      case "subtitle" {
        print "\tsub codec: ",$stream->codec,"\n";
        print "\tsub language: ",$stream->lang,"\n";
      }
    }
  };

=head1 METHODS

=head2 The Video::FFmpeg::AVFormat class

=head3 Video::FFmpeg::AVFormat->new($file)

AVFormat Constructor

=head3 filename

returns the filename

=head3 duration

duration of the stream, in HH:MM:SS.MS. 

=head3 start_time

position of the first frame of the component, in microseconds

=head3 bit_rate

total stream bitrate in bit/s, 0 if not available. 

=head3 video

if called in scalar context, returns the first Video::FFmpeg::AVStream::Video object. if called in list context, it returns all Video::FFmpeg::AVStream::Video objects

=head3 audio

if called in scalar context, returns the first Video::FFmpeg::AVStream::Audio object. if called in list context, it returns all Video::FFmpeg::AVStream::Audio objects

=head3 subtitles

if called in scalar context, returns the first Video::FFmpeg::AVStream::Subtitle object. if called in list context, it returns all Video::FFmpeg::AVStream::Subtitle objects

=head3 streams

returns a list of all Video::FFmpeg::AVStream objects.


=head2 The Video::FFmpeg::AVStream class

=head3 codec

name of the codec

=head3 codec_type

returns one of "audio", "video", "subtitle", "data", "attachment", "data", or "unknown"

=head3 lang

returns the stream's language

=head2 The Video::FFmpeg::AVStream::Audio class

=head3 bit_rate

the average bitrate in bit/s

=head3 sample_rate

samples per second (hz)

=head3 channels

number of audio channels 

=head2 The Video::FFmpeg::AVStream::Video class

=head3 width

picture width

=head3 height

picture height

=head3 fps

frames per second, 0 if not available. 

=head3 display_aspect

aspect ratio of the picture in "W:H" format

=head3 pixel_aspect

aspect ratio of the pixels in "W:H" format, or undef if not defined;

=head1 DESCRIPTION

Video::FFmpeg is a factory class for working with video files. Video::FFmpeg utilises FFmpeg's libavformat, and provides a basic interface.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over 4

=item L<Video::FFmpeg>

=item L<Video::FFmpeg::AVFormat>

=item L<Video::FFmpeg::AVStream>

=item L<Video::FFmpeg::AVStream::Audio>

=item L<Video::FFmpeg::AVStream::Video>

=item L<Video::FFmpeg::AVStream::Subtitle>

=item L<html://www.seattlenetworks.com/perl/FFmpeg>

=back

=head1 TODO

=head1 AUTHOR

Max Vohra, E<lt>max@seattlenetworks.comE<gt> L<html://www.seattlenetworks.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Max Vohra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
