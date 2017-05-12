package Text::Editor::Easy::Key;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Key - Key functions using object-oriented interface of "Text::Editor::Easy".

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';
use Data::Dump qw(dump);

sub left {
    my ( $self, $shift ) = @_;
    
    delete_start_selection_point( $self ) if ( ! $shift );

    my $cursor = $self->cursor;
    if ( my $position = $cursor->get ) {
        return $cursor->set( $position - 1 );
    }

    # Curseur en début de ligne
    my $line = $cursor->line->previous;
    if ($line) {
        return $cursor->set( length( $line->text ), $line );
    }

    # Curseur en début de fichier (utilisé par la touche 'backspace')
    return;
}

sub right {
    my ($self, $shift ) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $cursor   = $self->cursor;
    my $position = $cursor->get;
    my $line     = $cursor->line;
    if ( $position < length( $line->text ) ) {
        return $cursor->set( $position + 1 );
    }

    # Curseur en fin de ligne
    if ( my $next = $line->next )
    {    # Test car risque de retour à 0 sur la dernière ligne
        return $cursor->set( 0, $next );
    }
    return;
}

sub up {
    my ($self, $shift ) = @_;
    
    delete_start_selection_point( $self ) if ( ! $shift );

    my $cursor = $self->cursor;
    $cursor->make_visible;
    my $display  = $cursor->display;
    my $previous = $display->previous;
    if ( defined $previous ) {
        return $cursor->set(
            {
                'x'            => $cursor->virtual_abs,
                'display'      => $previous,
                'keep_virtual' => 1,
            }
        );
    }
    return;
}

sub down {
    my ($self, $shift ) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );
    
    my $cursor = $self->cursor;
    $cursor->make_visible;
    my $display = $cursor->display;
    my $next    = $display->next;
    if ( defined $next ) {
        return $cursor->set(
            {
                'x'            => $cursor->virtual_abs,
                'display'      => $next,
                'keep_virtual' => 1,
            }
        );
    }
    return;
}

sub move_down {
    my ($self) = @_;

    $self->screen->move( 0, -1 );
}

sub move_up {
    my ($self) = @_;

    $self->screen->move( 0, 1 );
}

sub backspace {
    my ($self) = @_;

    return
      if ( !defined Text::Editor::Easy::Key::left($self) )
      ;    # left_key renvoie undef si on est au début du fichier

    # Améliorer l'interface de erase en autorisant les nombres négatifs ==>
    #    $self->erase(-1)
    $self->erase(1);
}

sub home {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $cursor  = $self->cursor;
    my $display = $cursor->display;
    if ( $cursor->position_in_display ) {
        return $cursor->set( 0, $display );
    }
    elsif ( $display->previous_is_same ) {
        return $cursor->set( 0, $display->previous );
    }
    return;
}

sub end {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $cursor  = $self->cursor;
    my $display = $cursor->display;
    if ( $cursor->position_in_display == length( $display->text ) ) {
        if ( $display->next_is_same ) {
            my $next = $display->next;
            return $cursor->set( length( $next->text ), $next );
        }
    }
    else {
        return $cursor->set( length( $display->text ), $display );
    }
    return;
}

sub end_file {
    my ($self) = @_;

    my $last = $self->last;

    $self->display( $last, { 'at' => 'bottom', 'from' => 'bottom' } );
    my $cursor = $self->cursor;
    return $cursor->set( length( $last->text ), $last );
}

sub top_file {
    my ($self) = @_;

    my $first = $self->first;

    $self->display( $first, { 'at' => 'top', 'from' => 'top' } );
    my $cursor = $self->cursor;
    return $cursor->set( 0, $first );
}

sub jump_right {
    my ($self) = @_;

    my $cursor   = $self->cursor;
    my $position = $cursor->position_in_display;
    my $display  = $cursor->display;
    if ( $position + 6 > length( $display->text ) ) {
        return $cursor->set( length( $display->text ), $display );
    }
    else {
        return $cursor->set( $position + 6, $display );
    }
}

sub jump_left {
    my ($self) = @_;

    my $cursor   = $self->cursor;
    my $position = $cursor->position_in_display;
    my $display  = $cursor->display;
    if ( $position > 6 ) {
        return $cursor->set( $position - 6, $display );
    }
    else {
        return $cursor->set( 0, $display );
    }
}

sub jump_up {
    my ($self) = @_;

    my $cursor = $self->cursor;
    $cursor->make_visible;
    my $display = $cursor->display;
    my $jump    = 6;
    my $previous;
    while ( $display = $display->previous and $jump ) {
        $cursor->set(
            {
                'x'            => $cursor->virtual_abs,
                'display'      => $display,
                'keep_virtual' => 1,
            }
        );
        $cursor->make_visible;
        $jump -= 1;
    }
}

sub jump_down {
    my ($self) = @_;

    my $cursor = $self->cursor;
    $cursor->make_visible;
    my $display = $cursor->display;
    my $jump    = 6;
    my $next;
    while ( $display = $display->next and $jump ) {
        $cursor->set(
            {
                'x'            => $cursor->virtual_abs,
                'display'      => $display,
                'keep_virtual' => 1,
            }
        );
        $cursor->make_visible;
        $jump -= 1;
    }
}

# Pour les 2 fonctions suivantes, il manque :
#        - la gestion du curseur
#        - le recentrage
sub page_down {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $cursor = $self->cursor;
    my $display = $cursor->display;
    my $y = $display->middle_ord;

    my $screen = $self->screen;
    my $last   = $screen->number( $screen->number );
    print "LAST text :", $last->text, "\n";
    $self->display( $last, {
            'at' => 'top',
            'no_check' => '1',
        } );
    my ( @pos ) = $cursor->set(
            {
                'x'            => $cursor->virtual_abs,
                'y'               => $y,
                'keep_virtual' => 1,
            }
        );
    $screen->check_borders;
    return @pos;
}

sub page_up {
    my ($self, $shift) = @_;

    delete_start_selection_point( $self ) if ( ! $shift );

    my $cursor = $self->cursor;
    my $display = $cursor->display;
    my $y = $display->middle_ord;
    my $screen = $self->screen;
    my $first = $screen->number(1);
    print "FIRST text :", $first->text, "\n";
    $self->display( $first, {
            'at' => 'bottom',
            'from' => 'bottom',
            'no_check' => '1',
        } );
    my ( @pos ) = $cursor->set(
            {
                'x'            => $cursor->virtual_abs,
                'y'               => $y,
                'keep_virtual' => 1,
            }
        );
    $screen->check_borders;
    return @pos;
}

sub new_a {
    my ($self) = @_;

    $self->insert('bc');
}

sub query_segments {
    my ($self) = @_;

    return $self->query_segments;
}

sub save {
    my ($self) = @_;

# Si aucun nom n'existe pour l'éditeur courant, faire apparaître une fenêtre le demandant
# => accès à un gestionnaire de fichier
    return $self->save;
}

sub print_screen_number {
    my ($self) = @_;

    my $screen = $self->screen;
    print "Screen number = ", $screen->number, "\n";
    my $display = $screen->first;
    while ($display) {
        print $display->number, "|", $display->text, "\n";
        $display = $display->next;
    }
}

sub display_cursor_display {
    my ($self) = @_;

    my $display = $self->cursor->display;
    print "\nT|", $display->ord - $display->height, "\n";
    print "H|", $display->height, "\n";
    print "O|", $display->ord,    "\n";

}

my $buffer;

sub copy {
    my ($self) = @_;

    #Appel au thread manager à faire. Pour l'instant, méthode provisoire et très longue
    my $select_ref = set_start_selection_point($self, '+');
    return if ( ! defined $select_ref->{'stop_line'} );
    my ( $start_line, $start_pos, $stop_line, $stop_pos );
    if ( $select_ref->{'mode'} eq '+' ) {
        $start_line = $select_ref->{'start_line'};
        $start_pos = $select_ref->{'start_pos'};
        $stop_line = $select_ref->{'stop_line'};
        $stop_pos = $select_ref->{'stop_pos'};
    }
    else {
        $start_line = $select_ref->{'stop_line'};
        $start_pos = $select_ref->{'stop_pos'};
        $stop_line = $select_ref->{'start_line'};
        $stop_pos = $select_ref->{'start_pos'};
    }
    my $buffer;
    if ( $stop_line != $start_line ) {
        $buffer = substr ( $start_line->text, $start_pos );
        $buffer .= "\n";
    }
    else {
        # A gérer 
        $buffer = substr ( $start_line->text, $start_pos, $stop_pos - $start_pos );
        print "========Debut buffer\n$buffer\n==========Fin buffer\n";
        Text::Editor::Easy->clipboard_set($buffer);
        return;
    }
    my $line = $start_line->next;
    while ( defined $line and $line != $stop_line ) {
        $buffer .= $line->text . "\n";
        $line = $line->next;
    }
    return if ( ! defined $line ); # stop line suppressed
    $buffer .= substr ( $line->text, 0, $stop_pos );
    print "========Debut buffer\n$buffer\n==========Fin buffer\n";
    Text::Editor::Easy->clipboard_set($buffer);
    #$buffer = $self->cursor->line->text . "\n";
}

sub cut_line {
    my ($self) = @_;

    my $cursor = $self->cursor;
    my $line   = $cursor->line;
    $buffer = $line->text;
    $cursor->set(0);
    $self->erase( length( $line->text ) + 1 );
}

sub paste {
    my ($self) = @_;

    $self->insert(Text::Editor::Easy->clipboard_get());
}

sub wrap {
    my ($self) = @_;

    my $screen = $self->screen;
    if ( $screen->wrap ) {
        $screen->unset_wrap;
    }
    else {
        $screen->set_wrap;
    }
}

sub inser {
    my ($self) = @_;

    if ( $self->insert_mode ) {
        $self->set_replace;
    }
    else {
        $self->set_insert;
    }
}

# SHIFT (sélection)

sub shift_left {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $line, $pos ) = left( $self, 'shift' );
        return if ( ! $line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select( $pos, $start_pos);                    
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $start_pos, $pos );
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            if ( $line == $select_ref->{'stop_line'} ) {
                $line->deselect;
            }
            if ( $select_ref->{'mode'} eq '+' ) {
                $line->select(0, $pos);
            }
            else {
                $line->select($pos);
            }
        }
        
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub shift_right {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $line, $pos ) = right( $self, 'shift' );
        return if ( ! $line );
        
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select($start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            if ( $line == $select_ref->{'stop_line'} ) {
                $line->deselect;
            }
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                $line->select(0, $pos);
            }
            else {
                $line->select($pos);
            }
        }
        
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub shift_up {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $line, $pos ) = up( $self, 'shift' );
        return if ( ! $line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select( $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
                my $stop_line = $select_ref->{'stop_line'};
                if ( defined $stop_line and $line != $stop_line ) {
                        $stop_line->deselect;
                }
        }
        else {
            #print "shift_up intermédiaire mode = ", $select_ref->{'mode'}, "\n";
            my $stop_line = $select_ref->{'stop_line'};
            if ( ! defined $stop_line or $stop_line == $select_ref->{'start_line'} ) {
                $select_ref->{'start_line'}->deselect;
                $select_ref->{'start_line'}->select( 0, $select_ref->{'start_pos'} );
                $select_ref->{'mode'} = '-';
            }
            if ( defined $stop_line ) {
                if ( $line == $stop_line ) {
                    $line->deselect;
                }
                elsif ( $stop_line != $select_ref->{'start_line'} ) {
                    $stop_line->deselect;
                    if ( $select_ref->{'mode'} eq '-' ) {
                        $stop_line->select;
                    }
                }
            }
                    
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                $line->deselect;
                $line->select(0, $pos);
            }
            else {
                $line->deselect;
                $line->select($pos);
            }
        }
        
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub shift_down {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $line, $pos ) = down( $self, 'shift' );
        return if ( ! $line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select( $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
                my $stop_line = $select_ref->{'stop_line'};
                if ( defined $stop_line and $line != $stop_line ) {
                        $stop_line->deselect;
                }
        }
        else {
            my $stop_line = $select_ref->{'stop_line'};
            if ( ! defined $stop_line or $stop_line == $select_ref->{'start_line'} ) {
                $select_ref->{'start_line'}->deselect;
                $select_ref->{'start_line'}->select( $select_ref->{'start_pos'} );
                $select_ref->{'mode'} = '+';
            }
            if ( defined $stop_line ) {
                if ( $line == $stop_line ) {
                    $line->deselect;
                }
                elsif ( $stop_line != $select_ref->{'start_line'} ) {
                    $stop_line->deselect;
                    if ( $select_ref->{'mode'} eq '+' ) {
                        $stop_line->select;
                    }
                }
            }
                    
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                $line->deselect;
                $line->select(0, $pos);
            }
            else {
                $line->deselect;
                $line->select($pos);
            }
        }
        
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub shift_end {
        my ( $self ) = @_;
        
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $line, $pos ) = end( $self, 'shift' );
        return if ( ! $line );
        
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select( $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                $line->deselect;
                $line->select(0, $pos);
            }
            else {
                $line->deselect;
                $line->select($pos);
            }
        }
        
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub shift_home {
        my ( $self ) = @_;
        
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $line, $pos ) = home ( $self, 'shift' );
        return if ( ! $line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select( $start_pos, $pos );
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $pos, $start_pos);
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            #print "Dans shift_right, mode = ", $select_ref->{'mode'} , "\n";
            if ( $select_ref->{'mode'} eq '+' ) {
                $line->deselect;
                $line->select(0, $pos);
            }
            else {
                $line->deselect;
                $line->select($pos);
            }
        }
        
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub shift_page_up {
        my ( $self ) = @_;
        
        #print "Dans shift_left de Key\n";
        my $select_ref = set_start_selection_point($self, '-');
        
        my ( $line, $pos ) = page_up( $self, 'shift' );
        return if ( ! $line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select( $pos, $start_pos);                    
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $start_pos, $pos );
                    $select_ref->{'mode'} = '+';
                }
        }
        else {
            if ( $line == $select_ref->{'stop_line'} ) {
                $line->deselect;
            }
            if ( $select_ref->{'mode'} eq '+' ) {
                # Changement possible de sens
                my $search_line = $line->next;
                my $start_line = $select_ref->{'start_line'};
                my $stop_line = $select_ref->{'stop_line'};
                while ( $search_line 
                    and $search_line ne  $start_line
                    and $search_line ne  $stop_line ) {
                            #
                            #
                        $search_line = $search_line->next;
                }
                if ( $search_line == $start_line ) {
                        # Inversion
                        $select_ref->{'mode'} = '-';
                }
                $line->select(0, $pos);
            }
            else {
                $line->select($pos);
            }
        }
        
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub shift_page_down {
        my ( $self ) = @_;
        
        print "Dans shift_page_down de Key\n";
        my $select_ref = set_start_selection_point($self, '+');
        
        my ( $line, $pos ) = page_down( $self, 'shift' );
        return if ( ! $line );
        #print "Line récupérée de left $line, ", $line->text, " |", $line->ref, "\n";
        #print "Start Line ", $select_ref->{'start_line'}, $select_ref->{'start_line'}->text, " |", $select_ref->{'start_line'}->ref, "\n";
        if ( $line == $select_ref->{'start_line'} ) {
                $line->deselect;
                my $start_pos = $select_ref->{'start_pos'};
                if ( $start_pos > $pos ) {
                    $line->select( $pos, $start_pos);                    
                    $select_ref->{'mode'} = '-';
                }
                else {
                    $line->select( $start_pos, $pos );
                    $select_ref->{'mode'} = '+';
                }
                $select_ref->{'stop_line'} = $line;
                $select_ref->{'stop_pos'} = $pos;
                save_selection($self, $select_ref);
                return;
        }
        if ( $select_ref->{'mode'} eq '+' ) {
            my $line_to_select = $select_ref->{'stop_line'};
            $line_to_select = $select_ref->{'start_line'} if ( ! defined $line_to_select );
            while ( defined $line_to_select and $line_to_select != $line ) {
                    $line_to_select->deselect;
                    $line_to_select->select;
                    $line_to_select = $line_to_select->next;
            }
            return if ( ! $line_to_select ); # MEssage d'erreur ...
            $line->select( 0, $pos );
            
            $line_to_select = $select_ref->{'stop_line'};
            $select_ref->{'stop_line'} = $line;
            $select_ref->{'stop_pos'} = $pos;
            save_selection($self, $select_ref);
            return if ( ! defined $line_to_select );
            #Sélection par l'arrière
            TOP: while ( $line_to_select != $select_ref->{'start_line'} ) {
                $line_to_select = $line_to_select->previous;
                my $string = $line_to_select->select if ( $line_to_select );
                last TOP if ( ! defined $string );
            }
        }
        $select_ref->{'stop_line'} = $line;
        $select_ref->{'stop_pos'} = $pos;
        save_selection($self, $select_ref);
}

sub set_start_selection_point {
        my ( $self, $mode ) = @_;
        
        my $select_ref = $self->load_info('select');
        if ( ! defined $select_ref ) {
            my ( $line, $pos ) = $self->cursor->get;
            $select_ref = {
                    'start_line' => $line,
                    'start_pos' => $pos, 
                    'mode' => $mode,
            };
            #$self->save_info($select_ref, 'select');
        }
        else {
            $select_ref->{'start_line'} = Text::Editor::Easy::Line->new( $self, $select_ref->{'start_line'} );
            $select_ref->{'stop_line'} = Text::Editor::Easy::Line->new( $self, $select_ref->{'stop_line'} );
        }
        #print "Départ : mode = ", $select_ref->{'mode'}, "\n";
        return $select_ref;
}

sub delete_start_selection_point {
        my ( $self, $mode ) = @_;
        
        my $select_ref = undef;
        $self->async->save_info($select_ref, 'select');
        $self->deselect;
}


sub save_selection {
    my ( $self, $select_ref ) = @_;
        
    if ( my $start_line = $select_ref->{'start_line'} ) {
        $select_ref->{'start_line'} = $start_line->ref;
    }
    if ( my $stop_line = $select_ref->{'stop_line'} ) {
        $select_ref->{'stop_line'} = $stop_line->ref;
    }
    #print "Fin : mode = ", $select_ref->{'mode'}, "\n";
    $self->async->save_info($select_ref, 'select');
}


sub list_display_positions {
    my ($self) = @_;

    my $display = $self->cursor->display;
    print "Abscisses pour $display->text\n";
    for ( 0 .. length( $display->text ) ) {
        print "\t$_ : ", $display->abs($_), "\n";
    }
}

sub sel_first {
    my ($self) = @_;

    my @list = Text::Editor::Easy->list;
    print "Liste des éditeur ", @list, "\n";
    $self->focus( $list[0] );
}

sub sel_second {
    my ($self) = @_;

    print "Liste des éditeur ", Text::Editor::Easy->list, "\n";
    my @list = Text::Editor::Easy->list;
    $self->focus( $list[1] );
}

sub search {
    my ( $self ) = @_;
    
    Text::Editor::Easy->save_current( $self->id );

        my $macro_instructions = << 'END_PROGRAM';
my $editor = Text::Editor::Easy->last_current;
my $exp = "";
my ( $line, $start, $end, $regexp ) = $editor->search($exp);
$editor->deselect;
return if ( ! defined $line );
my $text = $line->select($start, $end);
$editor->visual_search( $regexp, $line, $end);
END_PROGRAM
        my $eval_editor = Text::Editor::Easy->whose_name( 'macro' );
        $eval_editor->bind_key ( {'package' => 'Text::Editor::Easy::Key', 'sub' => 'enter_search', 'key' => 'Return' } );
        $eval_editor->bind_key ( {'package' => 'Text::Editor::Easy::Key', 'sub' => 'enter_search', 'key' => 'KP_Enter' } );
        $eval_editor->empty;
        $eval_editor->insert($macro_instructions);
        $eval_editor->focus;
        $eval_editor->cursor->set( 11, $eval_editor->number(2));
        return;
}

sub enter_search {
    my $eval_editor = Text::Editor::Easy->whose_name( 'macro' );
    # Fonctionnement par défaut des touches récupérés
    $eval_editor->bind_key ( {'key' => 'Return' } );
    $eval_editor->bind_key ( {'key' => 'KP_Enter' } );
    my $exp = eval $eval_editor->number(2)->text;
    #print "REGEXP = $regexp\n";
    my $editor = Text::Editor::Easy->last_current;
    
    #$options_ref = Text::Editor::Easy->data_get_search_options ( $self->id );
    my ( $line_init, $pos ) = $editor->cursor->get;
    my ( $line, $start, $end, $regexp ) = $editor->search($exp);
    Text::Editor::Easy::Async->data_set_search_options ( $editor->id, {
        'exp' => dump ($regexp),
        'line_init' => $line_init->ref,
        'pos_init' => $pos,
    } );
    #print "Référence pour save ", $editor->id, "\n";
    $editor->deselect;
    return if ( ! defined $line );
    my $text = $line->select($start, $end, {'force' => 'middle_top'} );
    $editor->cursor->set( $end, $line );
    $editor->focus;
    $editor->visual_search( $regexp, $line, $end);
}

sub f3_search {
    my $editor = Text::Editor::Easy->last_current;
    my $options_ref = Text::Editor::Easy->data_get_search_options ( $editor->id );
    #print "Référence pour load ", $editor->id, "\n";
    #print "EXP : $options_ref->{'exp'}\n";
    #print "LINE: $options_ref->{'line_init'}\n";
    #print "pos : $options_ref->{'pos_init'}\n";
    my ( $line, $start, $end, $regexp ) = $editor->search(eval $options_ref->{'exp'}, {
            'stop_line' => $options_ref->{'line_init'},
            'stop_pos' => $options_ref->{'pos_init'},
    } );
    $editor->deselect;
    if ( ! defined $line ) {
        # Positionnement à l'endroit initial
        my $line_init = Text::Editor::Easy::Line->new($editor, $options_ref->{'line_init'});
        $editor->cursor->set($options_ref->{'pos_init'},$line_init);
        return;
    }
    my $text = $line->select($start, $end, {'force' => 'middle_top'} );
    $editor->cursor->set( $end, $line );
    $editor->focus;
    $editor->visual_search( $regexp, $line, $end);
}

sub close {
    my ( $self ) = @_;
    
    print "Dans key close, avant kill\n";
    
    $self->kill;
}


=head1 FUNCTIONS

=head2 backspace

=head2 close

Should behave like a standard file close.

=head2 copy

Copy the selected text to the clipboard.

=head2 copy_line

=head2 cut_line

=head2 delete_start_selection_point

Delete from memory the start point of the selected text.

=head2 display_cursor_display

=head2 down

=head2 end

=head2 end_file

=head2 enter_search

Action to be done when the user press enter for the first time in the macro panel after a ctrl-f sequence (the search expression have been set, the cursor will be sent to the first found position).

=head2 f3_search

Next search and new cursor position change.

=head2 home

=head2 inser

=head2 jump_down

=head2 jump_left

=head2 jump_right

=head2 jump_up

=head2 left

=head2 list_display_positions

=head2 move_down

=head2 move_up

=head2 new_a

=head2 page_down

=head2 page_up

=head2 paste

=head2 print_screen_number

=head2 query_segments

=head2 right

=head2 save

=head2 save_selection

Save selection after a "shift-press" : the end point of the selected text has been modified by a move, must be saved.

=head2 search

Code executed when the ctrl-f key is pressed.

=head2 sel_first

=head2 sel_second

=head2 set_start_selection_point

No text has been selected yet, so the start point of the selection must be fixed.

=head2 shift_down

Selection towards bottom.

=head2 shift_end

Selection towards end of the display.

=head2 shift_home

Selection towards start of the display.

=head2 shift_left

Selection towards left.

=head2 shift_page_down

Selection of one page towards bottom.

=head2 shift_page_up

Selection of one page towards top.

=head2 shift_right

Selection towards right.

=head2 shift_up

Selection towards up.

=head2 top_file

=head2 up

=head2 wrap

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
