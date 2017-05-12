#  You may distribute under the terms of the Artistic License (the same terms
#  as Perl itself)
#
#  (C) Tom Molesworth 2011,
#      Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

package Tickit::Widget::Tabbed;

use strict;
use warnings;
use parent qw(Tickit::ContainerWidget);
BEGIN {
        Tickit::Widget->VERSION("0.12");
        Tickit::Window->VERSION("0.23");
}
use Tickit::Style;
use constant KEYPRESSES_FROM_STYLE => 1;

use Carp;
use Tickit::Pen;
use List::Util qw(max);

use Tickit::Widget::Tabbed::Ribbon;

our $VERSION = '0.021';

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

sub TAB_CLASS { shift->{tab_class} || "Tickit::Widget::Tabbed::Tab" }
sub RIBBON_CLASS { shift->{ribbon_class} || "Tickit::Widget::Tabbed::Ribbon" }

=head2 new

Instantiate a new tabbed window.

Takes the following named parameters:

=over 4

=item * tab_position - (optional) location of the tabs, should be one of left, top, right, bottom.

=back

=cut

sub new {
        my $class = shift;
        my %args = @_;
        my $self = $class->SUPER::new(%args);

        $self->{tab_class}  = delete($args{tab_class});
        $self->{ribbon_class} = delete($args{ribbon_class});

        $self->tab_position(delete($args{tab_position}) || 'top');

        my $ribbon = $self->{ribbon};

        $ribbon->set_style( $self->get_style_pen("ribbon")->getattrs );

        return $self;
}

# Positions for the four screen edges - these will return appropriate sizes
# for the tab and child subwindows
sub _window_position_left {
        my $self = shift;
        my $ribbon = $self->{ribbon};
        my $label_width = $ribbon->cols;
        return 0, 0, $self->window->lines, $label_width,
               0, $label_width, $self->window->lines, $self->window->cols - $label_width;
}

sub _window_position_right {
        my $self = shift;
        my $ribbon = $self->{ribbon};
        my $label_width = $ribbon->cols;
        return 0, $self->window->cols - $label_width, $self->window->lines, $label_width,
               0, 0, $self->window->lines, $self->window->cols - $label_width;
}

sub _window_position_top {
        my $self = shift;
        my $ribbon = $self->{ribbon};
        my $label_height = $ribbon->lines;
        $label_height = 1 unless $self->window->lines > $label_height;
        return 0, 0, $label_height, $self->window->cols,
               $label_height, 0, max(1, $self->window->lines - $label_height), $self->window->cols;
}

sub _window_position_bottom {
        my $self = shift;
        my $ribbon = $self->{ribbon};
        my $label_height = $ribbon->lines;
        $label_height = 1 unless $self->window->lines > $label_height;
        return $self->window->lines - $label_height, 0, $label_height, $self->window->cols,
               0, 0, max(1, $self->window->lines - $label_height), $self->window->cols;
}

sub on_style_changed_values {
        my $self = shift;
        my %values = @_;

        if( grep { $_ =~ m/^ribbon_/ } keys %values ) {
                $self->{ribbon}->set_style( $self->get_style_pen("ribbon")->getattrs );
        }
}

sub reshape {
        my $self = shift;
        my $window = $self->window or return;
        my $tab_position = $self->tab_position;
        my @positions = $self->${\"_window_position_$tab_position"}();
        if( my $ribbon_window = $self->{ribbon}->window ) {
                $ribbon_window->change_geometry( @positions[0..3] );
        }
        else {
                my $ribbon_window = $window->make_sub( @positions[0..3] );
                $self->{ribbon}->set_window( $ribbon_window );
        }
        $self->{child_window_geometry} = [ @positions[4..7] ];
        foreach my $tab ( $self->{ribbon}->tabs ) {
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

sub _max_child_lines
{
        my $self = shift;
        my $ribbon = $self->{ribbon};
        return max( 1, map { $_->widget->requested_lines } $ribbon->tabs );
}

sub _max_child_cols
{
        my $self = shift;
        my $ribbon = $self->{ribbon};
        return max( 1, map { $_->widget->requested_cols } $ribbon->tabs );
}

sub lines
{
        my $self = shift;
        my $ribbon = $self->{ribbon};

        if( $ribbon->orientation eq "horizontal" ) {
                return $ribbon->lines + $self->_max_child_lines;
        }
        else {
                return max( $ribbon->lines, $self->_max_child_lines );
        }
}

sub cols
{
        my $self = shift;
        my $ribbon = $self->{ribbon};

        if( $ribbon->orientation eq "horizontal" ) {
                return max( $ribbon->cols, $self->_max_child_cols );
        }
        else {
                return $ribbon->cols + $self->_max_child_cols;
        }
}

# All the child widgets
sub children {
        my $self = shift;
        my $ribbon = $self->{ribbon};
        return $ribbon, map { $_->widget } $ribbon->tabs;
}

# The only focusable child widget is the active one
sub children_for_focus {
        my $self = shift;
        return $self->active_tab_widget;
}

sub _new_child_window
{
        my $self = shift;
        my ( $visible ) = @_;

        my $window = $self->window or return undef;

        my $child_window = $window->make_hidden_sub( @{ $self->{child_window_geometry} } );
        $child_window->show if $visible;

        return $child_window;
}

sub window_lost {
        my $self = shift;
        $self->SUPER::window_lost(@_);
        $_->widget->set_window(undef) for $self->{ribbon}->tabs;

        undef $self->{child_window_geometry};

        $self->{ribbon}->set_window(undef);
}

=head2 tab_position

Accessor for the tab position (top, left, right, bottom).

=cut

sub tab_position {
        my $self = shift;
        if(@_) {
                my $pos = shift;
                my $orientation = ( $pos eq "top" or $pos eq "bottom" ) ? "horizontal" :
                                  ( $pos eq "left" or $pos eq "right" ) ? "vertical" :
                                  croak "Unrecognised value for ->tab_position: $pos";

                if( !$self->{ribbon} or $self->{ribbon}->orientation ne $orientation ) {
                        my %args = (
                                tabbed => $self,
                                tab_position => $pos,
                        );
                        if( my $old_ribbon = $self->{ribbon} ) {
                                $old_ribbon->window->close;
                                $old_ribbon->set_window( undef );
                                $args{tabs} = [ $old_ribbon->tabs ];
                                $args{active_tab_index} = $old_ribbon->active_tab_index;
                                $args{pen}  = $old_ribbon->pen;
                                $args{active_pen} = $old_ribbon->active_pen;
                                undef $self->{ribbon};
                        }
                        $self->{ribbon} = $self->RIBBON_CLASS->new_for_orientation(
                                $orientation, %args
                        );
                        $self->{ribbon}->set_style( $args{pen}->getattrs ) if $args{pen};
                }

                $self->{tab_position} = $pos;
                undef $self->{child_window_geometry};

                $self->reshape if $self->window;
                $self->redraw;
        }
        return $self->{tab_position};
}

sub _tabs_changed {
        my $self = shift;
        $self->reshape if $self->window;
        $self->{ribbon}->redraw if $self->{ribbon}->window;
}

=head2 active_tab_index

Returns the 0-based index of the currently-active tab.

=cut

sub active_tab_index { shift->{ribbon}->active_tab_index }

=head2 active_tab

Returns the currently-active tab as a tab object. See below.

=cut

sub active_tab { shift->{ribbon}->active_tab }

=head2 active_tab_widget

Returns the widget in the currently active tab.

=cut

# Old name
*tab = \&active_tab_widget;
sub active_tab_widget {
        my $self = shift; $self->active_tab && $self->active_tab->widget
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

sub add_tab {
        my $self = shift;
        my ($child, %opts) = @_;

        my $ribbon = $self->{ribbon};

        my $tab = $self->TAB_CLASS->new( $self, widget => $child, %opts );

        $ribbon->append_tab( $tab );

        return $tab;
}

=head2 remove_tab

Remove tab given by 0-based index or tab object.

=cut

sub remove_tab { shift->{ribbon}->remove_tab( @_ ) }

=head2 move_tab

Move tab given by 0-based index or tab object forward the given number of
positions.

=cut

sub move_tab { shift->{ribbon}->move_tab( @_ ) }

=head2 activate_tab

Switch to the given tab; by 0-based index, or object.

=cut

sub activate_tab { shift->{ribbon}->activate_tab( @_ ) }

=head2 next_tab

Switch to the next tab. This may be bound as a key action.

=cut

*key_next_tab = \&next_tab;
sub next_tab { shift->{ribbon}->next_tab }

=head2 prev_tab

Switch to the previous tab. This may be bound as a key action.

=cut

*key_prev_tab = \&prev_tab;
sub prev_tab { shift->{ribbon}->prev_tab }

sub child_resized {
        my $self = shift;
        $self->reshape;
}

sub on_key {
        my $self = shift;
        my ($ev) = @_;

        return 1 if $self->{ribbon}->on_key(@_);

        return 0 unless $ev->type eq "key";

        my $str = $ev->str;
        if($str =~ m/^M-(\d)$/ ) {
                my $index = $1 - 1;
                $self->activate_tab( $index ) if $index < $self->{ribbon}->tabs;
                return 1;
        }
        return 0;
}

sub render_to_rb {
        my $self = shift;
        my ( $rb, $rect ) = @_;

        # Just clear the child area if we have nothing better to do
        $rb->eraserect( $rect );
}

package Tickit::Widget::Tabbed::Tab;

use 5.010; # for //= operator
use Scalar::Util qw( weaken );
use Tickit::Utils qw( textwidth );

=head1 METHODS ON TAB OBJECTS

The following methods may be called on the objects returned by C<add_tab> or
C<active_tab>.

=cut

sub new {
        my $class = shift;
        my ( $tabbed, %args ) = @_;
        my $self = bless {
                tabbed => $tabbed,
                widget => $args{widget},
                label  => $args{label},
                active => 0,
        }, $class;
        weaken( $self->{tabbed} );
        return $self;
}

=head2 index

Returns the 0-based index of this tab

=cut

sub index {
        my $self = shift;
        return $self->{tabbed}->{ribbon}->_tab2index( $self );
}

=head2 widget

Returns the C<Tickit::Widget> contained by this tab

=cut

sub widget { shift->{widget} }

=head2 label

Returns the current label text

=cut

sub label_width {
        my $self = shift;
        return $self->{label_width} //= textwidth( $self->{label} );
}

sub label { shift->{label} }

=head2 set_label

Set new label text for the tab

=cut

sub set_label {
        my $self = shift;
        ( $self->{label} ) = @_;
        undef $self->{label_width};
        $self->{tabbed}->_tabs_changed if $self->{tabbed};
}

=head2 is_active

Returns true if this tab is the currently active one

=cut

sub is_active {
        my $self = shift;
        return $self->{tabbed}->active_tab == $self;
}

=head2 activate

Activate this tab

=cut

sub activate {
        my $self = shift;
        $self->{tabbed}->activate_tab( $self );
}

sub _activate {
        my $self = shift;
        $self->widget->window->show if $self->widget->window;
        $self->${\$self->{on_activated}}() if $self->{on_activated};
}

sub _deactivate {
        my $self = shift;
        $self->${\$self->{on_deactivated}}() if $self->{on_deactivated};
        $self->widget->window->hide if $self->widget->window;
}

=head2 set_on_activated

Set a callback or method name to invoke when the tab is activated

=cut

sub set_on_activated
{
        my $self = shift;
        ( $self->{on_activated} ) = @_;
}

=head2 set_on_deactivated

Set a callback or method name to invoke when the tab is deactivated

=cut

sub set_on_deactivated
{
        my $self = shift;
        ( $self->{on_deactivated} ) = @_;
}

=head2 pen

Returns the C<Tickit::Pen> used to draw the label.

Pen observers are no longer registered on the return value; to set a different
pen on the tab, use the C<set_pen> method instead.

=cut

sub _has_pen { defined shift->{pen} }

sub pen {
        my $self = shift;
        return $self->{pen};
}

sub set_pen {
        my $self = shift;
        ( $self->{pen} ) = @_;
        $self->{tabbed}->_tabs_changed if $self->{tabbed};
}

sub on_mouse {
        my $self = shift;
        my ( $type, $button, $line, $col ) = @_;

        return 0 unless $type eq "press" && $button == 1;
        $self->{tabbed}->activate_tab( $self );
        return 1;
}

1;

__END__

=head1 CUSTOM TAB CLASS

Rather than use the default built-in object class for tab objects, a
C<Tickit::Widget::Tabbed> or subclass thereof can return objects in another
class instead. This is most useful for subclasses of the tabbed widget itself.

To perform this, create a subclass of C<Tickit::Widget::Tabbed::Tab> with a
constructor having the following behaviour:

 sub new
 {
         my $class = shift;
         my ( $tabbed, %args ) = @_;

         ...

         my $self = $class->SUPER::new( $tabbed, %args );

         ...

         return $self;
 }

Arrange for this class to be used by the tabbed widget either by passing its
name as a constructor argument called C<tab_class>, or by overriding a method
called C<TAB_CLASS>.

 my $tabbed = Tickit::Widget::Tabbed->new(
         tab_class => "Tab::Class::Name"
 );

or

 use constant TAB_CLASS => "Tab::Class::Name";

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
