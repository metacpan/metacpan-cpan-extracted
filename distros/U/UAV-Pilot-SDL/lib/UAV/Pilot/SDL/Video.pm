# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::SDL::Video;
use v5.14;
use Moose;
use namespace::autoclean;
use SDL;
use SDLx::Text;
use SDL::Event;
use SDL::Events;
use SDL::Video qw{ :surface :video };
use SDL::Overlay;
use Time::HiRes ();
use UAV::Pilot::SDL::VideoOverlay;

require DynaLoader;
our @ISA = qw(DynaLoader);
bootstrap UAV::Pilot::SDL::Video;

with 'UAV::Pilot::Logger';


use constant {
    SDL_WIDTH        => 640,
    SDL_HEIGHT       => 360,
    SDL_OVERLAY_FLAG => SDL_YV12_OVERLAY,
    #SDL_OVERLAY_FLAG => SDL_IYUV_OVERLAY,
    #SDL_OVERLAY_FLAG => SDL_YUY2_OVERLAY,
    #SDL_OVERLAY_FLAG => SDL_UYVY_OVERLAY,
    #SDL_OVERLAY_FLAG => SDL_YVYU_OVERLAY,
    #SDL_OVERLAY_FLAG => SDL_YVYU_OVERLAY,
    BG_COLOR         => [ 0, 255, 0 ],
};

with 'UAV::Pilot::Video::RawHandler';


has '_last_vid_frame' => (
    is  => 'rw',
    isa => 'Maybe[UAV::Pilot::Video::H264Decoder]',
);
has 'frames_processed' => (
    traits  => ['Number'],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        '_add_frames_processed' => 'add',
    },
);
has '_bg_rect' => (
    is     => 'ro',
    isa    => 'SDL::Rect',
    writer => '_set_bg_rect',
);
has '_bg_color' => (
    is  => 'rw',
);
has 'video_overlays' => (
    is      => 'ro',
    isa     => 'ArrayRef[UAV::Pilot::SDL::VideoOverlay]',
    default => sub {[]},
    traits  => [ 'Array' ],
    handles => {
        _add_video_overlay => 'push',
    },
);

with 'UAV::Pilot::SDL::WindowEventHandler';


sub BUILDARGS
{
    my ($class, $args) = @_;
    $$args{width}     = $class->SDL_WIDTH;
    $$args{height}    = $class->SDL_HEIGHT;
    return $args;
}

sub add_to_window
{
    my ($self, $window, $location) = @_;
    $location //= $window->TOP;
    $window->add_child_with_yuv_overlay( $self,
        $self->SDL_OVERLAY_FLAG, $location );

    my @bg_color_parts = @{ $self->BG_COLOR };
    my $sdl = $window->sdl;
    my $bg_color = SDL::Video::map_RGB( $sdl->format, @bg_color_parts );
    $self->_bg_color( $bg_color );

    return 1;
}

sub update_window_rect
{
    # Do nothing, since YUV overlay updates the area for us
    return 1;
}


sub process_raw_frame
{
    my ($self, $width, $height, $decoder) = @_;

    if( ($width != $self->width) || ($height != $self->height) ) {
        # TODO Ignore until we have a way of informing 
        # UAV::Pilot::SDL::Window of the change
        #$self->_set_width_height( $width, $height );
    }

    $self->_last_vid_frame( $decoder );
    $self->_add_frames_processed( 1 );
    return 1;
}

sub draw
{
    my ($self, $window) = @_;
    my $last_vid_frame = $self->_last_vid_frame;
    return 1 unless defined $last_vid_frame;

    my $bg_rect     = $window->yuv_overlay_rect;
    my $sdl_overlay = $window->yuv_overlay;
    SDL::Video::fill_rect(
        $window->sdl,
        $bg_rect,
        $self->_bg_color,
    );

    $self->_draw_last_video_frame(
        $sdl_overlay,
        $bg_rect,
        $last_vid_frame->get_last_frame_c_obj,
    );

    my @overlays = @{ $self->video_overlays };
    if( @overlays ) {
        foreach my $overlay (@overlays) {
            $overlay->process_video_overlay( $window );
        }
        
        SDL::Video::update_rects( $window->sdl, $bg_rect );
    }

    $self->_logger->info( 'VIDEO_FRAME_TIMER,DISPLAY,'
        . $self->frames_processed
        . ',' . join( ',', Time::HiRes::gettimeofday ) );

    return 1;
}

sub register_video_overlay
{
    my ($self, $overlay, $window) = @_;
    $overlay->init_video_overlay( $self, $window );
    $self->_add_video_overlay( $overlay );
    return 1;
}


sub _set_width_height
{
    my ($self, $width, $height) = @_;
    # TODO inform UAV::Pilot::SDL::Window of size change
    my $sdl         = $self->sdl_app;
    $sdl->resize( $width, $height );
    my $bg_rect     = SDL::Rect->new( 0, 0, $width, $height );
    my $sdl_overlay = SDL::Overlay->new( $width, $height, $self->SDL_OVERLAY_FLAG, $sdl );

    $self->_set_bg_rect( $bg_rect );
    $self->_set_sdl_overlay( $sdl_overlay );
    $self->_set_width( $width );
    $self->_set_height( $height );

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::SDL::Video

=head1 SYNOPSIS

    my $cv = AnyEvent->condvar;
    my $events = UAV::Pilot::Events->new({
        condvar => $cv,
    });
    
    my $window = UAV::Pilot::SDL::Window->new;
    my $display = UAV::Pilot::SDL::Video->new({
        window => $window,
    });
    
    my $video   = UAV::Pilot::Video::H264Decoder->new({
        display => $display,
    });
    
    $events->register( $display );

=head1 DESCRIPTION

Process raw video frames and displays them to an SDL surface.  This does the roles
C<UAV::Pilot::Video::RawHandler> and C<UAV::Pilot::EventHandler>.

=head1 METHODS

=head1 register_video_overlay

    register_video_overlay( $overlay )

Adds an object that does the C<UAV::Pilot::SDL::VideoOverlay> role.  This allows an 
object to draw things on top of the video, like telemetry information.

Not to be confused with C<SDL::Overlay>.

=cut
