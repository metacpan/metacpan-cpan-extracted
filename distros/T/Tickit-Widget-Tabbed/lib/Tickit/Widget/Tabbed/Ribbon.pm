#  You may distribute under the terms of the Artistic License (the same terms
#  as Perl itself)
#
#  (C) Paul Evans, 2011-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.43;  # ADJUST

package Tickit::Widget::Tabbed::Ribbon 0.024;
class Tickit::Widget::Tabbed::Ribbon
        extends Tickit::Widget;

Tickit::Window->VERSION( '0.57' );  # ->bind_event

use Scalar::Util qw( weaken );
use Tickit::Utils qw( textwidth );

use Carp;

# It isn't really; we only use the direct style setting directly from the
# containing Tickit::Widget::Tabbed
use constant WIDGET_PEN_FROM_STYLE => 1;

use Struct::Dumb;
struct MoreMarker => [qw( text width window )];

=head1 NAME

C<Tickit::Widget::Tabbed::Ribbon> - base class for C<Tickit::Widget::Tabbed>
control ribbon

=head1 DESCRIPTION

This class contains the default implementation for the control ribbon used by
L<Tickit::Widget::Tabbed>, and also acts as a base class to assist in the
creation of a custom ribbon. Details of this class and its operation are
useful to know when implenting a custom control ribbon.

It is not necessary to consider this class if simply using the
C<Tickit::Widget::Tabbed> with its default control ribbon.

=head1 CUSTOM RIBBON CLASS

To perform create a custom ribbon class, create a subclass of
C<Tickit::Widget::Tabbed::Ribbon> with a constructor having the following
behaviour:

 package Custom::Ribbon::Class;
 use base qw( Tickit::Widget::Tabbed::Ribbon );

 sub new_for_orientation
 {
         my $class = shift;
         my ( $orientation, %args ) = @_;

         ...

         return $self;
 }

Alternatively if this is not done, then one of two subclasses will be used for
the constructor, by appending C<::horizontal> or C<::vertical> to the class
name. In this case, the custom class should provide these as well.

 package Custom::Ribbon::Class;
 use base qw( Tickit::Widget::Tabbed::Ribbon );

 package Custom::Ribbon::Class::horizontal;
 use base qw( Custom::Ribbon::Class );

 ...

 package Custom::Ribbon::Class::vertical;
 use base qw( Custom::Ribbon::Class );

 ...

Arrange for this class to be used by the tabbed widget either by passing its
name as a constructor argument called C<ribbon_class>, or by overriding a
method called C<RIBBON_CLASS>.

 my $tabbed = Tickit::Widget::Tabbed->new(
         ribbon_class => "Ribbon::Class::Name"
 );

or

 use constant RIBBON_CLASS => "Ribbon::Class::Name";

=cut

=head1 METHODS

=cut

sub new_for_orientation ( $class, $orientation, @args ) {
        return ${\"${class}::${orientation}"}->new( @args );
}

{
        my $orig = __PACKAGE__->can( "new" );
        no warnings 'redefine';
        *new = sub ( $class, %args ) {
                foreach my $method (qw( scroll_to_visible on_key on_mouse )) {
                        $class->can( $method ) or
                                croak "$class cannot ->$method - do you subclass and implement it?";
                }

                return $class->$orig( %args );
        };
}

has $_tabbed :param;
method tabbed { $_tabbed }

has $_prev_more; method prev_more { $_prev_more }
has $_next_more; method next_more { $_next_more }

has $_active_tab_index :param = 0;

has @_tabs;

BUILD ( %args ) {
        push @_tabs, @{$args{tabs}} if $args{tabs};
}

ADJUST
{
        weaken( $_tabbed );

        my ( $prev_more, $next_more ) = $_tabbed->get_style_values(qw( more_left more_right ));
        $_prev_more = MoreMarker( $prev_more, textwidth( $prev_more ), undef );
        $_next_more = MoreMarker( $next_more, textwidth( $next_more ), undef );

        $self->scroll_to_visible( $_active_tab_index );
}

method active_pen () {
        return $_tabbed->get_style_pen( "active" );
}

=head2 tabs

 @tabs = $ribbon->tabs

 $count = $ribbon->tabs

Returns a list of the contained L<Tickit::Widget::Tabbed> tab objects in list
context, or the count of them in scalar context.

=cut

method tabs () { @_tabs }

method _tab2index ( $tab_or_index ) {
        if( !ref $tab_or_index ) {
                croak "Invalid tab index" if $tab_or_index < 0 or $tab_or_index >= @_tabs;
                return $tab_or_index;
        }
        return ( grep { $tab_or_index == $_tabs[$_] } 0 .. $#_tabs )[0];
}

method _pen_for_tab ( $tab ) {
        if( $tab->_has_pen and $tab->is_active ) {
                return Tickit::Pen->new($tab->pen->getattrs, $self->active_pen->getattrs);
        }
        elsif( $tab->_has_pen ) {
                return $tab->pen;
        }
        elsif( $tab->is_active ) {
                return $self->active_pen;
        }
        else {
                return (); # empty in list context
        }
}

=head2 active_tab_index

 $index = $ribbon->active_tab_index

Returns the index of the currently-active tab

=cut

method active_tab_index { $_active_tab_index }

=head2 active_tab

 $tab = $ribbon->active_tab

Returns the currently-active tab as a C<Tickit::Widget::Tabbed> tab object.

=cut

method active_tab {
        return $_tabs[$_active_tab_index];
}

method append_tab ( $tab ) {
        push @_tabs, $tab;

        $_tabbed->_tabs_changed;
        $self->scroll_to_visible( undef );
}

method remove_tab {
        my $del_index = $self->_tab2index( shift );

        my ( $tab ) = splice @_tabs, $del_index, 1, ();
        $tab->widget->window->close;

        if( $_active_tab_index > $del_index ) {
                $_active_tab_index--;
        }
        elsif( $_active_tab_index == $del_index ) {
                $_active_tab_index-- if $del_index == @_tabs;
                if( $self->active_tab ) {
                        $self->active_tab->_activate;
                }
                else {
                        $_tabbed->window->expose;
                }
        }

        $_tabbed->_tabs_changed;
        $self->scroll_to_visible( undef );
}

method move_tab {
        my $old_index = $self->_tab2index( shift );
        my $delta = shift;

        if( $delta < 0 ) {
                $delta = -$old_index if $delta < -$old_index;
        }
        elsif( $delta > 0 ) {
                my $spare = $#_tabs - $old_index;
                $delta = $spare if $delta > $spare;
        }
        else {
                # delta == 0
                return;
        }

        splice @_tabs, $old_index + $delta, 0, ( splice @_tabs, $old_index, 1, () );

        # Adjust the active_tab_index to cope with tab move
        $_active_tab_index += $delta if $_active_tab_index == $old_index;
        $_active_tab_index++ if $_active_tab_index < $old_index and $_active_tab_index >= $old_index + $delta;
        $_active_tab_index-- if $_active_tab_index > $old_index and $_active_tab_index <= $old_index + $delta;

        $self->redraw;
}

method activate_tab {
        my $new_index = $self->_tab2index( shift );

        return if $new_index == $_active_tab_index;

        if(my $old_widget = $self->active_tab->widget) {
                $self->active_tab->_deactivate;
        }

        $_active_tab_index = $new_index;

        $self->scroll_to_visible( $_active_tab_index );

        $self->redraw;

        if(my $tab = $self->active_tab) {
                $tab->_activate;
        }
        else {
                $self->window->clear;
        }

        return $self;
}

method next_tab {
        $self->activate_tab( ( $self->active_tab_index + 1 ) % $self->tabs );
}

method prev_tab {
        $self->activate_tab( ( $self->active_tab_index - 1 ) % $self->tabs );
}

method on_pen_changed ( $pen, $id ) {
        $self->redraw;
        return $self->SUPER::on_pen_changed( $pen, $id );
}

method on_key { 0 }

method on_mouse { 0 }

class # hide from indexer
    Tickit::Widget::Tabbed::Ribbon::horizontal
        extends Tickit::Widget::Tabbed::Ribbon;
use constant orientation => "horizontal";

use List::Util qw( sum0 );

has $_active_marker :param = undef;
has $_scroll_offset        = 0;

ADJUST
{
        $_active_marker //= [ "[", "]" ];
}

method lines { 1 }
method cols {
        return sum0(map { $_->label_width + 1 } $self->tabs) + 1;
}

method reshape {
        my $win = $self->window or return;

        $self->scroll_to_visible( undef );

        my $prev_more = $self->prev_more;
        if( $prev_more->window ) {
                $prev_more->window->change_geometry(
                        0, 0, 1, $prev_more->width,
                );
        }

        my $next_more = $self->next_more;
        if( $next_more->window ) {
                $next_more->window->change_geometry(
                        0, $win->cols - $next_more->width, 1, $next_more->width,
                );
        }
}

method render_to_rb ( $rb, $rect ) {
        $rect->top == 0 or return;
        $rect->bottom == 1 or return;

        $rb->goto(0, -$_scroll_offset);

        my $prev_active;
        foreach my $tab ($self->tabs) {
                my $active = $tab->is_active;

                $rb->text($active      ? $_active_marker->[0] :
                          $prev_active ? $_active_marker->[1] :
                                         ' ');
                $rb->text($tab->label, $self->_pen_for_tab($tab));

                $prev_active = $active;
        }

        if($prev_active) {
                $rb->text($_active_marker->[1]);
        }

        $rb->erase_to($self->window->cols);
}

method _col2tab ( $col ) {
        $col += $_scroll_offset;
        $col--;
        return if $col < 0;

        foreach my $tab ( $self->tabs ) {
                if( $col < $tab->label_width ) {
                        return $tab, $col if wantarray;
                        return $tab;
                }
                $col -= $tab->label_width;
                return if $col == 0;
                $col--;
        }
        return;
}

method scroll_to_visible ( $target_idx ) {
        my $win = $self->window or return;
        my $cols = $win->cols;

        my $prev_more = $self->prev_more or return;
        my $next_more = $self->next_more or return;

        my @tabs = $self->tabs;
        my $halfwidth = int( $cols / 2 );

        my $ofs = $_scroll_offset;
        my $want_prev_more = defined $prev_more->window;
        my $want_next_more = defined $next_more->window;

        {
                my $col = -$ofs;
                $col++; # initial space

                my $start_of_idx;
                my $end_of_idx;

                my $i = 0;
                if( defined $target_idx ) {
                        for( ; $i < $target_idx; $i++ ) {
                                $col += $tabs[$i]->label_width + 1;
                        }

                        $start_of_idx = $col;
                        $col += $tabs[$i++]->label_width;
                        $end_of_idx = $col;
                        $col++;
                }

                for( ; $i < @tabs; $i++ ) {
                        $col += $tabs[$i]->label_width + 1;
                }
                $col--;

                $want_prev_more = ( $ofs > 0 );
                $want_next_more = ( $col > $cols );

                my $left_margin  = $want_prev_more ? $prev_more->width
                                                   : 0;
                my $right_margin = $want_next_more ? $cols - $next_more->width
                                                   : $cols;

                if( defined $start_of_idx and $start_of_idx < $left_margin ) {
                        $ofs -= $halfwidth;
                        $ofs = 0 if $ofs < 0;
                        redo;
                }

                if( defined $end_of_idx and $end_of_idx >= $right_margin ) {
                        $ofs += $halfwidth;
                        redo;
                }
        }

        $_scroll_offset = $ofs;

        if( $want_prev_more and !$prev_more->window ) {
                my $w = $win->make_float(
                        0, 0, 1, $prev_more->width,
                );
                $prev_more->window = $w;
                $w->set_pen( $self->tabbed->get_style_pen( "more" ) );
                $w->bind_event( expose => sub ( $win, $, $info, $ ) {
                        $info->rb->text_at( 0, 0, $prev_more->text );
                });
                $w->bind_event( mouse => sub ( $win, $, $info, $ ) {
                        $self->_scroll_left if $info->type eq "press" && $info->button == 1;
                        return 1;
                } );
        }
        elsif( !$want_prev_more and $prev_more->window ) {
                $prev_more->window->hide;
                undef $prev_more->window;
        }

        if( $want_next_more and !$next_more->window ) {
                my $w = $win->make_float(
                        0, $win->cols - $next_more->width, 1, $next_more->width,
                );
                $next_more->window = $w;
                $w->set_pen( $self->tabbed->get_style_pen( "more" ) );
                $w->bind_event( expose => sub ( $win, $, $info, $ ) {
                        $info->rb->text_at( 0, 0, $next_more->text );
                } );
                $w->bind_event( mouse => sub ( $win, $, $info, $ ) {
                        $self->_scroll_right if $info->type eq "press" && $info->button == 1;
                        return 1;
                } );
        }
        elsif( !$want_next_more and $next_more->window ) {
                $next_more->window->hide;
                undef $next_more->window;
        }
}

method _scroll_left {
        my $win = $self->window or return;

        $_scroll_offset -= int( $win->cols / 2 );
        $_scroll_offset = 0 if $_scroll_offset < 0;
        $self->scroll_to_visible( undef );
        $self->redraw;
}

method _scroll_right {
        my $win = $self->window or return;

        $_scroll_offset += int( $win->cols / 2 );
        $self->scroll_to_visible( undef );
        $self->redraw;
}

method on_key ( $ev ) {
        return unless $ev->type eq "key";

        my $str = $ev->str;
        if($str eq 'Right') {
                $self->next_tab;
                return 1;
        }
        elsif($str eq 'Left') {
                $self->prev_tab;
                return 1;
        }
}

method on_mouse ( $ev ) {
        return 0 unless $ev->line == 0;
        return 0 unless my ( $tab, $tab_col ) = $self->_col2tab( $ev->col );

        return $tab->on_mouse( $ev->type, $ev->button, 0, $tab_col );
}

class # hide from indexer
    Tickit::Widget::Tabbed::Ribbon::vertical
        extends Tickit::Widget::Tabbed::Ribbon;
use constant orientation => "vertical";

use List::Util qw( max );

has $_tab_position  :param;
has $_scroll_offset        = 0;

method lines {
        return scalar $self->tabs;
}
method cols {
        return 2 + max(0, map { $_->label_width } $self->tabs);
}

method reshape {
        my $win = $self->window or return;

        $self->scroll_to_visible( undef );

        my $prev_more = $self->prev_more;
        if( $prev_more->window ) {
                $prev_more->window->change_geometry(
                        0, 0, 1, $win->cols,
                );
        }

        my $next_more = $self->next_more;
        if( $next_more->window ) {
                $next_more->window->change_geometry(
                        $win->lines - 1, $win->cols, 1, $win->cols,
                );
        }
}

method render_to_rb ( $rb, $rect ) {
        my $lines = $self->window->lines;
        my $cols  = $self->window->cols;

        my $next_line = -$_scroll_offset;
        foreach my $tab ($self->tabs) {
                my $active = $tab->is_active;

                my $this_line = $next_line;
                $next_line++;

                next if $this_line < $rect->top;
                return if $this_line >= $rect->bottom;
                $rb->goto($this_line, 0);

                my $spare = $cols - $tab->label_width;
                if($_tab_position eq 'left') {
                        $rb->text($tab->label, $self->_pen_for_tab($tab));
                        $rb->text($active ? (' ' . ('>' x ($spare - 1))) : (' ' x $spare));
                } elsif($_tab_position eq 'right') {
                        $rb->text($active ? (('<' x ($spare - 1)) . ' ') : (' ' x $spare));
                        $rb->text($tab->label, $self->_pen_for_tab($tab));
                }
        }

        while($next_line < $lines) {
                $rb->goto($next_line, 0);
                $rb->erase_to($cols);
                ++$next_line;
        }
}

method scroll_to_visible ( $idx ) {
        defined $idx or return;

        my $win = $self->window or return;
        my $lines = $win->lines;

        my $halfheight = int( $lines / 2 );

        my $ofs = $_scroll_offset;

        {
                my $line = -$ofs;
                $line += $idx;

                if( $line < 0 ) {
                        $ofs -= $halfheight;
                        $ofs = 0 if $ofs < 0;
                        redo;
                }

                if( $line >= $lines ) {
                        $ofs += $halfheight;
                        redo;
                }
        }

        $_scroll_offset = $ofs;
}

method _showhide_more_markers {
}

method on_key ( $ev ) {
        return unless $ev->type eq "key";

        my $str = $ev->str;
        if($str eq 'Down') {
                $self->next_tab;
                return 1;
        }
        elsif($str eq 'Up') {
                $self->prev_tab;
                return 1;
        }
}

method on_mouse ( $ev ) {
        my $line = $ev->line;
        $line += $_scroll_offset;

        my @tabs = $self->tabs;
        return 0 unless $line < @tabs;

        return $tabs[$line]->on_mouse( $ev->type, $ev->button, 0, $ev->col );
}

1;

=head1 SUBCLASS METHODS

The subclass will need to provide implementations of the following methods.

=cut

=head2 render

 $ribbon->render( %args )

=head2 lines

 $lines = $ribbon->lines

=head2 cols

 $cols = $ribbon->cols

As per the L<Tickit::Widget> methods.

=head2 on_key

 $handled = $ribbon->on_key( $ev )

=head2 on_mouse

 $handled = $ribbon->on_mouse( $ev )

As per the L<Tickit::Widget> methods. Optional. If not supplied then the
ribbon will not respond to keyboard or mouse events.

=head2 scroll_to_visible

 $ribbon->scroll_to_visible( $index )

Requests that a scrollable control ribbon scrolls itself so that the given
C<$index> tab is visible.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut
