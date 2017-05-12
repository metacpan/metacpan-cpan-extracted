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
package UAV::Pilot::SDL::Window;
use v5.14;
use Moose;
use namespace::autoclean;
use SDL;
use SDL::Video qw{ :surface :video };
use SDLx::App;
use UAV::Pilot::SDL::WindowEventHandler;

with 'UAV::Pilot::EventHandler';
with 'UAV::Pilot::Logger';

use constant {
    SDL_TITLE  => 'UAV::Pilot',
    SDL_WIDTH  => 0,
    SDL_HEIGHT => 0,
    SDL_DEPTH  => 32,
    SDL_FLAGS  => SDL_HWSURFACE | SDL_HWACCEL | SDL_ANYFORMAT,
    BG_COLOR   => [ 0,   0,   0   ],
    DIAG_COLOR => [ 255, 255, 0   ],

    TOP    => 0,
    BOTTOM => 1,
    #LEFT   => 2,
    #RIGHT  => 3,
};


has 'sdl' => (
    is  => 'ro',
    isa => 'SDLx::App',
);
has 'children' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[HashRef[Item]]',
    default => sub {[]},
    handles => {
        '_add_child'       => 'push',
        '_has_no_children' => 'is_empty',
    },
);
has 'yuv_overlay' => (
    is     => 'ro',
    isa    => 'Maybe[SDL::Overlay]',
    writer => '_set_yuv_overlay',
);
has 'yuv_overlay_rect' => (
    is     => 'ro',
    isa    => 'Maybe[SDL::Rect]',
    writer => '_set_yuv_overlay_rect',
);
has 'width' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    writer  => '_set_width',
);
has 'height' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    writer  => '_set_height',
);
has '_origin_x' => (
    is  => 'rw',
    isa => 'Int',
);
has '_origin_y' => (
    is  => 'rw',
    isa => 'Int',
);
has '_drawer' => (
    is  => 'rw',
    isa => 'Maybe[UAV::Pilot::SDL::WindowEventHandler]',
);
has '_bg_color' => (
    is  => 'ro',
);
has '_diag_color' => (
    is  => 'ro',
);
has '_bg_rect' => (
    is  => 'rw',
    isa => 'SDL::Rect',
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my @bg_color_parts = @{ $class->BG_COLOR };
    my $sdl = SDLx::App->new(
        title      => $class->SDL_TITLE,
        width      => $class->SDL_WIDTH,
        height     => $class->SDL_HEIGHT,
        depth      => $class->SDL_DEPTH,
        flags      => $class->SDL_FLAGS,
        resizeable => 1,
    );

    my $bg_color = SDL::Video::map_RGB( $sdl->format, @bg_color_parts );
    my $bg_rect = SDL::Rect->new( 0, 0, $class->SDL_WIDTH, $class->SDL_HEIGHT );
    my $diag_color = SDL::Video::map_RGB( $sdl->format, @{$class->DIAG_COLOR});

    $$args{sdl}         = $sdl;
    $$args{width}       = $class->SDL_WIDTH;
    $$args{height}      = $class->SDL_HEIGHT;
    $$args{_bg_color}   = $bg_color;
    $$args{_diag_color} = $diag_color;
    $$args{_bg_rect}    = $bg_rect;
    return $args;
}


sub add_child
{
    my ($self, $child, $float) = @_;
    $float //= $self->TOP;

    my ($x, $y, $new_width, $new_height) = $self->_calc_new_child(
        $child, $float );

    $self->_resize( $new_width, $new_height );
    $self->_add_child({
        origin_x => $x,
        origin_y => $y,
        drawer   => $child,
    });

    return 1;
}

sub add_child_with_yuv_overlay
{
    my ($self, $child, $overlay_flag, $float) = @_;
    $float //= $self->TOP;

    my $width  = $child->width;
    my $height = $child->height;
    my ($x, $y, $new_width, $new_height) = $self->_calc_new_child(
        $child, $float );

    my $sdl = $self->sdl;
    my $overlay = SDL::Overlay->new( $width, $height, $overlay_flag, $sdl );
    my $overlay_rect = SDL::Rect->new( $x, $y, $width, $height );

    $self->_set_yuv_overlay( $overlay );
    $self->_set_yuv_overlay_rect( $overlay_rect );

    $self->_resize( $new_width, $new_height );
    $self->_add_child({
        origin_x => $x,
        origin_y => $y,
        drawer   => $child,
    });
    return 1;
}



sub process_events
{
    my ($self) = @_;
    my $logger = $self->_logger;
    $logger->info( 'Start drawing of SDL window' );

    foreach my $child (@{ $self->children }) {
        my $drawer = $child->{drawer};
        $logger->debug( 'Drawing child ' . ref($drawer) );
        $self->_origin_x( $child->{origin_x} );
        $self->_origin_y( $child->{origin_y} );
        $self->_drawer( $drawer );
        $drawer->draw( $self );
        $drawer->update_window_rect( $self );
    }

    my $rect = $self->_bg_rect;
    $logger->debug( 'Updating rect'
        . '. X: '     . $rect->x
        . ' Y: '      . $rect->y
        . ' Width: '  . $rect->w
        . ' Height: ' . $rect->h );
    #SDL::Video::update_rects( $self->sdl, $self->_bg_rect );
    # Cleanup
    $self->_origin_x( 0 );
    $self->_origin_y( 0 );
    $self->_drawer( undef );

    $logger->info( 'Done drawing to SDL window' );
    return 1;
}

sub clear_screen
{
    my ($self) = @_;
    $self->_logger->debug( 'Clearing screen' );
    my $drawer = $self->_drawer;
    my $bg_rect = SDL::Rect->new( $self->_origin_x, $self->_origin_y,
        $drawer->width, $drawer->height );
    SDL::Video::fill_rect(
        $self->sdl,
        $bg_rect,
        $self->_bg_color,
    );
    return 1;
}

sub draw_txt
{
    my ($self, $text, $x, $y, $sdl_text) = @_;
    $x += $self->_origin_x;
    $y += $self->_origin_y;
    $sdl_text->write_xy( $self->sdl, $x, $y, $text );
    return 1;
}

sub draw_line
{
    my ($self, $left_coords, $right_coords, $color) = @_;
    $left_coords->[0]  += $self->_origin_x;
    $left_coords->[1]  += $self->_origin_y;
    $right_coords->[0] += $self->_origin_x;
    $right_coords->[1] += $self->_origin_y;

    $self->sdl->draw_line( $left_coords, $right_coords, $color );
    return 1;
}

sub draw_circle
{
    my ($self, $center_coords, $radius, $color ) = @_;
    $center_coords->[0] += $self->_origin_x;
    $center_coords->[1] += $self->_origin_y;
    $self->sdl->draw_circle( $center_coords, $radius, $color );
    return 1;
}

sub draw_rect
{
    my ($self, $rect_data, $color) = @_;
    $rect_data->[0] += $self->_origin_x;
    $rect_data->[1] += $self->_origin_y;
    $self->sdl->draw_rect( $rect_data, $color);
    return 1;
}

sub update_rect
{
    my ($self, $width, $height) = @_;
    my $rect = SDL::Rect->new( $self->_origin_x, $self->_origin_y, 
        $width, $height );
    SDL::Video::update_rects( $self->sdl, $rect );
    return 1;
}


sub _resize
{
    my ($self, $width, $height) = @_;
    my $bg_rect = SDL::Rect->new( 0, 0, $width, $height );

    $self->sdl->resize( $width, $height );
    $self->_set_width( $width );
    $self->_set_height( $height );
    $self->_bg_rect( $bg_rect );
    return 1;
}

sub _calc_new_child
{
    my ($self, $child, $float) = @_;
    my $x = 0;
    my $y = 0;
    my $new_width = 0;
    my $new_height = 0;

    if( $self->_has_no_children ) {
        $new_width  = $child->width;
        $new_height = $child->height;
    }
    elsif( $self->BOTTOM == $float ) {
        ($new_width, $new_height) = $self->_calc_resize_vert( $child );
        ($x, $y) = $self->_calc_position_bottom( $child );
    }
    else {
        # Assume TOP
        ($new_width, $new_height) = $self->_calc_resize_vert( $child );
    }

    return ($x, $y, $new_width, $new_height);
}

sub _calc_resize_vert
{
    my ($self, $child) = @_;
    my $child_height = $child->height;
    my $child_width  = $child->width;
    my $new_width  = $child_width;
    my $new_height = $child_height + $self->height;

    foreach my $child (@{ $self->children }) {
        my $width = $child->{drawer}->width;
        $new_width = $width
            if $width > $new_width;
    }

    return ($new_width, $new_height);
}

sub _calc_position_bottom
{
    my ($self, $child) = @_;
    my $x = 0;
    my $y = 0;
    $y += $_->{drawer}->height for @{ $self->children };
    return ($x, $y);
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

  UAV::Pilot::SDL::Window

=head1 SYNOPSIS

    my $window = UAV::Pilot::SDL::Window->new;
    $window->add_child( $window_event_handler );

    # In the child's draw method
    $window->clear_screen;
    $window->draw_line( [0, 0], [128, 128], $color );
    $window->draw_circle( [ 512, 512 ], 10, $color );

=head1 DESCRIPTION

A basic windowing system for drawing widgets.  Currently only supports adding 
new widgets on top or below an existing widget.

Does the C<UAV::Pilot::EventHandler> role.

=head1 METHODS

=head2 add_child

    add_child( $handler, $float ).

Pass a child that does the C<UAV::Pilot::SDL::WindowEventHandler> role.  
Float should be C<<$window->TOP>> or C<<$window->BOTTOM>> for the location to 
draw this child.  The window will be expanded to fit the child's width/height.

=head2 add_child_with_yuv_overlay

    add_child_with_yuv_overlay( $handle, $overlay_flag, $float )

Pass a child that does the C<UAV::Pilot::SDL::WindowEventHandler> role.  The 
C<$overlay_flag> will be the flag passed to C<SDL::Overlay> (see that module's 
docs for details).  The C<$float> param is the same as C<add_child()>.

=head2 sdl

Returns the C<SDLx::App> object for the given SDL window.

=head2 yuv_overlay

If a child was added with C<add_child_with_yuv_overlay()>, returns the 
C<SDL::Overlay> object.

=head2 yuv_overlay_rect

If a child was added with C<add_child_with_yuv_overlay()>, returns an 
C<SDL::Rect> object that covers the overlay area.

=head1 DRAWING METHODS

The should only be used by widgets when their C<draw()> method is called.

All C<$x, $y> coordinates are relative to the widgets's drawing area.

=head2 clear_screen

Blanks the area that the current widget is being drawn in.

=head2 draw_txt

    draw_txt( $string, $x, $y, $sdl_text )

Draws text to the screen.  Params:

C<$string>: The string to write

C<$x, $y>: The coords to draw at

C<$sdl_text>: An C<SDLx::Text> object

=head2 draw_line

    draw_line( [$x0,$y0], [$x1,$y1], $color )

Draws a line.  The C<$color> param is an C<SDL::Color> object.

=head2 draw_circle

    draw_circle( [$x,$y], $radius, $color )

Draws a circle.  The C<$color> param is an C<SDL::Color> object.

=head2 draw_rect

    draw_rect( [$x, $y, $width, $height], $color )

Draws a rect.  The C<$color> param is an C<SDL::Color> object.

=head2 update_rect

    update_rect( $width, $height )

Updates the draw area for the active window.

=cut
