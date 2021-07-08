#  You may distribute under the terms of the Artistic License (the same terms
#  as Perl itself)
#
#  (C) Tom Molesworth 2011,
#      Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.43;  # ADJUST

package Tickit::Widget::Tabbed 0.024;
class Tickit::Widget::Tabbed
        extends Tickit::ContainerWidget;

Tickit::Widget->VERSION("0.12");
Tickit::Window->VERSION("0.23");

use Tickit::Style;
use constant KEYPRESSES_FROM_STYLE => 1;

use Carp;
use Tickit::Pen;
use List::Util qw(max);

use Tickit::Widget::Tabbed::Ribbon;

=head1 NAME

Tickit::Widget::Tabbed - provide tabbed window support

=head1 SYNOPSIS

   use Tickit::Widget::Tabbed;

   my $tabbed = Tickit::Widget::Tabbed->new;
   $tabbed->add_tab(Tickit::Widget::Static->new(text => 'some text'), label => 'First tab');
   $tabbed->add_tab(Tickit::Widget::Static->new(text => 'some text'), label => 'Second tab');

=head1 DESCRIPTION

Provides a container that operates as a tabbed window.

Subclass of L<Tickit::ContainerWidget>.

=cut

=head1 STYLE

The default style pen is used as the widget pen. The following style pen
prefixes are also used:

=over 4

=item ribbon => PEN

The pen used for the ribbon

=item active => PEN

The pen attributes used for the active tab on the ribbon

=item more => PEN

The pen used for "more" ribbon scroll markers

=back

The following style keys are used:

=over 4

=item more_left => STRING

=item more_right => STRING

The text used to indicate that there is more content scrolled to the left or
right, respectively, in the ribbon

=back

=cut

style_definition base =>
        ribbon_fg => 7,
        ribbon_bg => 4,
        active_fg => 14,
        more_fg => "cyan",
        more_left => "<..",
        more_right => "..>",

        '<C-n>'        => "next_tab",
        '<C-p>'        => "prev_tab",
        '<C-PageDown>' => "next_tab",
        '<C-PageUp>'   => "prev_tab";

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 METHODS

=cut

=head2 new

Instantiate a new tabbed window.

Takes the following named parameters:

=over 4

=item * tab_position - (optional) location of the tabs, should be one of left, top, right, bottom.

=back

=cut

has $_tab_class :param = undef;
method TAB_CLASS { $_tab_class || "Tickit::Widget::Tabbed::Tab" }

has $_ribbon_class :param = undef;
method RIBBON_CLASS { $_ribbon_class || "Tickit::Widget::Tabbed::Ribbon" }

has $_ribbon;
method ribbon { $_ribbon }

has @_child_window_geometry;

BUILD ( %args ) {
        $self->tab_position(delete($args{tab_position}) || 'top');
        # sets $_ribbon

        $_ribbon->set_style( $self->get_style_pen("ribbon")->getattrs );
}

# Positions for the four screen edges - these will return appropriate sizes
# for the tab and child subwindows
method _window_position_left () {
        my $label_width = $_ribbon->cols;
        return 0, 0, $self->window->lines, $label_width,
               0, $label_width, $self->window->lines, $self->window->cols - $label_width;
}

method _window_position_right () {
        my $label_width = $_ribbon->cols;
        return 0, $self->window->cols - $label_width, $self->window->lines, $label_width,
               0, 0, $self->window->lines, $self->window->cols - $label_width;
}

method _window_position_top () {
        my $label_height = $_ribbon->lines;
        $label_height = 1 unless $self->window->lines > $label_height;
        return 0, 0, $label_height, $self->window->cols,
               $label_height, 0, max(1, $self->window->lines - $label_height), $self->window->cols;
}

method _window_position_bottom () {
        my $label_height = $_ribbon->lines;
        $label_height = 1 unless $self->window->lines > $label_height;
        return $self->window->lines - $label_height, 0, $label_height, $self->window->cols,
               0, 0, max(1, $self->window->lines - $label_height), $self->window->cols;
}

method on_style_changed_values (%values) {
        if( grep { $_ =~ m/^ribbon_/ } keys %values ) {
                $_ribbon->set_style( $self->get_style_pen("ribbon")->getattrs );
        }
}

method reshape () {
        my $window = $self->window or return;
        my $tab_position = $self->tab_position;
        my @positions = $self->${\"_window_position_$tab_position"}();
        if( my $ribbon_window = $_ribbon->window ) {
                $ribbon_window->change_geometry( @positions[0..3] );
        }
        else {
                my $ribbon_window = $window->make_sub( @positions[0..3] );
                $_ribbon->set_window( $ribbon_window );
        }
        @_child_window_geometry = @positions[4..7];
        foreach my $tab ( $_ribbon->tabs ) {
                my $child = $tab->widget;
                if( my $child_window = $child->window ) {
                        $child_window->change_geometry( @positions[4..7] );
                }
                else {
                        $child_window = $self->_new_child_window( $child == $self->active_tab->widget );
                        $child->set_window($child_window);
                }
        }
}

method _max_child_lines () {
        return max( 1, map { $_->widget->requested_lines } $_ribbon->tabs );
}

method _max_child_cols () {
        return max( 1, map { $_->widget->requested_cols } $_ribbon->tabs );
}

method lines () {
        if( $_ribbon->orientation eq "horizontal" ) {
                return $_ribbon->lines + $self->_max_child_lines;
        }
        else {
                return max( $_ribbon->lines, $self->_max_child_lines );
        }
}

method cols () {
        if( $_ribbon->orientation eq "horizontal" ) {
                return max( $_ribbon->cols, $self->_max_child_cols );
        }
        else {
                return $_ribbon->cols + $self->_max_child_cols;
        }
}

# All the child widgets
method children () {
        return $_ribbon, map { $_->widget } $_ribbon->tabs;
}

# The only focusable child widget is the active one
method children_for_focus () {
        return $self->active_tab_widget;
}

method _new_child_window ( $visible ) {
        my $window = $self->window or return undef;

        my $child_window = $window->make_hidden_sub( @_child_window_geometry );
        $child_window->show if $visible;

        return $child_window;
}

method window_lost ( $win ) {
        $self->SUPER::window_lost( $win );
        $_->widget->set_window(undef) for $_ribbon->tabs;

        undef @_child_window_geometry;

        $_ribbon->set_window(undef);
}

=head2 tab_position

Accessor for the tab position (top, left, right, bottom).

=cut

has $_tab_position;
method tab_position ( $pos = return $_tab_position ) {
        my $orientation = ( $pos eq "top" or $pos eq "bottom" ) ? "horizontal" :
                          ( $pos eq "left" or $pos eq "right" ) ? "vertical" :
                          croak "Unrecognised value for ->tab_position: $pos";

        if( !$_ribbon or $_ribbon->orientation ne $orientation ) {
                my %args = (
                        tabbed => $self,
                        tab_position => $pos,
                );
                if( my $old_ribbon = $_ribbon ) {
                        $old_ribbon->window->close;
                        $old_ribbon->set_window( undef );
                        $args{tabs} = [ $old_ribbon->tabs ];
                        $args{active_tab_index} = $old_ribbon->active_tab_index;
                        $args{pen}  = $old_ribbon->pen;
                        $args{active_pen} = $old_ribbon->active_pen;
                        undef $_ribbon;
                }
                $_ribbon = $self->RIBBON_CLASS->new_for_orientation(
                        $orientation, %args
                );
                $_ribbon->set_style( $args{pen}->getattrs ) if $args{pen};
        }

        $_tab_position = $pos;
        undef @_child_window_geometry;

        $self->reshape if $self->window;
        $self->redraw;

        return $_tab_position;
}

method _tabs_changed () {
        $self->reshape if $self->window;
        $_ribbon->redraw if $_ribbon->window;
}

=head2 active_tab_index

Returns the 0-based index of the currently-active tab.

=cut

method active_tab_index () { $_ribbon->active_tab_index }

=head2 active_tab

Returns the currently-active tab as a tab object. See below.

=cut

method active_tab () { $_ribbon->active_tab }

=head2 active_tab_widget

Returns the widget in the currently active tab.

=cut

# Old name
*tab = \&active_tab_widget;
method active_tab_widget () {
        $self->active_tab && $self->active_tab->widget
}

=head2 add_tab

Add a new tab to this tabbed widget. Returns an object representing the tab;
see L</METHODS ON TAB OBJECTS> below.

First parameter is the widget to use.

Remaining form a hash:

=over 4

=item label - label to show on the new tab

=back

=cut

method add_tab ( $child, %opts ) {
        my $tab = $self->TAB_CLASS->new( $self, widget => $child, %opts );

        $_ribbon->append_tab( $tab );

        return $tab;
}

=head2 remove_tab

Remove tab given by 0-based index or tab object.

=cut

method remove_tab { $_ribbon->remove_tab( @_ ) }

=head2 move_tab

Move tab given by 0-based index or tab object forward the given number of
positions.

=cut

method move_tab { $_ribbon->move_tab( @_ ) }

=head2 activate_tab

Switch to the given tab; by 0-based index, or object.

=cut

method activate_tab { $_ribbon->activate_tab( @_ ) }

=head2 next_tab

Switch to the next tab. This may be bound as a key action.

=cut

*key_next_tab = \&next_tab;
method next_tab (@) { $_ribbon->next_tab }

=head2 prev_tab

Switch to the previous tab. This may be bound as a key action.

=cut

*key_prev_tab = \&prev_tab;
method prev_tab (@) { $_ribbon->prev_tab }

method child_resized () {
        $self->reshape;
}

method on_key ( $ev ) {
        return 1 if $_ribbon->on_key( $ev );

        return 0 unless $ev->type eq "key";

        my $str = $ev->str;
        if($str =~ m/^M-(\d)$/ ) {
                my $index = $1 - 1;
                $self->activate_tab( $index ) if $index < $_ribbon->tabs;
                return 1;
        }
        return 0;
}

method render_to_rb ( $rb, $rect ) {
        # Just clear the child area if we have nothing better to do
        $rb->eraserect( $rect );
}

class # hide from indexer
        Tickit::Widget::Tabbed::Tab :repr(HASH);

use Scalar::Util qw( weaken );
use Tickit::Utils qw( textwidth );

=head1 METHODS ON TAB OBJECTS

The following methods may be called on the objects returned by C<add_tab> or
C<active_tab>.

=cut

sub BUILDARGS ( $class, $tabbed, %args ) {
        return ( tabbed => $tabbed, %args );
}

has $_tabbed :param;

has $_widget :param;
has $_label  :param;
has $_active        = 0;

has $_on_activated;
has $_on_deactivated;

ADJUST
{
        weaken( $_tabbed );
}

=head2 index

Returns the 0-based index of this tab

=cut

method index () {
        return $_tabbed->ribbon->_tab2index( $self );
}

=head2 widget

Returns the C<Tickit::Widget> contained by this tab

=cut

method widget () { $_widget }

=head2 label

Returns the current label text

=cut

has $_label_width;

method label_width () {
        return $_label_width //= textwidth( $_label );
}

method label () { $_label }

=head2 set_label

Set new label text for the tab

=cut

method set_label ( $label ) {
        $_label = $label;
        undef $_label_width;
        $_tabbed->_tabs_changed if $_tabbed;
}

=head2 is_active

Returns true if this tab is the currently active one

=cut

method is_active () {
        return $_tabbed->active_tab == $self;
}

=head2 activate

Activate this tab

=cut

method activate () {
        $_tabbed->activate_tab( $self );
}

method _activate () {
        $self->widget->window->show if $self->widget->window;
        $self->$_on_activated() if $_on_activated;
}

method _deactivate () {
        $self->$_on_deactivated() if $_on_deactivated;
        $self->widget->window->hide if $self->widget->window;
}

=head2 set_on_activated

Set a callback or method name to invoke when the tab is activated

=cut

method set_on_activated ($) { $_on_activated = $_[0]; }

=head2 set_on_deactivated

Set a callback or method name to invoke when the tab is deactivated

=cut

method set_on_deactivated ($) { $_on_deactivated = $_[0]; }

=head2 pen

Returns the C<Tickit::Pen> used to draw the label.

Pen observers are no longer registered on the return value; to set a different
pen on the tab, use the C<set_pen> method instead.

=cut

has $_pen;

method _has_pen () { defined $_pen }

method pen () { $_pen }

method set_pen ($) {
        $_pen = $_[0];
        $_tabbed->_tabs_changed if $_tabbed;
}

method on_mouse ( $type, $button, $line, $col ) {
        return 0 unless $type eq "press" && $button == 1;
        $_tabbed->activate_tab( $self );
        return 1;
}

1;

__END__

=head1 CUSTOM TAB CLASS

Rather than use the default built-in object class for tab objects, a
C<Tickit::Widget::Tabbed> or subclass thereof can return objects in another
class instead. This is most useful for subclasses of the tabbed widget itself.

To perform this, create a subclass of C<Tickit::Widget::Tabbed::Tab>. Since
version 0.022 this module is implemented using L<Object::Pad>, so you can rely
on having that available for implementing a subclass:

   use Object::Pad;

   class MyCustomTabClass extends Tickit::Widget::Tabbed::Tab;

Arrange for this class to be used by the tabbed widget either by passing its
name as a constructor argument called C<tab_class>, or by overriding a method
called C<TAB_CLASS>.

   my $tabbed = Tickit::Widget::Tabbed->new(
           tab_class => "MyCustomTabClass"
   );

or

   use constant TAB_CLASS => "MyCustomTabClass";

=head1 CUSTOM RIBBON CLASS

Rather than use the default built-in object class for the ribbon object, a
C<Tickit::Widget::Tabbed> or subclass thereof can use an object in another
subclass instead. This is most useful for subclasses of the tabbed widget
itself.

For more detail, see the documentation in L<Tickit::Widget::Tabbed::Ribbon>.

=cut

=head1 SEE ALSO

=over 4

=item * L<Tickit::Widget::Table>

=item * L<Tickit::Widget::HBox>

=item * L<Tickit::Widget::VBox>

=item * L<Tickit::Widget::Tree>

=item * L<Tickit::Window>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>, Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011; Paul Evans 2014. Licensed under the same terms as Perl itself.
