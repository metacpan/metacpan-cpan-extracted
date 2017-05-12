package Text::Editor::Easy::File_manager;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::File_manager - Management of the data that is edited.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

=head1 SYNOPSIS

By complexity order, this module, I think, is the third.

If you create a "Text::Editor::Easy" object, this module will be called very often (but you don't even have to know 
that this module exists, thanks to "Text::Editor::Easy::Comm").

It manages "file" or "memory" data in a very lazy way. Too lazy for now. I'm going to ask more to this module
soon.

You can read data from the start of the file, from the bottom, from the middle, ... from where you want in fact.
I just use the "seek" instruction for that. You can read a line, its next or its previous.

This module is lazy because it doesn't read the file even once. I will change this to compute the line number and
put some references in order to access faster to a given line number (with an interuptible long task at start).

If you modify a line that is on a file, well it has to work (reluctantly !). It puts the line in memory and will never
fetch this line any more from the file.

When you save a modified file, it reads data from the initial file (for non-modified lines) or from memory 
(when modified), create a new file and when finished, move the new file to the initial.

There is a little drawback : you need more disk space than an Editor which would load everything into memory.
The big advantage is that this module don't waste time reading uninteresting data : it reads only on the file the
part you can see on the screen. Said like that, this seems obvious not to ask more to your computer. But most
Editors think it's useful to read everything (well, it's surely because most programmers don't want to manage the
complexity !). And when the file is huge, your entire system blocks. This seems stupid, because who is able
to watch several Go of text data in a single day ? Well, I should say in a single year : but, nowadays, with 
cheap hard drives, most people don't know any more what can contain 1 Go of text data.

=cut

use Text::Editor::Easy::Comm;

use Scalar::Util qw(refaddr);
use Data::Dump qw(dump);
use Devel::Size qw(size total_size);

Text::Editor::Easy::Comm::manage_debug_file( __PACKAGE__, *DBG );

my $one_more_line;

use constant {
    FILE_DESC    => 0, # Descripteur de fichier, rattaché à un segment container
    LINE_TO_SEEK => 1,
    SEEK_TO_LINE => 2,
    MODIFIED     => 3, # A supprimer
    WHO          => 4,
    REF          => 5, # Garde le numéro de la dernière référence donnée
    PARENT => 6,
    , # Associe un simple entier à une référence de tableau correspondant à la ligne
    ROOT        => 7,
    NO_CREATION => 8,    # Si true, pas de création de lignes
    DESC        => 9
    , # Sauvegarde des lignes en cours de lecture par la procédure read_next (sauvegarde
     # par thread, identique à un DESCripteur de fichier noyau : ligne, segments précédent et suivant)
    UNDO        => 10,
    LAST_UPDATE => 11,
    GROWING     => 12,
    TO_DELETE   => 13,
    SAVED_INFO  => 14,
    ID          => 15,
    HASH_REF     => 16,
    LAST_MODIF => 17,
    
    UNTIL => 0, # Mémorisation de l'appel initial à until (procédure read_until)
                # On mémorise ici la référence  ne pas dépasser

    # Lignes de fichier
    SEEK_START => 1,
    SEEK_END   => 2,
    NEXT       => 3,
    PREVIOUS   => 4,

    # REF => 5,
    #PARENT      => 6,
    TYPE        => 7,    # "container", "empty", "line", "break"
    FIRST       => 8,
    LAST        => 9,
    TEXT        => 10,
    DIRTY       => 11,
    FILE_NAME   => 12,
    LINE_NUMBER => 13,
    PSEUDO_SEEK_START => 14,
    INFO => 15,

    # Gestion de LINE_NUMBER
    LAST_COMPUTE => 0,
    NUMBER       => 1,
};

sub init_file_manager {

    #my ( $editor, $file_name, $growing_file, $save_info ) = @_;
    my ( $file_manager_ref, $reference, $id, $file_name, $growing_file, $save_info, $bloc )
      = @_;

    #print "Dans init_file_manager tid ", threads-> tid, " $file_manager_ref|$reference|$id|$file_name\n";
    #print DBG "Dans init_file_manager tid ", threads-> tid, " $file_manager_ref|$reference|$id|$file_name\n";

    $file_manager_ref->[ID]  = $id;
    $file_manager_ref->[PARENT] = Text::Editor::Easy->get_from_id ($id );

    print DBG "File_manager de l'instance $id";
    my $name = Text::Editor::Easy->data_name($id);
    if ( defined $name ) {
        print DBG " ($name)";
    }
    print DBG "\n";

    my $file_desc;

    #my $file_manager_ref;

    my $segment_ref;    # Segment père de tous les segments

    if ($file_name) {
        $segment_ref->[FILE_NAME] = $file_name;
        if ( open( $file_desc, $file_name ) ) {
            # Le fichier existe
            $segment_ref->[SEEK_START] = 0;
            my $seek_end = ( stat $file_desc )[7];
            $segment_ref->[SEEK_END]       = $seek_end;
            $segment_ref->[FILE_DESC]      = $file_desc;
            $file_manager_ref->[FILE_DESC] = $file_desc;
            $file_manager_ref->[SEEK_END]  = $seek_end;
            $file_manager_ref->[LAST_MODIF] = ( stat $file_desc )[9];
            print "LAST MODIF = ", $file_manager_ref->[LAST_MODIF], "\n";
        }
        else {
            #print STDERR "From thread file_manager with tid ", threads->tid, " : can't open file $file_name : $!\n";
            $file_name =~ s{\\}{\/}g;
            if ( open( $file_desc, $file_name ) ) {

                # Le fichier existe
                $segment_ref->[SEEK_START] = 0;
                my $seek_end = ( stat $file_desc )[7];
                $segment_ref->[SEEK_END]       = $seek_end;
                $segment_ref->[FILE_DESC]      = $file_desc;
                $file_manager_ref->[FILE_DESC] = $file_desc;
                $file_manager_ref->[SEEK_END]  = $seek_end;
                $file_manager_ref->[LAST_MODIF] = ( stat $file_desc )[9];
            }
            else {
                print STDERR "From thread file_manager with tid ", threads->tid, " : can't open file $file_name : $!\n";
                $segment_ref->[SEEK_END]      = 0;
                $segment_ref->[SEEK_START]    = 0;
                $file_manager_ref->[SEEK_END] = 0;
            }
        }
    }
    $segment_ref->[TYPE] = "container";

    $file_manager_ref->[ROOT] = $segment_ref;
    if ( defined $save_info ) {

        #    print "Save info = " dump ($save_info), "\n";
        $file_manager_ref->[SAVED_INFO] = $save_info;
    }

    $file_manager_ref->[LAST_UPDATE] = 1;
    if ( defined $growing_file ) {
        $file_manager_ref->[GROWING] = $growing_file;
        $file_manager_ref->[PARENT]->async->set_at_end;
        $file_manager_ref->[PARENT]->async->repeat_instance_method(1, "growing_update");
    }
    else {    #Avoid warnings
        $file_manager_ref->[GROWING] = 0;
    }

    if ( defined $bloc ) {
        insert_bloc( $file_manager_ref, $bloc );
    }

    return $file_manager_ref;
}

sub growing_update {
    my ( $self ) = @_;
    
    return if ( ! $self->[GROWING] );

    my $segment_ref = $self->[ROOT];
    my $file_name = $segment_ref->[FILE_NAME];
    my $old_size = $segment_ref->[SEEK_END];
    
    if ( ! defined $file_name ) {
        print STDERR "File name is undefined : this is forbidden for a growing file\n";
        return;
    }
    my $actual_size =   ( stat ($file_name ) )[7] || ( stat ($segment_ref->[FILE_DESC] ) )[7];

    if ( ! defined $actual_size )  {
        print STDERR "Actual size undefined... can't update growing file\n";
        print DBG "SEGMENT_FILE_DESC : $segment_ref->[FILE_DESC]\n";
        return;
    }
    print DBG "Dans update_growing : taille actuelle $actual_size, ancienne : $old_size\n";
    
    if ( $actual_size != $old_size ) {
        if ( defined $segment_ref->[FILE_DESC] ) {
            CORE::close $segment_ref->[FILE_DESC];
        }
        open( $segment_ref->[FILE_DESC], $file_name );
        $self->[FILE_DESC] = $segment_ref->[FILE_DESC];
        
        my $last_ref = $segment_ref->[LAST];
        if ( defined $last_ref and $last_ref->[SEEK_END] == $old_size ) {
            seek $segment_ref->[FILE_DESC], $last_ref->[SEEK_START], 0;
            my $text = readline( $segment_ref->[FILE_DESC] );
            my $end_line = tell $segment_ref->[FILE_DESC];
            if ( chomp $text ) {
                $one_more_line = $end_line;
            }
            $last_ref->[TEXT] = $text;
            $last_ref->[SEEK_END] = $end_line;
        }

        $segment_ref->[SEEK_END] = $actual_size;
        print DBG "Appel à growing_check, nouvelle taille $actual_size\n";
        $self->[PARENT]->async->growing_check( $actual_size - $old_size, $actual_size );
    }
}

sub display {
    my ($self) = @_;

    print dump($self);
    return;
}

sub new_line {
    my ( $self, $ref, $where, $text ) = @_;

    $self->[DIRTY] = 1;
    $self->[LAST_UPDATE] += 1;

    my $line_ref = $self->[HASH_REF]{$ref};

    my $new_line_ref;
    $new_line_ref->[TEXT] = $text;
    my $new_ref = get_next_ref($self);
    $new_line_ref->[REF]        = $new_ref;
    $new_line_ref->[PARENT]     = $line_ref->[PARENT];
    $new_line_ref->[TYPE]       = 'line';
    $self->[HASH_REF]{$new_ref} = $new_line_ref;

    if ( $where eq "after" ) {
        $new_line_ref->[SEEK_START] = $line_ref->[SEEK_END];
        $new_line_ref->[SEEK_END]   = $line_ref->[SEEK_END];
        $new_line_ref->[PREVIOUS]   = $line_ref;
        $new_line_ref->[NEXT]       = $line_ref->[NEXT];
        $line_ref->[NEXT]           = $new_line_ref;
        if ( $new_line_ref->[NEXT] ) {
            $new_line_ref->[NEXT][PREVIOUS] = $new_line_ref;
        }
        if ( $line_ref->[PARENT][LAST] == $line_ref ) {
            $line_ref->[PARENT][LAST] = $new_line_ref;
        }
    }
    else {    # $where eq "before"
        $new_line_ref->[SEEK_START] = $line_ref->[SEEK_START];
        $new_line_ref->[SEEK_END]   = $line_ref->[SEEK_START];
        $new_line_ref->[NEXT]       = $line_ref;
        $new_line_ref->[PREVIOUS]   = $line_ref->[PREVIOUS];
        $line_ref->[PREVIOUS]       = $new_line_ref;

        #print "REF de new_line_ref $new_ref, NEXT = $line_ref->[NEXT][REF]\n";
        if ( $new_line_ref->[PREVIOUS] ) {
            $new_line_ref->[PREVIOUS][NEXT] = $new_line_ref;
        }
        if ( $line_ref->[PARENT][FIRST] == $line_ref ) {
            $line_ref->[PARENT][FIRST] = $new_line_ref;
        }
    }
    return $new_ref;
}

sub modify_line {
    my ( $self, $ref, $text ) = @_;

    $self->[DIRTY] = 1;

    my $line_ref = $self->[HASH_REF]{$ref};
    return if ( !defined $line_ref );
    $line_ref->[TEXT] = $text;    # Valeur de retour, texte forcé
}

sub delete_line {
    my ( $self, $ref ) = @_;


    #print "Dans delete_line REF = $ref\n";
    $self->[DIRTY] = 1;
    $self->[LAST_UPDATE] += 1;

    # Travail sale, on met à "empty" le segment de ligne correspondant
    # Il faudrait éventuellement concaténer avec un autre segment empty contigü
    # et aussi modifier le nombre de lignes résultant du segment PARENT...
    my $line_ref = $self->[HASH_REF]{$ref};
    $line_ref->[TYPE] = "empty";
    delete $self->[HASH_REF]{$ref};
    print "Fin de la suppression de REF = $ref\n";
}

sub read_until {
    my ( $self, $who, $ref ) = @_;

    my $line_ref;
    if ( !$self->[DESC]{$who} or $ref ) {

        #print "Premier accès pour read_until who = $who\n";
        if ( !$ref ) {
            print STDERR
              "Appel incorrect à read_until : position perdue sans référence\n";
        }
        $line_ref = $self->[HASH_REF]{$ref};
        $self->[DESC]{$who}[REF] = $line_ref;
    }
    if ($ref) {
        $self->[DESC]{$who}[UNTIL] = $ref;
    }
    $ref = $self->[DESC]{$who}[UNTIL];

    $line_ref = read_line_ref( $self, $who );
    if ( !$line_ref ) {    # On est à la fin du fichier
        $line_ref =
          read_line_ref( $self, $who )
          ; # Nouvelle lecture et recréation de $self->[DESC]{$who} par read_line_ref
        $self->[DESC]{$who}[UNTIL] = $ref;
    }
    if ( $line_ref->[REF] and $line_ref->[REF] == $self->[DESC]{$who}[UNTIL] ) {

        # "Démémorisation"
        init_read( $self, $who );

        #undef $self->[DESC]{$who};
        return;    # Fin du read_until
    }
    return $line_ref->[TEXT];
}

sub read_until2 {
    my ( $self, $who, $options_ref ) = @_;

    my $line_ref;
    if ( !$self->[DESC]{$who} or $options_ref->{'line_start'} ) {
        my $start_ref = $options_ref->{'line_start'};
        if ( defined $start_ref ) {
            $line_ref = read_line_ref( $self, $who, $start_ref );
        }
        else {
            $line_ref = read_line_ref( $self, $who );
        }
    }
    else {
        $line_ref = read_line_ref( $self, $who );
    }
    if ( !$line_ref ) {    # On est à la fin du fichier
        $line_ref = read_line_ref( $self, $who );
    }
    if ( !$line_ref ) {
            return; #A la fin du fichier
    }
    my $stop_ref = $options_ref->{'line_stop'};
    if ( $line_ref->[REF] and $stop_ref and $line_ref->[REF] == $stop_ref ) {

        # "Démémorisation"
        init_read( $self, $who );

        #undef $self->[DESC]{$who};
        return;                  # Fin du read_until
    }
    return $line_ref->[TEXT];
}

sub create_ref_current {
    my ( $self, $who ) = @_;

    my $line_ref = $self->[DESC]{$who}[REF];
    my $ref      = $line_ref->[REF];
    if ( !$line_ref->[REF] ) {
        $ref = save_line( $self, $line_ref );
    }
    return $ref;
}

sub save_line_number {
    my ( $self, $who, $ref, $line_number ) = @_;

    #my ( $self, $ref, $line_number ) = @_;

    my $line_ref = $self->[DESC]{$who}[REF];
     $line_ref->[LINE_NUMBER][LAST_COMPUTE] = $self->[LAST_UPDATE];
    $line_ref->[LINE_NUMBER][NUMBER]       = $line_number;
    return;
}

sub prev_line {
    my ( $parent_ref, $pos, $line_ref ) = @_;

    print DBG "Début de prev_line $pos\n";
    my $file_desc = $line_ref->[PARENT][FILE_DESC];
    if ( ! $file_desc ) {

        # Pas de fichier connu, donc on est au début du fichier
        return ( 0, "" );
    }
    
    if ( ref $file_desc eq 'ARRAY' ) {
        return ( $pos - 1, $file_desc->[$pos - 1] );
    }
    
    seek $parent_ref->[FILE_DESC], $pos, 0;
    my $end_position = tell $parent_ref->[FILE_DESC];
    return ( 0, "" ) if ( !$end_position );    # On est au début du fichier

    print DBG "position > 0\n";
    my $decrement = 0;

    # But de la boucle, être sûr de lire une ligne entière
  SEEK: while ( tell $parent_ref->[FILE_DESC] == $end_position ) {
        $decrement += 50;
        print DBG "Decrement $decrement\n";
        if ( $decrement < $pos ) {
            seek $parent_ref->[FILE_DESC], $pos - $decrement, 0;
            readline $parent_ref->[FILE_DESC];
        }
        else {
            print DBG "Positionnement au début du fichier\n";
            seek $parent_ref->[FILE_DESC], 0, 0;
            my $start_position = 0;
            while ( tell $parent_ref->[FILE_DESC] != $end_position ) {
                $start_position = tell $parent_ref->[FILE_DESC];
                readline $parent_ref->[FILE_DESC];
            }
            seek $parent_ref->[FILE_DESC], $start_position, 0;
            last SEEK;
        }
    }

    print DBG "Après première boucle : ", tell $parent_ref->[FILE_DESC], "\n";
    my $text;
    while ( tell $parent_ref->[FILE_DESC] != $end_position ) {
        $pos = tell $parent_ref->[FILE_DESC];

        print DBG "pos A = $pos\n";
        $text = readline $parent_ref->[FILE_DESC];

        my $last_position = tell  $parent_ref->[FILE_DESC];
        #print DBG "POS B = $last_position | texte = $text\n";
        if ( $last_position > $end_position ) {
            print DBG "On est à la fin d'un fichier qui grossit continuellement (growing file) sans retour charriot\n";
            # Il faut sortir et mettre à jour la taille de tous les segments parents à cette ligne (SEEK_END)
            $line_ref->[SEEK_END] = $last_position;
            $parent_ref->[SEEK_END] = $last_position;
            while ( $parent_ref->[PARENT] ) {
                $parent_ref = $parent_ref->[PARENT];
                $parent_ref->[SEEK_END] = $last_position;
            }
            #$self->[ROOT][SEEK_END] = $last_position;
            last;
        }
    }

    print DBG "Fin de prev_line $pos |$text| $end_position\n";
    
    #
    if ( ! chomp $text ) {
        return ( $pos, $text );
    }
    if ( $parent_ref->[SEEK_END] != $end_position ) {
        return ( $pos, $text );
        #my $line_ref;        
    }
    if ( $line_ref->[NEXT] ) {
        return ( $pos, $text );
    }
    print DBG "Il faut créer une ligne vide supplémentaire (fin de fichier)\n";
    
    
    my $prev_line_ref;
    
    # Pour le cas où $parent_ref aurait été modifié
    $parent_ref = $line_ref->[PARENT];
    
    $prev_line_ref->[PARENT] = $parent_ref;
    $prev_line_ref->[PREVIOUS] = $line_ref->[PREVIOUS];
    $line_ref->[PREVIOUS] = $prev_line_ref;
    $prev_line_ref->[TEXT] = $text;
    $prev_line_ref->[NEXT] = $line_ref;
    
    # Vrai mais déjà effectué en dehors
    #$parent_ref->[LAST] = $line_ref;
    if ( ! defined $parent_ref->[FIRST] ) {
        $parent_ref->[FIRST] = $prev_line_ref;
    }

    $prev_line_ref->[SEEK_END] = $end_position;
    $prev_line_ref->[SEEK_START] = $pos;
    
    # Vrai mais effectué en dehors
    #$line_ref->[SEEK_END] = $end_position;
    #$line_ref->[SEEK_START] = $end_position;
    
    $prev_line_ref->[TYPE] = 'line';
    
    return ( $end_position, '' );
}

sub line_text {
    my ( $self, $ref ) = @_;

    my $line_ref = $self->[HASH_REF]{$ref};
    return if ( !defined $line_ref );
    my ( undef, $text ) = get_ref_and_text_from_line_ref($line_ref);

    return $text;
}

sub query_segments {
    my ($self) = @_;

    for my $ref ( sort { $a <=> $b } keys %{ $self->[HASH_REF] } ) {
        my $line_ref = $self->[HASH_REF]{$ref};
        print
"$ref:$line_ref->[TYPE]:$line_ref->[SEEK_START]:$line_ref->[SEEK_END]:$line_ref->[TEXT]:\n";
    }
}

sub close {
    my ($self) = @_;

    CORE::close $self->[ROOT][FILE_DESC];
}

my @reports;

sub save_internal {

# Cette fonction est bloquante : à réécrire : sauvegarde rapide la structure, puis création d'un thread de sauvegarde avec doublage
# des saisies dans un tampon, rattrapage du tampon sur la nouvelle structure après la fin de la sauvegarde puis bascule sur la nouvelle structure
    my ( $self, $file_name ) = @_;
    
    my $time_start = time;
    print DBG "Début save internal : absolute time start $time_start, soit ", scalar(localtime($time_start)), "\n";
    
    my $test_last_modif = 1;
    
    if ( ! $file_name ) {
        if ( ! $self->[ROOT][FILE_NAME] ) {
            return if ( $self->[PARENT]->name eq 'eval*' );
            print STDERR "Can't save file : no file name has been given\n";
            return;
        }
        $file_name = $self->[ROOT][FILE_NAME];
    }
    else {
        $test_last_modif = 0;
    }

    my $report_file_name = $file_name;
    if ( ! defined $report_file_name ) {
        $report_file_name = 'thread__' . threads->tid;
    }
    $report_file_name =~ s/\\/__/g;
    $report_file_name =~ s/\//__/g;
    $report_file_name =~ s/:/_/g;
    my $report = "tmp/Save_report_of__${report_file_name}__" . time . ".trc";
    my $size_before = $self->[ROOT][SEEK_END] || 0;
    
    print DBG "Dans save_internal : création d'un rapport $report\n";

    # Ugly code to keep just a unique file handle to write in 2 separate files :
    #  ==> heavy traces to track the bugs that occur when saving, but only when there is a problem
    # (Save_reports are removed after each save when everything was OK, but not the general trace file)

    my $tied = tied *DBG;
    my $save_report = $Text::Editor::Easy::Trace{'save_report'};
    my $trace_all = $Text::Editor::Easy::Trace{'all'};

    if ( $save_report or $trace_all ) {
        tie *DBG, "Text::Editor::Easy::File_manager::Save_report", ($report);
        print DBG "Sauvegarde de $report_file_name\n";
        print DBG "Taille initiale : $size_before\n";
    }
    my $last_modif = (stat($file_name))[9];
    if ( $test_last_modif ) {
        if ( defined $self->[LAST_MODIF] and defined $last_modif and $self->[LAST_MODIF] != $last_modif ) {
            print DBG "\n\nDANGER : LAST_MODIF = $self->[LAST_MODIF], last modif stat file_name = $last_modif\n\n\n";
            print "\n\nDANGER : LAST_MODIF = $self->[LAST_MODIF], last modif stat file_name = $last_modif\n\n\n";
            if ( compare_ko( $self, $file_name ) ) {
                print "==>force to quit during save of file $file_name, done by thread ", threads->tid, "\n";
                Text::Editor::Easy->exit(1);
            }
            else {
                print "Fausse alerte, mise à jour de LAST_MODIF\n";
                $self->[LAST_MODIF] = $last_modif;
            }
        }
        elsif (defined $last_modif ){
            print DBG "LAst modif = $last_modif : ", scalar(localtime($last_modif)), "\n";
        }
    }

    my ( $errors_in_dump, $total_refs ) = dump_file_manager ( $self );

    return if ( !$self->[DIRTY] );    # Rien n'a été modifié, sauvegarde inutile

    my $temp_file_name = $file_name . "_tmp_";
    my $new_root_ref;    # Future arborescence (références récupérées)
    $new_root_ref->[SEEK_START] = 0;
    my $new_file_desc;
    open( $new_file_desc, ">$temp_file_name" )
      or die "Impossible d'ouvrir $temp_file_name : $!\n";
    $new_root_ref->[FILE_DESC] = $new_file_desc;
    $new_root_ref->[FILE_NAME] = $self->[ROOT][FILE_NAME];
    $new_root_ref->[TYPE]      = "container";
    my %hash;

    my $previous_line_ref;
    while ( my $line_ref = read_line_ref($self) ) {
        if ($previous_line_ref) {
            print DBG "Dans save : écriture d'un \\n\n";
            print {$new_file_desc} "\n";
            if ( $previous_line_ref->[REF] ) {
                $previous_line_ref->[SEEK_END] = tell $new_file_desc;
            }
        }

        my $ref = $line_ref->[REF];
        if ( $ref ) {

# Duplication de la ligne pour ne pas modifier la vraie ligne (SEEK_END, SEEK_START...)
            #my @new_line     = @{$line_ref};
            my $new_line_ref; # = \@new_line;
            $new_line_ref->[TEXT] = $line_ref->[TEXT];
            $new_line_ref->[TYPE] = 'line';
            $new_line_ref->[REF] = $ref;

            $new_line_ref->[SEEK_START] = tell $new_file_desc;
            $new_line_ref->[PARENT]     = $new_root_ref;
            if ( $new_root_ref->[LAST] ) {
                $new_root_ref->[LAST][NEXT] = $new_line_ref;
                $new_line_ref->[PREVIOUS]   = $new_root_ref->[LAST];
                $new_root_ref->[LAST]       = $new_line_ref;
            }
            else {
                $new_root_ref->[FIRST] = $new_line_ref;
                $new_root_ref->[LAST]  = $new_line_ref;
            }
            print $new_file_desc $new_line_ref->[TEXT];
            print DBG "Dans save : écriture de $line_ref (réf. ", $line_ref->[REF], ")---", $new_line_ref->[TEXT], "---\n";
            $previous_line_ref = $new_line_ref;
            $hash{ $ref } = $new_line_ref;
        }
        else {
            print $new_file_desc $line_ref->[TEXT];
            print DBG "Dans save : écriture de ---", $line_ref->[TEXT], "---\n";
            $previous_line_ref = $line_ref;
        }
    }
    my $new_size = tell $new_file_desc;
    if ( $previous_line_ref and $previous_line_ref->[REF] ) {
        $previous_line_ref->[SEEK_END] = $new_size;
    }
    print DBG "\n\n\nDans save : taille du nouveau fichier $new_size\n";
    $new_root_ref->[SEEK_END] = $new_size;

    if ( $self->[ROOT][FILE_DESC] ) {
        CORE::close $self->[ROOT][FILE_DESC];
    }
    CORE::close $new_file_desc;    # Vérification avec diff
    use File::Copy;
    my $OK = move( $temp_file_name, $file_name );
    if ( ! $OK ) {
        print STDERR "Can't move file $temp_file_name to $file_name : $!\nSave processs aborted\n";
        print DBG "Can't move file $temp_file_name to $file_name : $!\nSave processs aborted\n";
        open( $new_file_desc, $file_name )  or die "Impossible d'ouvrir $file_name : $!\n";
    }
    else {
        open( $new_file_desc, $file_name )  or die "Impossible d'ouvrir $file_name : $!\n";
        # Ménage à faire (supprimer l'arborescence $self->[ROOT] et [HASH_REF]
        $self->[ROOT]            = $new_root_ref;
        $self->[ROOT][FILE_DESC] = $new_file_desc;
        $self->[HASH_REF]        = \%hash;
        $last_modif = (stat($new_file_desc))[9];
        $self->[LAST_MODIF] = $last_modif;
        if ( defined $last_modif ) {
            print DBG "LAst modif = $last_modif : ", scalar(localtime($last_modif)), "\n";
        }
        else {
            print DBG "\n\n LAST MODIF NON DEFINI !!!\n";
        }
        $self->[ROOT][FILE_NAME] = $file_name;
    }
    $one_more_line = 0;
    
    my ( $new_errors_in_dump, $new_total_refs ) = dump_file_manager ( $self );

    $errors_in_dump += $new_errors_in_dump;

    if ( $save_report or $trace_all ) {
        print DBG "\n\nNouvelle taille : $new_root_ref->[SEEK_END]\n";
        print DBG "$errors_in_dump erreur(s) pour les 2 dumps...\n";
        print DBG "Lignes référencées passées de $total_refs à $new_total_refs\n";
        CORE::close( DBG );
        untie *DBG;
        if ( $new_total_refs < $total_refs ) {
            print STDERR "Referenced lines have disappeared !!!\n\t==> force exit...\n";
            Text::Editor::Easy->exit(1);
        }
        if ( $new_root_ref->[SEEK_END] >= $size_before ) {
            if ( ! defined $save_report or $save_report ne 'keep' ) {
                if ( $OK ) {
                    push @reports, $report;
                    if ( scalar(@reports) > 5 ) {
                        my $to_delete = shift @reports;
                        unlink $to_delete;
                    }
                }
            }
        }        
    }
    if ( $tied ) {
        #print "Réaffectation de null à DBG\n";
        *DBG = $tied;
        #print DBG "Ne doit rien écrire\n";
    }
    my $time_stop = time;
    print DBG "Fin save internal : absolute time stop $time_stop, soit ", scalar(localtime($time_stop)), "\n";

    return 1;    # OK
}

sub compare_ko {
    my ( $self, $file_name ) = @_;
    
    my $file = $self->[PARENT]->slurp;
    my @lines = split ( /\n/, $file );
    open ( LEC, $file_name ) or die "Impossible d'ouvrir $file_name dans compare_ko : $!\n";
    while ( <LEC> ) {
        chomp;
        my $line = shift @lines;
        if ( $line  ne $_ ) {
            print "Différence en ligne $. : \n==>$line\n==>$_\n";
            CORE::close( LEC );
            return 1;
        }
    }
    CORE::close( LEC );
    if ( scalar(@lines) ) {
        print "Plus de lignes dans le fichier de file_namager que sur le disque\n";
        return 1;
    }
    return;
}


sub revert_internal {
    my ($self) = @_;

    if ( !$self->[ROOT][FILE_DESC] ) {

        # Pas de fichier connu, donc il n'a pas de revert possible
        return ( 0, "" );
    }

    # Horribles fuites mémoires !!
    # ------------------------------

    undef $self->[ROOT][FIRST];
    undef $self->[ROOT][LAST];
    CORE::close $self->[ROOT][FILE_DESC];
    open( $self->[ROOT][FILE_DESC], $self->[ROOT][FILE_NAME] )
      or die "Impossible dans revert d'ouvrir $self->[ROOT][FILE_NAME] : $!\n";
    $self->[ROOT][SEEK_START] = 0;
    $self->[ROOT][SEEK_END]   = ( stat $self->[ROOT][FILE_DESC] )[7];

    #print "SELF->ROOT = $self->[ROOT]\n";
    #print "self->[ROOT][SEEK_END] = $self->[ROOT][SEEK_END]\n";
    return;
}

sub empty_internal {
    my ($self) = @_;

   # Horribles fuites mémoires !!
   # ------------------------------
   #print "Size self (ROOT) avant nettoyage :", total_size($self->[ROOT]), "\n";
   #print "Size self avant nettoyage :", total_size($self), "\n";
    for my $keys ( keys %{ $self->[HASH_REF] } ) {
        delete $self->[HASH_REF]{$keys};
    }
    delete $self->[HASH_REF];
    clean( $self->[ROOT] );

   #print "Size self (ROOT) après nettoyage :", total_size($self->[ROOT]), "\n";
   #print "Size self après nettoyage :", total_size($self), "\n";
   #if ( ! defined $self->[TO_DELETE] ) {
   #    $self->[TO_DELETE][FIRST] = $self->[ROOT];
   #    $self->[TO_DELETE][LAST] = $self->[ROOT];
   #}
   #else {
   #    $self->[TO_DELETE][LAST][NEXT] = $self->[ROOT];
   #    $self->[TO_DELETE][LAST] = $self->[ROOT];
   #}

#print "Avant undef : self->[TO_DELETE][FIRST] = ", dump $self->[TO_DELETE][FIRST], "\n";
#print "Avant undef : self->[TO_DELETE][LAST]  = ", dump $self->[TO_DELETE][LAST], "\n";
    undef $self->[ROOT][FIRST];
    undef $self->[ROOT][LAST];

#print "Après undef : self->[TO_DELETE][FIRST] = ", dump $self->[TO_DELETE][FIRST], "\n";
#print "Après undef : self->[TO_DELETE][LAST]  = ", dump $self->[TO_DELETE][LAST], "\n";
    if ( $self->[ROOT][FILE_DESC] ) {
        CORE::close $self->[ROOT][FILE_DESC];
        undef $self->[ROOT][FILE_DESC];
        $self->[ROOT][SEEK_START] = 0;
        $self->[ROOT][SEEK_END]   = 0;

#open ( $self->[ROOT][FILE_DESC], ">" . $self->[ROOT][FILE_NAME] ) or die "Impossible dans revert d'ouvrir $self->[ROOT][FILE_NAME] : $!\n";
#$self->[ROOT][SEEK_START] = 0;
#$self->[ROOT][SEEK_END] = (stat $self->[ROOT][FILE_DESC] )[7];
    }
    return;
}

sub read_line_ref {

    # PROCEDURE INTERNE au thread file_manager (non inter-thread) !!!!

# Attention, la variable $who en entrée ne signifie pas que l'on va renvoyer la réponse à un autre "thread"
# Elle est en entrée car la mémorisation de la position actuelle sur le "fichier édité" est mémorisée pour chaque thread (plusieurs lectures simultanées possibles)
# $ref permet de commencer la lecture ailleurs qu'au début (recherche de texte)
# On peut supprimer la mémorisation en envoyant $ref défini mais faut ("" ou 0)
    my ( $self, $who, $ref ) = @_;
    if ( !defined($who) ) {
        $who = threads->self->tid;
    }
    if ( !$self->[DESC]{$who} ) {

        print DBG "\tPremier accès pour who = $who\n";

        my $line_ref;
        if ($ref) {
            $line_ref = $self->[HASH_REF]{$ref};
            $line_ref = next_($line_ref);
        }
        else {
            $line_ref = first_( $self->[ROOT] );
        }

        if ($line_ref) {

            print DBG "\twho = $who, text = $line_ref->[TEXT]\n";
            $self->[DESC]{$who}[REF] = $line_ref;

            return $line_ref;
        }
        else {    # Rien dans le "fichier" édité
            return;
        }
    }
    my $line_ref = $self->[DESC]{$who}[REF];
    if ( defined $ref ) {
        print DBG "\tDans read_line_ref : ref définie à $ref...\n";
        if ($ref) {
            $line_ref = $self->[HASH_REF]{$ref};
            print DBG "\tLine ref trouvée à $line_ref...\n";
        }
        else {

            #print "Demande de démémorisation\n";
            init_read( $self, $who );

            #undef $self->[DESC]{$who};
            return;
        }
    }
    $line_ref = next_($line_ref);
    if ($line_ref) {
        print DBG "\tTrouvé next de line_ref à $line_ref...\n";
        print DBG "\t\tSEEK_END = $line_ref->[SEEK_END]\n" if ( defined $line_ref->[SEEK_END] );
        print DBG "\tC'est à dire, texte |", $line_ref->[TEXT], "|\n";
        $self->[DESC]{$who}[REF] = $line_ref;
        return $line_ref;
    }

    #print "Dernier appel read_next...démémorisation\n";
    init_read( $self, $who );

    #undef $self->[DESC]{$who};
    return;
}

sub init_read {

    #  my ( $self, $who ) = @_;
    my ( $self, $who ) = @_;

    #print "Dans init_read $who\n";
    #delete $self->[DESC]{$who}[REF];
    #delete $self->[DESC]{$who}[UNTIL];
    #delete $self->[DESC]{$who};

    $self->[DESC]{$who} = ();

    #undef $self->[DESC]{$who};
    #print "Fin de init_read $who\n";
    return;
}

sub read_next
{ #Eclater read_next en 2 procédures : une qui renvoie seulement le texte et une qui renvoie la référence + le texte
     # Ces 2 procédures faisant appel à la même (procédure interne au thread fichier) qui renvoie une référence de tableau (la ligne)
    my ( $self, $who, $ref ) = @_;

    my $line_ref = read_line_ref( $self, $who, $ref );
    if ($line_ref) {
        return $line_ref->[TEXT];
    }
    return;
}

sub ref_of_read_next {
    my ( $self, $who, $ref ) = @_;

    my $line_ref = read_line_ref( $self, $who, $ref );
    if ($line_ref) {
        if ( $line_ref->[REF] ) {
            return $line_ref->[REF];
        }
        else {    # Ligne "fichier" non mémorisée
            return;
        }
    }
    return;
}

sub next_line {
    my ( $self, $ref ) = @_;

    if ( !$ref ) {

        #print "next_line : pas de ref demandée\n";
        my $line_ref = first_( $self->[ROOT] );
        if ($line_ref) {
            my $ref = save_line( $self, $line_ref );
            print
              #"Dans next_line Une référence a été trouvée : $line_ref|$ref|",$line_ref->[TEXT], "\n";
            return ( $ref, $line_ref->[TEXT] );
        }
        else {    # Aucune ligne à renvoyer
            #print "Dans next line : Pas de référence trouvée, Threads tid : ", threads->tid, "\n";
            return;
        }
    }

    # Utilisation de la référence pour connaître la position
    my $line_ref = $self->[HASH_REF]{$ref};

    my $next_line_ref = next_($line_ref);

    if ($next_line_ref) {
        my $next_ref = save_line( $self, $next_line_ref );
        return ( $next_ref, $next_line_ref->[TEXT] );
    }
    print DBG "PAs de ligne suivante trouvée derrière $ref\n";
    if ( defined $line_ref->[SEEK_START] ) {
        print DBG "SEEK START de cette dernière ligne $line_ref->[SEEK_START]\n";
    }
    else {
        print DBG "SEEK START de cette dernière ligne : undef\n";
    }
    if ( defined $line_ref->[SEEK_END] ) {
        print DBG "SEEK END de cette dernière ligne $line_ref->[SEEK_END]\n";
    }
    else {
        print DBG "SEEK END de cette dernière ligne : undef\n";
    }
    return;
}

sub next_ {

# Récupère le segment suivant à partir d'un segment : renvoie undef si rien après (à la fin)
    my ($segment_ref) = @_;

    print DBG "Dans next_ de $segment_ref\n";
    if (    $segment_ref->[NEXT]
        and $segment_ref->[NEXT][SEEK_START] == $segment_ref->[SEEK_END] )
    {
        return ( first_( $segment_ref->[NEXT] ) );
    }
    if ( ! $segment_ref->[PARENT] ) {
        print DBG "Pas de segment parent : seek_end = $segment_ref->[SEEK_END]\n";
        return if ( ! $one_more_line or $one_more_line != $segment_ref->[SEEK_END] );        
        
        print DBG "Encore une ligne : one_more_line = $one_more_line!\n";
        $one_more_line = 0;
        my $line_ref;
        #$segment_ref->[SEEK_END] -= 1;
        $line_ref->[SEEK_START] = $segment_ref->[SEEK_END];
        $line_ref->[PARENT]     = $segment_ref;
        $line_ref->[TEXT] = '';
        $line_ref->[TYPE] = 'line';
        $line_ref->[SEEK_END] = $line_ref->[SEEK_START];
        if ( $segment_ref->[LAST] ) {
            $line_ref->[PREVIOUS] = $segment_ref->[LAST];
            $segment_ref->[LAST][NEXT] = $line_ref;
        }
        $segment_ref->[LAST] = $line_ref;
        if ( ! $segment_ref->[FIRST] ) {
            $segment_ref->[FIRST] = $line_ref;
        }
        return $line_ref;
    } # Fin de if ( ! $segment_ref->[PARENT] )

    # $segment_ref->[PARENT] existe
    if ( $segment_ref->[PARENT][TYPE] eq 'break' ) {
        return ( next_($segment_ref->[PARENT]) );
    }
    if ( $segment_ref->[PARENT][SEEK_END] > $segment_ref->[SEEK_END] ) {
        print DBG "Parent $segment_ref->[PARENT][SEEK_END]| segment précédant $segment_ref->[SEEK_END]\n";
        my $line_ref;

# Problème à résoudre : segment_ref peut être un segment sans référence (parcours du fichier)
# Si line_ref vient à être sauvegardé (référencé) son PREVIOUS
#   pointera à tort sur une fausse référence
        if ( $segment_ref->[REF] ) {
            $line_ref->[PREVIOUS] = $segment_ref;
        }
        elsif ( $segment_ref->[PREVIOUS] ) {
            $line_ref->[PREVIOUS] = $segment_ref->[PREVIOUS];
            if ( !$segment_ref->[PREVIOUS][REF] ) {

# Normalement impossible car les segments sans référence ne sont pas pointés par les segments référencés
                print STDERR "2 segments sans réf se suivent\n";
            }
        }
        $line_ref->[NEXT] = $segment_ref->[NEXT];   # Peut être affectation vide
        $line_ref->[SEEK_START] = $segment_ref->[SEEK_END];
        $line_ref->[PARENT]     = $segment_ref->[PARENT];
        my $new_line_ref = read_($line_ref);
        
        if ( defined $new_line_ref ) {
            print DBG "Segment next lu : seek_end = $new_line_ref->[SEEK_END]\n";
            return $new_line_ref;
        }
        print DBG "Problème new_line_ref indéfinie...\n";
        print STDERR "Bidouille à virer... forçage de la taille du segement PARENT à celle du segment fils\n";
        $segment_ref->[PARENT][SEEK_END] = $segment_ref->[SEEK_END];
        return;
    }
    print DBG "Avant appel next_ de $segment_ref->[PARENT], seek_end = $segment_ref->[PARENT][SEEK_END]\n";
    return ( next_( $segment_ref->[PARENT] ) );
}

sub first_ {

    # Récupère le premier segment contenu dans un segment :
    # Si container : cela correspond effectivement à ce que l'on attend
    # Si "line" : la ligne se renvoie elle-même
    # Si "empty" : n'existe pas vraiment : renvoie le suivant
    # Si "empty" : n'existe pas vraiment : renvoie le suivant
    my ($segment_ref) = @_;
    
    if ( $segment_ref->[TYPE] eq "empty" ) {
        if ( $segment_ref->[NEXT] ) {
#Deep recursion on subroutine "File_manager::first_" at ../File_manager.pm line 613
# Pour éviter ce message, supprimer correctement (voir remarques dans 'delete_line')
            return ( first_( $segment_ref->[NEXT] ) );
        }
        else {
            # On considère qu'un segment vide a toujours un parent
            return ( next_( $segment_ref->[PARENT] ) );
        }
    }
    if ( $segment_ref->[TYPE] eq "break" ) {
        return ( first_( $segment_ref->[FIRST] ) );
    }

    if ( $segment_ref->[FIRST] ) {
        if ( $segment_ref->[FIRST][SEEK_START] == $segment_ref->[SEEK_START] ) {
            return ( first_( $segment_ref->[FIRST] ) );
        }
        else {
            print DBG "Lecture d'une ligne avant le segment FIRST\n";
            my $line_ref;
            $line_ref->[NEXT]       = $segment_ref->[FIRST];
            $line_ref->[PARENT] = $segment_ref;
            $line_ref->[SEEK_START] = $segment_ref->[SEEK_START];
            return ( read_($line_ref) );
        }
    }
    if ( $segment_ref->[TYPE] eq "line" ) {
        return ($segment_ref);
    }

    # On est sur un segment container mais ne contenant pas encore d'éléments
    if ( $segment_ref->[TYPE] eq "container" ) {

#print "On est dans un segment container\n";
# Il faut créer un nouveau segment : si le container est vide c'est que :
#   - soit le fichier est intact : création d'un segment "line"
#   - soit il n'y a pas de fichier (buffer vide), pas encore sauvegardé : aucune ligne à renvoyer
        if ( $segment_ref->[FILE_DESC] ) {
            if ( $segment_ref->[SEEK_START] != $segment_ref->[SEEK_END] ) {

                # Fichier intact
                my $line_ref;
                $line_ref->[SEEK_START] = $segment_ref->[SEEK_START];
                $line_ref->[PARENT]     = $segment_ref;
                
                $segment_ref->[FIRST] = $line_ref;
                 $segment_ref->[LAST] = $line_ref;

                my $return = read_($line_ref);
                if ( defined $return ) {
                    $segment_ref->[FIRST] = $line_ref;
                     $segment_ref->[LAST] = $line_ref;

                    return $line_ref;
                }
                return;
            }
        }
        my $line_ref;
        $line_ref->[TYPE] = 'line';
        $line_ref->[TEXT] = '';
        $line_ref->[SEEK_START] = 0;
        $line_ref->[SEEK_END] = 0;
        $line_ref->[PARENT] = $segment_ref;
            
        $segment_ref->[SEEK_START] = 0;
        $segment_ref->[SEEK_END] = 0;
        $segment_ref->[FIRST] = $line_ref;
        $segment_ref->[LAST] = $line_ref;
        return $line_ref;
    }
}

sub read_ {
    my ($line_ref) = @_;

    my $parent_ref = $line_ref->[PARENT];
    my $file_desc = $parent_ref->[FILE_DESC];
    if ( ! $file_desc ) {
        print DBG "Le segment parent $parent_ref de $line_ref ne contient pas de descripteur de fichier !\n";
        return;
    }
    if ( ref $file_desc eq 'ARRAY' ) {
        # Memory bloc
        $line_ref->[TEXT] = $file_desc->[$line_ref->[SEEK_START]];
        $line_ref->[TYPE] = 'line';
        $line_ref->[SEEK_END] = $line_ref->[SEEK_START] + 1;
        return $line_ref;
    }

   my $pos = $line_ref->[SEEK_START];

   print DBG "===> Dans read_ à partir de seek_start = $pos (lu sur fichier)\n";

    my $OK = seek $file_desc, $pos, 0;
    if ( ! $OK ) {
        my $msg = $!;
        print STDERR "Can't seek to position $pos : $msg\n";
        print DBG "Can't seek to position $pos : $msg\n";
        print DBG "Taille fichier : ", ( stat $file_desc )[7], " positionnement initial à $pos\n";
        return;
    }
    $line_ref->[TEXT] = readline $file_desc;
    
    if ( ! defined $line_ref->[TEXT] ) {
        print STDERR "Problème de cohérence : appel à read_ après la fin de fichier, thread ", threads->tid, "\n";
        print DBG "Problème de cohérence : appel à read_ après la fin de fichier, thread ", threads->tid, "\n";
        print DBG "Taille fichier : ", ( stat $file_desc )[7], " positionnement intial à $line_ref->[SEEK_START]\n";
        return;
    }
    
    if ( chomp $line_ref->[TEXT] ) {
        my $last_ref = $parent_ref->[LAST];
        my $current_end = tell $file_desc;
        if ( defined $last_ref ) {
            my $seek_end = $last_ref->[SEEK_END];
            if ( defined $seek_end and $seek_end >= $current_end ) {
                # On a déjà récupéré la dernière ligne : il ne faut pas ajouter une ligne
                # supplémentaire à la fin à cause d'un retour chariot déjà compté (par lecture
                # arrière par exemple)
                $current_end = 0;
            }
        }
        $one_more_line = $current_end;
    }

    # Suppression des retours chariots
    $line_ref->[TEXT] =~ s/\r//g;

    # Suppression des tabulations ...
    $line_ref->[TEXT] =~ s/\t/    /g;

    $line_ref->[SEEK_END] = tell $file_desc;
    $line_ref->[TYPE] = 'line';

    return $line_ref;
}

sub previous_ {

# Récupère le segment précédant à partir d'un segment : renvoie undef si rien avant (au début)
    my ($segment_ref) = @_;

    if (    $segment_ref->[PREVIOUS]
        and $segment_ref->[PREVIOUS][SEEK_END] == $segment_ref->[SEEK_START] )
    {

#print "segment_ref->[PREVIOUS][SEEK_END] : $segment_ref->[PREVIOUS][SEEK_END]\n";
#print "segment_ref->[PREVIOUS][TEXT] : $segment_ref->[PREVIOUS][TEXT]\n";
        return ( last_( $segment_ref->[PREVIOUS] ) );
    }
    if ( $segment_ref->[PARENT] ) {
        if ( $segment_ref->[PARENT][SEEK_START] < $segment_ref->[SEEK_START] ) {
            my $line_ref;

    # OK mais seulement car il n'existe pas de procédure de parcours arrière sans mémorisation
    #  ==> différence importante par rapport à "sub next_"
            $line_ref->[NEXT] = $segment_ref;

            $line_ref->[PREVIOUS] =
              $segment_ref->[PREVIOUS];    # Peut être affectation vide
            $line_ref->[SEEK_END] = $segment_ref->[SEEK_START];
            $line_ref->[PARENT]   = $segment_ref->[PARENT];
            return ( read_previous_($line_ref) );                
        }
        return ( previous_( $segment_ref->[PARENT] ) );
    }
    # Pas de ligne suivante
    return;                            # Renvoie undef
}

sub last_ {

    # Récupère le premier segment contenu dans un segment :
    # Si container : cela correspond effectivement à ce que l'on attend
    # Si "line" : la ligne se renvoie elle-même
    # Si "empty" : n'existe pas vraiment : renvoie le suivant
    my ($segment_ref) = @_;

    print DBG "Dans last_ de segment_ref $segment_ref\n";

    if ( $segment_ref->[TYPE] eq 'break' ) {
        return last_( $segment_ref->[LAST] );
    }

    if ( $segment_ref->[LAST] ) {
        if ( $segment_ref->[LAST][SEEK_END] == $segment_ref->[SEEK_END] ) {
            print DBG "Un segment last qui correspond à la fin du fichier : $segment_ref->[LAST]\n";
            return ( last_( $segment_ref->[LAST] ) );
        }
        else {
            my $line_ref;
            $line_ref->[PREVIOUS] = $segment_ref->[LAST];
            $line_ref->[SEEK_END] = $segment_ref->[SEEK_END];
            $line_ref->[PARENT]   = $segment_ref;
            print DBG "Création d'un nouveau segment : $line_ref\n";
            return ( read_previous_($line_ref) );
        }
    }
    if ( $segment_ref->[TYPE] eq "line" ) {
        return ($segment_ref);
    }

    # On est sur un segment container mais ne contenant pas encore d'éléments
    if ( $segment_ref->[TYPE] eq "container" ) {

#print "On est dans un segment container\n";
# Il faut créer un nouveau segment : si le container est vide c'est que :
#   - soit le fichier est intact : création d'un segment "line"
#   - soit il n'y a pas de fichier (buffer vide), pas encore sauvegardé : aucune ligne à renvoyer
        if ( $segment_ref->[FILE_DESC] ) {
            if ( $segment_ref->[SEEK_START] != $segment_ref->[SEEK_END] ) {

                print DBG "Fichier intact\n";
                my $line_ref;
                $line_ref->[SEEK_END] = $segment_ref->[SEEK_END];
                $line_ref->[PARENT]   = $segment_ref;
                return ( read_previous_($line_ref) );
            }
        }
        else {

            print DBG "Cas d'un buffer vide à faire ici\n";
            return;
        }
    }
    if ( $segment_ref->[TYPE] eq "empty" ) {
        if ( $segment_ref->[PREVIOUS] ) {
            print DBG "Récup de last du segment précédent $segment_ref->[PREVIOUS]\n";
            return ( last_( $segment_ref->[PREVIOUS] ) );
        }
        else {

            # On considère qu'un segment vide a toujours un parent
            print DBG "Récup du précédent du parent $segment_ref->[PARENT]\n";
            return ( previous_( $segment_ref->[PARENT] ) );
        }
    }
}

sub read_previous_ {
    my ($line_ref) = @_;

    print DBG "Dans read_previous de line_ref $line_ref\n";

    my ( $seek_start, $text ) =
      prev_line( $line_ref->[PARENT], $line_ref->[SEEK_END], $line_ref );

    print DBG "On a lu seek_start $seek_start et text $text\n";

    $line_ref->[TEXT] = $text;
    chomp $line_ref->[TEXT];

    # Suppression des retours chariots
    $line_ref->[TEXT] =~ s/\r//g;

    # Suppression des tabulations ...
    $line_ref->[TEXT] =~ s/\t/    /g;

    $line_ref->[SEEK_START] = $seek_start;
    $line_ref->[TYPE] = 'line';
    
    return $line_ref;
}

sub save_line {

# Création d'une ligne dans la structure
# On crée la ligne à partir d'une structure ligne (pseudo "objet" : plus simple à passer en paramètre)
# Attention, NEXT et PREVIOUS du pseudo-objet ne sont pas forcément renseignés
    my ( $self, $line_ref ) = @_;

    my $ref;
    if ( !$line_ref->[REF] )
    {    # On ne fait pas de "création" si la ligne existe déjà
        $ref = get_next_ref($self);
    }
    else {
        $ref = $line_ref->[REF];
    }
    $line_ref->[REF]  = $ref;
    $line_ref->[TYPE] = 'line';

    my $segment_ref = $line_ref->[PARENT];
    if (    $segment_ref->[FIRST]
        and $segment_ref->[FIRST][SEEK_START] > $line_ref->[SEEK_START] )
    {
        $line_ref->[NEXT]           = $segment_ref->[FIRST];
        $segment_ref->[FIRST]       = $line_ref;
        $line_ref->[NEXT][PREVIOUS] = $line_ref;
    }
    if ( !$segment_ref->[FIRST] ) {
        $segment_ref->[FIRST] = $line_ref;
    }
    if (    $segment_ref->[LAST]
        and $segment_ref->[LAST][SEEK_END] < $line_ref->[SEEK_END] )
    {
        $line_ref->[PREVIOUS]       = $segment_ref->[LAST];
        $segment_ref->[LAST]        = $line_ref;
        $line_ref->[PREVIOUS][NEXT] = $line_ref;
    }
    if ( !$segment_ref->[LAST] ) {
        $segment_ref->[LAST] = $line_ref;
    }
    if ( $line_ref->[PREVIOUS] ) {
        $line_ref->[PREVIOUS][NEXT] = $line_ref;
    }
    if ( $line_ref->[NEXT] ) {
        $line_ref->[NEXT][PREVIOUS] = $line_ref;
    }
    $self->[HASH_REF]{$ref} = $line_ref;
    return $ref;
}

sub get_ref_and_text_from_line_ref {
    my ($line_ref) = @_;

    #print "line_ref = $line_ref\n";
    return ( $line_ref->[REF], $line_ref->[TEXT] );
}

sub get_next_ref {
    my ($self) = @_;

    $self->[REF] += 1;
    return $self->[REF];
}

sub previous_line {
    my ( $self, $ref ) = @_;

    if ( !$ref ) {

        print DBG "Previous à blanc demandé\n";
        dump_file_manager( $self );
        my $line_ref = last_( $self->[ROOT] );

        print DBG  "line_ref trouvé = $line_ref\n";
        if ($line_ref) {
            my $ref = save_line( $self, $line_ref );
            return ( $ref, $line_ref->[TEXT] );
        }
        return 0;
    }

    print DBG  "Previous de $ref demandé\n";
    # Utilisation de la référence pour connaître la position
    my $line_ref = $self->[HASH_REF]{$ref};

    if ( defined $line_ref ) {
        print DBG "Line ref trouvée : $line_ref\n";
    }
    else {
        print DBG "Pas de line ref trouvée\n";
    }
    my $previous_line_ref = previous_($line_ref);
    if ($previous_line_ref) {
        my $previous_ref = save_line( $self, $previous_line_ref );
        return ( $previous_ref, $previous_line_ref->[TEXT] );
    }
    return 0;
}

sub line_seek_start {
    my ( $self, $ref ) = @_;

    return if ( !$ref );
    my $line_ref = $self->[HASH_REF]{$ref};
    return if ( !defined $line_ref );
    if ( defined $line_ref->[PSEUDO_SEEK_START] ) {
        return $line_ref->[PSEUDO_SEEK_START];
    }
    init_pseudo_seek_start ( $line_ref );
    return $line_ref->[PSEUDO_SEEK_START];
}

sub line_set_info {
    my ( $self, $ref, $info ) = @_;
    
    return if ( !$ref );
    my $line_ref = $self->[HASH_REF]{$ref};
    return if ( !defined $line_ref );
    $line_ref->[INFO] = $info;
}

sub line_get_info {
    my ( $self, $ref, $info ) = @_;
    
    return if ( !$ref );
    my $line_ref = $self->[HASH_REF]{$ref};
    return if ( !defined $line_ref );
    return $line_ref->[INFO];
}

sub init_pseudo_seek_start {
    my ( $line_ref ) = @_;
    
    my $seek_start = $line_ref->[SEEK_START];
    if ( $seek_start == 0 ) {
        my $seek_end = $line_ref->[SEEK_END];
        if ( $seek_end == 0 ) {
            return;
        }
    }
    $line_ref->[PSEUDO_SEEK_START] = $line_ref->[SEEK_START];
}

sub line_add_seek_start {
    my ( $self, $ref, $seek_added ) = @_;

    return if ( !$ref );
    my $line_ref = $self->[HASH_REF]{$ref};
    return if ( !defined $line_ref );
    my $seek_start = $line_ref->[PSEUDO_SEEK_START];
    if ( ! defined $seek_start ) {
        init_pseudo_seek_start( $line_ref );
        $seek_start = $line_ref->[PSEUDO_SEEK_START];
    }
    if ( ! defined $seek_start ) {
        $line_ref->[PSEUDO_SEEK_START] = $seek_added;
    }
    else {
        $line_ref->[PSEUDO_SEEK_START] = $seek_start . ";" . $seek_added;
    }
}

sub get_ref_for_empty_structure {

# Fonction appelée sur fichier vide (par exemple, au démarrage, lors de la création)
    my ($self) = @_;
    
    #print "Dans get_ref_for_empty_structure : self = $self\n";

    my $line_ref;
    $line_ref->[PARENT] = $self->[ROOT];
    $line_ref->[TEXT]   = "";
    $line_ref->[TYPE]   = "line";
    my $ref = get_next_ref($self);
    $line_ref->[REF]        = $ref;
    $line_ref->[SEEK_START] = 0;
    $line_ref->[SEEK_END]   = 0;

    $line_ref->[PARENT][LAST]       = $line_ref;
    $line_ref->[PARENT][FIRST]      = $line_ref;
    $line_ref->[PARENT][SEEK_START] = 0;
    $line_ref->[PARENT][SEEK_END]   = 0;

    $self->[HASH_REF]{$ref} = $line_ref;

    return $ref;
}

sub clean {
    my ($segment_ref) = @_;

    #return;
    # Récupération du premier élément
    #print "Dans clean de file_manager, \n";
    my $first = $segment_ref;

    # NEXT, PREVIOUS, PARENT, FIRST, LAST
    my $still_segment;
    while ( $still_segment = $first->[FIRST] ) {
        $first = $still_segment;
    }
    while ( $first = delete_and_return_first($first) ) {
    }
}

sub delete_and_return_first {
    my ($segment_ref) = @_;

    my $first;
    if ( $first = $segment_ref->[NEXT] ) {
        $segment_ref->[PARENT][FIRST] = $first;
        $first->[PREVIOUS] = 0;
    }
    elsif ( $first = $segment_ref->[PARENT] ) {
        $first->[FIRST] = 0;
    }
    $segment_ref->[NEXT]     = 0;
    $segment_ref->[PREVIOUS] = 0;
    $segment_ref->[PARENT]   = 0;

    #$segment_ref->[LAST] = 0;
    return $first;
}

sub save_info {
    my ( $self, $info, $key ) = @_;

    if ( defined $key ) {
        $self->[SAVED_INFO]{$key} = $info;
    }
    else {
        $self->[SAVED_INFO] = $info;
    }
}

sub load_info {
    my ( $self, $key ) = @_;

    if ( defined $key ) {
        if ( ref ($self->[SAVED_INFO] ) eq 'HASH' ) {
            return $self->[SAVED_INFO]{$key};
        }
        else {
            #print STDERR "Saved_info in File_manager is not a hash, key wanted : $key\n===\n", dump( $self->[SAVED_INFO] ), "\n====\n";
            return;
        }
    }
    return $self->[SAVED_INFO];
}

sub editor_number {
    my ( $self, $number, $options_ref ) = @_;
    
    print DBG "Dans editor_number, reçu : NUMBER $number\n";
    dump_file_manager ( $self );

    my $check_every = 20;
    my $lazy;
    if ( defined $options_ref and ref $options_ref eq 'HASH' ) {
        $check_every = $options_ref->{'check_every'} || 20;
        $lazy = $options_ref->{'lazy'};
    }

    my $indice = 0;
    # 'I' pour ne pas empiéter sur une autre utilisation directe par init_read, 'I' pour 'internal'
    my $who = 'I' . $indice;
    while  ( defined $self->[DESC]{$who} ) {
        $indice += 1;
        $who = 'I' . $indice;
    }
    $self->[DESC]{$who} = ();
    
    my $text = read_next($self, $who);

    $indice = 0;
    my $current;
    while ( defined($text) ) {
        $current += 1;
        $indice += 1;
        print DBG "Texte de la ligne $current : |$text|\n";
        if ( $current == $number ) {
            my $new_ref = create_ref_current($self, $who);
            print DBG "C'est la bonne ligne !\n";
            save_line_number( $self, $who, $new_ref, $number );
            # Désinit
            init_read( $self, $who );
            dump_file_manager ( $self );
            return $new_ref;
        }
        if ( $indice == $check_every ) {
            $indice = 0;
            if ( defined $lazy and Text::Editor::Easy::Comm::anything_for( $lazy ) ) {
                return;
            }
            if ( Text::Editor::Easy::Comm::anything_for_me() ) {
                #return if ( Text::Editor::Easy::Comm::have_task_done() );
                Text::Editor::Easy::Comm::have_task_done()
            }
        }
        $text = read_next($self, $who);
    }
    print DBG "Texte undefined, aucune ligne trouvée\n";
    dump_file_manager ( $self );
    return;
}

sub editor_search {
    my ( $self, $regexp, $options_ref ) = @_;
    
    my $check_every = 20;
    my ( $lazy, $who, $start_line, $start_pos, $stop_line, $stop_pos );
    if ( defined $options_ref and ref $options_ref eq 'HASH' ) {
        $check_every = $options_ref->{'check_every'} || 20;
        $lazy = $options_ref->{'lazy'};
        $who = $options_ref->{'thread'};
        $start_line = $options_ref->{'start_line'};
        $start_pos = $options_ref->{'start_pos'};
        $stop_line = $options_ref->{'stop_line'};
        $stop_pos = $options_ref->{'stop_pos'};
    }
    if ( ! defined $stop_line ) {
        $stop_line = $start_line;
    }

     if ( ! defined $who ) {
        my $indice = 0;
        # 'I' pour ne pas empiéter sur une autre utilisation directe par init_read, 'I' pour 'internal'
        $who = 'I' . $indice;
        while  ( defined $self->[DESC]{$who} ) {
            $indice += 1;
            $who = 'I' . $indice;
        }
    }
    $self->[DESC]{$who} = ();
    
    #my $text = read_next($self, $who, $start_line);
    my $line_ref = $self->[HASH_REF]{$start_line};
    return if ( ! defined $line_ref ); # Mauvaise référence
    $self->[DESC]{$who}[REF] = $line_ref;
    my $text = $line_ref->[TEXT];
    if ( ! defined $stop_pos ) {
        $stop_pos = length ( $text );
    }

    my $indice = 0;
    while ( defined($text) ) {
        $indice += 1;
        #print "Ligne lue : |$text|\n";
        while ( $text =~ m/($regexp)/g ) {
            my $length    = length($1);
            my $end_pos   = pos($text);
            my $start_pos = $end_pos - $length;
            my $new_ref = create_ref_current($self, $who);
            #print "Texte de la ligne : |$text|\n";
            if ( $new_ref != $start_line ) {
                save_line_number( $self, $who, $new_ref );
            }
            if ( $new_ref != $start_line or $start_pos  > $options_ref->{'start_pos'} ) {
                $self->[DESC]{$who} = undef;
                return ( $new_ref, $start_pos, $end_pos);
            }
        }
        if ( $indice == $check_every ) {
            $indice = 0;
            if ( defined $lazy and Text::Editor::Easy::Comm::anything_for( $lazy ) ) {
                return;
            }
            if ( Text::Editor::Easy::Comm::anything_for_me() ) {
                #return if ( Text::Editor::Easy::Comm::have_task_done() );
                Text::Editor::Easy::Comm::have_task_done()
            }
        }
        #$text = read_next($self, $who);
        $text = read_until2( $self, $who, { 'line_stop' => $stop_line } );
    }
    return;
}

sub get_line_number_from_ref {
    my ( $self, $ref, $options_ref ) = @_;
    
    #print "Dans get_line_number_from_ref, reçu : REF $ref\n";

    my $check_every = 20;
    my $lazy;
    if ( defined $options_ref and ref $options_ref eq 'HASH' ) {
        $check_every = $options_ref->{'check_every'} || 20;
        $lazy = $options_ref->{'lazy'};
    }

    my $number = 1;
    my $indice = 0;
    my $line_ref = first_ ($self->[ROOT]);
    while ( defined $line_ref and ( ! defined $line_ref->[REF] or $line_ref->[REF] != $ref ) ) {
        $number += 1;
        $indice += 1;
        $line_ref = next_ ($line_ref);
        if ( $indice == $check_every ) {
            $indice = 0;
            if ( defined $lazy and Text::Editor::Easy::Comm::anything_for( $lazy ) ) {
                return;
            }
            if ( Text::Editor::Easy::Comm::anything_for_me() ) {
                #return if ( Text::Editor::Easy::Comm::have_task_done() );
                Text::Editor::Easy::Comm::have_task_done()
            }
        }
    }
    return if ( ! defined $line_ref );
    return $number;
}

my $total_ref_lines;

sub dump_file_manager {
    my ( $self ) = @_;
    
    my $errors = 0;
    $total_ref_lines = 0;
    
    print DBG "Dans dump_file_manager : tid = ", threads->tid, ", $errors erreurs\n";
    print DBG "=" x 80;
    my $root = $self->[ROOT];
    print DBG "\nROOT : ", $self->[ROOT], "\n";
    
    my $file_name = $root->[FILE_NAME];
    if ( defined $file_name and $file_name ne '.' ) {
        print DBG "FILE_NAME  : ", $root->[FILE_NAME], "\n";
        print DBG "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>";
        open (TOT, $root->[FILE_NAME] ) or die "dfdfd : $!\n";
        my $enreg = <TOT>;
        while ( defined $enreg ) {
            print DBG $enreg;
            $enreg = <TOT>;
        }
        CORE::close( TOT );
        print DBG "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
    }
    else {
        print DBG "undefined FILE_NAME\n";        
    }
    print DBG "SEEK_START : ", $root->[SEEK_START], "\n" if ( defined $root->[SEEK_START] );
    print DBG "SEEK_END   : ", $root->[SEEK_END], "\n" if ( defined $root->[SEEK_END] );
    print DBG "FIRST      : ", $root->[FIRST], "\n" if ( defined $root->[FIRST] );
    print DBG "LAST       : ", $root->[LAST], "\n" if ( defined $root->[LAST] );
    print DBG "=" x 80, "\n";
    
    $errors += dump_level($root, 1);
    
    print DBG "\nLe dump a renvoyé $errors erreurs\n\n";
    return ( $errors, $total_ref_lines);
}

sub dump_level {
    my ( $root_ref, $level ) = @_;
    
    my $errors = 0;
    my $segment_ref = $root_ref->[FIRST];
    return 0 if ( ! defined $segment_ref );
    my $previous_ref;
    while ( defined $segment_ref ) {
        $errors += print_segment ( $segment_ref, $level, $root_ref );
        $previous_ref = $segment_ref;
        $segment_ref = $segment_ref->[NEXT];
        if ( defined $segment_ref ) {
            if ( $previous_ref != $segment_ref->[PREVIOUS] ) {
                print STDERR "Le segment $segment_ref a un mauvais previous...\n";
                print DBG "Le segment $segment_ref a un mauvais previous...\n";
                $errors += 1;
            }
        }
    }
    print DBG "\t" x $level, "\n";
    if ( $previous_ref != $root_ref->[LAST] ) {
        print STDERR "Le LAST du root $root_ref n'est pas correct...\n";
        print DBG "Le LAST du root $root_ref n'est pas correct...\n";
        $errors += 1;
    }
    print DBG "\t" x $level,  "LAST = ", $root_ref->[LAST], "\n";
    return $errors;
}

sub print_segment {
    my ( $segment_ref, $level, $parent ) = @_;

    my $errors = 0;
    print DBG "\t" x $level, "Level $level : ", $segment_ref, "\n";
    
    if ( defined $segment_ref->[TYPE] ) {
        print DBG "\t" x $level, "TYPE       : '", $segment_ref->[TYPE], "'\n";
    }
    else {
        print DBG "\t" x $level, "TYPE       : undefined\n";
        print STDERR "Le segment $segment_ref n'a pas de TYPE\n";
        print DBG "Le segment $segment_ref n'a pas de TYPE\n";
        $errors += 1;
    }        
    if ( defined $segment_ref->[PREVIOUS] ) {
        print DBG "\t" x $level, "PREVIOUS   : ", $segment_ref->[PREVIOUS], "\n";
        if ( $parent->[FIRST] == $segment_ref ) {
            print STDERR "Le segment $segment_ref a un PREVIOUS mais il est le FIRST de $parent...\n";
            print DBG "Le segment $segment_ref a un PREVIOUS mais il est le FIRST de $parent...\n";
            $errors += 1;
        }
    }
    else {
        print DBG "\t" x $level, "PREVIOUS   : undefined\n";
        if ( $parent->[FIRST] != $segment_ref ) {
            print STDERR "Le segment $segment_ref n'a pas de PREVIOUS et n'est pas le FIRST de $parent...\n";
            print DBG "Le segment $segment_ref n'a pas de PREVIOUS et n'est pas le FIRST de $parent...\n";
            $errors += 1;
        }
    }
    print DBG "\t" x $level, "SEEK_START : ", $segment_ref->[SEEK_START], "\n";
    print DBG "\t" x $level, "SEEK_END   : ", $segment_ref->[SEEK_END], "\n";
    if ( defined $segment_ref->[FIRST] ) {
       print DBG "\t" x $level, "FIRST      : ", $segment_ref->[FIRST], "\n";
       $errors += dump_level ( $segment_ref, $level + 1 );
    }
    if ( defined $segment_ref->[LAST] ) {
       print DBG "\t" x $level, "LAST       : ", $segment_ref->[LAST], "\n";
    }
    if ( defined $segment_ref->[TEXT] ) {
       print DBG "\t" x $level, "TEXT       : ", $segment_ref->[TEXT], "\n";
    }
    if ( $parent != $segment_ref->[PARENT] ) {
        print STDERR "Un segment fils ne référence pas son propre père...\n";
        print DBG "Un segment fils ne référence pas son propre père...\n";
        $errors += 1;
    }
    print DBG "\t" x $level, "PARENT       : ", $segment_ref->[PARENT], "\n";
    if ( defined $segment_ref->[REF] ) {
        print DBG "\t" x $level, "REF          : ", $segment_ref->[REF], "\n";
        if ( $segment_ref->[TYPE] ne 'empty' ) {
            $total_ref_lines += 1;
        }
    }
    if ( defined $segment_ref->[NEXT] ) {
        print DBG "\t" x $level, "NEXT       : ", $segment_ref->[NEXT], "\n";
        if ( $parent->[LAST] == $segment_ref ) {
            print STDERR "Le segment $segment_ref a un NEXT mais il est le LAST de $parent...\n";
            print DBG "Le segment $segment_ref a un NEXT mais il est le LAST de $parent...\n";
            $errors += 1;
        }
    }
    else {
        print DBG "\t" x $level, "NEXT       : undefined\n";    
        if ( $parent->[LAST] != $segment_ref ) {
            print STDERR "Le segment $segment_ref n'a pas de NEXT mais il est le LAST de $parent...\n";
            print DBG "Le segment $segment_ref n'a pas de NEXT mais il est le LAST de $parent...\n";
            $errors += 1;
        }
    }
    print DBG "\t" x $level, "=" x 80, "\n";
    return $errors;
}

sub insert_bloc {
    my ( $self, $bloc, $options_ref ) = @_;
    
    $options_ref = {} if ( ! defined $options_ref );
    print DBG "Dans insert_bloc\n\n\nbloc = $bloc\n", join( ', ', %{$options_ref}), "\n\n\n";
    
    dump_file_manager ( $self );
    if ( ! defined $bloc ) {
        print DBG "Bloc à insérer vide : aucune action\n";
        return;
    }
    my $line_ref;
    my $ref = $options_ref->{'where'};
    if ( defined $ref ) {
        $line_ref = $self->[HASH_REF]{$ref};
    }
    if ( ! defined $line_ref ) {
        $line_ref = first_ ( $self->[ROOT] );
    }
    my $where = $options_ref->{'how'} || 'before';
    
    # Insertion d'un segment container au niveau de $line_ref
    my $first_container_ref;
    $first_container_ref->[TYPE] = 'break';
    $first_container_ref->[PARENT] = $line_ref->[PARENT];
    my $seek;
    if ( $where eq 'before' ) {
        $seek = $line_ref->[SEEK_START];
    }
    else {
        $seek = $line_ref->[SEEK_END];
    }
    $first_container_ref->[SEEK_START] = $seek;
    $first_container_ref->[SEEK_END] = $seek;
    
    if ( $where eq 'before' ) {
        $first_container_ref->[PREVIOUS] = $line_ref->[PREVIOUS];
        if ( defined $first_container_ref->[PREVIOUS] ) {
            $first_container_ref->[PREVIOUS][NEXT] = $first_container_ref;
        }
        $line_ref->[PREVIOUS] = $first_container_ref;
        $first_container_ref->[NEXT] = $line_ref;
        if ( $line_ref->[PARENT][FIRST] == $line_ref ) {
            $line_ref->[PARENT][FIRST] = $first_container_ref;
        }
    }
    else { # 'after'
        $first_container_ref->[NEXT] = $line_ref->[NEXT];
        if ( defined $first_container_ref->[NEXT] ) {
            $first_container_ref->[NEXT][PREVIOUS] = $first_container_ref;
        }
        $line_ref->[NEXT] = $first_container_ref;
        $first_container_ref->[PREVIOUS] = $line_ref;
        if ( $line_ref->[PARENT][LAST] == $line_ref ) {
            $line_ref->[PARENT][LAST] = $first_container_ref;
        }
    }
    
    # Insertion du container des lignes mémoires
    my $last_container_ref;
    $last_container_ref->[SEEK_START] = 0;
    $last_container_ref->[TYPE] = 'container';
    my @lines = split (/\n/, $bloc, -1);
    $last_container_ref->[FILE_DESC] = \@lines;
    my $size = scalar ( @lines );
    $last_container_ref->[SEEK_END] = $size;
    $first_container_ref->[FIRST] = $last_container_ref;
    $first_container_ref->[LAST] = $last_container_ref;
    $last_container_ref->[PARENT] = $first_container_ref;
    
    # Insertion de la première ligne
    my $first_line_ref;
    $first_line_ref->[TYPE] = 'line';
    $first_line_ref->[TEXT] = $last_container_ref->[FILE_DESC][0];
    $first_line_ref->[PARENT] = $last_container_ref;
    $first_line_ref->[SEEK_START] = 0;
    $first_line_ref->[SEEK_END] = 1;
    
    #$last_container_ref->[FIRST] = $first_line_ref;
    my $first_ref = save_line( $self, $first_line_ref );
    #print DBG "last_container_ref->[FIRST] = $last_container_ref->[FIRST]\n";

    my $search_ref = $options_ref->{'search'};
    if ( defined $search_ref->{'1'} ) {
        $search_ref->{'1'} = $first_ref;
    }

    if ( $size == 1 ) {
        $last_container_ref->[LAST] = $first_line_ref;
        print DBG "La taille du bloc à insérer est de 1\n";
        # Scalar or list context : only one element inserted
        if ( defined $search_ref ) {
            my $answer_ref = {};
            $answer_ref->{'last'} = $first_ref;
            $answer_ref->{'return'} = [ $first_ref ];
            $answer_ref->{'found'} = $search_ref;
            return $answer_ref;
        }
        return $first_ref;
    }

    # Insertion de la dernière ligne
    my $last_line_ref;
    $last_line_ref->[TYPE] = 'line';
    $last_line_ref->[TEXT] = $last_container_ref->[FILE_DESC][$size - 1];
    $last_line_ref->[PARENT] = $last_container_ref;
    $last_line_ref->[SEEK_START] = $size - 1;
    $last_line_ref->[SEEK_END] = $size;    
    
    $last_line_ref->[PREVIOUS] = $first_line_ref;
    $first_line_ref->[NEXT] = $last_line_ref;
    
    #$last_container_ref->[LAST] = $last_line_ref;    
    my $last_ref = save_line( $self, $last_line_ref );
    if ( defined $search_ref->{$size} ) {
        $search_ref->{$size} = $last_ref;
    }

    print DBG "\n\n\nFin de insert_bloc\n\n\n";
    dump_file_manager( $self );

    my @list_refs = ( $first_ref );    
    if ( $options_ref->{'force_create'} ) {
        my $next_line_ref = next_($first_line_ref);
        while ( $next_line_ref ne $last_line_ref ) {
            push @list_refs, save_line ( $self, $next_line_ref );
            $next_line_ref = next_($next_line_ref);
        }
        
        print DBG "Après application de l'option force_create :\n\n";
        dump_file_manager( $self );
    }
    push @list_refs, $last_ref;

    if ( defined $search_ref ) {
        my $answer_ref = {};
        $answer_ref->{'last'} = $last_ref;
        $answer_ref->{'return'} = \@list_refs;
        my $current_line_ref = $first_line_ref;
        for my $number ( sort keys %$search_ref ) {
            if ( ! $search_ref->{$number} and $number < $size ) {
                # Adding new referenced line
    my $new_line_ref;
    $new_line_ref->[TYPE] = 'line';
    $new_line_ref->[TEXT] = $last_container_ref->[FILE_DESC][$number - 1];
    $new_line_ref->[PARENT] = $last_container_ref;
    $new_line_ref->[SEEK_START] = $number - 1;
    $new_line_ref->[SEEK_END] = $number;
    
    $last_line_ref->[PREVIOUS] = $new_line_ref;
    $current_line_ref->[NEXT] = $new_line_ref;
        
    $search_ref->{$number} = save_line( $self, $new_line_ref );
    $current_line_ref = $new_line_ref;
                # End of adding new referenced line
                print "Ajout pour number $number de la ligne |", $new_line_ref->[TEXT], "|\n";
            }
        }
        $answer_ref->{'found'} = $search_ref;
        return $answer_ref;
    }

    if ( wantarray ) {
        print DBG "Valeur de retour de insert_bloc : ", join ("\n\t", @list_refs ), "\n";
        return @list_refs;
    }
    if ( $where eq 'before' ) {
        return $first_ref;
    }
    else {
        return $last_ref;
    }
}

package Text::Editor::Easy::File_manager::Save_report;

sub TIEHANDLE {
    my ( $classe, $name ) = @_;

    my $file_desc;
    open ( $file_desc, ">$name" ) or die "Can't open $name while trying to tie : $!\n";
    my $array_ref = [ $name, $file_desc ];
    
    bless $array_ref, $classe;
}

sub PRINT {
    my $self = shift;
    
    no warnings;
    print { $self->[1] } @_;
}

sub CLOSE {
    my $self = shift;
    
    close ( $self->[1] );
}

=head1 FUNCTIONS

=head2 clean

=head2 close

=head2 create_ref_current

=head2 delete_and_return_first

=head2 delete_line

=head2 display

=head2 editor_number

Return the line of a Text::Editor::Easy instance given its number. This task may be long for the moment (with huge file), so lazy mode is possible. At the beginning, this task was done outside this module,
because sub "anything_for" was not written. Lazy processing can now be transmitted between threads : this means that one thread can stop its processing if another thread receives a new task.

=head2 editor_search

Return the line of a Text::Editor::Easy instance and the position (start and end) in this line that match the regexp given. This task may be long (with huge file), so lazy mode is possible.

=head2 empty_internal

=head2 empty_internal

=head2 first_

=head2 get_line_number_from_ref

=head2 get_next_ref

=head2 get_ref_and_text_from_line_ref

=head2 get_ref_for_empty_structure

=head2 init_file_manager

=head2 init_read

=head2 last_

=head2 line_seek_start

=head2 load_info

=head2 manage_requests

=head2 modify_line

=head2 new_line

=head2 next_

=head2 next_line

=head2 prev_line

=head2 previous_

=head2 previous_line

=head2 query_segments

=head2 read_

=head2 read_line_ref

=head2 read_next

=head2 read_previous_

=head2 read_until

=head2 read_until2

=head2 ref_of_read_next

=head2 revert_internal

=head2 save_info

=head2 save_info_on_file

=head2 save_internal

=head2 save_line

=head2 save_line_number

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;