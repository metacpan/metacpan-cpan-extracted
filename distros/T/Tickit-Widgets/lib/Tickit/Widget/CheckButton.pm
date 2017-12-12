#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::CheckButton;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;

our $VERSION = '0.28';

use Carp;

use Tickit::Utils qw( textwidth );
use List::Util 1.33 qw( any );

use constant CAN_FOCUS => 1;

=head1 NAME

C<Tickit::Widget::CheckButton> - a widget allowing a toggle true/false option

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::CheckButton;
 use Tickit::Widget::VBox;

 my $vbox = Tickit::Widget::VBox->new;
 $vbox->add( Tickit::Widget::CheckButton->new(
       label => "Check button $_",
 ) ) for 1 .. 5;

 Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This class provides a widget which allows a true/false selection. It displays
a clickable indication of status and a caption. Clicking on the status or
caption inverts the status of the widget.

This widget is part of an experiment in evolving the design of the
L<Tickit::Style> widget integration code, and such is subject to change of
details.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item check => PEN

The pen used to render the check marker

=back

The following style keys are used:

=over 4

=item check => STRING

The text used to indicate the active status

=item spacing => INT

Number of columns of spacing between the check mark and the caption text

=back

The following style tags are used:

=over 4

=item :active

Set when this button's status is true

=back

The following style actions are used:

=over 4

=item toggle

The main action to activate the C<on_click> handler.

=back

=cut

style_definition base =>
   check_fg => "hi-white",
   check_b  => 1,
   check    => "[ ]",
   spacing  => 2,
   '<Space>' => "toggle";

style_definition ':active' =>
   b        => 1,
   check    => "[X]";

style_reshape_keys qw( spacing );

style_reshape_textwidth_keys qw( check );

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 $checkbutton = Tickit::Widget::CheckButton->new( %args )

Constructs a new C<Tickit::Widget::CheckButton> object.

Takes the following named argmuents

=over 8

=item label => STRING

The label text to display alongside this button.

=item on_toggle => CODE

Optional. Callback function to invoke when the check state is changed.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->set_label( $args{label} ) if defined $args{label};
   $self->set_on_toggle( $args{on_toggle} ) if $args{on_toggle};

   return $self;
}

sub lines
{
   my $self = shift;
   return 1;
}

sub cols
{
   my $self = shift;
   return textwidth( $self->get_style_values( "check" ) ) +
          $self->get_style_values( "spacing" ) +
          textwidth( $self->{label} );
}

=head1 ACCESSORS

=cut

=head2 $label = $checkbutton->label

=head2 $checkbutton->set_label( $label )

Returns or sets the label text of the button.

=cut

sub label
{
   my $self = shift;
   return $self->{label};
}

sub set_label
{
   my $self = shift;
   ( $self->{label} ) = @_;
   $self->reshape;
   $self->redraw;
}

=head2 $on_toggle = $checkbutton->on_toggle

=cut

sub on_toggle
{
   my $self = shift;
   return $self->{on_toggle};
}

=head2 $checkbutton->set_on_toggle( $on_toggle )

Return or set the CODE reference to be called when the button state is
changed.

 $on_toggle->( $checkbutton, $active )

=cut

sub set_on_toggle
{
   my $self = shift;
   ( $self->{on_toggle} ) = @_;
}

=head1 METHODS

=cut

=head2 $checkbutton->activate

Sets this button's active state to true.

=cut

sub activate
{
   my $self = shift;
   $self->{active} = 1;
   $self->set_style_tag( active => 1 );
   $self->{on_toggle}->( $self, 1 ) if $self->{on_toggle};
}

=head2 $checkbutton->deactivate

Sets this button's active state to false.

=cut

sub deactivate
{
   my $self = shift;
   $self->{active} = 0;
   $self->set_style_tag( active => 0 );
   $self->{on_toggle}->( $self, 0 ) if $self->{on_toggle};
}

*key_toggle = \&toggle;
sub toggle
{
   my $self = shift;
   $self->is_active ? $self->deactivate : $self->activate;
   return 1;
}

=head2 $active = $checkbutton->is_active

Returns this button's active state.

=cut

sub is_active
{
   my $self = shift;
   return !!$self->{active};
}

sub reshape
{
   my $self = shift;

   my $win = $self->window or return;

   my $check = $self->get_style_values( "check" );

   $win->cursor_at( 0, ( textwidth( $check )-1 ) / 2 );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->clear;

   return if $rect->top > 0;

   $rb->goto( 0, 0 );

   $rb->text( my $check = $self->get_style_values( "check" ), $self->get_style_pen( "check" ) );
   $rb->erase( $self->get_style_values( "spacing" ) );
   $rb->text( $self->{label} );
   $rb->erase_to( $rect->right );
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   return unless $args->type eq "press" and $args->button == 1;
   return 1 unless $args->line == 0;

   $self->toggle;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
