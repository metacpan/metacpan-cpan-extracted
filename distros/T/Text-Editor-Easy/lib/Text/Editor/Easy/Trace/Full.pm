package Text::Editor::Easy::Trace::Full;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Trace::Full - Full trace management. The following events are saved on files : print (on STDOUT or STDERR), inter-thread call and
user event (key press, mouse move, ...). For each trace, the client thread and the stack call are saved.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

# Ce thread génère le fichier d'info et le hachage permettant d'y accéder rapidement
# Ce fichier d'info contient :
#   La liste des print (thread, liste d'appels ayant générée ce print, heure)
#   La liste des calls de méthodes inter-thread (call_id, méthode, liste d'appels ayant générée cet appel de méthode, heure, paramètres d'appels ?)
#   La liste des débuts de réponse (call_id)
#   La liste des fins de réponse (call_id, paramètres de retour ?)

use Fcntl;
use SDBM_File;

use Devel::Size qw(size total_size);
use IO::File;

Text::Editor::Easy::Comm::manage_debug_file( __PACKAGE__, *DBG );

use constant {

    #------------------------------------
    # LEVEL 1 : $self->[???]
    #------------------------------------
    HASH      => 0,
    OUT_NAME  => 1,
    INFO_DESC => 2,
    DBG_DESC  => 3,
    CALL_DESC => 4,
    HIDE => 5,
    INTER_CALL => 6,
    EVAL_DESC => 7,
    EXTENDED_SELF => 8,
};

# Hash content : depends on the key shape
#
# key = "\d+" (seek position, digits only : 5678) :
#     => the key corresponds to the position of text displayed in the redirected file (redirection of STDOUT and STDERR)
#     => the value corresponds to the position of the stack call ( at the time of the print ) in the print trace file

# key = "\d+_\d+" (call_id form : 0_345)
#     => the key corresponds to call_id, call identification
#     => the value corresponds to the position of the stack call ( at the time of the call ) in the call trace file

# key = "U_\d+" (user event : U_345 ) => "extended call"
#     => the key corresponds to the pseudo-call_id : the user made the "initial call"
#     => the value corresponds to the position of the user event description in the call trace file

# key = "E_\d+_\d+" (eval : E_0_345 = 'E' . $call_id)
#     => the second part of the key corresponds to the call_id that made the eval
#     => the value corresponds to the position(s) (if several, positions are separated by ';') of the code that has been 'evaled' in the eval file

=head1 FUNCTIONS

=head2 init_trace_print

This function is called just after the Trace::Full thread has been created. It initializes the files that will make possible to link a print and the
code that generated it.

=cut

my $length_s_n;

sub init_trace_full {
    my ( $self, $reference, $file_name ) = @_;

# Faire de même avec le fichier info. Référencer également
# le nom initial du fichier STDOUT (pour analyse : ouverture et réouverture régulières dans full_trace)
#$self = 'Bidon';
    print DBG "Dans init_trace_print ", total_size($self), " : $file_name|\n";
    my %h;

    # Hash (tied to a file to enable huge size)
    my $suppressed = unlink( $file_name . '.pag', $file_name . '.dir' );
    tie( %h, 'SDBM_File', $file_name, O_RDWR | O_CREAT, 0666 )
      or die "Couldn't tie SDBM file $file_name: $!; aborting";
    $self->[HASH]     = \%h;
    $self->[OUT_NAME] = $file_name;
    use IO::File;
    
    # print trace file
    open( $self->[INFO_DESC], "+>${file_name}.print_info" )
      or print DBG "Ouverture Info impossible\n";
    autoflush { $self->[INFO_DESC] };
    
    # call trace file
    open( $self->[CALL_DESC], "+>${file_name}.call_info" )
      or print DBG "Ouverture Call impossible\n";
    autoflush { $self->[CALL_DESC] };
    
    # eval trace file
    open( $self->[EVAL_DESC], "+>${file_name}.eval_info" )
      or print DBG "Ouverture Eval impossible\n";
    autoflush { $self->[EVAL_DESC] };

    my %package = (
        'Text::Editor::Easy' => 1,
        'Text::Editor::Easy::Comm' => 1,
        'Text::Editor::Easy::Abstract' => 1,
    );

    my $indice = 0;
    FILE: while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
        if ( $pack eq 'Text::Editor::Easy::Comm' ) {
            # Comm
            $package{$pack} = $file;
            
            # Abstract
            $file =~ s/Comm\.pm/Abstract\.pm/;
            $package{'Text::Editor::Easy::Abstract'} = $file;
            
            # Easy
            $file =~ s/Easy\/Abstract\.pm/Easy\.pm/;
            $package{'Text::Editor::Easy'} = $file;
        }
        last FILE;
    }

    print "Fichiers trouvés :\n\t", join( "\n\t", values %package), "\n";

    while ( my ( $package, $file ) = each %package ) {
        open ( FIC, $file ) or die "Can't open file $file : $!\n";
        while ( <FIC> ) {
            if ( /# Following call not to be shown in trace/ ) {
                $self->[HIDE]{$package}{$. + 1} = 1;
                print "Package $package, ligne à ignorer : ", $. + 1, " :\n";
                print scalar <FIC>;
            }
            if ( /# Inter-thread call, not to be shown in trace/ ) {
                $self->[INTER_CALL]{$. + 1} = 1;
            }
        }
        close FIC;
    }
    $length_s_n = Text::Editor::Easy->tell_length_slash_n;
}

=head2 trace_full_print

This function saves the link between a print and the code that generated it.

=cut

sub trace_full_print {
    my ( $self, $seek_start, $seek_end, $tid, $call_id, $on, $calls_dump, $data ) = @_;

    print DBG "Appel à trace_full_print : seek_start $seek_start|seek_end $seek_end|$data\n";

    return if ( !$self->[INFO_DESC] );

    # Valeur de la clé (ou des clés de hachage)
    my $value = tell $self->[INFO_DESC];
    $self->[HASH]{$seek_start} = $value;
    print { $self->[INFO_DESC] } "$seek_start|$seek_end\n";
    $call_id = '' if ( !defined $call_id );
    print { $self->[INFO_DESC] } "\t$tid|$call_id|$on\n";
    my @calls = eval $calls_dump;
    for my $tab_ref ( @calls ) {
        my ( $pack, $file, $line ) = @$tab_ref;
        print { $self->[INFO_DESC] } "\t$file|$line|$pack\n";
    }

# La donnée a été écrite sur le fichier, on peut l'ouvrir et analyser les départs de nouvelles lignes
    # On utilise pour cette analyse la variable $length_s_n (pas d'ouverture du fichier)
    my @lines = split ( /\n/, $data );
    my $seek_current = $seek_start;
    return if ( scalar ( @lines ) < 2 );
    for my $line ( @lines ) {
        $seek_current += length ( $line ) + $length_s_n;
        $self->[HASH]{$seek_current} = $value;
    }
}

=head2 get_info_for_display 

This function recovers the link between a print and the code that generated it.

=cut

sub get_info_for_eval_display {
    my ( $self, $ref_editor, $ref_line, $pos_in_line ) = @_;

    print DBG "Dans get_info_for_eval_display : ref_editor : $ref_editor| ref_line $ref_line| pos_in_line $pos_in_line\n";
    my $editor = Text::Editor::Easy->get_from_id( $ref_editor );
    my $seek_start = $editor->line_get_info( $ref_line );
    my $text = $editor->line_text ( $ref_line );
    print DBG "Seek start de la ligne : $seek_start| texte : $text\n";
    
    # Décomposition de la ligne
    my @seek_start = split ( /;/, $seek_start );
    my $to_calc = scalar(@seek_start);
    #my $current_length = length ( $text );
    my $current_length = 0;
    print DBG "\tCURRENT LENGTH $current_length\n";
    my $indice = 0;
    my ( $top_start, $real_start ) = split ( /,/, $seek_start[0] );

    while ( $to_calc ) {
        my ( $start, $end, $length ) = split ( /,/, $seek_start[$indice] );
        if ( ! defined $length ) {
            print STDERR "No information for following eval display : ", $editor->line_text( $ref_line ), "\n";
            print DBG "No information for following eval display : ", $editor->line_text( $ref_line ), "\n";
            last;
        }
        print DBG "\tSEEK_START $start de la position ", $current_length, " à la position ", $current_length + $length, "\n";
        if ( $pos_in_line <= $current_length + $length - ( $end - $start ) ) {
            print DBG "C'est ce seek_start $start qu'il faut renvoyer :\n";
            my $seek = $self->[HASH]{$start};
            if ( print_info_is_more_precise ( $self, $seek, $length ) ) {
                my ( $ref_first, $pos_first ) = get_first_line_for_print ( $self, $editor, $ref_line, $current_length, $end - $start );
                # Analyse de $@ : les messages sont par ligne entière (voir "trace_full_eval_err").
                # Seule la première ligne peut commencer au milieu (message précédent le $@ sans \n)
                print DBG "Après analyse ref_first $ref_first, pos_first $pos_first, ref_line $ref_line\n";
                if ( $ref_first != $ref_line ) {
                    return get_info_for_display ( $self, $end, $pos_in_line, $ref_editor, $ref_line );
                }
                my ( $ref1, $pos1, @next ) = get_info_for_display ( $self, $start, $pos_in_line, $ref_editor, $ref_line );
                return ( $ref1, $pos1 + $pos_first, @next );
            }
            print DBG "\tcurrent_length = $current_length\n";
            print DBG "\tpos_in_line = $pos_in_line\n";
            print DBG "\treal_start = $real_start\n";
            print DBG "\tstart = $start\n";
            print DBG "\tend = $end\n";
            print DBG "\tlength = $length\n";
            
            return (
                get_first_line_for_print ( $self, $editor, $ref_line, $current_length, $end - $start ),
                get_last_line_for_print ( $self, $editor, $ref_line, 0, $length + $current_length - ( $end - $start )),
                get_call_list_for_print ( $self, $seek ),
            );
        }
        $current_length += $length - ( $end - $start );
        print DBG "\tCURRENT LENGTH $current_length\n";
        $to_calc -= 1;
        $indice += 1;
    }
    my ( $start, $end, $length ) = split ( /,/, $seek_start[$indice - 1] );
    #print DBG "\tCURRENT LENGTH $current_length\n";
    #print DBG "\tPour finir, SEEK_START $start de la position ", $end - $real_start , " à la position ", $end + $current_length - $real_start, "\n";
    
    my $last_info_seek = $self->[HASH]{$start};
    print DBG "\tlast_info_seek = $last_info_seek\n";
    seek $self->[INFO_DESC], $last_info_seek, 0;
    my $info = readline ( $self->[INFO_DESC] );
    chomp $info;
    print DBG "\tinfo lu pour start = $start : $info\n";
    my ( $seek_1, $seek_2 ) = split ( /\|/, $info );
    print DBG "\tla longueur de SEEK_START $start est de ", $seek_2 - $seek_1, "\n";
    print DBG "\tIl reste donc ", $seek_2 - ( $end + $length ), " caractères sur le dernier seek_start\n";

    print DBG "\tIl reste également 1 ", $real_start - $top_start, " caractères à lire pour start $top_start\n";
    my $first_info_seek = $self->[HASH]{$top_start};
    print DBG "\tfirst_info_seek = $first_info_seek\n";
    seek $self->[INFO_DESC], $first_info_seek, 0;
    $info = readline ( $self->[INFO_DESC] );
    print DBG "\tinfo lu pour start = $top_start : $info\n";
    ( $seek_1, $seek_2 ) = split ( /\|/, $info );
    print DBG "\tIl reste également 2 ", $real_start - $seek_1, " caractères à lire pour start $top_start\n";

    seek $self->[INFO_DESC], 0, 2;
    return;
}

sub print_info_is_more_precise {
    my ( $self, $seek, $length ) = @_;

    seek $self->[INFO_DESC], $seek, 0;    
    my $enreg = readline( $self->[INFO_DESC] );
    seek $self->[INFO_DESC], 0, 2;
    chomp $enreg;
    my ( $seek_1, $seek_2 ) = split ( /\|/, $enreg );
    my $info_length = $seek_2 - $seek_1;
    if ( $info_length < $length ) {
        print DBG "Il y a plus d'information sur le fichier print info... :\n";
        print DBG "START = $seek_1 | End = $seek_2 | length $info_length (au lieu de $length)\n";
        return 1;
    }
    return;
}

sub get_first_line_for_print {
    my ( $self, $editor, $ref_line, $start, $end ) = @_;
    
    my $remain = $end - $start;
    print DBG "Dans get_first_line_for_print : Il faut remonter de $remain caractères\n";
    my $text;
    if ( $remain <= 0 ) {
        return ( $ref_line, -$remain );
    }
    while ( $remain > 0 ) {
        $remain -= $length_s_n;
        ( $ref_line, $text ) = $editor->previous_line( $ref_line );
        my $length = length($text);
        if ( $length >= $remain ) {
            return ( $ref_line, $length - $remain );
        }
        else {
            $remain -= $length;
        }
    }
    return ( $ref_line, 0 );
}

sub get_last_line_for_print {
    my ( $self, $editor, $ref_line, $start_of_line, $end ) = @_;

    my $text = $editor->line_text ( $ref_line );

    my $remain = $end - length ( $text ) - $start_of_line;
    print DBG "Dans get_last_line_for_print : Il faut descendre de $remain caractères\n";

    if ( $remain < 0 ) {
        return ( $ref_line, length ( $text ) + $remain );
    }
    while ( $remain > 0 ) {
        $remain -= $length_s_n;
        
        # Contournement d'un bug sur la gestion des "\n" en fin de fichier (ligne suivante (vide) absente...à voir)
        my ( $new_ref_line, $new_text ) = $editor->next_line( $ref_line );
        if ( ! defined $new_ref_line ) {
            return ( $ref_line, length($text) );
        }
        ( $ref_line, $text ) = ( $new_ref_line, $new_text );
        
        my $length = length($text);
        if ( $length >= $remain ) {
            return ( $ref_line, $remain );
        }
        else {
            $remain -= $length;
        }
    }
    return ( $ref_line, 0 );
}

sub get_info_for_display {
    my ( $self, $start_of_line, $shift, $ref_editor, $ref_line ) = @_;

    print DBG "Dans get_info_for_display : |$start_of_line| décalage : $shift\n";
    my $editor = Text::Editor::Easy->get_from_id( $ref_editor );

    my $value = $self->[HASH]{$start_of_line};
    if ( ! defined $value ) {
        print DBG "No info for print at position $start_of_line\n";
    }
    print DBG "Clé $start_of_line trouvée !! valeur : |$value|\n";
    seek $self->[INFO_DESC], $value, 0;
    my $enreg = readline $self->[INFO_DESC];
    print DBG "Enreg lu : $enreg | start_of_line $start_of_line | shift $shift\n";
    my ( $start, $end ) = $enreg =~ /^(\d+)\|(\d+)/;
    print DBG "\tSTART et END : $start|$end\n";
    while ( $end < $start_of_line + $shift ) {
        ($start, $end ) = next_display( $self );
         print DBG "\tSTART et END : $start|$end\n";        
    }
    print DBG "\tRenvoyé ==> START et END : $start|$end\n";
    return (
       get_first_line_for_print ( $self, $editor, $ref_line, $start, $start_of_line ),
       get_last_line_for_print ( $self, $editor, $ref_line, $start_of_line, $end ),
       #$ref_line, $end,
       get_call_list_for_print( $self, $self->[HASH]{$start} )
    );
}
    
sub get_call_list_for_print {
    my ( $self, $seek ) = @_;
    
    seek $self->[INFO_DESC], $seek, 0;
    readline $self->[INFO_DESC];
    my $enreg = readline $self->[INFO_DESC];
    $enreg =~ s/\t//;
    chomp $enreg;
    my @enreg = $enreg;
    my ( $tid, $call_id ) = split( /\|/, $enreg );
    $enreg = readline $self->[INFO_DESC];
    PRINT: while ( defined $enreg and $enreg =~ /^\t/ ) {
        chomp $enreg;
        my ( $file, $line, $package ) = split( /\|/, $enreg );
        if ( $package eq 'Text::Editor::Easy::Comm' or $package eq 'Text::Editor::Easy::Abstract' ) {
            if ( $self->[INTER_CALL]{$line} ) {
                push @enreg, "", get_info_for_call ( $self, $call_id );
                last PRINT;
            }
        }
        if ( my $hash_ref = $self->[HIDE]{$package} ) {
            if ( $hash_ref->{$line} ) {
                $enreg = readline $self->[INFO_DESC];
                next PRINT;
            }
        }
        if ( $file =~ /^\t\(eval / ) {
            $enreg = try_to_identify_eval ( $self, $enreg, $call_id, $self->[INFO_DESC] );
        }
        print DBG "J'empile $enreg\n";
        push @enreg, $enreg;
        
        if ( $package eq 'Text::Editor::Easy::Graphic' ) {
            push @enreg, "", get_info_for_call ( $self, $call_id );
            last PRINT;
        }
        
        $enreg = readline $self->[INFO_DESC];
    }
    seek $self->[INFO_DESC], 0, 2;
    
    print DBG "Retour de get_call_list...\n";
    return @enreg;
}

sub next_display {
    my ( $self ) = @_;
    
    my $enreg = readline $self->[INFO_DESC];
    while ( $enreg =~ /^\t.+/ ) {
        $enreg = readline $self->[INFO_DESC];
    }
    return $enreg =~ /^(\d+)\|(\d+)$/;
}

sub try_to_identify_eval {
    my ( $self, $enreg, $call_id, $file_desc ) = @_;
    
    print DBG "Dans try_to_identify : clé E$call_id\n";
    my $value = $self->[HASH]{'E_' . $call_id};
    return $enreg if ( ! defined $value );
    print DBG "Dans identify : trouvé $value pour clé E_$call_id\n";
    
    my $seek = tell $file_desc;
    my $eval_call = readline $file_desc;
    seek $file_desc, $seek, 0;
        
    return $enreg if ( $eval_call !~ /\t(.+)\|(.+)\|(.+)$/ );
    my ( $file, $line, $package ) = ( $1, $2, $3 );
    print "file line et package : $file | $line | $package\n";

    # Vérification de l'égalité de fichier et de ligne entre l'eval et la ligne suivante du fichier $file_desc
    my @position = split ( /;/, $value);
    my $indice = 0;
    my $found = 0;
    EVAL: for ( @position ) {
        seek $self->[EVAL_DESC], $_, 0;
        my $eval_info = readline $self->[EVAL_DESC];
        print "INFO Eval lu =\n\t$eval_info";
        
        chomp $eval_info;
        my ( $tid, $c_file, $c_package, $c_line, $c_call_id ) = split (/\|/, $eval_info );
        if ( $c_file eq $file and $line == $c_line ) {
            print "EVAL identifié : E_${call_id}__$indice\n";
            $found = 1;
            last EVAL;
        }
        $indice += 1;
    };
    if ( $found ) {
        my ( $file, $line, $package ) = $enreg =~ /\t(.+)\|(.+)\|(.+)$/;
        $enreg = "\teval E_${call_id}__$indice|$line|$package\n";
        print "Trouvé, on renvoie $enreg\n";
    }
    
    
    # Repositionement à la fin
    seek $self->[EVAL_DESC], 0, 2;

    return $enreg;
}

sub trace_full_call {
    my ( $self, $call_id, $client_call_id, @calls ) = @_;
    
    #print DBG "Dans trace_full_call (self = $self): $call_id\n";
    my $seek = tell $self->[CALL_DESC];
    no warnings;
    print { $self->[CALL_DESC] } "$call_id|$client_call_id\n";
    use warnings;
    for my $tab_ref ( @calls ) {
        if ( ref $tab_ref ) {
            my ( $pack, $file, $line ) = @$tab_ref;
            print { $self->[CALL_DESC] } "\t$file|$line|$pack\n";            
        }
        else {
            print { $self->[CALL_DESC] } "\t$tab_ref\n";
        }

    }
    $self->[HASH]{$call_id} = $seek;
    #print DBG "Fin de trace_full_call pour call_id $call_id => position $seek\n";
    #print DBG "Relecture du hachage : ", $self->[HASH]{$call_id}, "\n";
    #print DBG "Hash = ", $self->[HASH], "\n";
}

sub get_info_for_call {
    my ( $self, $call_id ) = @_;

    #print DBG "Dans get_info_for_call (self = $self): position de $call_id :\n";
    #print DBG "HASH = ", $self->[HASH], "\n";
    #print DBG "KEY  = ", $self->[HASH]{$call_id}, "\n";
    return if ( ! defined $call_id );
    
    my $seek = $self->[HASH]{$call_id};
    return if ( ! defined $seek );
    #print DBG "\tSEEK de $call_id => $seek\n";
    seek $self->[CALL_DESC], $seek, 0;
    my $enreg = readline $self->[CALL_DESC];
    chomp $enreg;
    my ( undef, $new_call_id ) = split ( /\|/, $enreg );
    my @return = $enreg;
    print DBG $enreg;
    $enreg = readline $self->[CALL_DESC];
    CALL: while ( $enreg =~ /^\t/ ) {
        chomp $enreg;
        my ( $file, $line, $package ) = split( /\|/, $enreg );
        if ( $package eq 'Text::Editor::Easy::Comm' or $package eq 'Text::Editor::Easy::Abstract' ) {
            if ( $self->[INTER_CALL]{$line} ) {
                if ( defined $new_call_id ) {
                    push @return, "", get_info_for_call ( $self, $new_call_id );
                }
                last CALL;
            }
        }
        if ( my $hash_ref = $self->[HIDE]{$package} ) {
            if ( $hash_ref->{$line} ) {
                $enreg = readline $self->[CALL_DESC];
                next CALL;
            }
        }
        push @return, $enreg;
        
        if ( $package eq 'Text::Editor::Easy::Graphic' ) {
            push @return, "", get_info_for_call ( $self, $new_call_id );
            last CALL;
        }
        
        $enreg = readline $self->[CALL_DESC];
    }
    # Repostionnement à la fin
    seek $self->[CALL_DESC], 0, 2;
    return @return;
}
=head2 trace_display_calls

This function is not used.

=cut

# Internal
sub trace_display_calls {
    my @calls = @_;
    for my $indice ( 1 .. scalar(@calls) / 3 ) {
        my ( $pack, $file, $line ) = splice @calls, 0, 3;

        #print ENC "\tF|$file|L|$line|P|$pack\n";
    }
}

sub trace_full_eval {
    my ( $self, $eval, $tid, $file, $package, $line, $call_id ) = @_;
    
    my $key = 'E_' . $call_id;
    my $value;
    if ( $value = $self->[HASH]{$key} ) {
        $value .= ';';
    }
    $value .= tell $self->[EVAL_DESC];
    $self->[HASH]{$key} = $value;
    print { $self->[EVAL_DESC] } "$tid|$file|$package|$line|$call_id\n";
    my @eval = split ( /\n/, $eval );
    for ( @eval ) {
        print { $self->[EVAL_DESC] } "\t$_\n";
    }
}

sub get_code_for_eval {
    my ( $self, $eval_id ) = @_;
    
    print "Dans get_code_for_eval : eval_id = $eval_id\n";
    return if ( $eval_id !~ /(E_.+)__(.+)$/ );
    my ( $key, $indice ) = ( $1, $2 );
    print "Dans get_code_for_eval : clé $key, indice $indice\n";
    my $value = $self->[HASH]{$key};
    my @position = split ( /;/, $value );
    seek $self->[EVAL_DESC], $position[$indice], 0;
    readline $self->[EVAL_DESC];
    my $enreg = readline $self->[EVAL_DESC];
    my @enreg;
    while ( $enreg =~ /^\t(.*)/ ) {
        push @enreg, $1;
        $enreg = readline $self->[EVAL_DESC];
    }
    seek $self->[EVAL_DESC], 0, 2;
    return @enreg;
}

sub trace_full_eval_err {
    my ( $self, $seek_start, $seek_end, $dump_hash, $message ) = @_;
    
    print DBG "Dans trace_full_eval_err, reçu : $seek_start | $seek_end | message\n$message";
    
    my @line = split ( /\n/, $message, -1 );
#    if ( scalar(@line) > 1 ) {
#        print "Cas pas encore géré : retrouver la taille du \\n\n";
#        return;
#    }
    
    my ( $num_eval, $num_line );
    my $seek_start_current = $seek_start;
    my $seek_end_current = $seek_start;
    my $to_write = 0;
    my $info = $line[0];
    my $value = tell $self->[INFO_DESC];
    
    # très dangereux !
    
    my %option = eval $dump_hash;
    for my $info ( @line ) {
        print DBG "Elément |$info| dans la boucle de traitement\n";
        if ( $info =~ / at \(eval (\d+)\) line (\d+)/ ) {
            if ( $to_write ) {
                print DBG "On va écrire $info et ce qui précède : seek_start : $seek_start_current\n";
                print DBG "SEEK end current : $seek_end_current\n";
                print DBG "Valeur $value pour la clé $seek_start_current\n";
                $self->[HASH]{$seek_start_current} = $value;   
                print { $self->[INFO_DESC] } "$seek_start_current|$seek_end_current\n";
                print { $self->[INFO_DESC] } "\t$option{'who'}|$option{'call_id'}|STDERR (\$@)\n";
                print { $self->[INFO_DESC] } "\t(eval $num_eval)|$num_line|$option{'package'}\n";
                print { $self->[INFO_DESC] } "\t$option{'file'}|$option{'line'}|$option{'package'}\n";
                my @calls = eval $option{'calls'};
                for my $tab_ref ( @calls ) {
                    my ( $pack, $file, $line ) = @$tab_ref;
                    print { $self->[INFO_DESC] } "\t$file|$line|$pack\n";
                }
                $value = tell $self->[INFO_DESC];
                $seek_start_current = $seek_end_current;
            }
            ( $num_eval, $num_line ) = ( $1, $2 );
            $to_write = 1;
        }
        $seek_end_current += $length_s_n + length( $info );
    }
    print DBG "Fin : On va écrire $info et ce qui précède : seek_start : $seek_start_current\n";
    $seek_end_current -= $length_s_n;
    print DBG "SEEK end current : $seek_end_current\n";
    print DBG "Valeur $value pour la clé $seek_start_current\n";
    $self->[HASH]{$seek_start_current} = $value;
    print { $self->[INFO_DESC] } "$seek_start_current|$seek_end_current\n";
    print { $self->[INFO_DESC] } "\t$option{'who'}|$option{'call_id'}|\$@\n";
    print { $self->[INFO_DESC] } "\t(eval $num_eval)|$num_line|$option{'package'}\n";
    print { $self->[INFO_DESC] } "\t$option{'file'}|$option{'line'}|$option{'package'}\n";
        
    my @calls = eval $option{'calls'};
    for my $tab_ref ( @calls ) {
        my ( $pack, $file, $line ) = @$tab_ref;
        print { $self->[INFO_DESC] } "\t$file|$line|$pack\n";
    }
}

sub declare_trace_for {
    my ( $self, $name, $file_name ) = @_;

    my $editor = Text::Editor::Easy->whose_name( $name );
    my $ref = $editor->id;
    
    my $new_self;
    $new_self->[OUT_NAME] = $file_name;
    $new_self->[HIDE] = {};
    $new_self->[INTER_CALL] = {};
    print DBG "Fin de declare_trace_for $name, $file_name, reference $ref\n";
    $self->[EXTENDED_SELF]{$ref} = $new_self;
    print DBG "1 self $self, new_self $new_self, out_name ", $new_self->[OUT_NAME], "\n";
}

sub get_info_for_extended_trace {
    my ( $self, $start, $shift, $ref_editor, $ref_line ) = @_;
    
    print DBG "Dans get_info_for_extended ref_editor = $ref_editor\n";
    my $new_self = $self->[EXTENDED_SELF]{$ref_editor};
    print DBG "2 self $self, new_self $new_self, out_name ", $new_self->[OUT_NAME], "\n";
    my $file_name = $new_self->[OUT_NAME];
    if ( ! -f $file_name or ! -f "${file_name}.print_info" ) {
        print DBG "Problème d'initialisation... fichiers de log absents\n";
        return;
    }
    my %h;
    if ( defined $new_self->[INFO_DESC] ) {
        close ( $new_self->[INFO_DESC] );
        untie %{$new_self->[HASH]};
    }
    open ( $new_self->[INFO_DESC], "${file_name}.print_info" ) or die "Can't open $file_name : $!\n";
    tie( %h, 'SDBM_File', $file_name, O_RDONLY, 0666 )
      or die "Couldn't tie SDBM file $file_name: $!; aborting";
    $new_self->[HASH] = \%h;
    
    return get_info_for_display ( $new_self, $start, $shift, $ref_editor, $ref_line );
}
=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;




# End
