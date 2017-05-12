package Text::Editor::Easy::Program::Tab;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Program::Tab - Tab simulation with a Text::Editor::Easy object.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Text::Editor::Easy::Comm;

use File::Basename;

use Data::Dump qw(dump);

sub on_main_editor_change {
    my ( $zone, $info_ref, @user ) = @_;
    
    my $name = on_top_editor_change( $zone, $info_ref, @user );
    #print "On main editor change : $name, zone = $zone->{'name'}\n";
    $info_ref->{'editor'}->change_title($name);
    #print "Après changement de nom\n";
}

sub on_top_editor_change {
    my ( $zone, $info_ref, $tab_ref ) = @_;

    #print "Dans on_top_editor_change : tab_ref = $tab_ref\n";

    my $new_on_top_editor = $info_ref->{'editor'};
    my $hash_ref          = $info_ref->{'hash_ref'};
    
    my $old_on_top_editor = $info_ref->{'old_editor'};
    my $conf_ref          = $info_ref->{'conf'};
    

    #print "Nom du nouveau fichier on_top : |", $new_on_top_editor->file_name, "|\n";
    
    my $tab_editor = Text::Editor::Easy->get_from_id ( $tab_ref );
    
    if ( defined $old_on_top_editor ) {
        my $name = $old_on_top_editor->name;
        #print "\n\nDans on_top_editor_change de Tab : old_editor => $name\n";
        Text::Editor::Easy::Async->update_conf ( $old_on_top_editor->id, $conf_ref, $name );
    }

    #$tab_editor->async->select_new_on_top ( $new_on_top_editor->id, $tab_ref, $hash_ref );
    my ( $absolute_path, $file_name, $relative_path, $full_absolute, $full_relative, $name )
            = $new_on_top_editor->file_name;



    # Mieux vaut afficher le changement de Tab de façon synchrone avec le changement d'éditeur... donc faire travailler
    # un peu plus longtemps le thread 0 (la tâche n'est pas lourde et, de toutes façons, le thread 0 est impliqué plusieurs fois :
    # déselection, sélection, ...)
    
    # Ancien appel asynchrone
            #$tab_editor->async->select_new_on_top ( $new_on_top_editor->id, $tab_ref, $hash_ref, 
            #    $absolute_path, $file_name, $relative_path, $full_absolute, $full_relative, $name );
    # Nouvel appel asynchrone
    select_new_on_top_thread_0 ( $tab_editor, $new_on_top_editor, $hash_ref, 
        $absolute_path, $file_name, $relative_path, $full_absolute, $full_relative, $name );

    return $name;
}

sub motion_over_tab {
    my ( $editor, $hash_ref ) = @_;

    #print "Dans motion_over_tab $editor|", $hash_ref->{'line'}, "|\n";
  # Vérification que l'on est bien sur la première ligne
    return if ( anything_for_me() );

    $editor->async->make_visible;

    return if ( anything_for_me() );
    
    my $first_line = $editor->first;
    if ( ! $first_line ) {
        print STDERR "Problème grave avec l'éditeur $editor : ", $editor->name, "\n";
        return;
    }
    
    my $pointed_line = $hash_ref->{'line'};
    return if ( $first_line != $pointed_line );

    my $pos = $hash_ref->{'pos'};

    return if ( anything_for_me() );
    my $info_ref = $editor->load_info;
    return if ( anything_for_me() );
    my $file_list_ref = $info_ref->{'file_list'};

    my $file_ref;
    my $current_left  = 0;
    my $current_right = 0;
    my $name;
    my $selected = 0;
  FILE: for my $file_conf_ref ( @{$file_list_ref} ) {
        $name = $file_conf_ref->{'name'};
        my $length = length($name);
        $current_right += $length;
        if ( $pos >= $current_left and $pos <= $current_right ) {

            #print "POS $pos|$name| left $current_left, right $current_right\n";
            $file_ref = $file_conf_ref;
            last FILE;
        }
        return if ( anything_for_me() );
        $current_left  += $length + 1;
        $current_right += 1;
        $selected += 1;
    }
    return if ( anything_for_me() );
    return if ( $selected > scalar ( @{$file_list_ref} ) - 1 );
    if ( !defined $file_ref or ref $file_ref ne 'HASH' ) {
        # Bug à voir
        $file_ref = {};
    }

    #print "FILE _ref |$name|$file_ref->{'file'}\n";
    new_on_top ( $name, $file_ref, 'focus' );
    $info_ref->{'selected'} = $selected;
    my $zone_ref = $file_ref->{'zone'};
    if ( ref $zone_ref ) {
        $file_ref->{'zone'} = $zone_ref->{'name'};
    }
    $editor->save_info( $info_ref );
}

sub new_on_top {
    my ( $name, $file_ref, $focus ) = @_;
    
    #print "Dans new_on_top : $name |", threads->tid, "|\n";
    my $new_on_top = Text::Editor::Easy->whose_name($name);
    if ( !$new_on_top ) {

   # L'éditeur n'existe pas on le crée à la volée
   #print "Création d'un éditeur par motion sur tab : ", dump ($file_ref), "\n";
        return if ( !$file_ref->{'zone'} );
        $file_ref->{'focus'} = 'yes';
        #$new_on_top = Text::Editor::Easy->new($file_ref);

# Appel asynchrone obligatoire : la création d'un éditeur peut obliger le thread 0 à appeler le thread motion
# de façon synchrone si des évènements sont "à référencer de façon asynchrone"
# ==> et en cas d'appel synchrone ici, on aurait un deadlock : 3 en attente de 0, lui-même en attente de 3
        #print "Dans motion over tab : un nouvel éditeur va être créé\n";
        Text::Editor::Easy::Async->new($file_ref);
    }
    else {

#$new_on_top->focus;
        #$new_on_top->async->focus;
        if ( $focus ) {
            $new_on_top->async->focus;
        }
        else {
            $new_on_top->async->at_top;
        }
    }
}

sub on_editor_destroy {
    my ( $zone, $hash_ref, $tab_ref ) = @_;

    my $destroyed = $hash_ref->{'name'};
    
    my $tab_editor = Text::Editor::Easy->get_from_id( $tab_ref );
    my $info_ref      = $tab_editor->load_info;
    my $file_list_ref = $info_ref->{'file_list'};
    my $selected = $info_ref->{'selected'};
    my $indice = 0;
    my $found;
    my $tab_line;
    my @new_file_list;
    
    FILE: for my $file_conf_ref ( @{$file_list_ref} ) {
        my $name = $file_conf_ref->{'name'};
        if (  $name eq $destroyed ) {
            $found = $indice;
            next FILE;
        }
        push @new_file_list, $file_conf_ref;
        $indice += 1;
        $tab_line .= $name . ' ';
    }
    $info_ref->{'file_list'} = \@new_file_list;
    $tab_editor->save_info($info_ref);
    $tab_editor->first->set($tab_line);
    $tab_editor->deselect;

    if ( defined $found and $selected == $found ) {
        if ( $found ) {
            $indice = $found - 1;
        }
        elsif ( $found <= $indice ) {
            $indice = $found;
        }
        else {
            return;
        }
    }
    else {
        if ( defined $found and $found< $selected ) {
            $indice = $selected - 1;
        }
        else {
            $indice = $selected;
        }
    }
    new_on_top ( $new_file_list[$indice]->{'name'}, $new_file_list[$indice] );
}

sub select_new_on_top_thread_0 {
    my ( $tab_editor, $new_on_top, $hash_ref, $absolute_path, $file_name, $relative_path, $full_absolute, $full_relative, $name ) = @_;
    
    my $info_ref = $tab_editor->load_info;
    my $file_list_ref = $info_ref->{'file_list'};
    my ( $text, $indice, $start, $end ) = search_position ( $file_list_ref, $name );
    #print "Dans select_new_on_top_thread_0 : texte = $text, indice = $indice, start = $start, end = $end\n";
    #print "DUMP\n", dump ($file_list_ref), "FIN DUMP\n";
    my $first = $tab_editor->first;

    $tab_editor->deselect;

    if ( defined $indice ) {
        if ( ! defined $first ) { # En principe impossible...
            $tab_editor->insert( $text );
        }
        elsif ( $first->text ne $text ) {
            $first->set($text);
        }
        $first->select($start, $end, $info_ref->{'color'});
        $info_ref->{'selected'} = $indice;
    }
    else {
        $start = length ( $text );
        $text .= $name . ' ';
        $end =  length ( $text ) - 1;
        $first->set($text);
        $first->select($start, $end, $info_ref->{'color'});
        $hash_ref->{'relative_path'} = $relative_path;
        $hash_ref->{'absolute_path'} = $absolute_path;
        $hash_ref->{'full_relative'} = $full_relative;
        $hash_ref->{'full_absolute'} = $full_absolute;
        $hash_ref->{'file'} = $full_relative if ( defined $full_relative );
        $hash_ref->{'name'} = $name;
        my $zone_ref = $hash_ref->{'zone'};
        if ( ref $zone_ref ) {
            $hash_ref->{'zone'} = $zone_ref->{'name'};
        }        
        #print "Dans select_new_on_top : Ajout d'un nouvel éditeur : zone => ", $hash_ref->{'zone'}, "\n";
        #print "Avant sauvegarder par save_info, highlight = \n", dump ( $hash_ref->{'highlight'} ),
        #    "\nEVENTS = \n", dump ( $hash_ref->{'events'} ), "\n";
        push @$file_list_ref, $hash_ref;
        
        $info_ref->{'selected'} = scalar (@$file_list_ref) - 1;
    }
    #print "DUMP\n", dump ($file_list_ref), "FIN DUMP\n";
    #print "DUMP\n", dump ($info_ref), "FIN DUMP\n";
    $info_ref->{'file_list'} = $file_list_ref;
    $tab_editor->save_info($info_ref);
}


# "update_conf" et "select_new_on_top" sont exécutées par le thread 'File_manager' de l'object Text::Editor::Easy correspondant au Tab
sub update_conf {
    my ( $self, $ref_old_on_top_editor, $conf_ref, $old_name ) = @_;
    
    my $old_editor = Text::Editor::Easy->get_from_id( $ref_old_on_top_editor );
    
    # Text::Editor::Easy::Program::Tab n'a pas été "évalué" par File_manager => il faudrait gérer l'évaluation automatique dans Comm...
    
    $conf_ref->{'first_line_number'} =  get_from_other_thread ( $old_editor, $conf_ref->{'first_line_ref'} );
    $conf_ref->{'cursor_line_number'} = get_from_other_thread ( $old_editor,  $conf_ref->{'cursor_line_ref'} );
    
    my $info_old_editor_ref = $conf_ref;
    #print "Dans update_conf : récupéré info :\n",
    #    "\$info_old_editor_ref->{'first_line_ref'} = ", $info_old_editor_ref->{'first_line_ref'},
    #    "\n\$info_old_editor_ref->{'cursor_line_ref'} = ", $info_old_editor_ref->{'cursor_line_ref'}, "\n";
    my $load_info_ref = Text::Editor::Easy::File_manager::load_info( $self );
    #print "Load info de Tab = \n", dump( $load_info_ref ), "\n";
    my $file_list_ref = $load_info_ref->{'file_list'};
    my ( $text, $indice, $start, $end ) = search_position ( $file_list_ref, $old_name );
    #print "Dans update_conf : texte = $text, indice = $indice, start = $start, end = $end\n";
    if ( defined $indice ) {
        my $info_ref = $file_list_ref->[$indice];
        my ( $absolute_path, $file_name, $relative_path, $full_absolute, $full_relative, $name )
            = Text::Editor::Easy->data_file_name( $ref_old_on_top_editor );
        if ( defined $relative_path and ! defined $info_ref->{'relative_path'} ) {
            $info_ref->{'relative_path'} = $relative_path;
            $info_ref->{'absolute_path'} = $absolute_path;
            $info_ref->{'full_relative'} = $full_relative;
            $info_ref->{'full_absolute'} = $full_absolute;
            if ( defined $full_relative ) {
                $info_ref->{'file'} = $full_relative;
            }
            elsif ( defined $full_absolute ) {
                $info_ref->{'file'} = $full_absolute;
            }
            else {
                $info_ref->{'file'} = $file_name;
            }
        }
        $info_ref->{'config'} = $info_old_editor_ref;
        #print "Avant appel méthode zone\n";
        $info_ref->{'zone'} = $old_editor->zone;
    }
    return $load_info_ref;
}

sub get_from_other_thread {
   my ( $editor, $ref ) = @_;
   
   #print "Dans get_from_other_thread => REF = $ref\n";
   my $call_id = $editor->async->get_line_number_from_ref( $ref );
    while ( Text::Editor::Easy->async_status($call_id) ne 'ended' ) {
        if ( anything_for_me ) {
            have_task_done;
        }
    }
    return Text::Editor::Easy->async_response($call_id);
}

# N'est plus appelée : tâche effectuée directement par le thread 0
sub select_new_on_top {
    my ( $self, $ref_new_on_top, $tab_ref, $hash_ref, $absolute_path, $file_name, $relative_path, $full_absolute, $full_relative, $name ) = @_;
    
    my $info_ref = Text::Editor::Easy::File_manager::load_info( $self );
    my $file_list_ref = $info_ref->{'file_list'};
    my ( $text, $indice, $start, $end ) = search_position ( $file_list_ref, $name );
    my ( $first_ref, $first_text ) = Text::Editor::Easy::File_manager::next_line( $self );
    my $tab_editor = Text::Editor::Easy->get_from_id( $tab_ref );
    $tab_editor->async->deselect;

    if ( defined $indice ) {
        if ( ! $first_ref ) { # En principe impossible...
            $tab_editor->async->insert( $first_text );
        }
        elsif ( $first_text ne $text ) {
            $tab_editor->async->line_set($first_ref, $text);
        }
        $tab_editor->async->line_select($first_ref, $start, $end, $info_ref->{'color'});
        return $name;
    }
    else {
        $start = length ( $text );
        $text .= $name . ' ';
        $end =  length ( $text ) - 1;
        $tab_editor->async->line_set($first_ref, $text);
        $tab_editor->async->line_select($first_ref, $start, $end, $info_ref->{'color'});
        $hash_ref->{'relative_path'} = $relative_path;
        $hash_ref->{'absolute_path'} = $absolute_path;
        $hash_ref->{'full_relative'} = $full_relative;
        $hash_ref->{'full_absolute'} = $full_absolute;
        $hash_ref->{'file'} = $full_relative || $full_absolute;
        $hash_ref->{'name'} = $name;
        push @$file_list_ref, $hash_ref;
        #print "Dans select_new_on_top : Ajout d'un nouvel éditeur : zone => ", $hash_ref->{'zone'}, "\n";
        my $zone_ref = $hash_ref->{'zone'};
        if ( ref $zone_ref ) {
            $hash_ref->{'zone'} = $zone_ref->{'name'};
        }
        $info_ref->{'selected'} = scalar (@$file_list_ref) - 1;
    }
}

sub search_position {
    my ( $file_list_ref, $name_to_find ) = @_;

    my $indice = 0;
    my $start  = 0;
    my $end;
    my @found;
    my $tab_line = "";
  FILE: for my $file_conf_ref ( @{$file_list_ref} ) {
        $indice += 1 if ( ! @found );
        my $name = $file_conf_ref->{'name'};
        $end += length($name);
        $tab_line .= $name . ' ';
        if ( $name eq $name_to_find ) {
            #print "Dans search position : trouvé $name en position $indice, de $start à $end\n";
            @found = ( $start, $end );

            #last FILE;
        }
        $start += length( $name ) + 1;
        $end   += 1;
    }
    if ( wantarray ) {
        if ( @found ) {
            return ( $tab_line, $indice - 1, @found );
        }
        else {
            return ( $tab_line );
        }
    }
    else {
        if ( @found ) {
            return $indice;
        }
        else {
            return;
        }
    }
}

sub save_conf {
    my ( $self, $file ) = @_;
    
    my $old_editor = Text::Editor::Easy::Zone->whose_name('zone1')->on_top_editor;
    my $conf_ref = $old_editor->on_focus_lost();
    update_conf( $self, $old_editor->id, $conf_ref, $old_editor->name );

    open (INFO, ">$file" ) or die "Impossible d'ouvrir $file : $!\n";
    print INFO dump Text::Editor::Easy::File_manager::load_info( $self );
    close INFO;
}

sub save_conf_thread_0 {
    my ( $self, $file ) = @_;
    
    #print "Dans save_conf_thread_0 : file = $file\n";
    my $old_editor = Text::Editor::Easy::Zone->whose_name('zone1')->on_top_editor;
    my $conf_ref = $old_editor->on_focus_lost();
    return Text::Editor::Easy->update_conf( $old_editor->id, $conf_ref, $old_editor->name );
}

sub get_conf_for_absolute_file_name {
    my ( $self, $absolute_file_name ) = @_;
    
    my $abs_slash = $absolute_file_name;
    $abs_slash =~ s{\\}{/}g;
    print "ABS SLASH = $abs_slash\n";

    my $abs_anti_slash = $absolute_file_name;
    $abs_anti_slash =~ s{/}{\\}g;
    print "ABS ANTI SLASH = $abs_anti_slash\n";

    my $file_list_ref = Text::Editor::Easy::File_manager::load_info( $self, 'file_list' );
    FILE: for my $file_conf_ref ( @$file_list_ref ) {
        print "UN ELEMENT : ", $file_conf_ref->{'file'}, "\n";
        my $full_absolute = $file_conf_ref->{'full_absolute'};
        if ( defined  $full_absolute ) {
             if ( $full_absolute eq $abs_slash or $full_absolute eq $abs_anti_slash ) {
                print "\tCorrespondance pour cet élément...\n";
                return $file_conf_ref;
            }
        }
        my $file = $file_conf_ref->{'file'};
        next if ( ! defined $file );
    }
    return;
}

sub nop {
   # Just to stop other potential useless processing
}

=head1 FUNCTIONS

=head2 new_on_top

=head2 motion_over_tab

=head2 on_editor_destroy

=head2 on_main_editor_change

=head2 on_top_editor_change

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;