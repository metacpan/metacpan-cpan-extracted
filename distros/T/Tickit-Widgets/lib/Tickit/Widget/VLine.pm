#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.20;
use Object::Pad 0.73;

package Tickit::Widget::VLine 0.37;
class Tickit::Widget::VLine
   :strict(params)
   :isa(Tickit::Widget);

use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE CAP_BOTH );

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 NAME

C<Tickit::Widget::HLine> - a widget displaying a vertical line

=head1 SYNOPSIS

   use Tickit::Widget::HLine;
   use Tickit::Widget::VBox;
   use Tickit::Widget::HLine;

   my $vbox = Tickit::Widget::VBox->new;

   $vbox->add( ... );

   $vbox->add( Tickit::Widget::HLine->new );

   $vbox->add( ... );

   Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This class provides a widget which displays a single vertical line, using
line-drawing characters. It consumes the full height of the window given to it
by its parent. By default it is drawn in the horizontal centre of the window but
this can be adjusted by the C<align> style value.

=head1 STYLE

The default style pen is used as the widget pen.

The following additional style keys are used:

=over 4

=item line_style => INT

The style to draw the line in. Must be one of the C<LINE_*> constants from
L<Tickit::RenderBuffer>.

=item align => NUM | STR

A fraction giving a position within the window to draw the line. Defaults to
C<0.5>, which puts it in the centre.

Symbolic names of C<left>, C<centre> and C<right> are also accepted.

=back

=cut

style_definition base =>
   line_style => LINE_SINGLE,
   align      => 0.5;

style_redraw_keys qw( line_style align );

my %symbolics = (
   left =>   0.0,
   centre => 0.5,
   right  => 1.0,
);

=head1 CONSTRUCTOR

=cut

=head2 new

   $hline = Tickit::Widget::HLine->new( %args )

Constructs a new C<Tickit::Widget::HLine> object.

=cut

method lines { 1 }
method cols { 1 }

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );

   my ( $line_style, $align ) = $self->get_style_values(qw( line_style align ));
   $align = $symbolics{$align} if exists $symbolics{$align};

   my $col = int( ( $rb->cols - 1 ) * $align );
   $rb->vline_at( 0, $rb->lines - 1, $col, $line_style, $self->pen, CAP_BOTH );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
