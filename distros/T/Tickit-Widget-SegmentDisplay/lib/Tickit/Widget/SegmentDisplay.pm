#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2020 -- leonerd@leonerd.org.uk

use 5.026;  # signatures
use Object::Pad 0.19;

class Tickit::Widget::SegmentDisplay 0.06
   extends Tickit::Widget;

use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE LINE_THICK );

use utf8;

use Carp;

# The 7 segments are
#  AAA
# F   B
# F   B
#  GGG
# E   C
# E   C
#  DDD
#
# B,C,E,F == 2cols wide
# A,D,G   == 1line tall

=encoding UTF-8

=head1 NAME

C<Tickit::Widget::SegmentDisplay> - show a single character like a segmented display

=head1 DESCRIPTION

This class provides a widget that imitates a segmented LED or LCD display. It
shows a single character by lighting or shading fixed rectangular bars.

=head1 STYLE

The default style pen is used as the widget pen, though only the background
colour will actually matter as the widget does not directly display text.

The following style keys are used:

=over 4

=item lit => COLOUR

=item unlit => COLOUR

Colour descriptions (index or name) for the lit and unlight segments of the
display.

=back

=cut

style_definition base =>
   lit => "red",
   unlit => 16+36;

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 new

   $segmentdisplay = Tickit::Widget::SegmentDisplay->new( %args )

Constructs a new C<Tickit::Widget::SegmentDisplay> object.

Takes the following named arguments

=over 8

=item value => STR

Sets an initial value.

=item type => STR

The type of display. Supported types are:

=over 4

=item seven

A 7-segment bar display. The display can also be blanked with the value " ".

=item seven_dp

A 7-segment bar display with decimal-point. To light the decimal point, append
the value with ".".

=item colon

A static C<:>

=item symb

A unit, prefix symbol or other character. The following characters are
recognised:

  V A W Ω F H s
  G M k m µ n p
  + - %

Each will be drawn in a style approximately to fit the general LED shape
display, by drawing lines of erased cells. Note however that some more
intricate shapes may not be very visible on smaller scales.

=back

=item use_unicode => BOOL

If true, use Unicode block-drawing characters. If false, use only coloured
erase cells using the background colour.

=item use_halfline => BOOL

If true, vertical resolution of rendered block characters is effectively
doubled by using half-filled Unicode block-drawing characters. Setting this
option implies C<use_unicode>.

=item use_linedraw => BOOL

If true, use Unicode linedrawing instead of erased or solid blocks. This style
is more readable on smaller sizes, but is only supported by C<seven> and
C<colon> types.

=item thickness => INT

Gives the number of columns wide and half-lines tall that LED bars will be
drawn in. Note that unless C<use_halfline> is set, this value ought to be an
even number. Defaults to 2.

When C<use_linedraw> is in effect, if C<thickness> is greater than 1 then
C<LINE_THICK> segments will be used for drawing. Defaults to 1.

=back

=cut

my %types = (
   seven    => [qw( 7 )],
   seven_dp => [qw( 7. )],
   colon    => [qw( : )],
   symb     => [],
);

has $_reshape_method;
has $_render_to_rb;

has $_use_halfline;
has $_linestyle;
has $_hthickness;
has $_vthickness;
has $_margin;

has $_value;

method BUILD ( %args )
{
   my $type = $args{type} // "seven";
   my $method;
   foreach my $typename ( keys %types ) {
      $type eq $typename and $method = $typename, last;
      $type eq $_ and $method = $typename, last for @{ $types{$typename} };
   }
   defined $method or croak "Unrecognised type name '$type'";

   $_reshape_method = $self->can( "reshape_${method}" );

   my $use_halfline = $args{use_halfline};
   $_use_halfline = $use_halfline;

   my $use_linedraw = $args{use_linedraw};

   if( $use_linedraw and my $code = $self->can( "render_${method}_as_linedraw" ) ) {
      $_linestyle = ( $args{thickness} // 1 ) > 1 ? LINE_THICK : LINE_SINGLE;
      $_render_to_rb = $code;
   }
   else {
      my $render = $self->can( "render_${method}" );

      my $use_unicode  = $args{use_unicode};

      my $flush = $self->can(
         $use_halfline ? "flush_halfline" :
         $use_unicode  ? "flush_unicode"  :
                         "flush" );

      $_render_to_rb = sub {
         my $self = shift;
         my ( $rb, $rect ) = @_;
         my @buff;

         # TODO: sizing?
         $render->( $self, \@buff );

         $rb->eraserect( $rect );

         $flush->( $self, \@buff, $rb, $rect );
      };
   }

   $_hthickness = $args{thickness} // 2;

   $_vthickness = $_hthickness;
   $_vthickness /= 2 unless $_use_halfline;

   if( $use_linedraw ) {
      $_hthickness = 1;
      $_vthickness = 1;
   }

   $_margin = $use_linedraw ? 0 : 1;

   $_value = $args{value} // "";

   $self->on_style_changed_values(
      lit   => [ undef, $self->get_style_values( "lit" ) ],
      unlit => [ undef, $self->get_style_values( "unlit" ) ],
   );
}

# ADG + atleast 1 line each for FB and EC
method lines () { 3 + 2 }

# FE, BC + atleast 2 columns for AGD
method cols  () { 4 + 2 }

=head1 ACCESSORS

=cut

=head2 value

   $value = $segmentdisplay->value

   $segmentdisplay->set_value( $value )

Return or set the character on display

=cut

method value () { $_value }

method set_value ( $new_value )
{
   $_value = $new_value;
   $self->redraw;
}

has $_lit_pen;
has $_unlit_pen;

method on_style_changed_values ( %values )
{
   $_lit_pen   = Tickit::Pen::Immutable->new( fg => $values{lit}[1]   ) if $values{lit};
   $_unlit_pen = Tickit::Pen::Immutable->new( fg => $values{unlit}[1] ) if $values{unlit};
}

method reshape ()
{
   my $win = $self->window or return;

   my $linescale = 1 + !!$_use_halfline;

   $_reshape_method->( $self, $win->lines * $linescale, $win->cols, 0, 0 );
}

use constant {
   LIT   => 0x01,
   UNLIT => 0x02,
};

method render_to_rb ( $rb, $rect )
{
   $_render_to_rb->( $self, $rb, $rect );
}

method flush ( $buff, $rb, $rect )
{
   my $lit_pen   = Tickit::Pen::Immutable->new( bg => $_lit_pen->getattr( "fg" ) );
   my $unlit_pen = Tickit::Pen::Immutable->new( bg => $_unlit_pen->getattr( "fg" ) );

   foreach my $line ( $rect->linerange ) {
      next unless defined( my $cells = $buff->[$line] );
      foreach my $col ( $rect->left .. $rect->right - 1 ) {
         my $val = vec( $cells, $col, 2 ) or next;
         $rb->setpen( $val == LIT ? $lit_pen : $unlit_pen );
         $rb->erase_at( $line, $col, 1 );
      }
   }
}

use constant {
   U_FULL  => 0x2588,
   U_UPPER => 0x2580,
   U_LOWER => 0x2584,
};

method flush_unicode ( $buff, $rb, $rect )
{
   foreach my $line ( $rect->linerange ) {
      next unless defined( my $cells = $buff->[$line] );
      foreach my $col ( $rect->left .. $rect->right - 1 ) {
         my $val = vec( $cells, $col, 2 ) or next;
         $rb->setpen( $val == LIT ? $_lit_pen : $_unlit_pen );
         $rb->char_at( $line, $col, U_FULL );
      }
   }
}

method flush_halfline ( $buff, $rb, $rect )
{
   my $both_pen = Tickit::Pen::Immutable->new(
      fg => $_lit_pen->getattr( 'fg' ),
      bg => $_unlit_pen->getattr( 'fg' ),
   );

   foreach my $phyline ( $rect->linerange ) {
      my $hicells = $buff->[$phyline*2];
      my $locells = $buff->[$phyline*2 + 1];

      next unless defined $hicells or defined $locells;

      $hicells //= "";
      $locells //= "";

      foreach my $col ( $rect->left .. $rect->right - 1 ) {
         my $hival = vec( $hicells, $col, 2 );
         my $loval = vec( $locells, $col, 2 );

         $hival or $loval or next;

         if( $hival == $loval ) {
            $rb->setpen( ( $hival || $loval ) == LIT ? $_lit_pen : $_unlit_pen );
            $rb->char_at( $phyline, $col, U_FULL );
         }
         elsif( !$hival or !$loval ) {
            $rb->setpen( ( $hival || $loval ) == LIT ? $_lit_pen : $_unlit_pen );
            $rb->char_at( $phyline, $col, $hival ? U_UPPER : U_LOWER );
         }
         else {
            # Half lit, half unlit
            $rb->setpen( $both_pen );
            $rb->char_at( $phyline, $col, $hival == LIT ? U_UPPER : U_LOWER );
         }
      }
   }
}

method _fill ( $buff, $startline, $endline, $startcol, $endcol, $val = LIT )
{
   my @colrange = ( $startcol .. $endcol + $_hthickness - 1 );

   my @linerange = ( $startline .. $endline + $_vthickness - 1 );

   foreach my $line ( @linerange ) {
      vec( $buff->[$line], $_, 2 ) = $val for @colrange;
   }
}

method _dot ( $buff, $line, $col, $val = LIT )
{
   $self->_fill( $buff, $line, $line, $col, $col, $val );
}

has %_geom;

# 7-Segment
my %segments = (
   ' ' => "       ",
   '-' => "      G",
   0   => "ABCDEF ",
   1   => " BC    ",
   2   => "AB DE G",
   3   => "ABCD  G",
   4   => " BC  FG",
   5   => "A CD FG",
   6   => "A CDEFG",
   7   => "ABC    ",
   8   => "ABCDEFG",
   9   => "ABCD FG",
);

method _val_for_seg ( $segment )
{
   my $segments = $segments{substr $self->value, 0, 1} or return UNLIT;

   my $lit = substr( $segments, ord($segment) - ord("A"), 1 ) ne " ";
   return $lit ? LIT : UNLIT;
}

method reshape_seven ( $lines, $cols, $top, $left )
{
   my $margin = $_margin;

   my $hthickness = $_hthickness;

   my $right = $left + $cols - $hthickness;

   $_geom{FE_col}       = $left;
   $_geom{AGD_startcol} = $left + $hthickness * $margin;
   $_geom{AGD_endcol}   = $right - $hthickness * $margin;
   $_geom{BC_col}       = $right;

   my $vthickness = $_vthickness;

   my $bottom = $top + $lines - $vthickness;
   my $mid    = int( ( $top + $bottom ) / 2 );

   $_geom{A_line}       = $top;
   $_geom{BF_startline} = $top + $vthickness * $margin;
   $_geom{BF_endline}   = $mid - $vthickness * $margin;
   $_geom{G_line}       = $mid;
   $_geom{CE_startline} = $mid + $vthickness * $margin;
   $_geom{CE_endline}   = $bottom - $vthickness * $margin;
   $_geom{D_line}       = $bottom;
}

method render_seven ( $buff )
{
   $self->_fill( $buff, ( $_geom{A_line} ) x 2, $_geom{AGD_startcol}, $_geom{AGD_endcol}, $self->_val_for_seg( "A" ) );
   $self->_fill( $buff, ( $_geom{G_line} ) x 2, $_geom{AGD_startcol}, $_geom{AGD_endcol}, $self->_val_for_seg( "G" ) );
   $self->_fill( $buff, ( $_geom{D_line} ) x 2, $_geom{AGD_startcol}, $_geom{AGD_endcol}, $self->_val_for_seg( "D" ) );

   $self->_fill( $buff, $_geom{BF_startline}, $_geom{BF_endline}, ( $_geom{FE_col} ) x 2, $self->_val_for_seg( "F" ) );
   $self->_fill( $buff, $_geom{BF_startline}, $_geom{BF_endline}, ( $_geom{BC_col} ) x 2, $self->_val_for_seg( "B" ) );
   $self->_fill( $buff, $_geom{CE_startline}, $_geom{CE_endline}, ( $_geom{FE_col} ) x 2, $self->_val_for_seg( "E" ) );
   $self->_fill( $buff, $_geom{CE_startline}, $_geom{CE_endline}, ( $_geom{BC_col} ) x 2, $self->_val_for_seg( "C" ) );
}

method render_seven_as_linedraw ( $rb, $rect )
{
   $rb->eraserect( $rect );

   $rb->setpen( $_lit_pen );

   $rb->hline_at( $_geom{A_line}, $_geom{AGD_startcol}, $_geom{AGD_endcol}, $_linestyle ) if $self->_val_for_seg( "A" ) == LIT;
   $rb->hline_at( $_geom{G_line}, $_geom{AGD_startcol}, $_geom{AGD_endcol}, $_linestyle ) if $self->_val_for_seg( "G" ) == LIT;
   $rb->hline_at( $_geom{D_line}, $_geom{AGD_startcol}, $_geom{AGD_endcol}, $_linestyle ) if $self->_val_for_seg( "D" ) == LIT;

   $rb->vline_at( $_geom{BF_startline}, $_geom{BF_endline}, $_geom{FE_col}, $_linestyle ) if $self->_val_for_seg( "F" ) == LIT;
   $rb->vline_at( $_geom{BF_startline}, $_geom{BF_endline}, $_geom{BC_col}, $_linestyle ) if $self->_val_for_seg( "B" ) == LIT;
   $rb->vline_at( $_geom{CE_startline}, $_geom{CE_endline}, $_geom{FE_col}, $_linestyle ) if $self->_val_for_seg( "E" ) == LIT;
   $rb->vline_at( $_geom{CE_startline}, $_geom{CE_endline}, $_geom{BC_col}, $_linestyle ) if $self->_val_for_seg( "C" ) == LIT;
}

# 7-Segment with DP
method reshape_seven_dp ( $lines, $cols, $top, $left )
{
   $self->reshape_seven( $lines, $cols - 2, $top, $left );

   $_geom{DP_line} = $top  + $lines - 1;
   $_geom{DP_col}  = $left + $cols  - 2;
}

method render_seven_dp ( $buff )
{
   $self->render_seven( $buff );

   my $dp = $_value =~ m/\.$/;
   $self->_dot( $buff, $_geom{DP_line}, $_geom{DP_col}, $dp ? LIT : UNLIT );
}

# Static double-dot colon
method reshape_colon ( $lines, $cols, $top, $left )
{
   my $bottom = $top + $lines - 1;

   $_geom{colon_col} = 2 + int( ( $cols - 4 ) / 2 );

   my $ofs = int( ( $lines - 1 + 0.5 ) / 4 );

   $_geom{A_line} = $top    + $ofs;
   $_geom{B_line} = $bottom - $ofs;
}

method render_colon ( $buff )
{
   my $col = $_geom{colon_col};
   $self->_dot( $buff, $_geom{A_line}, $col );
   $self->_dot( $buff, $_geom{B_line}, $col );
}

method render_colon_as_linedraw ( $rb, $rect )
{
   $rb->eraserect( $rect );

   $rb->setpen( $_lit_pen );

   # U+2022 BULLET
   $rb->char_at( $_geom{A_line}, $_geom{colon_col}, 0x2022 );
   $rb->char_at( $_geom{B_line}, $_geom{colon_col}, 0x2022 );
}

# Symbol drawing
#
# Each symbol is drawn as a series of erase calls on the RB to draw 'lines'.

my %symbol_strokes = do {
   no warnings 'qw'; # Quiet the 'Possible attempt to separate words with commas' warning

   # Letters likely to be used for units
   V => [ [qw( 0,0 50,100 100,0 )] ],
   A => [ [qw( 0,100 50,0 100,100 )], [qw( 20,70 80,70)] ],
   W => [ [qw( 0,0 25,100 50,50 75,100 100,0)] ],
   Ω => [ [qw( 0,100 25,100 25,75 10,60 0,50 0,20 20,0 80,0 100,20 100,50 90,60 75,75 75,100 100,100 ) ] ],
   F => [ [qw( 0,100 0,0 100,0 )], [qw( 0,50 80,50 )] ],
   H => [ [qw( 0,0 0,100 )], [qw( 0,50 100,50 )], [qw( 100,0 100,100 )] ],
   s => [ [qw( 100,50 75,40 25,40 0,50 0,60 25,70 75,70 100,80 100,90 75,100 25,100 0,90 )] ],

   # Symbols likely to be used as SI prefixes
   G => [ [qw( 100,25 65,0 35,0 0,25 0,75 35,100 65,100 100,75 100,50 55,50 )] ],
   M => [ [qw( 0,100 0,0 50,50 100,0 100,100 )] ],
   k => [ [qw( 10,0 10,100 )], [qw( 90,40 10,70 90,100 )] ],
   m => [ [qw( 0,100 0,50 10,40 40,40 50,50 50,100 )], [qw( 50,50 60,40 90,40 100,50 100,100 )] ],
   µ => [ [qw( 0,100 0,40 )], [qw( 0,80 70,80 80,75 90,60 100,40 )] ],
   n => [ [qw( 0,100 0,40 )], [qw( 0,50 30,40 70,40 100,50 100,100 )] ],
   p => [ [qw( 0,100 0,40 )], [qw( 0,55 30,40 70,40 100,55 100,60 70,80 30,80 0,60 )] ],

   # Mathematical symbols
   '+' => [ [qw( 10,50 90,50 )], [qw( 50,30 50,70 )] ],
   '-' => [ [qw( 10,50 90,50 )] ],
   '%' => [ [qw( 10,10 10,30 30,30 30,10 10,10 )], [qw( 20,100 80,00 )], [qw( 70,70 70,90 90,90 90,70 70,70 )] ],
};

method reshape_symb ( $lines, $cols, $top, $left )
{
   $_geom{mid_line} = int( ( $lines - 1 ) / 2 );
   $_geom{mid_col}  = int( ( $cols  - 2 ) / 2 );

   $_geom{Y_to_line} = ( $lines - 1 ) / 100;
   $_geom{X_to_col}  = ( $cols  - 2 ) / 100;
}

method _roundpos ( $l, $c )
{
   # Round away from the centre of the widget
   return
      int($l) + ( $l > int($l) && $l > $_geom{mid_line} ),
      int($c) + ( $c > int($c) && $c > $_geom{mid_col}  );
}

method render_symb ( $buff )
{
   my $strokes = $symbol_strokes{$self->value} or return;

   my $Y_to_line = $_geom{Y_to_line};
   my $X_to_col  = $_geom{X_to_col};

   foreach my $stroke ( @$strokes ) {
      my ( $start, @points ) = @$stroke;
      $start =~ m/^(\d+),(\d+)$/;
      my ( $atL, $atC ) = $self->_roundpos( $2 * $Y_to_line, $1 * $X_to_col );

      foreach ( @points ) {
         m/^(\d+),(\d+)$/;
         my ( $toL, $toC ) = $self->_roundpos( $2 * $Y_to_line, $1 * $X_to_col );

         if( $toL == $atL ) {
            my ( $c, $limC ) = $toC > $atC ? ( $atC, $toC ) : ( $toC, $atC );
            $self->_fill( $buff, $atL, $atL, $c, $limC );
         }
         elsif( $toC == $atC ) {
            my ( $l, $limL ) = $toL > $atL ? ( $atL, $toL ) : ( $toL, $atL );
            $self->_fill( $buff, $l, $limL, $atC, $atC );
         }
         else {
            my ( $sL, $eL, $sC, $eC ) = $toL > $atL ? ( $atL, $toL, $atC, $toC )
                                                    : ( $toL, $atL, $toC, $atC );
            # Maths is all easier if we use exclusive coords.
            $eL++;
            $eC > $sC ? $eC++ : $eC--;

            my $dL = $eL - $sL;
            my $dC = $eC - $sC;

            if( $dL >= abs $dC ) {
               my $c = $sC;
               my $err = 0;

               for( my $l = $sL; $l != $eL; $l++ ) {
                  $c++, $err -= $dL if  $err > $dL;
                  $c--, $err += $dL if -$err > $dL;

                  $self->_dot( $buff, $l, $c );

                  $err += $dC;
               }
            }
            else {
               my $l = $sL;
               my $err = 0;
               my $adC = abs $dC;

               for( my $c = $sC; $c != $eC; $c += ( $eC > $sC ) ? 1 : -1 ) {
                  $l++, $err -= $adC if  $err > $adC;
                  $l--, $err += $adC if -$err > $adC;

                  $self->_dot( $buff, $l, $c );

                  $err += $dL;
               }
            }
         }

         $atL = $toL;
         $atC = $toC;
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
