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
package UAV::Pilot::SDL::VideoOverlay::Reticle;
use v5.14;
use Moose;
use namespace::autoclean;

use constant RETICLE_COLOR             => [ 0x00, 0xff, 0x00 ];
use constant RETICLE_HALF_SIZE_PERCENT => 0.1; # Takes up x percent of screen size

with 'UAV::Pilot::SDL::VideoOverlay';

has 'reticle_color' => (
    is     => 'ro',
    writer => '_set_reticle_color',
);


after 'init_video_overlay' => sub {
    my ($self, $video, $window) = @_;
    my $sdl = $window->sdl;
    my @color_parts = @{ $self->RETICLE_COLOR };
    my $reticle_color = SDL::Video::map_RGB( $sdl->format, @color_parts );
    $self->_set_reticle_color( $reticle_color );

    return 1;
};


sub process_video_overlay
{
    my ($self, $window) = @_;
    my $sdl               = $window->sdl;
    my $reticle_color     = $self->reticle_color;
    my $half_size_percent = $self->RETICLE_HALF_SIZE_PERCENT;
    # TODO this needs to be based on the rect that the Video is being drawn on
    my $w                 = $sdl->w;
    my $h                 = $sdl->h;
    my $center_x          = int( $w / 2 );
    my $center_y          = int( $h / 2 );

    my $reticle_half_width  = $w * $half_size_percent;
    my $reticle_half_height = $h * $half_size_percent;
    my $left_x   = $center_x - $reticle_half_width;
    my $right_x  = $center_x + $reticle_half_width;
    my $top_y    = $center_y - $reticle_half_height;
    my $bottom_y = $center_y + $reticle_half_height;

    $sdl->draw_line( [$left_x,   $center_y], [$right_x,  $center_y] );
    $sdl->draw_line( [$center_x, $top_y],    [$center_x, $bottom_y] );
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::SDL::VideoOverlay::Reticle

=head1 DESCRIPTION

A C<UAV::Pilot::SDL::Overlay> for drawing a targeting reticle in the middle 
of the screen.

=cut
