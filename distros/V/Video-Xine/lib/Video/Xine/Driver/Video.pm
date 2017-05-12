package Video::Xine::Driver::Video;
{
  $Video::Xine::Driver::Video::VERSION = '0.26';
}

use strict;
use warnings;

use Carp;

use Video::Xine;
use base 'Exporter';

our @EXPORT_OK = qw/
  XINE_VISUAL_TYPE_NONE
  XINE_VISUAL_TYPE_X11
  XINE_VISUAL_TYPE_X11_2
  XINE_VISUAL_TYPE_AA
  XINE_VISUAL_TYPE_FB
  XINE_VISUAL_TYPE_GTK
  XINE_VISUAL_TYPE_DFB
  XINE_VISUAL_TYPE_PM
  XINE_VISUAL_TYPE_DIRECTX
  XINE_VISUAL_TYPE_CACA
  XINE_VISUAL_TYPE_MACOSX
  XINE_VISUAL_TYPE_XCB
  /;

our %EXPORT_TAGS = (
    constants => [
        qw/
          XINE_VISUAL_TYPE_NONE
          XINE_VISUAL_TYPE_X11
          XINE_VISUAL_TYPE_X11_2
          XINE_VISUAL_TYPE_AA
          XINE_VISUAL_TYPE_FB
          XINE_VISUAL_TYPE_GTK
          XINE_VISUAL_TYPE_DFB
          XINE_VISUAL_TYPE_PM
          XINE_VISUAL_TYPE_DIRECTX
          XINE_VISUAL_TYPE_CACA
          XINE_VISUAL_TYPE_MACOSX
          XINE_VISUAL_TYPE_XCB
          /
    ]
);

use constant {
    XINE_VISUAL_TYPE_NONE    => 0,
    XINE_VISUAL_TYPE_X11     => 1,
    XINE_VISUAL_TYPE_X11_2   => 10,
    XINE_VISUAL_TYPE_AA      => 2,
    XINE_VISUAL_TYPE_FB      => 3,
    XINE_VISUAL_TYPE_GTK     => 4,
    XINE_VISUAL_TYPE_DFB     => 5,
    XINE_VISUAL_TYPE_PM      => 6,
    XINE_VISUAL_TYPE_DIRECTX => 7,
    XINE_VISUAL_TYPE_CACA    => 8,
    XINE_VISUAL_TYPE_MACOSX  => 9,
    XINE_VISUAL_TYPE_XCB     => 11
};


use Carp;

sub new {
    my $type = shift;
    my ( $xine, $id, $visual, $data, $display ) = @_;

    $id ||= "auto";

    $xine->isa('Video::Xine')
      or croak "First argument must be of type Video::Xine (was $xine)";

    my $self = {};
    $self->{'xine'} = $xine;
    if ( defined($visual) && defined($data) ) {

	# Store the display to keep it from being garbage-collected
	$self->{'display'} = $display if defined $display;

        $self->{'driver'} =
          xine_open_video_driver( $self->{'xine'}{'xine'}, $id, $visual, $data )
          or die "Unable to load video driver";
    }
    elsif ( defined($id) ) {
        $self->{'driver'} =
          xine_open_video_driver( $self->{'xine'}{'xine'}, $id )
          or return;

    }
    else {

        # Open a null/auto driver
        $self->{'driver'} = xine_open_video_driver( $self->{'xine'}{'xine'} )
          or return;
    }
    bless $self, $type;
}

sub send_gui_data {
    my $self = shift;
    my ( $type, $data ) = @_;
    
    defined $data or confess "\$data must be defined";

    xine_port_send_gui_data( $self->{'driver'}, $type, $data );
}

sub DESTROY {
    my $self = shift;
    xine_close_video_driver( $self->{'xine'}{'xine'}, $self->{'driver'} );
}

1;

__END__

=head1 NAME

Video::Xine::Driver::Video - Video driver class for Xine

=head1 SYNOPSIS

  use Video::Xine::Driver::Video qw/:constants/;

  my $driver =   Video::Xine::Driver::Video->new($xine, $id, $visual, $data, $display)

=head1 METHODS

=head3 new()

  Video::Xine::Driver::Video->new($xine, $id, $visual, $data, $display)

Returns a video driver which can be used to open streams. C<id>,
C<$visual>, and C<$data> are optional. If C<$id> is undefined, returns
an automatically-chosen driver.

C<$visual> is the visual type, which should be an integer. L<Video::Xine>
provides a series of constants indicating the different visual types.

C<$data> is an opaque value dependent on the visual type. For
XINE_VISUAL_TYPE_X11, C<$data> is of type C<x11_visual_type>, a C
struct which should be created with with the method
C<Video::Xine::Util::make_x11_visual()>.

C<$display> is an optional argument for anything that you do not wish
to fall out of scope so long as the driver is alive.

Example:

  my $display = X11::FullScreen->new($display_str);

  my $x11_visual = Video::Xine::Util::make_x11_visual
     ($display,
      $display->getDefaultScreen(),
      $display->createWindow(),
      $display->getWidth(),
      $display->getHeight(),
      $display->getPixelAspect()
     );
  my $driver = Video::Xine::Driver::Video->new
     ($xine,"Xv",XINE_VISUAL_TYPE_X11, $x11_visual, $display)
    or die "Couldn't load video driver";

=head4 VIDEO DRIVER CONSTANTS

=over 4

=item *

XINE_VISUAL_TYPE_NONE

=item *

XINE_VISUAL_TYPE_X11

=item *

XINE_VISUAL_TYPE_X11_2

=item *

XINE_VISUAL_TYPE_AA

=item *

XINE_VISUAL_TYPE_FB

=item *

XINE_VISUAL_TYPE_GTK

=item *

XINE_VISUAL_TYPE_DFB

=item *

XINE_VISUAL_TYPE_PM

=item *

XINE_VISUAL_TYPE_DIRECTX

=item *

XINE_VISUAL_TYPE_CACA

=item *

XINE_VISUAL_TYPE_MACOSX

=item *

XINE_VISUAL_TYPE_XCB

=back

