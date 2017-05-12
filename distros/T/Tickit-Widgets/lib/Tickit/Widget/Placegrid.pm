#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk
#  Original render code by Tom Molesworth

package Tickit::Widget::Placegrid;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE LINE_THICK );

our $VERSION = '0.27';

use Tickit::Utils qw( textwidth );

=head1 NAME

C<Tickit::Widget::Placegrid> - a placeholder grid display

=head1 DESCRIPTION

This class provides a widget which displays a simple grid pattern in its
display area, and prints the size of the area in its centre.

It is intended as a placeholder for other widget code while applications are
under development. It easily allows a container to have a child that can take
any size, and will keep its window area painted (so avoiding bugs caused by
"empty" containers that do not clear unused child areas).

=head1 STYLE

The default style pen is used as the widget pen. The following style pen
prefixes are also used:

=over 4

=item grid => PEN

The pen used to render the grid lines

=back

=cut

style_definition base =>
   fg => "white",
   grid_fg => "blue";

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=head2 $placegrid = Tickit::Widget::Placegrid->new( %args )

Constructs a new C<Tickit::Widget::Placegrid> object.

Takes the following named arguments.

=over 8

=item title => STR

Optional. If provided, prints an identifying title just above the box
dimensions in the centre of the grid.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = $class->SUPER::new( %args );

   $self->{title} = $args{title};

   return $self;
}

sub lines { 1 }
sub cols  { 1 }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->clear($self->pen);

   my ($w, $h) = map $self->window->$_ - 1, qw(cols lines);

   $rb->setpen($self->get_style_pen("grid"));
   $rb->hline_at(0, 0, $w, LINE_THICK);
   $rb->hline_at($h, 0, $w, LINE_THICK);
   $rb->hline_at($h / 2, 0, $w, LINE_SINGLE);
   $rb->vline_at(0, $h, 0, LINE_THICK);
   $rb->vline_at(0, $h, $w, LINE_THICK);
   $rb->vline_at(0, $h, $w / 2, LINE_SINGLE);

   $rb->setpen($self->pen);

   if(defined(my $title = $self->{title})) {
      $rb->text_at(($h / 2) - 1, (1 + $w - textwidth($title)) / 2, $title);
   }

   my $txt = '(' . $self->window->cols . ',' . $self->window->lines . ')';
   $rb->text_at($h / 2, (1 + $w - textwidth($txt)) / 2, $txt);
}

=head1 AUTHOR

Original rendering code by Tom Molesworth <cpan@entitymodel.com>

Widget wrapping by Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
