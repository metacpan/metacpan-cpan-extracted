#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2021 -- leonerd@leonerd.org.uk

use Object::Pad 0.51;

package Tickit::Widget::Static 0.54;
class Tickit::Widget::Static
   extends Tickit::Widget;

use Tickit::Style;

use Tickit::WidgetRole::Alignable name => 'align',  dir => 'h';
use Tickit::WidgetRole::Alignable name => 'valign', dir => 'v';

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

has @_lines;
has $_on_click :reader :writer :param = undef;

ADJUSTPARAMS
{
   my ( $params ) = @_;

   $self->set_text( delete $params->{text} );
   $self->set_align( delete $params->{align} || 0 );
   $self->set_valign( delete $params->{valign} || 0 );
}

=head1 ACCESSORS

=cut

method lines
{
   return scalar @_lines;
}

method cols
{
   return max map { textwidth $_ } @_lines;
}

=head2 text

   $text = $static->text

=cut

method text
{
   return join "\n", @_lines;
}

=head2 set_text

   $static->set_text( $text )

Accessor for C<text> property; the actual text on display in the widget

=cut

method set_text
{
   my ( $text ) = @_;

   my $waslines = $self->lines;
   my $wascols  = $self->cols;

   @_lines = split m/\n/, $text;
   # split on empty string returns empty list
   @_lines = ( "" ) if !@_lines;

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

# generated accessor

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   my $win = $self->window;

   $rb->erase_at( $_, $rect->left, $rect->cols ) for $rect->linerange;

   my $cols = $win->cols;
   my ( $above, $lines ) = $self->_valign_allocation( $self->lines, $win->lines );

   foreach my $line ( 0 .. $lines - 1 ) {
      my $text = $_lines[$line];

      my ( $left, $textwidth ) = $self->_align_allocation( textwidth( $text ), $cols );

      $rb->text_at( $above + $line, $left, substrwidth( $text, 0, $textwidth ) );
   }
}

method on_mouse
{
   my ( $args ) = @_;

   return unless $args->type eq "press" and $args->button == 1;
   return unless $_on_click;

   $_on_click->( $self, $args->line, $args->col );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
