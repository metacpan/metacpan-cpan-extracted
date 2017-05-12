#  You may distribute under the terms of the Artistic License (the same terms
#  as Perl itself)
#
#  (C) Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

package Tickit::Widget::Tabbed::Ribbon;

use strict;
use warnings;

use base qw( Tickit::Widget );
Tickit::Window->VERSION( '0.57' );  # ->bind_event

our $VERSION = '0.021';

use Scalar::Util qw( weaken );
use Tickit::Utils qw( textwidth );

use Carp;

# It isn't really; we only use the direct style setting directly from the
# containing Tickit::Widget::Tabbed
use constant WIDGET_PEN_FROM_STYLE => 1;

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

sub new_for_orientation {
        my $class = shift;
        my ( $orientation, @args ) = @_;

        return ${\"${class}::${orientation}"}->new( @args );
}

sub new {
        my $class = shift;
        my %args = @_;

        foreach my $method (qw( scroll_to_visible on_key on_mouse )) {
                $class->can( $method ) or
                        croak "$class cannot ->$method - do you subclass and implement it?";
        }

        my $self = $class->SUPER::new( %args );

        my ( $prev_more, $next_more ) = $args{tabbed}->get_style_values(qw( more_left more_right ));
        $self->{prev_more} = [ $prev_more, textwidth $prev_more ];
        $self->{next_more} = [ $next_more, textwidth $next_more ];

        $self->{tabs} = [];
        push @{$self->{tabs}}, @{$args{tabs}} if $args{tabs};

        $self->{scroll_offset} = 0;
        $self->{active_tab_index} = $args{active_tab_index} || 0;

        weaken( $self->{tabbed} = $args{tabbed} );

        $self->scroll_to_visible( $self->{active_tab_index} );

        return $self;
}

sub active_pen {
        my $self = shift;
        return $self->{tabbed}->get_style_pen( "active" );
}

=head2 @tabs = $ribbon->tabs

=head2 $count = $ribbon->tabs

Returns a list of the contained L<Tickit::Widget::Tabbed> tab objects in list
context, or the count of them in scalar context.

=cut

sub tabs {
        my $self = shift;
        return @{$self->{tabs}};
}

sub _tab2index {
        my $self = shift;
        my ( $tab_or_index ) = @_;
        if( !ref $tab_or_index ) {
                croak "Invalid tab index" if $tab_or_index < 0 or $tab_or_index >= @{ $self->{tabs} };
                return $tab_or_index;
        }
        return ( grep { $tab_or_index == $self->{tabs}[$_] } 0 .. $#{ $self->{tabs} } )[0];
}

sub _pen_for_tab {
        my $self = shift;
        my ( $tab ) = @_;

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

=head2 $index = $ribbon->active_tab_index

Returns the index of the currently-active tab

=cut

sub active_tab_index {
        my $self = shift;
        return $self->{active_tab_index};
}

=head2 $tab = $ribbon->active_tab

Returns the currently-active tab as a C<Tickit::Widget::Tabbed> tab object.

=cut

sub active_tab {
        my $self = shift;
        return $self->{tabs}->[$self->{active_tab_index}];
}

sub append_tab {
        my $self = shift;
        my ( $tab ) = @_;

        push @{$self->{tabs}}, $tab;

        $self->{tabbed}->_tabs_changed;
        $self->scroll_to_visible( undef );
}

sub remove_tab {
        my $self = shift;
        my $del_index = $self->_tab2index( shift );

        my $tabs = $self->{tabs};

        my ( $tab ) = splice @$tabs, $del_index, 1, ();
        $tab->widget->window->close;

        if( $self->{active_tab_index} > $del_index ) {
                $self->{active_tab_index}--;
        }
        elsif( $self->{active_tab_index} == $del_index ) {
                $self->{active_tab_index}-- if $del_index == @$tabs;
                if( $self->active_tab ) {
                        $self->active_tab->_activate;
                }
                else {
                        $self->{tabbed}->window->expose;
                }
        }

        $self->{tabbed}->_tabs_changed;
        $self->scroll_to_visible( undef );
}

sub move_tab {
        my $self = shift;
        my $old_index = $self->_tab2index( shift );
        my $delta = shift;

        my $tabs = $self->{tabs};

        if( $delta < 0 ) {
                $delta = -$old_index if $delta < -$old_index;
        }
        elsif( $delta > 0 ) {
                my $spare = $#$tabs - $old_index;
                $delta = $spare if $delta > $spare;
        }
        else {
                # delta == 0
                return;
        }

        splice @$tabs, $old_index + $delta, 0, ( splice @$tabs, $old_index, 1, () );

        # Adjust the active_tab_index to cope with tab move
        $self->{active_tab_index} += $delta if $self->{active_tab_index} == $old_index;
        $self->{active_tab_index}++ if $self->{active_tab_index} < $old_index and $self->{active_tab_index} >= $old_index + $delta;
        $self->{active_tab_index}-- if $self->{active_tab_index} > $old_index and $self->{active_tab_index} <= $old_index + $delta;

        $self->redraw;
}

sub activate_tab {
        my $self = shift;
        my $new_index = $self->_tab2index( shift );

        return if $new_index == $self->{active_tab_index};

        if(my $old_widget = $self->active_tab->widget) {
                $self->active_tab->_deactivate;
        }

        $self->{active_tab_index} = $new_index;

        $self->scroll_to_visible( $self->{active_tab_index} );

        $self->redraw;

        if(my $tab = $self->active_tab) {
                $tab->_activate;
        }
        else {
                $self->window->clear;
        }

        return $self;
}

sub next_tab {
        my $self = shift;
        $self->activate_tab( ( $self->active_tab_index + 1 ) % $self->tabs );
}

sub prev_tab {
        my $self = shift;
        $self->activate_tab( ( $self->active_tab_index - 1 ) % $self->tabs );
}

sub on_pen_changed {
        my $self = shift;
        my ( $pen, $id ) = @_;
        $self->redraw;
        return $self->SUPER::on_pen_changed( @_ );
}

sub on_key { 0 }

sub on_mouse { 0 }

package Tickit::Widget::Tabbed::Ribbon::horizontal;
use base qw( Tickit::Widget::Tabbed::Ribbon );
use constant orientation => "horizontal";

use List::Util qw( sum0 );

sub new {
        my $class = shift;
        my %args = @_;
        my $self = $class->SUPER::new( %args );
        $self->{active_marker} = $args{active_marker} || [ "[", "]" ];
        return $self;
}

sub lines { 1 }
sub cols {
        my $self = shift;
        return sum0(map { $_->label_width + 1 } $self->tabs) + 1;
}

sub reshape {
        my $self = shift;

        my $win = $self->window or return;

        $self->scroll_to_visible( undef );

        my $prev_more = $self->{prev_more};
        if( $prev_more->[2] ) {
                $prev_more->[2]->change_geometry(
                        0, 0, 1, $prev_more->[1],
                );
        }

        my $next_more = $self->{next_more};
        if( $next_more->[2] ) {
                $next_more->[2]->change_geometry(
                        0, $win->cols - $next_more->[1], 1, $next_more->[1],
                );
        }
}

sub render_to_rb {
        my $self = shift;
        my ( $rb, $rect ) = @_;

        $rect->top == 0 or return;
        $rect->bottom == 1 or return;

        $rb->goto(0, -$self->{scroll_offset});

        my $prev_active;
        foreach my $tab ($self->tabs) {
                my $active = $tab->is_active;

                $rb->text($active      ? $self->{active_marker}[0] :
                          $prev_active ? $self->{active_marker}[1] :
                                         ' ');
                $rb->text($tab->label, $self->_pen_for_tab($tab));

                $prev_active = $active;
        }

        if($prev_active) {
                $rb->text($self->{active_marker}[1]);
        }

        $rb->erase_to($self->window->cols);
}

sub _col2tab {
        my $self = shift;
        my ( $col ) = @_;

        $col += $self->{scroll_offset};
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

sub scroll_to_visible {
        my $self = shift;
        my ( $target_idx ) = @_;

        my $win = $self->window or return;
        my $cols = $win->cols;

        my $prev_more = $self->{prev_more} or return;
        my $next_more = $self->{next_more} or return;

        my @tabs = $self->tabs;
        my $halfwidth = int( $cols / 2 );

        my $ofs = $self->{scroll_offset};
        my $want_prev_more = defined $prev_more->[2];
        my $want_next_more = defined $next_more->[2];

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

                my $left_margin  = $want_prev_more ? $prev_more->[1]
                                                   : 0;
                my $right_margin = $want_next_more ? $cols - $next_more->[1]
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

        $self->{scroll_offset} = $ofs;

        if( $want_prev_more and !$prev_more->[2] ) {
                my $w = $win->make_float(
                        0, 0, 1, $prev_more->[1],
                );
                $prev_more->[2] = $w;
                $w->set_pen( $self->{tabbed}->get_style_pen( "more" ) );
                $w->bind_event( expose => sub {
                        my ( $win, undef, $info ) = @_;
                        $info->rb->text_at( 0, 0, $prev_more->[0] );
                });
                $w->bind_event( mouse => sub {
                        my ( $win, undef, $info ) = @_;
                        $self->_scroll_left if $info->type eq "press" && $info->button == 1;
                        return 1;
                } );
        }
        elsif( !$want_prev_more and $prev_more->[2] ) {
                $prev_more->[2]->hide;
                undef $prev_more->[2];
        }

        if( $want_next_more and !$next_more->[2] ) {
                my $w = $win->make_float(
                        0, $win->cols - $next_more->[1], 1, $next_more->[1],
                );
                $next_more->[2] = $w;
                $w->set_pen( $self->{tabbed}->get_style_pen( "more" ) );
                $w->bind_event( expose => sub {
                        my ( $win, undef, $info ) = @_;
                        $info->rb->text_at( 0, 0, $next_more->[0] );
                } );
                $w->bind_event( mouse => sub {
                        my ( $win, undef, $info ) = @_;
                        $self->_scroll_right if $info->type eq "press" && $info->button == 1;
                        return 1;
                } );
        }
        elsif( !$want_next_more and $next_more->[2] ) {
                $next_more->[2]->hide;
                undef $next_more->[2];
        }
}

sub _scroll_left {
        my $self = shift;

        my $win = $self->window or return;

        $self->{scroll_offset} -= int( $win->cols / 2 );
        $self->{scroll_offset} = 0 if $self->{scroll_offset} < 0;
        $self->scroll_to_visible( undef );
        $self->redraw;
}

sub _scroll_right {
        my $self = shift;

        my $win = $self->window or return;

        $self->{scroll_offset} += int( $win->cols / 2 );
        $self->scroll_to_visible( undef );
        $self->redraw;
}

sub on_key {
        my $self = shift;
        my ( $ev ) = @_;

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

sub on_mouse {
        my $self = shift;
        my ( $ev ) = @_;

        return 0 unless $ev->line == 0;
        return 0 unless my ( $tab, $tab_col ) = $self->_col2tab( $ev->col );

        return $tab->on_mouse( $ev->type, $ev->button, 0, $tab_col );
}

package Tickit::Widget::Tabbed::Ribbon::vertical;
use base qw( Tickit::Widget::Tabbed::Ribbon );
use constant orientation => "vertical";

use List::Util qw( max );

sub new {
        my $class = shift;
        my %args = @_;
        my $self = $class->SUPER::new( %args );
        $self->{tab_position} = $args{tab_position};
        return $self;
}

sub lines {
        my $self = shift;
        return scalar $self->tabs;
}
sub cols {
        my $self = shift;
        return 2 + max(0, map { $_->label_width } $self->tabs);
}

sub reshape {
        my $self = shift;

        my $win = $self->window or return;

        $self->scroll_to_visible( undef );

        my $prev_more = $self->{prev_more};
        if( $prev_more->[2] ) {
                $prev_more->[2]->change_geometry(
                        0, 0, 1, $win->cols,
                );
        }

        my $next_more = $self->{next_more};
        if( $next_more->[2] ) {
                $next_more->[2]->change_geometry(
                        $win->lines - 1, $win->cols, 1, $win->cols,
                );
        }
}

sub render_to_rb {
        my $self = shift;
        my ( $rb, $rect ) = @_;

        my $lines = $self->window->lines;
        my $cols  = $self->window->cols;

        my $pos = $self->{tab_position};

        my $next_line = -$self->{scroll_offset};
        foreach my $tab ($self->tabs) {
                my $active = $tab->is_active;

                my $this_line = $next_line;
                $next_line++;

                next if $this_line < $rect->top;
                return if $this_line >= $rect->bottom;
                $rb->goto($this_line, 0);

                my $spare = $cols - $tab->label_width;
                if($pos eq 'left') {
                        $rb->text($tab->label, $self->_pen_for_tab($tab));
                        $rb->text($active ? (' ' . ('>' x ($spare - 1))) : (' ' x $spare));
                } elsif($pos eq 'right') {
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

sub scroll_to_visible {
        my $self = shift;
        my ( $idx ) = @_;

        defined $idx or return;

        my $win = $self->window or return;
        my $lines = $win->lines;

        my $halfheight = int( $lines / 2 );

        my $ofs = $self->{scroll_offset};

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

        $self->{scroll_offset} = $ofs;
}

sub _showhide_more_markers {
}

sub on_key {
        my $self = shift;
        my ( $ev ) = @_;

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

sub on_mouse {
        my $self = shift;
        my ( $ev ) = @_;

        my $line = $ev->line;
        $line += $self->{scroll_offset};

        my @tabs = $self->tabs;
        return 0 unless $line < @tabs;

        return $tabs[$line]->on_mouse( $ev->type, $ev->button, 0, $ev->col );
}

1;

=head1 SUBCLASS METHODS

The subclass will need to provide implementations of the following methods.

=cut

=head2 $ribbon->render( %args )

=head2 $lines = $ribbon->lines

=head2 $cols = $ribbon->cols

As per the L<Tickit::Widget> methods.

=head2 $handled = $ribbon->on_key( $ev )

=head2 $handled = $ribbon->on_mouse( $ev )

As per the L<Tickit::Widget> methods. Optional. If not supplied then the
ribbon will not respond to keyboard or mouse events.

=head2 $ribbon->scroll_to_visible( $index )

Requests that a scrollable control ribbon scrolls itself so that the given
C<$index> tab is visible.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut
