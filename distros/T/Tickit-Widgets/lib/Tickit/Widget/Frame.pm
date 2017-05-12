#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2014 -- leonerd@leonerd.org.uk

package Tickit::Widget::Frame;

use strict;
use warnings;
use base qw( Tickit::SingleChildWidget );
use Tickit::Style;

use Tickit::WidgetRole::Alignable name => "title_align";

our $VERSION = '0.31';

use Carp;

use Tickit::Pen;
use Tickit::Utils qw( textwidth substrwidth );
use Tickit::RenderBuffer qw( LINE_SINGLE LINE_DOUBLE LINE_THICK CAP_START CAP_END );

=head1 NAME

C<Tickit::Widget::Frame> - draw a frame around another widget

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Frame;
 use Tickit::Widget::Static;

 my $hello = Tickit::Widget::Static->new(
    text   => "Hello, world",
    align  => "centre",
    valign => "middle",
 );

 my $frame = Tickit::Widget::Frame->new(
    child => $hello,
    style => { linetype => "single" },
 );

 Tickit->new( root => $frame )->run;

=head1 DESCRIPTION

This container widget draws a frame around a single child widget.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen
prefixes are also used:

=over 4

=item frame => PEN

The pen used to render the frame lines

=back

The following style keys are used:

=over 4

=item linetype => STRING

Controls the type of line characters used to draw the frame. Must be one of
the following names:

 ascii single double thick solid_inside solid_outside

The C<ascii> linetype is default, and uses only the C<-|+> ASCII characters.
Other linetypes use Unicode box-drawing characters. These may not be supported
by all terminals or fonts.

=item linetype_top => STRING

=item linetype_bottom => STRING

=item linetype_left => STRING

=item linetype_right => STRING

Overrides the C<linetype> attribute for each side of the frame specifically.
If two line-drawing styles meet at corners they should be drawn correctly if
C<Tickit::RenderBuffer> can combine the line segments, but in other
circumstances the corners are drawn as extensions of the top or bottom line,
and the left and right lines do not meet it.

Any edge's linetype may be set to C<none> to cause that edge not to have a
line at all; no extra space will be consumed on that side.

=back

=cut

style_definition base =>
   linetype => "ascii";

style_redraw_keys qw( linetype linetype_top linetype_bottom linetype_left linetype_right );

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 $frame = Tickit::Widget::Frame->new( %args )

Constructs a new C<Tickit::Widget::Static> object.

Takes the following named arguments in addition to those taken by the base
L<Tickit::SingleChildWidget> constructor:

=over 8

=item title => STRING

Optional.

=item title_align => FLOAT|STRING

Optional. Defaults to C<0.0> if unspecified.

=back

For more details see the accessors below.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   # Previously 'linetype' was called 'style', but it collided with
   # Tickit::Widget's idea of style
   if( defined $args{style} and !ref $args{style} ) {
      $args{style} = { linetype => delete $args{style} };
   }

   my $self = $class->SUPER::new( %args );

   $self->set_title( $args{title} ) if defined $args{title};
   $self->set_title_align( $args{title_align} || 0 );

   # Prepopulate has_* caches
   $self->on_style_changed_values;

   return $self;
}

=head1 ACCESSORS

=cut

sub on_style_changed_values
{
   my $self = shift;
   my %values = @_;

   my $reshape = 0;

   my $linetype = $values{linetype}[1] // $self->get_style_values( "linetype" );

   # Cache these
   foreach (qw( top bottom left right )) {
      no warnings 'uninitialized'; # treat undef as false

      my $new = ( $values{"linetype_$_"}[1] // $self->get_style_values( "linetype_$_") // $linetype )
         ne "none";

      $reshape = 1 if $self->{"has_$_"} != $new;
      $self->{"has_$_"} = $new;
   }

   $self->reshape if $reshape;
}

sub lines
{
   my $self = shift;
   my $child = $self->child;
   return ( $child ? $child->requested_lines : 0 ) + $self->{has_top} + $self->{has_bottom};
}

sub cols
{
   my $self = shift;
   my $child = $self->child;
   return ( $child ? $child->requested_cols : 0 ) + $self->{has_left} + $self->{has_right};
}

use constant {
   TOP       => 0,
   BOTTOM    => 1,
   LEFT      => 2,
   RIGHT     => 3,
   CORNER_TL => 4,
   CORNER_TR => 5,
   CORNER_BL => 6,
   CORNER_BR => 7,
};

# Character numbers from
#   http://en.wikipedia.org/wiki/Box-drawing_characters

my %LINECHARS = ( #            TOP     BOTTOM  LEFT    RIGHT   TL      TR      BL      BR
   ascii         => [          '-',    '-',    '|',    '|',    '+',    '+',    '+',    '+' ],
   solid_inside  => [ map chr, 0x2584, 0x2580, 0x2590, 0x258C, 0x2597, 0x2596, 0x259D, 0x2598 ],
   solid_outside => [ map chr, 0x2580, 0x2584, 0x258C, 0x2590, 0x259B, 0x259C, 0x2599, 0x259F ],
);
my %LINESTYLES = (
   single => LINE_SINGLE,
   double => LINE_DOUBLE,
   thick  => LINE_THICK,
);

=head2 $title = $frame->title

=cut

sub title
{
   my $self = shift;
   return $self->{title};
}

=head2 $frame->set_title( $title )

Accessor for the C<title> property, a string written in the top of the
frame.

=cut

sub set_title
{
   my $self = shift;
   $self->{title} = $_[0];
   $self->redraw;
}

=head2 $title_align = $frame->title_align

=head2 $frame->set_title_align( $title_align )

Accessor for the C<title_align> property. Gives a vlaue in the range C<0.0> to
C<1.0> to align the title in the top of the frame.

See also L<Tickit::WidgetRole::Alignable>.

=cut

## This should come from Tickit::ContainerWidget
sub children_changed { shift->reshape }

sub reshape
{
   my $self = shift;

   my $window = $self->window or return;
   my $child  = $self->child  or return;

   my $lines = $window->lines;
   my $cols  = $window->cols;

   my $extra_lines = $self->{has_top} + $self->{has_bottom};
   my $extra_cols  = $self->{has_left} + $self->{has_right};
   if( $lines > $extra_lines and $cols > $extra_cols ) {
      my @geom = ( $self->{has_top}, $self->{has_left}, $lines - $extra_lines, $cols - $extra_cols );

      if( my $childwin = $child->window ) {
         $childwin->change_geometry( @geom );
      }
      else {
         my $childwin = $window->make_sub( @geom );
         $child->set_window( $childwin );
      }
   }
   else {
      if( $child->window ) {
         $child->set_window( undef );
      }
   }
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->setpen( $self->get_style_pen( "frame" ) );

   my $cols  = $self->window->cols;
   my $lines = $self->window->lines;

   my $right  = $cols - 1;
   my $bottom = $lines - 1;

   my $linetype = $self->get_style_values( "linetype" );

   my $linetype_top    = $self->get_style_values( "linetype_top"    ) // $linetype;
   my $linetype_bottom = $self->get_style_values( "linetype_bottom" ) // $linetype;
   my $linetype_left   = $self->get_style_values( "linetype_left"   ) // $linetype;
   my $linetype_right  = $self->get_style_values( "linetype_right"  ) // $linetype;

   my $top_is_line    = defined $LINESTYLES{$linetype_top};
   my $bottom_is_line = defined $LINESTYLES{$linetype_bottom};
   my $left_is_line   = defined $LINESTYLES{$linetype_left};
   my $right_is_line  = defined $LINESTYLES{$linetype_right};

   my $h_caps = ( $left_is_line ? 0 : CAP_START ) | ( $right_is_line  ? 0 : CAP_END );
   my $v_caps = ( $top_is_line  ? 0 : CAP_START ) | ( $bottom_is_line ? 0 : CAP_END );
   my $v_start = $top_is_line ? 0 : $self->{has_top};
   my $v_end   = $bottom_is_line ? $bottom : $bottom - $self->{has_bottom};

   my $linechars;
   my $style;

   # Top
   if( $rect->top == 0 ) {
      if( $linechars = $LINECHARS{$linetype_top} ) {
         $rb->goto( 0, 0 );

         $rb->text( $linechars->[$linetype_top eq $linetype_left  ? CORNER_TL : TOP] );
         $rb->text( $linechars->[TOP] x ($cols - 2) ) if $cols > 2;
         $rb->text( $linechars->[$linetype_top eq $linetype_right ? CORNER_TR : TOP] ) if $cols > 1;
      }
      elsif( $style = $LINESTYLES{$linetype_top} ) {
         $rb->hline_at( 0, 0, $right, $style, undef, $h_caps );
      }

      if( defined( my $title = $self->title ) ) {
         my $cols = $self->window->cols;

         # At most we can fit $cols-4 columns of title
         my ( $left, $titlewidth, $right ) = $self->_title_align_allocation( textwidth( $title ), $cols - 4 );

         $rb->goto( 0, 1 + $left );

         $rb->text( " " );
         $rb->text( $title );
         $rb->text( " " );
      }
   }

   # Left
   if( $rect->left == 0 ) {
      if( $linechars = $LINECHARS{$linetype_left} ) {
         $rb->text_at( $_, 0, $linechars->[LEFT] ) for 1 .. $bottom-1;
      }
      elsif( $style = $LINESTYLES{$linetype_left} ) {
         $rb->vline_at( $v_start, $v_end, 0, $style, undef, $v_caps );
      }
   }
   # Right
   if( $rect->right == $cols and $cols > 1 ) {
      if( $linechars = $LINECHARS{$linetype_right} ) {
         $rb->text_at( $_, $right, $linechars->[RIGHT] ) for 1 .. $bottom-1;
      }
      elsif( $style = $LINESTYLES{$linetype_right} ) {
         $rb->vline_at( $v_start, $v_end, $right, $style, undef, $v_caps );
      }
   }

   # Bottom
   if( $rect->bottom == $lines and $lines > 1 ) {
      if( $linechars = $LINECHARS{$linetype_bottom} ) {
         $rb->goto( $bottom, 0 );

         $rb->text( $linechars->[$linetype_bottom eq $linetype_left  ? CORNER_BL : BOTTOM] );
         $rb->text( $linechars->[BOTTOM] x ($cols - 2) ) if $cols > 2;
         $rb->text( $linechars->[$linetype_bottom eq $linetype_right ? CORNER_BR : BOTTOM] ) if $cols > 1;
      }
      elsif( $style = $LINESTYLES{$linetype_bottom} ) {
         $rb->hline_at( $bottom, 0, $right, $style, undef, $h_caps );
      }
   }
}

=head1 TODO

=over 4

=item *

Specific pen for title. Layered on top of frame pen.

=item *

Caption at the bottom of the frame as well. Identical to title.

=item *

Consider if it's useful to provide accessors to apply extra padding inside the
frame, surrounding the child window.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
