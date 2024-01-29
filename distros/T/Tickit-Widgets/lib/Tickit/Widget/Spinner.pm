#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2023 -- leonerd@leonerd.org.uk

use v5.20;
use warnings;
use Object::Pad 0.807;

package Tickit::Widget::Spinner 0.41;
class Tickit::Widget::Spinner :strict(params);

inherit Tickit::Widget;

use experimental 'postderef';

use Tickit::Style;

use List::Util qw( max );
use Tickit::Utils qw( textwidth );

=head1 NAME

C<Tickit::Widget::Spinner> - a widget displaying a small text animation

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Spinner;

   my $spinner = Tickit::Widget::Spinner->new(
      chars => [ "<X>  ", " <X> ", "  <X>", ">  <X", "X>  <" ],
   );

   Tickit->new( root => $spinner )->run;

=head1 DESCRIPTION

This class provides a widget which displays a simple animation, cycling
through a fixed set of strings with a fixed interval.

=head1 STYLE

The default style pen is used as the widget pen.

=cut

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 new

   $spinner = Tickit::Widget::Spinner->new( %args );

Constructs a new C<Tickit::Widget::Spinner> object.

Takes the following named arguments:

=over 8

=item chars => ARRAY

Optional. An ARRAY reference containing the text strings to use.

=item interval => NUM

Optional. The time each string is displayed for. Defaults to 0.5.

=back

=cut

field @_chars;
field $_state = 0;
field $_interval :param //= 0.5;
field $_cols;

ADJUST :params (
   :$chars = [qw( - \ | / )],
) {
   @_chars = $chars->@*;

   $_cols = max map { textwidth $_ } @_chars;
}

field $_running;
field $_x;
field $_y;
field $_rect;

=head1 METHODS

=cut

method lines
{
   return 1;
}

method cols
{
   return $_cols;
}

=head2 start

   $spinner->start;

Starts the animation effect.

=cut

method start
{
   return if $_running;
   $_running = 1;
   $self->tick;
}

=head2 stop

   $spinner->stop;

Stops the animation effect.

=cut

method stop
{
   $_running = 0;
}

method window_gained
{
   $self->SUPER::window_gained( @_ );
   $self->start;
}

# precache position
method reshape
{
   my $win = $self->window or return;

   ( $_x, $_y ) = map int($_ / 2), $win->cols - $self->cols, $win->lines - $self->lines;

   $_rect = Tickit::Rect->new(
      top   => $_y,
      left  => $_x,
      lines => $self->lines,
      cols  => $self->cols,
   );
}

method tick
{
   return unless $_running;

   my $state = $_state++;
   $_state %= @_chars;

   if( my $win = $self->window ) {
      $win->tickit->timer( after => $_interval => sub { $self->tick } );
      $win->expose( $_rect );
   }
}

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );

   $rb->text_at( $_y, $_x, $_chars[$_state] );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
