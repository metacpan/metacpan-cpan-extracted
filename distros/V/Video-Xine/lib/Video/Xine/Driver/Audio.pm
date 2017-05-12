package Video::Xine::Driver::Audio;
{
  $Video::Xine::Driver::Audio::VERSION = '0.26';
}

use strict;
use warnings;

use Video::Xine;

sub new {
  my $type = shift;
  my ($xine, $id, $data) = @_;
  my $self = {};

  $self->{'xine'} = $xine;

  # Need to figure out how to make undefs into NULLs
  if ( defined($data) ) {
    $self->{'driver'} = xine_open_audio_driver($xine->{'xine'}, $id, $data);
  }
  elsif ( defined($id) ) {
    $self->{'driver'} = xine_open_audio_driver($xine->{'xine'}, $id);
  }
  else {
    $self->{'driver'} = xine_open_audio_driver($xine->{'xine'});
  }

  $self->{'driver'}
    or return;
  bless $self, $type;
}

sub DESTROY {
  my $self = shift;
  xine_close_audio_driver($self->{'xine'}{'xine'}, $self->{'driver'});
}

1;

__END__

=head1 NAME

Video::Xine::Driver::Audio - Audio port for Xine

=head1 SYNOPSIS

  use Video::Xine::Driver::Audio;

  my $ao = Video::Xine::Driver::Audio->new($xine, 'auto')
    or die "Couldn't load audio driver!";

=head1 DESCRIPTION

Audio port for Xine.

=head3 new()

  new($xine, $id, $data)

Creates a new audio driver for opening streams. C<$id> and C<$data>
are optional. Returns undef on failure. If C<$id> is undefined, returns
Xine's idea of the default audio driver.

Example:

  # Creates an audio driver that doesn't make any noise
  my $audio_driver = Video::Xine::Driver::Audio->new($xine, 'none')
     or die "Couldn't load audio driver!";


=cut
