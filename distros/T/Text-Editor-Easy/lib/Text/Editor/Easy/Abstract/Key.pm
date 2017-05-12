package Text::Editor::Easy::Abstract::Key;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Abstract::Key - Key functions using subs of "Text::Editor::Easy::Abstract" module.
Faster than using the object-oriented interface (that is, faster than "Text::Editor::Easy::Key") but not very clear.

=head1 VERSION

Version 0.49

=cut

use constant {
    PARENT    => 13,
    SELECTION => 18,
};

our $VERSION = '0.49';
use Data::Dump qw(dump);

sub left {
    my ( $self, $shift ) = @_;
    
    delete_start_selection_point( $self ) if ( ! $shift );

    if ( my $position = Text::Editor::Easy::Abstract::cursor_get($self) ) {
        return Text::Editor::Easy::Abstract::cursor_set( $self, $position - 1 );
    }

    # Curseur en début de ligne
    #my $line = $cursor->line->previous;
    my ( $ref_line, $text ) = $self->[PARENT]->previous_line( scalar(Text::Editor::Easy::Abstract::cursor_line($self)) );
    if ( $ref_line ) {
        return Text::Editor::Easy::Abstract::cursor_set( $self, length( $text ), $ref_line );
    }

    # Curseur en début de fichier (utilisé par la touche 'backspace')
    return;
}

sub right {
    my ( $self, $shift ) = @_;
    
    delete_start_selection_point( $self ) if ( ! $shift );
    my ( $text, $ref_cursor_line ) = Text::Editor::Easy::Abstract::cursor_line($self);
    my $position = Text::Editor::Easy::Abstract::cursor_get($self);
    
    if ( $position < length( $text ) ) {
        return Text::Editor::Easy::Abstract::cursor_set( $self, $position + 1, $ref_cursor_line );
    }

    # Curseur en début de ligne
    #my $line = $cursor->line->previous;
    ( $ref_cursor_line, $text ) = $self->[PARENT]->next_line( $ref_cursor_line );
    if ( $ref_cursor_line ) {
        return Text::Editor::Easy::Abstract::cursor_set( $self, 0, $ref_cursor_line );
    }

    # Curseur en début de fichier (utilisé par la touche 'backspace')
    return;
}

sub home {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $display = Text::Editor::Easy::Abstract::cursor_display($self);
    if ( Text::Editor::Easy::Abstract::cursor_position_in_display( $self ) ) {
        return Text::Editor::Easy::Abstract::cursor_set( $self, 0, $display );
    }
    elsif ( Text::Editor::Easy::Abstract::display_previous_is_same( $self, $display ) ) {
        return Text::Editor::Easy::Abstract::cursor_set( $self, 0, Text::Editor::Easy::Abstract::display_previous( $self, $display ) );
    }
    return;
}

sub end {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $display = Text::Editor::Easy::Abstract::cursor_display($self);
    if ( Text::Editor::Easy::Abstract::cursor_position_in_display( $self )
    == length( Text::Editor::Easy::Abstract::display_text( $self, $display ) ) ) {
        if ( Text::Editor::Easy::Abstract::display_next_is_same ($self, $display ) ) {
            my $next = Text::Editor::Easy::Abstract::display_next ($self, $display );
            return Text::Editor::Easy::Abstract::cursor_set( 
                $self, 
                length( Text::Editor::Easy::Abstract::display_text( $self, $next ) ), 
                $next
            );
        }
    }
    else {
        return Text::Editor::Easy::Abstract::cursor_set(
            $self,
            length( Text::Editor::Easy::Abstract::display_text( $self, $display ) ),
            $display
        );
    }
    return;
}

sub delete_start_selection_point {
    my ( $self ) = @_;
        
    $self->[SELECTION] = undef;
    Text::Editor::Easy::Abstract::deselect( $self );
}

sub shift_left {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $ref_line, $pos ) = left( $self, 'shift' );
        return if ( ! $ref_line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect($self, $ref_line);
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos, $start_pos);                    
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            if ( $ref_line == $select_ref->{'stop_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect($self, $ref_line);
            }
            if ( $select_ref->{'mode'} eq '+' ) {
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos);
            }
            else {
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos);
            }
        }
        
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub shift_right {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $ref_line, $pos ) = right( $self, 'shift' );
        return if ( ! $ref_line );
        
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line);
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            if ( $ref_line == $select_ref->{'stop_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line);
            }
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos);
            }
            else {
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos);
            }
        }
        
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub down {
    my ($self, $shift ) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );
    
    Text::Editor::Easy::Abstract::cursor_make_visible( $self );
    my $display  = Text::Editor::Easy::Abstract::cursor_display( $self );
    #print "Après cursor_display\n";
    my $next = Text::Editor::Easy::Abstract::display_next( $self, $display );
    #print "Après display_next\n";
    if ( defined $next ) {
        #print "NExt est définie\n";
        return Text::Editor::Easy::Abstract::cursor_set( $self,
            {
                'x'            => Text::Editor::Easy::Abstract::cursor_virtual_abs ($self ),
                'display'      => $next,
                'keep_virtual' => 1,
            }
        );
    }
    return;
}

sub up {
    my ($self, $shift ) = @_;
    
    delete_start_selection_point( $self ) if ( ! $shift );

    Text::Editor::Easy::Abstract::cursor_make_visible( $self );
    my $display  = Text::Editor::Easy::Abstract::cursor_display( $self );
    my $previous = Text::Editor::Easy::Abstract::display_previous( $self, $display );
    if ( defined $previous ) {
        return Text::Editor::Easy::Abstract::cursor_set( $self,
            {
                'x'            => Text::Editor::Easy::Abstract::cursor_virtual_abs ($self ),
                'display'      => $previous,
                'keep_virtual' => 1,
            }
        );
    }
    return;
}

sub shift_down {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $ref_line, $pos ) = down( $self, 'shift' );
        return if ( ! $ref_line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line);
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
                my $ref_stop_line = $select_ref->{'stop_line'};
                if ( defined $ref_stop_line and $ref_line != $ref_stop_line ) {
                        Text::Editor::Easy::Abstract::line_deselect( $self, $ref_stop_line);
                }
        }
        else {
            my $ref_stop_line = $select_ref->{'stop_line'};
            if ( ! defined $ref_stop_line or $ref_stop_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $select_ref->{'start_line'} );
                Text::Editor::Easy::Abstract::line_select( $self, $select_ref->{'start_line'}, $select_ref->{'start_pos'} );
                $select_ref->{'mode'} = '+';
            }
            if ( defined $ref_stop_line ) {
                if ( $ref_line == $ref_stop_line ) {
                    Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line);
                }
                elsif ( $ref_stop_line != $select_ref->{'start_line'} ) {
                    Text::Editor::Easy::Abstract::line_deselect( $self, $ref_stop_line);
                    if ( $select_ref->{'mode'} eq '+' ) {
                        Text::Editor::Easy::Abstract::line_select( $self, $ref_stop_line);
                    }
                }
            }
                    
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line);
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos);
            }
            else {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line);
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos);
            }
        }
        
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub shift_up {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $ref_line, $pos ) = up( $self, 'shift' );
        return if ( ! $ref_line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line);
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line,  $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
                my $ref_stop_line = $select_ref->{'stop_line'};
                if ( defined $ref_stop_line and $ref_line != $ref_stop_line ) {
                        Text::Editor::Easy::Abstract::line_deselect( $self, $ref_stop_line );
                }
        }
        else {
            #print "shift_up intermédiaire mode = ", $select_ref->{'mode'}, "\n";
            my $ref_stop_line = $select_ref->{'stop_line'};
            if ( ! defined $ref_stop_line or $ref_stop_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $select_ref->{'start_line'} );
                Text::Editor::Easy::Abstract::line_select( $self, $select_ref->{'start_line'}, 0, $select_ref->{'start_pos'} );
                $select_ref->{'mode'} = '-';
            }
            if ( defined $ref_stop_line ) {
                if ( $ref_line == $ref_stop_line ) {
                    Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                }
                elsif ( $ref_stop_line != $select_ref->{'start_line'} ) {
                    Text::Editor::Easy::Abstract::line_deselect( $self, $ref_stop_line );
                    if ( $select_ref->{'mode'} eq '-' ) {
                        Text::Editor::Easy::Abstract::line_select( $self, $ref_stop_line );
                    }
                }
            }
                    
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos);
            }
            else {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos);
            }
        }
        
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub shift_home {
        my ( $self ) = @_;
        
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $ref_line, $pos ) = home ( $self, 'shift' );
        return if ( ! $ref_line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos);
            }
            else {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos);
            }
        }
        
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub shift_end {
        my ( $self ) = @_;
        
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $ref_line, $pos ) = end( $self, 'shift' );
        return if ( ! $ref_line );
        
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos);
            }
            else {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos);
            }
        }
        
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub set_start_selection_point {
        my ( $self, $mode ) = @_;
        
        my $select_ref = $self->[SELECTION];
        if ( ! defined $select_ref ) {
            my ( $ref_line, $pos ) = Text::Editor::Easy::Abstract::cursor_get($self);
            $select_ref = {
                    'start_line' => $ref_line,
                    'start_pos' => $pos, 
                    'mode' => $mode,
            };
            #$self->save_info($select_ref, 'select');
        }
        #print "Départ : mode = ", $select_ref->{'mode'}, "\n";
        return $select_ref;
}

sub page_down {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $ref_display = Text::Editor::Easy::Abstract::cursor_display( $self );
    my $y = Text::Editor::Easy::Abstract::display_middle_ord( $self, $ref_display );

    my $ref_last   = Text::Editor::Easy::Abstract::screen_number( $self, Text::Editor::Easy::Abstract::screen_number( $self ) );
    #print "LAST text :", $last->text, "\n";
    Text::Editor::Easy::Abstract::display( $self, $ref_last, {
            'at' => 'top',
            'no_check' => '1',
        } );
    my ( @pos ) = Text::Editor::Easy::Abstract::cursor_set( $self, 
            {
                'x'            => Text::Editor::Easy::Abstract::cursor_virtual_abs( $self ),
                'y'               => $y,
                'keep_virtual' => 1,
            }
        );
    Text::Editor::Easy::Abstract::screen_check_borders ( $self );
    return @pos;
}

sub page_up {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $ref_display = Text::Editor::Easy::Abstract::cursor_display( $self );
    my $y = Text::Editor::Easy::Abstract::display_middle_ord( $self, $ref_display );
    my $ref_first   = Text::Editor::Easy::Abstract::screen_number( $self, 1 );

    #print "FIRST text :", $first->text, "\n";
    Text::Editor::Easy::Abstract::display( $self, $ref_first, {
            'at' => 'bottom',
            'from' => 'bottom',
            'no_check' => '1',
        } );
    my ( @pos ) = Text::Editor::Easy::Abstract::cursor_set( $self,
            {
                'x'            => Text::Editor::Easy::Abstract::cursor_virtual_abs( $self ),
                'y'               => $y,
                'keep_virtual' => 1,
            }
        );
    Text::Editor::Easy::Abstract::screen_check_borders ( $self );
    return @pos;
}

sub shift_page_down {
        my ( $self ) = @_;
        
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $ref_line, $pos ) = page_down( $self, 'shift' );
        return if ( ! $ref_line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                #$line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos, $start_pos);                    
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '+';
                }
                $select_ref->{'stop_line'} = $ref_line;
                $select_ref->{'stop_pos'} = $pos;
                $self->[SELECTION] = $select_ref;
                return;
        }
        if ( $select_ref->{'mode'} eq '+' ) {
            my $ref_line_to_select = $select_ref->{'stop_line'};
            $ref_line_to_select = $select_ref->{'start_line'} if ( ! defined $ref_line_to_select );
            print "1 Dans shift_page_down : ref = $ref_line_to_select\n";
            while ( defined $ref_line_to_select and $ref_line_to_select != $ref_line ) {
                    Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line_to_select );
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line_to_select );
                    ( $ref_line_to_select ) = $self->[PARENT]->next_line( $ref_line_to_select );
                    print "2 Dans shift_page_down : ref = $ref_line_to_select\n";
            }
            return if ( ! $ref_line_to_select ); # MEssage d'erreur ...
            Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos );
            
            $ref_line_to_select = $select_ref->{'stop_line'};
            $select_ref->{'stop_line'} = $ref_line;
            $select_ref->{'stop_pos'} = $pos;
            $self->[SELECTION] = $select_ref;
            return if ( ! defined $ref_line_to_select );
            #Sélection par l'arrière
            TOP: while ( $ref_line_to_select != $select_ref->{'start_line'} ) {
                ( $ref_line_to_select ) = $self->[PARENT]->previous_line( $ref_line_to_select );
                my $string = Text::Editor::Easy::Abstract::line_select( $self, $ref_line_to_select ) if ( $ref_line_to_select );
                last TOP if ( ! defined $string );
            }
        }
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub shift_page_up {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $ref_line, $pos ) = page_up( $self, 'shift' );
        return if ( ! $ref_line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $ref_line == $select_ref->{'start_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    #$line->select( $pos, $start_pos);            
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos, $start_pos);
                    $select_ref->{'mode'} = '-';
                }
                else {
                    Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $start_pos, $pos );
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            if ( $ref_line == $select_ref->{'stop_line'} ) {
                Text::Editor::Easy::Abstract::line_deselect( $self, $ref_line );
            }
            if ( $select_ref->{'mode'} eq '+' ) {
                # Changement possible de sens
                #my $search_line = $line->next;
                my ( $ref_search_line ) = $self->[PARENT]->next_line( $ref_line );
                my $ref_start_line = $select_ref->{'start_line'};
                my $ref_stop_line = $select_ref->{'stop_line'};
                while ( $ref_search_line 
                    and $ref_search_line ne  $ref_start_line
                    and $ref_search_line ne  $ref_stop_line ) {
                            #
                            #
                        ( $ref_search_line ) = $self->[PARENT]->next_line( $ref_search_line );
                }
                if ( $ref_search_line == $ref_start_line ) {
                        # Inversion
                        $select_ref->{'mode'} = '-';
                }
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, 0, $pos);
            }
            else {
                Text::Editor::Easy::Abstract::line_select( $self, $ref_line, $pos);
            }
        }
        
        $select_ref->{'stop_line'} = $ref_line;
        $select_ref->{'stop_pos'} = $pos;
        $self->[SELECTION] = $select_ref;
}

sub copy {
    my ($self) = @_;

    #Appel au thread manager à faire. Pour l'instant, méthode provisoire et très longue
    my $select_ref = set_start_selection_point($self, '+');
    return if ( ! defined $select_ref->{'stop_line'} );
    my ( $ref_start_line, $start_pos, $ref_stop_line, $stop_pos );
    if ( $select_ref->{'mode'} eq '+' ) {
        $ref_start_line = $select_ref->{'start_line'};
        $start_pos = $select_ref->{'start_pos'};
        $ref_stop_line = $select_ref->{'stop_line'};
        $stop_pos = $select_ref->{'stop_pos'};
    }
    else {
        $ref_start_line = $select_ref->{'stop_line'};
        $start_pos = $select_ref->{'stop_pos'};
        $ref_stop_line = $select_ref->{'start_line'};
        $stop_pos = $select_ref->{'start_pos'};
    }
    my $buffer;
    if ( $ref_stop_line != $ref_start_line ) {
        $buffer = substr ( $self->[PARENT]->line_text( $ref_start_line) , $start_pos );
        $buffer .= "\n";
    }
    else {
        $buffer = substr ( $self->[PARENT]->line_text( $ref_start_line ), $start_pos, $stop_pos - $start_pos );
        print "========Debut buffer\n$buffer\n==========Fin buffer\n";
        Text::Editor::Easy->clipboard_set($buffer);
        return;
    }
    my ( $ref_line ) = $self->[PARENT]->next_line( $ref_start_line );
    while ( defined $ref_line and $ref_line != $ref_stop_line ) {
        $ref_start_line = $ref_line;
        $buffer .= $self->[PARENT]->line_text( $ref_line ) . "\n";
        ( $ref_line ) = $self->[PARENT]->next_line( $ref_line );
    }
    if ( ! defined $ref_line ) { # stop line suppressed ?
        print STDERR "Can't copy : no line after line with reference $ref_start_line\n";
        return;
    }
    $buffer .= substr ( $self->[PARENT]->line_text( $ref_line ), 0, $stop_pos );
    #print "========Debut buffer\n$buffer\n==========Fin buffer\n";
    Text::Editor::Easy->clipboard_set($buffer);
    return $buffer;
    #$buffer = $self->cursor->line->text . "\n";
}

sub delete_selection {
    my ( $self ) = @_;
    
    my $select_ref = $self->[SELECTION];
    
    return if ( ! defined $select_ref );
    
    my ( $ref_start_line, $start_pos, $ref_stop_line, $stop_pos );
    if ( $select_ref->{'mode'} eq '+' ) {
        $ref_start_line = $select_ref->{'start_line'};
        $start_pos = $select_ref->{'start_pos'};
        $ref_stop_line = $select_ref->{'stop_line'};
        $stop_pos = $select_ref->{'stop_pos'};
    }
    else {
        $ref_start_line = $select_ref->{'stop_line'};
        $start_pos = $select_ref->{'stop_pos'};
        $ref_stop_line = $select_ref->{'start_line'};
        $stop_pos = $select_ref->{'start_pos'};
    }
    
    #print "Dans delete_selection : $start_pos|$stop_pos\n";
    if ( $ref_start_line ==  $ref_stop_line ) {
        my ( $text, $ref_cursor_line ) = Text::Editor::Easy::Abstract::cursor_line($self);
        if ( $ref_cursor_line != $ref_stop_line ) {
            # Bizarre !
            print STDERR "Cursor not on start or end of selection : the text won't be suppressed\n";
            Text::Editor::Easy::Abstract::deselect( $self );
            undef $self->[SELECTION];
            return;
        }
        my $new_text = substr ( $text, 0, $start_pos) . substr( $text, $stop_pos);
        #print "Nouveau text de $ref_stop_line : |$new_text| START POS : $start_pos\n";
        Text::Editor::Easy::Abstract::cursor_set( $self, $start_pos, $ref_stop_line );
        Text::Editor::Easy::Abstract::line_set($self, $ref_stop_line, $new_text);
        Text::Editor::Easy::Abstract::line_deselect( $self, $ref_stop_line );
        undef $self->[SELECTION];
        return;
    }
    
    my ( $text, $ref_cursor_line ) = Text::Editor::Easy::Abstract::cursor_line($self);
    if ( $ref_cursor_line != $ref_start_line and $ref_cursor_line != $ref_stop_line ) {
        print STDERR "Cursor not on start or end of selection : the text won't be suppressed\n";
        Text::Editor::Easy::Abstract::deselect( $self );
        undef $self->[SELECTION];
        return;
    }

    my ( $at, $from );
    if ( Text::Editor::Easy::Abstract::line_displayed( $self, $ref_start_line ) ) {
        $at = Text::Editor::Easy::Abstract::line_top_ord ( $self, $ref_start_line );
        $from = 'top';        
    }
    elsif ( Text::Editor::Easy::Abstract::line_displayed( $self, $ref_stop_line ) ) {
        $at = Text::Editor::Easy::Abstract::line_bottom_ord ( $self, $ref_stop_line );
        $from = 'bottom';
    }
    else { # Affichage au milieu des 2 lignes jointes
        $from = 'middle';
        $at = 'middle';        
    }
    Text::Editor::Easy::Abstract::cursor_set( $self, $start_pos, $ref_start_line );
    my $start_text = substr ( $self->[PARENT]->line_text( $ref_start_line) , 0, $start_pos );
    my $end_text = substr ( $self->[PARENT]->line_text( $ref_stop_line) , $stop_pos );
        
        #print "Nouveau texte première ligne : $start_text$end_text\n";
    Text::Editor::Easy::Abstract::line_set($self, $ref_start_line, $start_text . $end_text );
    Text::Editor::Easy::Abstract::deselect( $self );
    #Suppression des lignes jusqu'à $ref_stop_line incluse
    my @refs_to_suppress;
    my $ref_to_suppress = $ref_start_line;
    do {
        ( $ref_to_suppress ) = $self->[PARENT]->next_line( $ref_to_suppress );
        push @refs_to_suppress, $ref_to_suppress;
    }
    while ( $ref_to_suppress != $ref_stop_line );
    for my $ref_line ( @refs_to_suppress ) {
        $self->[PARENT]->delete_line( $ref_line );
    }
    
    Text::Editor::Easy::Abstract::display ( $self, $ref_start_line, { 
            'from' => $from,
            'at' => $at
        } );

    undef $self->[SELECTION];
    return;
}

sub backspace {
    my ($self) = @_;
    
    if ( defined $self->[SELECTION] ) {
        print "Avant delete_selection\n";
        delete_selection($self);
        return; # pour comportement le plus "standard"
    }
    # left_key renvoie undef si on est au début du fichier
    return if ( !defined left($self) );
    
    # Améliorer l'interface de erase en autorisant les nombres négatifs ==>
    #    $self->erase(-1)
    print "Retour de left\n";
    Text::Editor::Easy::Abstract::erase($self, 1);
}

sub delete {
    my ($self) = @_;
    
    if ( defined $self->[SELECTION] ) {
        delete_selection($self);
        return; # pour comportement le plus "standard"
    }
    print "Fin de la suppression de la sélection\n";
    Text::Editor::Easy::Abstract::erase($self, 1);
}

sub enter {
    my ($self) = @_;
    
    if ( defined $self->[SELECTION] ) {
        Text::Editor::Easy::Abstract::Key::delete_selection($self);
    }

    #Text::Editor::Easy::Abstract::enter( $self, { 'indent' => 'auto' } );
    Text::Editor::Easy::Abstract::insert( $self, "\n", { 'assist' => 1 } );
}

sub cut {
    my ( $self ) = @_;
    
    copy ( $self );

    delete_selection ( $self );
}

sub paste {
    my ( $self ) = @_;
    
    delete_selection ( $self );
    
    Text::Editor::Easy::Abstract::paste( $self );
}

sub end_file {
    my ( $self, $pos ) = @_;

    my ( $ref_last, $text ) = $self->[PARENT]->previous_line;
    
    Text::Editor::Easy::Abstract::display( $self, $ref_last, { 'at' => 'bottom', 'from' => 'bottom' } );

    if ( ! defined $pos ) {
        $pos = length( $text );
        Text::Editor::Easy::Abstract::set_at_end( $self );
    }
    return Text::Editor::Easy::Abstract::cursor_set( $self, $pos, $ref_last );
}

sub motion_select {
    my ( $self, $options_ref ) = @_;
    
    my $select_ref = $self->[SELECTION];
    if ( ! defined $select_ref ) {
        $select_ref = set_start_selection_point ( $self, '=' );
        $self->[SELECTION] = $select_ref;
    }
    $select_ref->{'stop_line'} = $options_ref->{'line'};
    $select_ref->{'stop_pos'} = $options_ref->{'pos'};
    #print "START LINE $select_ref->{'start_line'}\n";
    #print "OPTIO LINE $options_ref->{'line'}\n";
    #print "LINE   POS $options_ref->{'pos'}\n";
    if ( $select_ref->{'start_line'} eq $options_ref->{'line'} ) {
        if ( $select_ref->{'stop_pos'} > $select_ref->{'start_pos'} ) {
            $select_ref->{'mode'} = '+';
        }
        else {
            $select_ref->{'mode'} = '-';
        }
        Text::Editor::Easy::Abstract::area_select (
            $self,
            [ $select_ref->{'start_line'}, $select_ref->{'start_pos'} ],
            [ $select_ref->{'start_line'}, $options_ref->{'pos'} ]
        );
        Text::Editor::Easy::Abstract::cursor_set ( 
            $self,
            $select_ref->{'stop_pos'},
            $select_ref->{'stop_line'}
        );
        return;
    }
    my ( $first, $last ) = Text::Editor::Easy::Abstract::tell_order (
        $self,
        $select_ref->{'start_line'},
        $options_ref->{'line'},
    );
    my ( $first_ref, $last_ref );
    if ( ! defined $last ) {
        if ( $select_ref->{'mode'} eq '+' ) {
            $first_ref = 'top';
            $last_ref = [ $options_ref->{'line'}, $options_ref->{'pos'} ];
        }
        else {
            $first_ref = [ $options_ref->{'line'}, $options_ref->{'pos'} ];
            $last_ref = [ 'bottom' ];
        }
    }
    else {
        my $area_ref;
        $area_ref->{ $select_ref->{'start_line'} } = $select_ref->{'start_pos'};
        $area_ref->{ $options_ref->{'line'} } = $options_ref->{'pos'};

        $first_ref = [ $first, $area_ref->{$first} ];
        $last_ref = [ $last, $area_ref->{$last} ];

        if ( $first == $select_ref->{'start_line'} ) {
            $select_ref->{'mode'} = '+';
        }
        else {
            $select_ref->{'mode'} = '-';
        }
    }    
    #print "FIRST : $first\n";
    #print "LAST : $last\n";
    Text::Editor::Easy::Abstract::area_select (
        $self,
        $first_ref,
        $last_ref,
    );
    Text::Editor::Easy::Abstract::cursor_set ( 
        $self,
        $select_ref->{'stop_pos'},
        $select_ref->{'stop_line'}
    );
}


=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;



