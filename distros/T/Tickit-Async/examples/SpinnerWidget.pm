package SpinnerWidget;
use base 'Tickit::Widget';

use IO::Async::Timer::Periodic;

my $animation = "-/|\\";

sub lines { 1 }
sub cols  { 1 }

sub window_gained
{
   my $self = shift;
   $self->window->tickit->get_loop->add(
      IO::Async::Timer::Periodic->new(
         interval => 0.25,
         on_tick => sub { $self->tick },
      )->start,
   );
}

sub tick
{
   my $self = shift;

   $self->{anim_index} = ( $self->{anim_index} + 1 ) % 4;
   $self->redraw;
}

sub render_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $win = $self->window;

   $rb->clear;
   $rb->text_at(
      ( $win->lines - 1 ) / 2, ( $win->cols - 1 ) / 2,
      substr( $animation, $self->{anim_index}, 1 ),
   );
}

1;
