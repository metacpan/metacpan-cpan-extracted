package Audio::SuperTag::Plugin;

use base qw/Exporter/;
use strict;

sub new {
  my $file = shift;
  return bless {} => __PACKAGE__;
}

sub file {
  my $self = shift;
  return $self->unimplemented();
}

sub filetype {
  my $self = shift;
  return $self->unimplemented();
}

sub get_tags {
  my $self = shift;
  return $self->unimplemented();
}

sub set_tags {
  my $self = shift;
  my $tags = shift;
  return $self->unimplemented();
}

sub get_audio_info {
  my $self = shift;
  return $self->unimplemented();
}

sub get_codec_info {
  my $self = shift;
  return $self->unimplemented();
}

sub unimplemented {
  my $self = shift;
  my $class = ref $self;
  my $caller = [ caller 1 ];
  my $subname = (split /::/, $caller->[3])[-1];

  die "plugin error: $class does not define $subname()";
}

1;

