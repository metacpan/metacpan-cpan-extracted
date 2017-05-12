#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Tickit::Widget::Choice;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;

our $VERSION = '0.02';

use Carp;

use Tickit::RenderBuffer qw( LINE_SINGLE LINE_DOUBLE CAP_START CAP_END );
use Tickit::Utils qw( textwidth );

use Tickit::Widget::Menu 0.09; # ->highlight_item
use Tickit::Widget::Menu::Item;

use List::Util qw( max );

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant CAN_FOCUS => 1;

=head1 NAME

C<Tickit::Widget::Choice> - a widget giving a choice from a list

=cut

style_definition base =>
   border_fg => "hi-white",
   border_linestyle => LINE_SINGLE,
   '<Home>'  => "first_choice",
   '<Up>'    => "prev_choice",
   '<Down>'  => "next_choice",
   '<End>'   => "last_choice",
   '<Space>' => "popup";

style_definition ':focus' =>
   border_linestyle => LINE_DOUBLE;

style_redraw_keys qw( border_linestyle );

use constant KEYPRESSES_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 new

   $choice = Tickit::Widget::Choice->new( %args )

Constructs a new C<Tickit::Widget::Choice> object.

Takes the following named arguments

=over 8

=item choices => ARRAY

Optional. If supplied, should be an ARRAY reference containing two-element
ARRAY references. Each will be added to the list of choices as if by a call to
C<push_choice> for each element in the array.

=item on_changed => CODE

Optional. If supplied, used to set the initial value of the C<on_changed>
event handler.

=back

=cut

sub new
{
   my $class = shift;
   my %params = @_;

   my $self = $class->SUPER::new( %params );

   $self->{choices} = [];

   $self->push_choice( @$_ ) for @{ $params{choices} || [] };

   $self->set_on_changed( $params{on_changed} ) if $params{on_changed};

   return $self;
}

sub lines { 1 }

sub cols
{
   my $self = shift;
   return 4 + max( 1, map { textwidth $_->[1] } @{ $self->{choices} } );
}

sub window_gained
{
   my $self = shift;
   my ( $window ) = @_;
   $self->SUPER::window_gained( $window );

   $window->cursor_at( 0, 1 );
}

=head1 ACCESSORS

=cut

=head2 on_changed

   $on_changed = $self->on_changed

=cut

sub on_changed
{
   my $self = shift;
   return $self->{on_changed};
}

=head2 set_on_changed

   $self->set_on_changed( $on_changed )

Return or set the CODE reference to be called when the chosen selection is
changed.

 $on_changed->( $choice, $value )

=cut

sub set_on_changed
{
   my $self = shift;
   ( $self->{on_changed} ) = @_;
}

=head1 METHODS

=cut

=head2 push_choice

   $choice->push_choice( $value, $caption )

Appends another choice to the list of choices, with the given value and
display caption.

=cut

sub push_choice
{
   my $self = shift;
   my ( $value, $caption ) = @_;

   push @{ $self->{choices} }, [ $value, $caption ];
   $self->{chosen} = 0 if !defined $self->{chosen};

   $self->resized;
   $self->redraw;

   return $self;
}

=head2 chosen_value

   $value = $choice->chosen_value

Returns the value of the currently-chosen choice.

=cut

sub chosen_value
{
   my $self = shift;
   return $self->{choices}[ $self->{chosen} ]->[0];
}

=head2 choose_by_idx

   $choice->choose_by_idx( $idx )

Moves the chosen choice to the one at the given index. If this wasn't the
previously-chosen one, invokes the C<on_changed> event.

=cut

sub choose_by_idx
{
   my $self = shift;
   my ( $idx ) = @_;

   return if $self->{chosen} == $idx;

   $self->{chosen} = $idx;
   $self->redraw;

   $self->{on_changed}->( $self, $self->chosen_value ) if $self->{on_changed};
}

=head2 choose_by_value

   $choice->choose_by_value( $value )

Moves the chosen choise to the one having the given value, if such a choice
exists. If this wasn't the previously-chosen one, invokes the C<on_changed>
event.

=cut

sub choose_by_value
{
   my $self = shift;
   my ( $value ) = @_;

   my $choices = $self->{choices};
   $choices->[$_][0] eq $value and return $self->choose_by_idx( $_ )
      for 0 .. $#$choices;

   croak "No such choice with value '$value'";
}

=head2 popup_menu

   $choice->popup_menu

Display the popup menu in a modal float until a choice is made.

=cut

sub popup_menu
{
   my $self = shift;

   my $menu = $self->{menu} = Tickit::Widget::Menu->new(
      items => [ map {
         my ( $value, $caption ) = @$_;
         Tickit::Widget::Menu::Item->new(
            name        => $caption,
            on_activate => sub {
               undef $self->{menu};
               $self->choose_by_value( $value );
            },
         )
      } @{ $self->{choices} } ],
   );

   my $top = -1;
   $top = 0 if $self->window->abs_top == 0;

   $menu->popup( $self->window, $top, 0 );

   $menu->highlight_item( $self->{chosen} );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $border_pen = $self->get_style_pen( 'border' );
   my $linestyle  = $self->get_style_values( 'border_linestyle' );

   my $chosen = $self->{choices}[ $self->{chosen} ];

   my $right = $self->window->cols - 3;

   $rb->vline_at( 0, 0, 0, $linestyle, $border_pen, CAP_START|CAP_END );

   $rb->goto( 0, 1 );
   $rb->text( substr( $chosen->[1], 0, $right - 1 ) );
   $rb->erase_to( $right );

   $rb->vline_at( 0, 0, $right, $linestyle, $border_pen, CAP_START|CAP_END );
   $rb->text_at( 0, $right+1, "-", $border_pen );
   $rb->vline_at( 0, 0, $right+2, $linestyle, $border_pen, CAP_START|CAP_END );
}

sub key_first_choice { my $self = shift; $self->choose_by_idx( 0 ); 1 }
sub key_last_choice  { my $self = shift; $self->choose_by_idx( $#{ $self->{choices} } ); 1 }

sub key_next_choice  { my $self = shift; $self->choose_by_idx( $self->{chosen}+1 ) if $self->{chosen} < $#{ $self->{choices} }; 1 }
sub key_prev_choice  { my $self = shift; $self->choose_by_idx( $self->{chosen}-1 ) if $self->{chosen} > 0; 1 }

sub key_popup { my $self = shift; $self->popup_menu; 1 }

sub on_mouse
{
   my $self = shift;
   my ( $ev ) = @_;

   return unless $ev->type eq "press" and $ev->button == 1;

   my $win = $self->window;
   my $right = $win->cols - 3;

   my $col = $ev->col;
   if( $ev->line == 0 and ( $col > 1 && $col < $right or $col == $right + 1 ) ) {
      $self->popup_menu;
   }

   return 1;
}

=head1 TODO

=over 4

=item *

Render a full border around the widget if height is at least 3.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
