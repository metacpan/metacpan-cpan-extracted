#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2021 -- leonerd@leonerd.org.uk

use Object::Pad 0.43;  # ADJUST

package Tickit::Widget::RadioButton 0.32;
class Tickit::Widget::RadioButton
   extends Tickit::Widget;

use Tickit::Style;

use Carp;

use Tickit::Utils qw( textwidth );
use List::Util 1.33 qw( any );

use constant CAN_FOCUS => 1;

=head1 NAME

C<Tickit::Widget::RadioButton> - a widget allowing a selection from multiple
options

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::RadioButton;
   use Tickit::Widget::VBox;

   my $group = Tickit::Widget::RadioButton::Group->new;

   my $vbox = Tickit::Widget::VBox->new;
   $vbox->add( Tickit::Widget::RadioButton->new(
         caption => "Radio button $_",
         group   => $group,
   ) ) for 1 .. 5;

   Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This class provides a widget which allows a selection of one value from a
group of related options. It provides a clickable area and a visual indication
of which button in the group is the one currently active. Selecting a new
button within a group will unselect the previously-selected one.

This widget is part of an experiment in evolving the design of the
L<Tickit::Style> widget integration code, and such is subject to change of
details.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item tick => PEN

The pen used to render the tick marker

=back

The following style keys are used:

=over 4

=item tick => STRING

The text used to indicate the active button

=item spacing => INT

Number of columns of spacing between the tick mark and the caption text

=back

The following style tags are used:

=over 4

=item :active

Set when this button is the active one of the group.

=back

The following style actions are used:

=over 4

=item activate

The main action to activate the C<on_click> handler.

=back

=cut

style_definition base =>
   tick_fg => "hi-white",
   tick_b  => 1,
   tick    => "( )",
   spacing => 2,
   '<Space>' => "activate";

style_definition ':active' =>
   b        => 1,
   tick     => "(*)";

style_reshape_keys qw( spacing );

style_reshape_textwidth_keys qw( tick );

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 new

   $radiobutton = Tickit::Widget::RadioButton->new( %args )

Constructs a new C<Tickit::Widget::RadioButton> object.

Takes the following named argmuents

=over 8

=item label => STRING

The label text to display alongside this button.

=item group => Tickit::Widget::RadioButton::Group

Optional. If supplied, the group that the button should belong to. If not
supplied, a new group will be constructed that can be accessed using the
C<group> accessor.

=item value => SCALAR

Optional. If supplied, used to set the button's identification value, which
is passed to the group's C<on_changed> callback.

=back

=cut

has $_label     :reader         :param;
has $_on_toggle :reader :writer :param = undef;
has $_value     :reader :writer :param = undef;
has $_group     :reader         :param = undef;

ADJUST
{
   $_group //= Tickit::Widget::RadioButton::Group->new;
}

method lines
{
   return 1;
}

method cols
{
   return textwidth( $self->get_style_values( "tick" ) ) +
          $self->get_style_values( "spacing" ) +
          textwidth( $_label );
}

=head1 ACCESSORS

=cut

=head2 group

   $group = $radiobutton->group

Returns the C<Tickit::Widget::RadioButton::Group> this button belongs to.

=cut

# generated accessor

=head2 label

=head2 set_label

   $label = $radiobutton->label

   $radiobutton->set_label( $label )

Returns or sets the label text of the button.

=cut

# generated accessor

method set_label
{
   $_label = $_[0];
   $self->reshape;
   $self->redraw;
}

=head2 on_toggle

   $on_toggle = $radiobutton->on_toggle

=cut

# generated accessor

=head2 set_on_toggle

   $radiobutton->set_on_toggle( $on_toggle )

Return or set the CODE reference to be called when the button state is
changed.

 $on_toggle->( $radiobutton, $active )

When the radio tick mark moves from one button to another, the old button is
marked unactive before the new one is marked active.

=cut

# generated accessor

=head2 value

   $value = $radiobutton->value

=cut

# generated accessor

=head2 set_value

   $radiobutton->set_value( $value )

Return or set the scalar value used to identify the radio button to the
group's C<on_changed> callback. This can be any scalar value; it is simply
stored by the button and not otherwise used.

=cut

# generated accessor

=head1 METHODS

=cut

=head2 activate

   $radiobutton->activate

Sets this button as the active member of the group, deactivating the previous
one.

=cut

*key_activate = \&activate;
method activate
{
   if( my $old = $_group->active ) {
      $old->set_style_tag( active => 0 );
      $old->on_toggle->( $old, 0 ) if $old->on_toggle;
   }

   $_group->set_active( $self );

   $self->set_style_tag( active => 1 );
   $_on_toggle->( $self, 1 ) if $_on_toggle;

   return 1;
}

=head2 is_active

   $active = $radiobutton->is_active

Returns true if this button is the active button of the group.

=cut

method is_active
{
   return $self->group->active == $self;
}

method reshape
{
   my $win = $self->window or return;

   my $tick = $self->get_style_values( "tick" );

   $win->cursor_at( 0, ( textwidth( $tick )-1 ) / 2 );
}

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   $rb->clear;

   return if $rect->top > 0;

   $rb->goto( 0, 0 );

   $rb->text( my $tick = $self->get_style_values( "tick" ), $self->get_style_pen( "tick" ) );
   $rb->erase( $self->get_style_values( "spacing" ) );
   $rb->text( $_label );
   $rb->erase_to( $rect->right );
}

method on_mouse
{
   my ( $args ) = @_;

   return unless $args->type eq "press" and $args->button == 1;
   return 1 unless $args->line == 0;

   $self->activate;
}

class Tickit::Widget::RadioButton::Group {
   use Scalar::Util qw( weaken refaddr );

=head1 GROUPS

Every C<Tickit::Widget::RadioButton> belongs to a group. Only one button can
be active in a group at any one time. The C<group> accessor returns the group
the button is a member of. The following methods are available on it.

A group can be explicitly created to pass to a button's constructor, or one
will be implicitly created for a button if none is passed.

=cut

=head2 new

   $group = Tickit::Widget::RadioButton::Group->new

Returns a new group.

=cut

   has $_active :reader;
   has $_on_changed :reader :writer;

=head2 active

   $radiobutton = $group->active

Returns the button which is currently active in the group

=cut

   method set_active
   {
      ( $_active ) = @_;
      $_on_changed->( $self->active, $self->active->value ) if $_on_changed;
   }

=head2 on_changed

   $on_changed = $group->on_changed

=cut

=head2 set_on_changed

   $group->set_on_changed( $on_changed )

Return or set the CODE reference to be called when the active member of the
group changes. This may be more convenient than setting the C<on_toggle>
callback of each button in the group.

The callback is passed the currently-active button, and its C<value>.

   $on_changed->( $active, $value )

=cut

}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
