#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2018 -- leonerd@leonerd.org.uk

package Tickit::Widget::SegmentDisplay;

use strict;
use warnings;
use 5.010; # //
use base qw( Tickit::Widget );
use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE LINE_THICK );

use utf8;

our $VERSION = '0.05';

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

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = $class->SUPER::new( %args );

   my $type = $args{type} // "seven";
   my $method;
   foreach my $typename ( keys %types ) {
      $type eq $typename and $method = $typename, last;
      $type eq $_ and $method = $typename, last for @{ $types{$typename} };
   }
   defined $method or croak "Unrecognised type name '$type'";

   $self->{reshape_method} = $self->can( "reshape_${method}" );

   my $use_halfline = $args{use_halfline};
   $self->{use_halfline} = $use_halfline;

   my $use_linedraw = $args{use_linedraw};

   if( $use_linedraw and my $code = $self->can( "render_${method}_as_linedraw" ) ) {
      $self->{linestyle} = ( $args{thickness} // 1 ) > 1 ? LINE_THICK : LINE_SINGLE;
      $self->{render_to_rb} = $code;
   }
   else {
      my $render = $self->can( "render_${method}" );

      my $use_unicode  = $args{use_unicode};

      my $flush = $self->can(
         $use_halfline ? "flush_halfline" :
         $use_unicode  ? "flush_unicode"  :
                         "flush" );

      $self->{render_to_rb} = sub {
         my $self = shift;
         my ( $rb, $rect ) = @_;
         my @buff;

         # TODO: sizing?
         $render->( $self, \@buff );

         $rb->eraserect( $rect );

         $flush->( $self, \@buff, $rb, $rect );
      };
   }

   $self->{hthickness} = $args{thickness} // 2;

   $self->{vthickness} = $self->{hthickness};
   $self->{vthickness} /= 2 unless $self->{use_halfline};

   if( $use_linedraw ) {
      $self->{hthickness} = 1;
      $self->{vthickness} = 1;
   }

   $self->{margin} = $use_linedraw ? 0 : 1;

   $self->{value} = $args{value} // "";

   $self->on_style_changed_values(
      lit   => [ undef, $self->get_style_values( "lit" ) ],
      unlit => [ undef, $self->get_style_values( "unlit" ) ],
   );

   return $self;
}

# ADG + atleast 1 line each for FB and EC
sub lines { 3 + 2 }

# FE, BC + atleast 2 columns for AGD
sub cols  { 4 + 2 }

=head1 ACCESSORS

=cut

=head2 value

   $value = $segmentdisplay->value

   $segmentdisplay->set_value( $value )

Return or set the character on display

=cut

sub value
{
   my $self = shift;
   return $self->{value};
}

sub set_value
{
   my $self = shift;
   ( $self->{value} ) = @_;
   $self->redraw;
}

sub on_style_changed_values
{
   my $self = shift;
   my %values = @_;

   $self->{lit_pen}   = Tickit::Pen::Immutable->new( fg => $values{lit}[1]   ) if $values{lit};
   $self->{unlit_pen} = Tickit::Pen::Immutable->new( fg => $values{unlit}[1] ) if $values{unlit};
}

sub reshape
{
   my $self = shift;
   my $win = $self->window or return;

   my $linescale = 1 + !!$self->{use_halfline};

   $self->{reshape_method}->( $self, $win->lines * $linescale, $win->cols, 0, 0 );
}

use constant {
   LIT   => 0x01,
   UNLIT => 0x02,
};

sub render_to_rb
{
   my $self = shift;
   $self->{render_to_rb}->( $self, @_ );
}

sub flush
{
   my $self = shift;
   my ( $buff, $rb, $rect ) = @_;

   my $lit_pen   = Tickit::Pen::Immutable->new( bg => $self->{lit_pen}->getattr( "fg" ) );
   my $unlit_pen = Tickit::Pen::Immutable->new( bg => $self->{unlit_pen}->getattr( "fg" ) );

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

sub flush_unicode
{
   my $self = shift;
   my ( $buff, $rb, $rect ) = @_;

   my $lit_pen   = $self->{lit_pen};
   my $unlit_pen = $self->{unlit_pen};

   foreach my $line ( $rect->linerange ) {
      next unless defined( my $cells = $buff->[$line] );
      foreach my $col ( $rect->left .. $rect->right - 1 ) {
         my $val = vec( $cells, $col, 2 ) or next;
         $rb->setpen( $val == LIT ? $lit_pen : $unlit_pen );
         $rb->char_at( $line, $col, U_FULL );
      }
   }
}

sub flush_halfline
{
   my $self = shift;
   my ( $buff, $rb, $rect ) = @_;

   my $lit_pen   = $self->{lit_pen};
   my $unlit_pen = $self->{unlit_pen};

   my $both_pen = Tickit::Pen::Immutable->new(
      fg => $lit_pen->getattr( 'fg' ),
      bg => $unlit_pen->getattr( 'fg' ),
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
            $rb->setpen( ( $hival || $loval ) == LIT ? $lit_pen : $unlit_pen );
            $rb->char_at( $phyline, $col, U_FULL );
         }
         elsif( !$hival or !$loval ) {
            $rb->setpen( ( $hival || $loval ) == LIT ? $lit_pen : $unlit_pen );
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

sub _fill
{
   my $self = shift;
   my ( $buff, $startline, $endline, $startcol, $endcol, $val ) = @_;
   $val //= LIT;

   my @colrange = ( $startcol .. $endcol + $self->{hthickness} - 1 );

   my @linerange = ( $startline .. $endline + $self->{vthickness} - 1 );

   foreach my $line ( @linerange ) {
      vec( $buff->[$line], $_, 2 ) = $val for @colrange;
   }
}

sub _dot
{
   my $self = shift;
   my ( $buff, $line, $col, $val ) = @_;
   $self->_fill( $buff, $line, $line, $col, $col, $val );
}

# 7-Segment
my %segments = (
   ' ' => "       ",
   0 => "ABCDEF ",
   1 => " BC    ",
   2 => "AB DE G",
   3 => "ABCD  G",
   4 => " BC  FG",
   5 => "A CD FG",
   6 => "A CDEFG",
   7 => "ABC    ",
   8 => "ABCDEFG",
   9 => "ABCD FG",
);

sub _val_for_seg
{
   my $self = shift;
   my ( $segment ) = @_;

   my $segments = $segments{$self->value} or return UNLIT;

   my $lit = substr( $segments, ord($segment) - ord("A"), 1 ) ne " ";
   return $lit ? LIT : UNLIT;
}

sub reshape_seven
{
   my $self = shift;
   my ( $lines, $cols, $top, $left ) = @_;

   my $margin = $self->{margin};

   my $hthickness = $self->{hthickness};

   my $right = $left + $cols - $hthickness;

   $self->{FE_col}       = $left;
   $self->{AGD_startcol} = $left + $hthickness * $margin;
   $self->{AGD_endcol}   = $right - $hthickness * $margin;
   $self->{BC_col}       = $right;

   my $vthickness = $self->{vthickness};

   my $bottom = $top + $lines - $vthickness;
   my $mid    = int( ( $top + $bottom ) / 2 );

   $self->{A_line}       = $top;
   $self->{BF_startline} = $top + $vthickness * $margin;
   $self->{BF_endline}   = $mid - $vthickness * $margin;
   $self->{G_line}       = $mid;
   $self->{CE_startline} = $mid + $vthickness * $margin;
   $self->{CE_endline}   = $bottom - $vthickness * $margin;
   $self->{D_line}       = $bottom;
}

sub render_seven
{
   my $self = shift;
   my ( $buff ) = @_;

   $self->_fill( $buff, ( $self->{A_line} ) x 2, $self->{AGD_startcol}, $self->{AGD_endcol}, $self->_val_for_seg( "A" ) );
   $self->_fill( $buff, ( $self->{G_line} ) x 2, $self->{AGD_startcol}, $self->{AGD_endcol}, $self->_val_for_seg( "G" ) );
   $self->_fill( $buff, ( $self->{D_line} ) x 2, $self->{AGD_startcol}, $self->{AGD_endcol}, $self->_val_for_seg( "D" ) );

   $self->_fill( $buff, $self->{BF_startline}, $self->{BF_endline}, ( $self->{FE_col} ) x 2, $self->_val_for_seg( "F" ) );
   $self->_fill( $buff, $self->{BF_startline}, $self->{BF_endline}, ( $self->{BC_col} ) x 2, $self->_val_for_seg( "B" ) );
   $self->_fill( $buff, $self->{CE_startline}, $self->{CE_endline}, ( $self->{FE_col} ) x 2, $self->_val_for_seg( "E" ) );
   $self->_fill( $buff, $self->{CE_startline}, $self->{CE_endline}, ( $self->{BC_col} ) x 2, $self->_val_for_seg( "C" ) );
}

sub render_seven_as_linedraw
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );

   $rb->setpen( $self->{lit_pen} );

   my $linestyle = $self->{linestyle};

   $rb->hline_at( $self->{A_line}, $self->{AGD_startcol}, $self->{AGD_endcol}, $linestyle ) if $self->_val_for_seg( "A" ) == LIT;
   $rb->hline_at( $self->{G_line}, $self->{AGD_startcol}, $self->{AGD_endcol}, $linestyle ) if $self->_val_for_seg( "G" ) == LIT;
   $rb->hline_at( $self->{D_line}, $self->{AGD_startcol}, $self->{AGD_endcol}, $linestyle ) if $self->_val_for_seg( "D" ) == LIT;

   $rb->vline_at( $self->{BF_startline}, $self->{BF_endline}, $self->{FE_col}, $linestyle ) if $self->_val_for_seg( "F" ) == LIT;
   $rb->vline_at( $self->{BF_startline}, $self->{BF_endline}, $self->{BC_col}, $linestyle ) if $self->_val_for_seg( "B" ) == LIT;
   $rb->vline_at( $self->{CE_startline}, $self->{CE_endline}, $self->{FE_col}, $linestyle ) if $self->_val_for_seg( "E" ) == LIT;
   $rb->vline_at( $self->{CE_startline}, $self->{CE_endline}, $self->{BC_col}, $linestyle ) if $self->_val_for_seg( "C" ) == LIT;
}

# 7-Segment with DP
sub reshape_seven_dp
{
   my $self = shift;
   my ( $lines, $cols, $top, $left ) = @_;

   $self->reshape_seven( $lines, $cols - 2, $top, $left );

   $self->{DP_line} = $top  + $lines - 1;
   $self->{DP_col}  = $left + $cols  - 2;
}

sub render_seven_dp
{
   my $self = shift;
   my ( $buff ) = @_;

   my $value = $self->{value};
   my $dp;
   local $self->{value};

   if( $value =~ m/^(\d?)(\.?)/ ) {
      $self->{value} = $1;
      $dp = length $2;
   }
   else {
      $self->{value} = $value;
   }

   $self->render_seven( $buff );

   $self->_dot( $buff, $self->{DP_line}, $self->{DP_col}, $dp ? LIT : UNLIT );
}

# Static double-dot colon
sub reshape_colon
{
   my $self = shift;
   my ( $lines, $cols, $top, $left ) = @_;
   my $bottom = $top + $lines - 1;

   $self->{colon_col} = 2 + int( ( $cols - 4 ) / 2 );

   my $ofs = int( ( $lines - 1 + 0.5 ) / 4 );

   $self->{A_line} = $top    + $ofs;
   $self->{B_line} = $bottom - $ofs;
}

sub render_colon
{
   my $self = shift;
   my ( $buff ) = @_;

   my $col = $self->{colon_col};
   $self->_dot( $buff, $self->{A_line}, $col );
   $self->_dot( $buff, $self->{B_line}, $col );
}

sub render_colon_as_linedraw
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );

   $rb->setpen( $self->{lit_pen} );

   # U+2022 BULLET
   $rb->char_at( $self->{A_line}, $self->{colon_col}, 0x2022 );
   $rb->char_at( $self->{B_line}, $self->{colon_col}, 0x2022 );
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

sub reshape_symb
{
   my $self = shift;
   my ( $lines, $cols, $top, $left ) = @_;

   $self->{mid_line} = int( ( $lines - 1 ) / 2 );
   $self->{mid_col}  = int( ( $cols  - 2 ) / 2 );

   $self->{Y_to_line} = ( $lines - 1 ) / 100;
   $self->{X_to_col}  = ( $cols  - 2 ) / 100;
}

sub _roundpos
{
   my $self = shift;
   my ( $l, $c ) = @_;

   # Round away from the centre of the widget
   return
      int($l) + ( $l > int($l) && $l > $self->{mid_line} ),
      int($c) + ( $c > int($c) && $c > $self->{mid_col}  );
}

sub render_symb
{
   my $self = shift;
   my ( $buff ) = @_;

   my $strokes = $symbol_strokes{$self->value} or return;

   my $Y_to_line = $self->{Y_to_line};
   my $X_to_col  = $self->{X_to_col};

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
