#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Spinner;

use strict;
use warnings;
use base qw( Tickit::Widget );

use Tickit::Style;

our $VERSION = '0.27';

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

=head2 $spinner = Tickit::Widget::Spinner->new( %args )

Constructs a new C<Tickit::Widget::Spinner> object.

Takes the following named arguments:

=over 8

=item chars => ARRAY

Optional. An ARRAY reference containing the text strings to use.

=item interval => NUM

Optional. The time each string is displayed for. Defaults to 0.5.

=back

=cut

sub new
{
   my $class = shift;
   my %params = @_;

   my $self = $class->SUPER::new( %params );

   $self->{chars} = $params{chars} || [qw( - \ | / )];
   $self->{state} = 0;

   $self->{interval} = $params{interval} // 0.5;

   $self->{cols} = max map { textwidth $_ } @{ $self->{chars} };

   return $self;
}

=head1 METHODS

=cut

sub lines
{
   return 1;
}

sub cols
{
   my $self = shift;
   return $self->{cols};
}

=head2 $spinner->start

Starts the animation effect.

=cut

sub start
{
   my $self = shift;
   return if $self->{running};
   $self->{running} = 1;
   $self->tick;
}

=head2 $spinner->stop

Stops the animation effect.

=cut

sub stop
{
   my $self = shift;
   $self->{running} = 0;
}

sub window_gained
{
   my $self = shift;
   $self->SUPER::window_gained( @_ );
   $self->start;
}

# precache position
sub reshape
{
   my $self = shift;

   my $win = $self->window or return;

   @{$self}{qw( x y )} = map int($_ / 2), $win->cols - $self->cols, $win->lines - $self->lines;

   $self->{rect} = Tickit::Rect->new(
      top   => $self->{y},
      left  => $self->{x},
      lines => $self->lines,
      cols  => $self->cols,
   );
}

sub tick
{
   my $self = shift;
   return unless $self->{running};

   my $state = $self->{state}++;
   $self->{state} %= @{ $self->{chars} };

   if( my $win = $self->window ) {
      $win->tickit->timer( after => $self->{interval} => sub { $self->tick } );
      $win->expose( $self->{rect} );
   }
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $chars = $self->{chars};
   my $state = $self->{state};

   $rb->eraserect( $rect );

   $rb->text_at( $self->{y}, $self->{x}, $chars->[$state] );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
