#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2020 -- leonerd@leonerd.org.uk

package Tickit::Widget::Static;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;
use Tickit::RenderBuffer;

use Tickit::WidgetRole::Alignable name => 'align',  dir => 'h';
use Tickit::WidgetRole::Alignable name => 'valign', dir => 'v';

our $VERSION = '0.51';

use List::Util qw( max );
use Tickit::Utils qw( textwidth substrwidth );

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 NAME

C<Tickit::Widget::Static> - a widget displaying static text

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Static;

   my $hello = Tickit::Widget::Static->new(
      text   => "Hello, world",
      align  => "centre",
      valign => "middle",
   );

   Tickit->new( root => $hello )->run;

=head1 DESCRIPTION

This class provides a widget which displays a single piece of static text. The
text may contain more than one line, separated by linefeed (C<\n>) characters.
No other control sequences are allowed in the string.

=head1 STYLE

The default style pen is used as the widget pen.

Note that while the widget pen is mutable and changes to it will result in
immediate redrawing, any changes made will be lost if the widget style is
changed.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $static = Tickit::Widget::Static->new( %args )

Constructs a new C<Tickit::Widget::Static> object.

Takes the following named arguments in addition to those taken by the base
L<Tickit::Widget> constructor:

=over 8

=item text => STRING

The text to display

=item align => FLOAT|STRING

Optional. Defaults to C<0.0> if unspecified.

=item valign => FLOAT|STRING

Optional. Defaults to C<0.0> if unspecified.

=item on_click => CODE

Optional. Defaults to C<undef> if unspecified.

=back

For more details see the accessors below.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{lines} = [];
   $self->set_text( $args{text} );
   $self->set_align( $args{align} || 0 );
   $self->set_valign( $args{valign} || 0 );

   $self->set_on_click( $args{on_click} );

   return $self;
}

=head1 ACCESSORS

=cut

sub lines
{
   my $self = shift;
   return scalar @{ $self->{lines} };
}

sub cols
{
   my $self = shift;
   return max map { textwidth $_ } @{ $self->{lines} }
}

=head2 text

   $text = $static->text

=cut

sub text
{
   my $self = shift;
   return join "\n", @{ $self->{lines} };
}

=head2 set_text

   $static->set_text( $text )

Accessor for C<text> property; the actual text on display in the widget

=cut

sub set_text
{
   my $self = shift;
   my ( $text ) = @_;

   my $waslines = $self->lines;
   my $wascols  = $self->cols;

   my @lines = split m/\n/, $text;
   # split on empty string returns empty list
   @lines = ( "" ) if !@lines;
   $self->{lines} = \@lines;

   $self->resized if $self->lines != $waslines or $self->cols != $wascols;

   $self->redraw;
}

=head2 align

=head2 set_align

   $align = $static->align

   $static->set_align( $align )

Accessor for horizontal alignment value.

Gives a value in the range from C<0.0> to C<1.0> to align the text display
within the window. If the window is larger than the width of the text, it will
be aligned according to this value; with C<0.0> on the left, C<1.0> on the
right, and other values inbetween.

See also L<Tickit::WidgetRole::Alignable>.

=cut

sub set_on_click
{
   my $self = shift;
   my ( $on_click ) = @_;

   $self->{on_click} = $on_click;
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $win = $self->window;

   $rb->erase_at( $_, $rect->left, $rect->cols ) for $rect->linerange;

   my $cols = $win->cols;
   my ( $above, $lines ) = $self->_valign_allocation( $self->lines, $win->lines );

   foreach my $line ( 0 .. $lines - 1 ) {
      my $text = $self->{lines}[$line];

      my ( $left, $textwidth ) = $self->_align_allocation( textwidth( $text ), $cols );

      $rb->text_at( $above + $line, $left, substrwidth( $text, 0, $textwidth ) );
   }
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   return unless $args->type eq "press" and $args->button == 1;
   return unless my $on_click = $self->{on_click};

   $on_click->( $self, $args->line, $args->col );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
