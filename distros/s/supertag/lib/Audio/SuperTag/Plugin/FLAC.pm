package Audio::SuperTag::Plugin::FLAC;

use base qw/Audio::SuperTag::Plugin/;
use Audio::FLAC::Header;
use strict;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $file = shift;
  my $flac = Audio::FLAC::Header->new($file);
  return bless [ $flac, $file ] => $class;
}

sub file {
  return shift->[1];
}

sub filetype {
  return 'flac';
}

sub get_tags {
  my $self = shift;
  my $tags = $self->[0]->tags;
  $tags->{TRACKNUM} = delete $tags->{TRACKNUMBER};
  return $tags;
}

sub set_tags {
  my $self = shift;
  my $tags = shift;
  my %set = %$tags;

  $set{TRACKNUMBER} = delete $set{TRACKNUM};
  $self->[0]->{tags} = \%set;
  return $self->[0]->write;
}

sub get_audio_info {
  my $self = shift;
  my $info = $self->[0]->info;
  my %info = (
    SECS => $info->{trackTotalLengthSeconds},
    SAMPLERATE => $info->{SAMPLERATE},
    NUMCHANNELS => $info->{NUMCHANNELS}
  );

  return \%info;
}

sub get_codec_info {
  my $self = shift;
  my $info = $self->[0]->info;
  my %info = map (("FLAC_$_" => $info->{$_}) => keys %$info);

  return \%info;
}

1;

