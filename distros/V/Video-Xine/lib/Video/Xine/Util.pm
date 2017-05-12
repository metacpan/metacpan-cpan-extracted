package Video::Xine::Util;
{
  $Video::Xine::Util::VERSION = '0.26';
}

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/make_x11_visual make_x11_fs_visual/;

use Video::Xine;

sub make_x11_fs_visual {
	my ($fullscreen) = @_;
	
	return Video::Xine::Util::make_x11_visual(
		$fullscreen->display(),
        $fullscreen->screen(),
        $fullscreen->window(), 
        $fullscreen->display_width(),
        $fullscreen->display_height(),
        $fullscreen->pixel_aspect()	
	);
}

1;

__END__

=head1 NAME

Video::Xine::Util -- Utility methods for Xine

=head1 SYNOPSIS

  use Video::Xine::Util qw/make_x11_visual make_x11_fs_visual/;

  my $visual = make_x11_visual
                (
                  $x_display,
                  $screen,
                  $window_id,
                  $width,
                  $height,
                  $aspect
                );

  # Get a visual from X11::FullScreen
  my $display = X11::FullScreen->new(':0');
  
  my $fs_visual = make_x11_fs_visual($display, $display->createWindow());


=head1 DESCRIPTION

The Util package provides helper subroutines for gluing Video::Xine to windowing systems.

=head1 SUBROUTINES

=head3 make_x11_visual()

 make_x11_visual($x_display, $screen, $window_id, $width, $height, $aspect)

Returns a C struct suitable for passing to the
Video::Xine::Driver::Video constructor with a XINE_VISUAL_TYPE_X11.



=cut

