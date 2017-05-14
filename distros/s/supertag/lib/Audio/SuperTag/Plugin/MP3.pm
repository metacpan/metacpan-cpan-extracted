package Audio::SuperTag::Plugin::MP3;

use base qw/Audio::SuperTag::Plugin/;
use MP3::Info qw/get_mp3tag set_mp3tag get_mp3info/;
use strict;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $file = shift;
  return bless [ $file ] => $class;
}

sub file {
  return shift->[0];
}

sub filetype {
  return 'mp3';
}

sub get_tags {
  my $self = shift;
  return get_mp3tag($self->file, @_);
}

sub set_tags {
  my $self = shift;
  my $tags = shift;
  # FIXME apparently MP3::Info only sets id3v1? 
  return set_mp3tag($self->file, $tags);
}

sub get_audio_info {
  my $self = shift;
  my $info = get_mp3info($self->file);
  my %info = (
    SECS => $info->{SECS},
    SAMPLERATE => $info->{FREQUENCY} * 1000,
    NUMCHANNELS => $info->{STEREO} ? 2 : 1
  );

  return \%info;
}

sub get_codec_info {
  my $self = shift;
  my $info = get_mp3info($self->file);
  my %info = map (("MP3_$_" => $info->{$_}) => keys %$info);

  return \%info;
}

1;

