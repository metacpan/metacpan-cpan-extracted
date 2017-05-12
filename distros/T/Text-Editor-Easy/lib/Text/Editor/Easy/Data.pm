package Text::Editor::Easy::Data;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Data - Global common data shared by all threads.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Data::Dump qw(dump);
use threads;
use Thread::Queue;

use Devel::Size qw(size total_size);
use File::Basename;
use File::Spec;

my $self_global;

use constant {

    #------------------------------------
    # LEVEL 1 : $self->[???]
    #------------------------------------
    ZONE_ORDER     => 0,
    FILE_OF_ZONE   => 1,
    EDITOR_OF_ZONE => 2,
    #FILE_NAME      => 3,
    THREAD         => 4,
    CALL           => 5,
    RESPONSE       => 6,
    REDIRECT       => 7,    # Redirection des print
    COUNTER        => 8,
    TOTAL          => 9,
    NAME_OF_ZONE   => 10,
    NAME           => 11,
    INSTANCE       => 12,
    FULL_TRACE     => 13,
    ZONE           => 14,
    CURRENT => 15,
    SEARCH => 16,
    ZONE => 17,
    DEFAULT => 18,
    CONF => 19,

    #------------------------------------
    # LEVEL 2 : $self->[TOTAL][???]
    #------------------------------------
    CALLS     => 0,
    STARTS    => 0,
    RESPONSES => 0,

    #------------------------------------
    # LEVEL 3 : $self->[CALL]{$call_id}[???]
    #------------------------------------
    STATUS        => 0,
    THREAD_LIST   => 1,
    METHOD_LIST   => 2,
    INSTANCE_LIST => 3,

    #THREAD => 4,
    METHOD   => 5,
    C_INSTANCE => 6,
    PREVIOUS => 7,
    SYNC     => 8,
    CONTEXT  => 9,

    #------------------------------------
    # LEVEL 3 : $self->[THREAD][$tid][???]
    #------------------------------------
    STATUS      => 0,
    CALL_ID     => 1,
    CALL_ID_REF => 2,
    EVAL        => 3,
};

use IO::File;
my $own_STDOUT;

sub import {
    my ( $self, $trace_ref ) = @_;


    my $name       = fileparse($0);
    $own_STDOUT = "tmp/${name}_trace.trc";
    #print "Dans data reçu trace_ref = $trace_ref\n";
    #if ( $Text::Editor::Easy::Trace{'trace_print'} ) {
    if ( $trace_ref->{'trace_print'} ) {
        #print "Dans data, ouverture de ENC avec name tmp/${name}_trace.trc\n";
        open( ENC, ">$own_STDOUT" ) or die "ouverture de $own_STDOUT : $!\n";
        autoflush ENC;
    }

    #print "Dans data, avant ouverture de ENC\n";
    #print DBG "Dans data, avant ouverture de ENC\n";
    Text::Editor::Easy::Comm::manage_debug_file( __PACKAGE__, *DBG, { 'trace' => $trace_ref } );
    #print "Dans data, après ouverture de ENC\n";
    print DBG "Dans data, après ouverture de ENC\n";
}

sub reference_editor {
    my ( $self, $ref, $options_ref ) = @_;
    
    #open ( DB1, ">DEBUG.txt" ) or die "Impossible d'ouvrir DEBUG.txt : $!\n";
    #print DB1 "Dans reference_editor\n";

    my $zone_ref = $options_ref->{'zone'};
    
    my $file = $options_ref->{'file'};
    my ($file_name, $absolute_path, $relative_path );
    if ( defined $file ) {
            my $file_path;
            ($file_name, $file_path ) = fileparse($options_ref->{'file'});
            my $is_absolute = File::Spec->file_name_is_absolute( $file_path );
            
            if ( $is_absolute ) {
                $absolute_path = $file_path;
                $relative_path = File::Spec->abs2rel( $file_path ) ;
            }
            else {
                $relative_path = $file_path;
                $absolute_path = File::Spec->rel2abs( $file_path ) ;
            }
    }

    my $name = $options_ref->{'name'};
    
    #print DBG "Dans reference_editor de Data : $self |$ref|$zone_ref|$file_name|$name|\n";
    my $zone;
    if ( defined $zone_ref ) {
        if (   ref $zone_ref eq 'HASH'
            or ref $zone_ref eq 'Text::Editor::Easy::Zone' )
        {
            $zone = $zone_ref->{'name'};
        }
        else {
            $zone = $zone_ref;
        }
    }
    $self->[ZONE]{$ref} = $zone;

    #print "...suite reference de Data : |$zone|\n";
    # Bogue à voir
    $zone = '' if ( !defined $zone );
    my $order = $self->[ZONE_ORDER]{$zone};
    $order = 0 if ( !defined $order );
    if ( defined $file_name ) {
        push @{ $self->[FILE_OF_ZONE]{$zone}{$file_name} }, $order;
    }
    if ( !defined $name and defined $file_name ) {
        $name = fileparse($file_name);
    }
    if ( defined $name ) {
        push @{ $self->[NAME_OF_ZONE]{$zone}{$name} }, $order;
    }
    $self->[EDITOR_OF_ZONE]{$zone}[$order] = $ref;
    $self->[NAME]{$name} = 1 if ( defined $name );
    $self->[INSTANCE]{$ref}{'name'}        = $name;
    $self->[INSTANCE]{$ref}{'file_name'}   = $file_name;
    $self->[INSTANCE]{$ref}{'absolute_path'}   = $absolute_path;
    $self->[INSTANCE]{$ref}{'relative_path'}   = $relative_path;
    my ( $volume, $directory );
    if ( defined $absolute_path ) {
        ( $volume, $directory ) = File::Spec->splitpath( $absolute_path, 'no_file' );
    }
    $volume = '' if ( ! defined $volume );
    $directory = '' if ( ! defined $directory );
    $file_name = '' if ( ! defined $file_name );
    my $full_absolute = File::Spec->catpath( $volume, $directory, $file_name );
    $self->[INSTANCE]{$ref}{'full_absolute'} = $full_absolute;
    my $full_relative = File::Spec->abs2rel( $full_absolute ) ;
    if ( $full_relative ne $full_absolute ) {
        $self->[INSTANCE]{$ref}{'full_relative'} = $full_relative;
    }
 
    $self->[ZONE_ORDER]{$zone} += 1;    # Valeur de retour, ordre dans la zone
    
    
    print DBG "\n\nAvant fusion, event_ref = ", dump($options_ref->{'events'}), "\n\n\n";
    
    my ( $event_ref, $sequence_ref ) = merge_seq_in_events( $self,  $options_ref->{'events'},  $options_ref->{'sequences'} );
    # Forçage éventuel d'évènements
    $event_ref = undef if ( ! %$event_ref );
    print DBG "\n\nAvant forçages, event_ref = ", dump($event_ref), "\n\n\n";

    ( $event_ref, $sequence_ref ) = force_default( $self->[DEFAULT], $event_ref, $sequence_ref, $name );
     
     print DBG "\n\nAprès forçages divers, event_ref = ", dump($event_ref), "\n\n\n";
    #print DB1 "1 - Event ref vaut ", dump($event_ref), "\n";
    if ( defined $event_ref ) {
        $event_ref = Text::Editor::Easy::Events::reference_events($ref, $event_ref);
        #print DB1 "2 - Event ref vaut ", dump($event_ref), "\n";
    }
    else {
        $event_ref = {};
    }
    #print DB1 "3 - Event ref vaut ", dump($event_ref), "\n";
    $self->[INSTANCE]{$ref}{'events'} = $event_ref;
    $self->[INSTANCE]{$ref}{'sequences'} = $sequence_ref;
    $options_ref->{'events'} = $event_ref;
    $options_ref->{'sequences'} = $sequence_ref;

    #close DB1;
    return $options_ref;
}

sub data_events {
    my ( $self, $id, $name ) = @_;
    
    if ( ! $id ) {
        return $self->[DEFAULT];
    }
    
    if ( ! defined $name ) {
        return $self->[INSTANCE]{$id}{'events'};
    }
    else {
        return $self->[INSTANCE]{$id}{'events'}{$name};
    }
}

sub data_sequences {
    my ( $self, $id, $name ) = @_;

    if ( ! $id ) {
        return;
    }
    
    if ( ! defined $name ) {
        return $self->[INSTANCE]{$id}{'sequences'};
    }
    else {
        return $self->[INSTANCE]{$id}{'sequences'}{$name};
    }
}

my %true_instance_value = (
    'existing' => 1,
    'future'   => 1,
    'all'      => 1,
);

sub data_set_sequence {
    my ( $self, $id, $sequence_ref, $options_ref ) = @_;

    if ( $id ) {
        my $instance_ref = $self->[INSTANCE]{$id};
        my $name = $instance_ref->{'name'};
        my $old_sequence_ref = $instance_ref->{'sequences'}; 
        if ( sequence_is_applicable( $old_sequence_ref, $sequence_ref, $options_ref, $name ) ) {
            my $new_sequence_ref = merge_sequences( $old_sequence_ref, $sequence_ref );
            $self->[INSTANCE]{$id}{'sequences'} = $new_sequence_ref;
            return ( [ $id ], { '0' => 1 }, { 'sequences' => $sequence_ref } );
        }
        return;
    }
   
    # Class call
    return if ( for_future_only( $self, $options_ref->{'instances'}, 'sequence', $sequence_ref, $options_ref ) );
      
    my $instance_ref = $self->[INSTANCE];
    my $update_ref;   
    for my $id ( keys %$instance_ref ) {
        my $id_ref = $instance_ref->{$id};
        my $name = $id_ref->{'name'};
        my $old_sequence_ref = $id_ref->{'sequences'};
        if ( sequence_is_applicable( $old_sequence_ref, $sequence_ref, $options_ref, $name ) ) {
            my $new_sequence_ref = merge_sequences( $old_sequence_ref, $sequence_ref );
            $self->[INSTANCE]{$id}{'sequences'} = $new_sequence_ref;
            push @$update_ref, $id;
        }
    }
    
    # Référencement du nouvel évènement dans les thread qui en ont besoin
    if ( $update_ref ) {
        return ( $update_ref, { 0 => 1 }, { 'sequences' => $sequence_ref } );
    }
    else {
        return;
    }
}

sub data_set_event {
    my ( $self, $id, $event_name, $event_ref, $options_ref ) = @_;
    
    print DBG "\n\nDans data_set_event : id = $id, name = $event_name\n\n\n";

    if ( $id ) {
        my $instance_ref = $self->[INSTANCE]{$id};
        my $name = $instance_ref->{'name'};
        my $old_event_ref = $instance_ref->{'events'}{$event_name};
        if ( event_is_applicable( $old_event_ref, $event_ref, $options_ref, $name ) ) {
            $self->[INSTANCE]{$id}{'events'}{$event_name} = $event_ref;
            my $seq_value_ref = undef;
            if ( exists $event_ref->{'sequence'} ) {
                $seq_value_ref = $event_ref->{'sequence'};
                $instance_ref->{'sequences'}{$event_name} = $seq_value_ref;
                return ( [ $id ], { '0' => 1 }, { 
                    'sequence' => { $event_name => $seq_value_ref },
                    'event'    => $event_ref,
                    'name'     => $event_name,
                } );
            }
            return ( [ $id ], { '0' => 1 }, { 
                'event'    => $event_ref,
                'name'     => $event_name,
            } );
        }
        return;
    }
   
    # Class call
    return if ( for_future_only( $self, $options_ref->{'instances'}, 'event', $event_name, $event_ref, $options_ref ) );
      
    my $instance_ref = $self->[INSTANCE];
    my $ids_ref = undef;
    for my $id ( keys %$instance_ref ) {
        my $id_ref = $instance_ref->{$id};
        my $name = $id_ref->{'name'};
        my $old_event_ref = $id_ref->{'events'}{$event_name};
        if ( event_is_applicable( $old_event_ref, $event_ref, $options_ref, $name ) ) {
            my $seq_value_ref = undef;
            if ( exists $event_ref->{'sequence'} ) {
                $seq_value_ref = $event_ref->{'sequence'};
                $id_ref->{'sequences'}{$event_name} = $seq_value_ref;
            }
            $old_event_ref = $event_ref;
            push @$ids_ref, $id;
        }
    }
    
    # Référencement du nouvel évènement dans les thread qui en ont besoin
    if ( $ids_ref ) {
        if ( exists $event_ref->{'sequence'} ) {
            return ( $ids_ref, { 0 => 1 }, {
                'sequence' => { $event_name => $event_ref->{'sequence'} },
                'event'    => $event_ref,
                'name'     => $event_name,
            } );                
        }
        else {
            return ( $ids_ref, { 0 => 1 }, {
                'event'    => $event_ref,
                'name'     => $event_name,
            } );                
        }
    }
    else {
        return;
    }
}

sub data_set_events {
    my ( $self, $id, $events_ref, $options_ref ) = @_;
    
    print DBG "\n\nDans data_set_event : id = $id\n\n\n";

    if ( $id ) {
        my $instance_ref = $self->[INSTANCE]{$id};
        if ( event_is_applicable( $instance_ref->{'events'}, $events_ref, $options_ref, $instance_ref->{'name'} ) ) {
            
            # Copie inutile : aucune référence utilisée en double
            $instance_ref->{'events'} = $events_ref;
            
            my $sequence_ref = undef;
            for ( my ( $event_name, $value_ref ) = each ( %$events_ref ) ) {
                if ( exists $value_ref->{'sequence'} ) {
                    $sequence_ref->{$event_name} = $value_ref->{'sequence'};
                }
            }
            if ( defined $sequence_ref ) {
                return ( [ $id ], { '0' => 1 }, { 
                    'sequence' => $sequence_ref,
                    'events'   => $events_ref,
                } );
            }
            else {
                return ( [ $id ], { '0' => 1 }, { 
                    'events'    => $events_ref,
                } );
            }
        }
        return;
    }
   
    # Class call
    return if ( for_future_only( $self, $options_ref->{'instances'}, 'events', $events_ref, $options_ref ) );
      
    my $root_ref = $self->[INSTANCE];
    my $id_ref;
    
    for my $id ( keys %$root_ref ) {
        my $instance_ref = $root_ref->{$id};
        if ( event_is_applicable( $instance_ref->{'events'}, $events_ref, $options_ref, $instance_ref->{'name'} ) ) {

            # Copie indispensable : un appel a set_event d'instance (après un set_events de classe) modifierait l'ensemble des instances à tort
            %{ $instance_ref->{'events'} } = %$events_ref;

            push @$id_ref, $id;
        }
    }
    
    # Référencement du nouvel évènement dans les thread qui en ont besoin
    if ( $id_ref ) {
        my $sequence_ref = undef;
        for ( my ( $event_name, $value_ref ) = each ( %$events_ref ) ) {
            if ( exists $value_ref->{'sequence'} ) {
                $sequence_ref->{$event_name} = $value_ref->{'sequence'};
            }
        }
        if ( defined $sequence_ref ) {
            return ( $id_ref, { 0 => 1 }, {
                'sequences' => $sequence_ref,
                'events'    => $events_ref,
            } );                
        }
        else {
            return ( $id_ref, { 0 => 1 }, {
                'events'    => $events_ref,
            } );                
        }
    }
    else {
        return;
    }
}

sub for_future_only {
    my ( $self, $instances, $method, @data ) = @_;
    
    if ( defined $instances and ! $true_instance_value{$instances} ) {
        print STDERR "'$instances' is an unknown value for 'instances' option of 'set_$method' method\n";
        return 1;
    }
    if ( ! $instances or ( $instances eq 'all' or $instances eq 'future' ) ) {
        push @{$self->[DEFAULT]}, [ $method, @data ];
    }
    if ( $instances and $instances eq 'future' ) {
        return 1;
    }
    return;
}

sub sequence_is_applicable {
    my ( $old_sequence_ref, $sequence_ref, $options_ref, $name ) = @_;

    # Correspondance de nom
    $options_ref = {} if ( ! defined $options_ref );
        
    my $names = $options_ref->{'names'};
    if ( defined $names and $names->isa('Regexp') ) {
        if ( ! defined $name or $name !~ $names ) {
            return;
        }
    }

    # Correspondance de valeurs
    my $values = $options_ref->{'values'};
    if ( defined $values ) {
        if ( $values eq 'defined' ) {
            my $OK = 0;
            SEQ: for my $seq_name ( keys %$sequence_ref ) {
                if ( defined $old_sequence_ref->{$seq_name} ) {
                    $OK = 1;
                    last SEQ;
                }
            }
            return if ( ! $OK );
        }
        elsif ( $values eq 'undefined' ) {
            my $KO = 0;
            SEQ: for my $seq_name ( keys %$sequence_ref ) {
                if ( defined $old_sequence_ref->{$seq_name} ) {
                    $KO = 1;
                    last SEQ;
                }
            }
            return if ( $KO );
        }
        else {
            print STDERR "'$values' is an unknown value for 'values' option\n";
            return;
        }
    }
    return 1;
}

sub event_threads {
    my ( $self, $id, $name ) = @_;
    
    return if ( ! defined $id or ! defined $name );
    return ( [ 0, 2 ], $self->[INSTANCE]{$id}{'events'}{$name} );
}

sub update_events {
    my ( $self, $ref, $id_ref, $options_ref ) = @_;
    
    # clé 'sequences'
    my $instance_ref = $self->[INSTANCE];
    my $sequence_ref = $options_ref->{'sequences'};
    if ( defined $sequence_ref ) {
        #print STDERR "Il faut faire un update de sequence : ", dump( $sequence_ref ), "\n";
        for my $id ( @$id_ref ) {
            # Affectation inutile... (travail par référence)
            $instance_ref->{$id}{'sequences'} = merge_sequence( $instance_ref->{$id}{'sequences'}, $sequence_ref );
        }
    }
    
    # clés 'event' et 'name'
    my $event_ref = $options_ref->{'event'};
    my $event_name = $options_ref->{'name'};
    if ( defined $event_name ) {
        for my $id ( @$id_ref ) {           
            $instance_ref->{$id}{'events'}{$event_name} = $event_ref;
        }
    }
    
    # clés 'events'
    my $events = $options_ref->{'events'};
    if ( defined $events ) {
        for my $id ( @$id_ref ) {           
            $instance_ref->{$id}{'events'} = $events;
        }
    }
}


sub merge_sequences {
    my ( $new_sequence_ref, $sequence_ref ) = @_;
    
    while ( my ( $name, $seq_ref ) = each %$sequence_ref ) {
        if ( defined $seq_ref ) {
            $new_sequence_ref->{$name} = $seq_ref;
        }
        else {
            # La clé existe, donc suppression
            delete $new_sequence_ref->{$name}
        }
    }
    return $new_sequence_ref;
}

sub force_default {
    my ( $default_ref, $event_ref, $sequence_ref, $name ) = @_;
    
    print DBG "Dans force_default\n";
    
    return ( $event_ref, $sequence_ref ) if ( ! defined $default_ref );
    
    print DBG "\n\n\ndefault_ref DEFINI !!! : ", dump( $default_ref ), "\n\n\n";
    
    for my $el_ref ( @$default_ref ) {
        my @data = @$el_ref;
        my $type = shift @data;
        print DBG "Forçage d'un type $type\n";
        if ( $type eq 'sequence' ) {
            $sequence_ref = force_sequence ( $sequence_ref, $name, @data );
        }
        elsif ( $type eq 'event' ) {
            ( $event_ref, $sequence_ref ) = force_event ( $event_ref, $sequence_ref, $name, @data );
        }
        else { # type eq 'events'
            ( $event_ref, $sequence_ref ) = force_events ( $event_ref, $sequence_ref, $name, @data );
        }
    }    
    return ( $event_ref, $sequence_ref );
}

sub force_sequence {
    my ( $old_sequence_ref, $name, $sequence_ref, $options_ref ) = @_;
    
    if ( sequence_is_applicable( $old_sequence_ref, $sequence_ref, $options_ref, $name ) ) {
        my $new_sequence_ref = merge_sequences( $old_sequence_ref, $sequence_ref );
        return $new_sequence_ref;
    }
}

sub force_event {
    my ( $events_ref, $sequence_ref, $name, $event_name, $event_ref, $options_ref ) = @_;
    
    if ( event_is_applicable( $events_ref->{$event_name}, $event_ref, $options_ref, $name ) ) {
        if ( exists $event_ref->{'sequence'} ) {
            $sequence_ref->{$event_name} = $event_ref->{'sequence'};
        }
        $events_ref->{$event_name} = $event_ref;
    }
    return ( $events_ref, $sequence_ref );
}


sub merge_seq_in_events {
    my ( $self, $event_ref, $sequence_ref, $name ) = @_;
    
    # Fusion de 'events' et 'sequences' en un seul 'sequences', 'sequences' est prioritaire
    while ( my ( $name, $value_ref ) = ( each %$event_ref ) ) {
        if ( ref $value_ref ne 'HASH' ) {
            $value_ref = $value_ref->[0];
        }
        my $seq_event = $value_ref->{'sequence'};
        if ( defined $seq_event and ! defined $sequence_ref->{$name} ) {
            $sequence_ref->{$name} = $seq_event;
        }
    }
    
    # A faire, forçage compte tenu des appels de classe antérieurs à 'set_sequene'
    return ( $event_ref, $sequence_ref );
}

sub event_is_applicable{
    my ( $old_event_ref, $event_ref, $options_ref, $name ) = @_;
    
    $options_ref = {} if ( ! defined $options_ref );
    
    my $names = $options_ref->{'names'};
    if ( defined $names and $names->isa('Regexp') ) {
        if ( ! defined $name or $name !~ $names ) {
            return;
        }
    }
    #print "Le nom correspond ou il n'y a pas d'expression régulière\n";
    my $values = $options_ref->{'values'};
    if ( defined $values ) {
        if ( $values eq 'defined' and ! defined $old_event_ref ){
            return;
        }
        if ( $values eq 'undefined' and defined $old_event_ref ) {
            return;
        }
    }
    return 1;
}

sub force_events {
    my ( $events_ref, $sequence_ref, $name, $default_events_ref, $options_ref ) = @_;
    
    if ( event_is_applicable( $events_ref, $default_events_ref, $options_ref, $name ) ) {
        for ( my ( $event_name, $value_ref ) = each ( %$default_events_ref ) ) {
            if ( exists $value_ref->{'sequence'} ) {
                @{$sequence_ref->{$event_name}} = @{$value_ref->{'sequence'}};
            }
        }
        %$events_ref = %$default_events_ref;
    }
    return ( $events_ref, $sequence_ref );
}

sub set_default {
    my ( $self, $default ) = @_;
    
    $self->[DEFAULT] = $default;
}

sub print_default_events {
    my ( $self ) = @_;
    
    print "DEFAULT EVENTS = ", dump( $self->[DEFAULT] ), "\n";
}

sub data_zone {
    my ( $self, $ref ) = @_;
    
    return $self->[ZONE]{$ref};
}

sub data_file_name {
    my ( $self, $ref, $key ) = @_;

    #print DBG "Dans data_file_name $self|$ref|";
    my $instance_ref = $self->[INSTANCE]{$ref};
    #print DBG "$file_name" if ( defined $file_name );
    #print DBG "|\n";
    if ( wantarray ) {
        return (
            $instance_ref->{'absolute_path'},
            $instance_ref->{'file_name'},
            $instance_ref->{'relative_path'},
            $instance_ref->{'full_absolute'},
            $instance_ref->{'full_relative'},
            $instance_ref->{'name'},
        )
    }
    else {
        if ( defined $key ) {
           #print "Dans data_file_name : demande pour ref = $ref, key = $key\n";
           return $instance_ref->{$key};
        }
        else {
           return $instance_ref->{'file_name'};
        }
    }
}

sub data_name {
    my ( $self, $ref ) = @_;

    return $self->[INSTANCE]{$ref}{'name'};
}

sub data_get_editor_from_name {
    my ( $self, $wanted_name ) = @_;

    my $instance_ref = $self->[INSTANCE];

    print DBG "Dans data_get...$self|$wanted_name|$instance_ref\n";
    #return if ( ref $instance_ref ne 'HASH');
    for my $key_ref ( keys %{$instance_ref} ) {
        print DBG "Dans boucle data...$key_ref|$instance_ref->{$key_ref}|\n";
        #return if ( ref $instance_ref->{$key_ref} ne 'HASH' );
        my $name = $instance_ref->{$key_ref}{'name'};
        if ( defined $name and $name eq $wanted_name ) {


            return $key_ref;
        }
    }
    return;
}

sub data_get_editor_from_file_name {
    my ( $self, $wanted_name ) = @_;

    my $instance_ref = $self->[INSTANCE];

    #print DBG "Dans data_get...$self|$wanted_name\n";
    for my $key_ref ( keys %{$instance_ref} ) {
        my $name = $instance_ref->{$key_ref}{'file_name'};

        #print DBG "Dans boucle data...$key_ref|$name\n";
        return $key_ref if ( defined $name and $name eq $wanted_name );
    }
    return;
}

sub find_in_zone {
    my ( $self, $zone, $file_name ) = @_;

    #print "Dans find_in_zone de Data : $self, $zone, $file_name\n";
    my $tab_of_file_ref = $self->[FILE_OF_ZONE]{$zone}{$file_name};
    my @ref_editor;
    my $tab_of_zone_ref = $self->[EDITOR_OF_ZONE]{$zone};
    for my $order (@$tab_of_file_ref) {

        #print "Trouvé à la position $order de la zone $zone\n";
        push @ref_editor, $tab_of_zone_ref->[$order];
    }
    return @ref_editor;
}

sub list_in_zone {
    my ( $self, $zone ) = @_;

    #print "Dans Liste_in_zone : $zone\n";
    my $tab_of_zone_ref = $self->[EDITOR_OF_ZONE]{$zone};
    my @ref_editor;
    for (@$tab_of_zone_ref) {
        push @ref_editor, $_;
    }
    return @ref_editor;
}

sub init_data {
    my ( $self, $reference, $trace_ref ) = @_;

    #print DBG "Dans init_data : $self, $reference, $trace_ref\n";
    bless $self, 'Text::Editor::Easy::Data';

    #print "Data a été créé\n";
    $self->[COUNTER] = 0;         # PAs de redirection de print
    $self_global = $self;         # Mise à jour de la variable 'globale'
    if ( defined $trace_ref->{'trace_print'} and $trace_ref->{'trace_print'} eq 'full' ) {
        create_full_trace_server( $self );
        $self->[FULL_TRACE] = 1;
    }
}

sub update_full_trace {
    my ( $self ) = @_;
    
    if ( defined $Text::Editor::Easy::Trace{'trace_print'} ) {
        if ( $Text::Editor::Easy::Trace{'trace_print'} eq 'full' ) {
            create_full_trace_server( $self );
            $self->[FULL_TRACE] = 1;
        }
        elsif ( defined  $self->[FULL_TRACE] ) {
            $self->[FULL_TRACE] = 0;
        }
    }
}



# Traçage
my %function = (
    'print'    => \&trace_print,
    'call'     => \&trace_call,
    'response' => \&trace_response,
#    'new'      => \&trace_new,
    'start'    => \&trace_start,
);

sub trace {
    my ( $self, $function, @data ) = @_;
    
    print DBG "Dans sub trace pour fonction $function\n";
    $function{$function}->( $self, @data );
}

my $trace_print_counter;

sub trace_print {
    my ( $self, $dump_hash, @param ) = @_;

    #Ecriture sur fichier
    my $seek_start = tell ENC;
    no warnings;    # @param peut contenir des élément undef
    print DBG "Début d'écriture sur ENC, start = $seek_start\n";
    print ENC @param;
    my $param = join( '', @param );
    use warnings;
    my $seek_end = tell ENC;
    print DBG "Fin d'écriture sur ENC, end = $seek_end\n";

    # Traçage des print
    my %options;
    #print DBG "trace_print avant eval dump\n";
    if ( defined $dump_hash ) {
        %options = eval $dump_hash;
        return if ($@);
    }
    else {
        return;
    }
    #print DBG "trace_print après eval dump\n";
    my @calls = eval $options{'calls'};
    my $tid = $options{'who'};

    my $thread_ref = $self->[THREAD][$tid];

    #        my $seek_start = tell ENC;
    #        no warnings; # @param peut contenir des élément undef
    #        {
    #            my $call_id = "";
    #            $call_id = $thread_ref->[CALL_ID] if ( defined $call_id );
    #            print ENC $tid, "|", $call_id, ":", @param;
    #        }
    #        my $param = join ('', @param);
    #        use warnings;
    #        my $seek_end = tell ENC;
    #return if ( !defined $thread_ref );

    if ( my $eval_ref = $thread_ref->[EVAL] ) {
        for my $tab_ref ( @calls ) {
            my $file = $tab_ref->[1];

         #print ENC "evaluated file $eval_ref->[0]|$eval_ref->[1]|FILE|$file\n";
            if ( $file =~ /\(eval (\d+)/ ) {
                if ( $1 >= $eval_ref->[1] ) {
                    $tab_ref->[1] = $eval_ref->[0];
                }
            }
        }
        $options{'calls'} = dump @calls;
    }

    if ( defined $thread_ref->[STATUS] ) {

        #print DBG "\t  Statut de $tid : ", $thread_ref->[STATUS][0] . "\n";
    }
    my $call_id_ref = $thread_ref->[CALL_ID_REF];
    my $call_id;
    if ( defined $call_id_ref ) {
        $call_id = $thread_ref->[CALL_ID];

        #print DBG "\tThread liste :\n";
        for my $thread_id ( sort keys %{ $call_id_ref->[THREAD_LIST] } ) {

            #print DBG "\t\t$thread_id\n";
        }

        #print DBG "\tMethod liste :\n";
        for my $method ( sort keys %{ $call_id_ref->[METHOD_LIST] } ) {

            #print DBG "\t\t$method\n";
        }
    }

    # Redirection éventuelle du print
    #print DBG "trace_print avant redirection\n";
    if ( my $hash_list_ref = $self->[REDIRECT] ) {

      #print DBG "REDIRECTION effective pour appel ", $thread_ref->[CALL_ID], "\n";
      RED: for my $redirect_ref ( values %{$hash_list_ref} ) {

            # Eviter l'autovivification
            next RED
            if ( !defined $call_id_ref
                and $tid != $redirect_ref->{'thread'} );

#print DBG "redirect_ref thread = ", $redirect_ref->{'thread'}, " (tid = $tid)\n";
            if ( $tid == $redirect_ref->{'thread'}
                or defined $call_id_ref->[THREAD_LIST]
                { $redirect_ref->{'thread'} } )
            {

                print DBG "A ECRIRE : ", join ('', @param), "\n";
                my $excluded = $redirect_ref->{'exclude'};

 #      print DBG "Excluded : ", $call_id_ref->[THREAD_LIST]{ $excluded }, "\n";
                next RED
                  if (  defined $excluded
                    and defined $call_id_ref->[THREAD_LIST]{$excluded} );
                Text::Editor::Easy::Async->ask2( $redirect_ref->{'method'},
                    $seek_start, $param );
# Redirection synchrone impossible : appel de méthode quasi-standard (ask2) donc demande
# de traçage de la méthode (trace_call, trace_start puis trace_response) au thread Data qui ne peut
# par conséquent pas attendre ici (sans quoi, il ne répondrait plus aux requêtes de traçage et tout se bloque...)

                # La seule façon d'être synchrone, ne plus activer la trace pour l'appel et ses successeurs et ne jamais
                # rien demander au thread 2 en synchrone jusqu'à la fin...
                # ==> paramètre supplémentaire à l'appel à passer à toute la chaîne d'appel (possible ? sans Data)
                
                # La solution la plus simple est de loin le pseudo-synchronisme... mais elle ne sert pas à grand chose
                # sinon à bloquer les threads...
            }

  #         print DBG "redirect_ref method = ", $redirect_ref->{'method'}, "\n";
        }
    }

    if ( $self->[FULL_TRACE] ) {
        if ( ! defined $options{'line'} ) {
            Text::Editor::Easy::Async->trace_full_print( $seek_start, $seek_end, $tid,
            $call_id, $options{'on'}, $options{'calls'}, $param );
        }
        else {
            Text::Editor::Easy::Async->trace_full_eval_err ( $seek_start, $seek_end, $dump_hash, $param );
        }
    }
    #print DBG "Fin trace_print $self\n";
    
    # Eviter autre chose que le context void pour Text::Editor::Easy::Async
    return;
}

sub create_full_trace_server {
    my ( $self ) = @_;
    
    return if ( defined $self->[FULL_TRACE] );
    
    Text::Editor::Easy->create_new_server( {
        'use'     => 'Text::Editor::Easy::Trace::Full',
        'package' => "Text::Editor::Easy::Trace::Full",
        'methods' => [ 
            'trace_full_print',
            'get_info_for_display',
            'trace_full_call',
            'get_info_for_call',
            'trace_full_eval',
            'get_code_for_eval',
            'trace_full_eval_err',
            'get_info_for_eval_display',
            'declare_trace_for',
            'get_info_for_extended_trace',
        ],
        'object'  => [],
        'init'    => [
            'Text::Editor::Easy::Trace::Full::init_trace_full',
            $own_STDOUT
        ],
    } );
}

sub reference_print_redirection {
    my ( $self, $hash_ref ) = @_;

    if ( !defined $self->[COUNTER] ) {
        $self->[COUNTER] = 0;
    }
    my $counter = $self->[COUNTER] + 1;

    $self->[REDIRECT]{$counter} = $hash_ref;
    $self->[COUNTER] = $counter;
    return $counter;
}

sub trace_call {
    my (
        $self,    $call_id, $server, $method, $editor_id,
        $context, $seconds, $micro,  @calls
      )
      = @_;

    $self->[TOTAL][CALLS] += 1;

    print DBG "C|$call_id|$server|$seconds|$micro|$method\n";

    my ( $client, $id ) = split( /_/, $call_id );
    my $thread_ref = $self->[THREAD][$client]; 
    
    if ( $self->[FULL_TRACE] ) {
        my $client_call_id = $thread_ref->[CALL_ID];
        #print DBG "Appel trace_full_call pour call_id = $call_id\n";
        Text::Editor::Easy::Async->trace_full_call( $call_id, $client_call_id, @calls );
    }
    #else {
    #    print DBG "Pas d'appel pour call_id = $call_id => $self->[FULL_TRACE]\n";
    #}
    
    my $call_id_ref = $self->[CALL]{$call_id};
    $call_id_ref->[CONTEXT] = $context;
    if ( length($context) == 1 )
    {    # Appel synchrone, donc le thread appelant se met en attente
        unshift @{ $thread_ref->[STATUS] }, "P|$call_id|$server|$method"
          ;    # Thread $client pending for $server ($method)
        $call_id_ref->[SYNC] = 1;
    }
    else {
        $call_id_ref->[SYNC] = 0;
    }

    #print DBG "Dans trace_call, définition de \$call_id_ref |$call_id_ref| effectuée, call_id $call_id, tid", threads->tid, "\n";

    # Le thread client est peut-être déjà au service d'un call...
    if ( $call_id_ref->[SYNC] ) {

        #print DBG "$call_id synchrone ($context)\n";
        if ( my $previous_call_id_ref = $thread_ref->[CALL_ID_REF] ) {
            #if ( ref $previous_call_id_ref->[THREAD_LIST] ne 'HASH' ) {
            #    print DBG "PAs une référence de hachage pour thread client $client, call_id en cours $call_id\n" .
            #     "\t|$previous_call_id_ref|$previous_call_id_ref->[THREAD_LIST]|, tid", threads->tid, "\n";
            #}
            #print DBG "CALL_ID = $thread_ref->[CALL_ID], ref =  $previous_call_id_ref, $previous_call_id_ref->[THREAD_LIST]\n";
            #print DBG "=> appel du previous par $call_id synchrone\n";
            %{ $call_id_ref->[THREAD_LIST] } =
              %{ $previous_call_id_ref->[THREAD_LIST] };
            %{ $call_id_ref->[METHOD_LIST] } =
              %{ $previous_call_id_ref->[METHOD_LIST] };
            %{ $call_id_ref->[INSTANCE_LIST] } =
              %{ $previous_call_id_ref->[INSTANCE_LIST] };

#print DBG "Thread liste pour $call_id futur : ", keys %{$call_id_ref->[THREAD_LIST]}, "\n";
        }
        else {

            #print DBG "Pour $call_id, pas de récupération d'éléments\n";
            $call_id_ref->[THREAD_LIST]{$client} = 1;
        }
    }
    else
    { # En asynchrone, tant qu'il n'est pas démarré, personne (aucun thread) ne s'occupe de cette demande (call_id)
        $call_id_ref->[THREAD_LIST] = {};
    }

    #print DBG "THREAD_LIST de $call_id après CALL contexte $context :\n";
    #for ( sort keys %{$call_id_ref->[THREAD_LIST]} ) {
    #        print DBG "$_ ";
    #}
    #print DBG "\n";
    $call_id_ref->[METHOD_LIST]{$method}       = 1;
    $call_id_ref->[INSTANCE_LIST]{$editor_id} = 1;
    $call_id_ref->[METHOD]                     = $method;
    $call_id_ref->[C_INSTANCE]                   = $editor_id;

    my $thread_status = $self->[THREAD][$server][STATUS][0];
    if ( defined $thread_status and $thread_status =~ /^P/ ) {

        # deadlock possible
        print DBG
"DANGER client '$client' asking '$method' to server '$server', already pending : $thread_status\n";
    }
    $call_id_ref->[STATUS] = 'not yet started';

    $self->[CALL]{$call_id} = $call_id_ref;
    $self->[THREAD][$client] = $thread_ref;
}

sub trace_new {
    my ( $self, $from, $dump_array ) = @_;

    #print DBG "N:$from\n";
    my @calls = eval $dump_array;
}

sub trace_response {
    my ( $self, $from, $call_id, $method, $seconds, $micro, $response ) = @_;

    my $call_id_ref = $self->[CALL]{$call_id};
    return
      if ( !defined $call_id_ref )
      ;    # Cela arrive pour les méthodes d'initialisation de thread
     # ==> tant qu'elles ne sont pas appelées de façon standard (avec traçage du call)

    #print DBG "trace_response : début d'actions sur \$call_id_ref |$call_id_ref|, méthod $method call_id $call_id, tid", threads->tid, "\n";
    #if ( ! defined $method ) {
    #    print DBG "La méthode est non définie , tid", threads->tid, "\n";
    #}
    #else {
    #    print DBG "La méthode vaut $method, tid", threads->tid, "\n";
    #} 

    $self->[TOTAL][RESPONSES] += 1;

    if ( !defined $method ) {
        $method = "? (asynchronous call) : " . $call_id_ref->[METHOD];
        $call_id_ref->[STATUS] = 'ended';
        $self->[RESPONSE]{$call_id} = $response;
    }

    print DBG "R|$from|$call_id|$seconds|$micro|$method\n";

# Ne faudrait-il pas faire plutot un shift de "$self->[THREAD][$from][STATUS]" ?
# ==> permettre de tracer des requêtes interruptibles tout en traçant les requêtes internes
    $self->[THREAD][$from] = ();
    $self->[THREAD][$from][STATUS][0] = "idle|$call_id";

    my ($client) = split( /_/, $call_id );

    my $status_ref = $self->[THREAD][$client][STATUS];
    
    if ( $call_id_ref->[SYNC] ) {
        if ( scalar(@$status_ref) < 2 ) {

         # Cas d'un thread client, pas vraiment idle mais on ne peut rien savoir
            $status_ref->[0] = 'idle';
        }
        else {
            shift @$status_ref;
        }
    }
    
    $self->[THREAD][$client][STATUS] = $status_ref;

    # Ménage de THREAD (systématique)
    #$self->[THREAD][$from][CALL_ID_REF] = ();
    #undef $self->[THREAD][$from][CALL_ID];

    my $call_id_client_ref = $self->[THREAD][$client][CALL_ID_REF];
    #if ( defined $call_id_client_ref ) {
    #    print DBG "Chargement de \$call_id_client_ref |$call_id_client_ref|, tid", threads->tid, "\n";
    #}

#if ( defined $call_id_client_ref ) {
#        print DBG "Liste de threads avant ménage pour l'appelant (", $self->[THREAD][$client][CALL_ID], ")\n";
#        for ( sort keys %{$call_id_client_ref->[THREAD_LIST]} ) {
#            print DBG "$_ ";
#        }
#        print DBG "\n";
#}
#print DBG "Mise à zéro de la THREAD_LIST pour $call_id\n";

 # Ménage de CALL et RESPONSE (sauf si asynchrone avec récupération identifiant)
    if ( $call_id_ref->[SYNC] or $call_id_ref->[CONTEXT] eq 'AV' ) {    # Asynchronous Void
        #print DBG "trace_response : suppressions des listes pour \$call_id_ref |$call_id_ref| call_id $call_id, tid", threads->tid, "\n";
        %{ $call_id_ref->[THREAD_LIST] }   = ();
        %{ $call_id_ref->[METHOD_LIST] }   = ();
        %{ $call_id_ref->[INSTANCE_LIST] } = ();

        #$call_id_ref->[PREVIOUS] = 0;
        $self->[CALL]{$call_id} = $call_id_ref;
        @{ $self->[CALL]{$call_id} } = ();
        delete $self->[CALL]{$call_id};
        delete $self->[RESPONSE]{$call_id};
    }
    $call_id_client_ref = $self->[THREAD][$client][CALL_ID_REF];

#if ( defined $call_id_client_ref ) {
#        print DBG "Liste de threads restant pour l'appelant (", $self->[THREAD][$client][CALL_ID], ")\n";
#        for ( sort keys %{$call_id_client_ref->[THREAD_LIST]} ) {
#            print DBG "$_ ";
#        }
#        print DBG "\n";
#}
#if ( my $call_id_ref = $self->[CALL]{$call_id} ) {
#    print DBG "Status de call_id $call_id : ", $call_id_ref->[STATUS], "\n";
#}
#else {
#    print DBG "$call_id plus défini...\n";
#}


}

sub free_call_id {
    my ( $self, $call_id ) = @_;

    #print DBG "Dans free_call_id A libérer : $call_id\n";

    my $call_id_ref = $self->[CALL]{$call_id};

    #print DBG "   Context $call_id_ref->[CONTEXT]\n";

    %{ $call_id_ref->[THREAD_LIST] }   = ();
    %{ $call_id_ref->[METHOD_LIST] }   = ();
    %{ $call_id_ref->[INSTANCE_LIST] } = ();

    #$call_id_ref->[PREVIOUS] = 0;
    $self->[CALL]{$call_id} = $call_id_ref;
    @{ $self->[CALL]{$call_id} } = ();
    delete $self->[CALL]{$call_id};
}

sub trace_start {
    my ( $self, $who, $call_id, $method, $seconds, $micro ) = @_;

    my $call_id_ref = $self->[CALL]{$call_id};
    return if ( !defined $call_id_ref );
    
    #print DBG "Dans trace_start \$call_id_ref |$call_id_ref|, call_id $call_id, tid", threads->tid, "\n";

    $self->[TOTAL][STARTS] += 1;

    my $thread_ref = $self->[THREAD][$who];
    my $status_ref = $thread_ref->[STATUS];
    unshift @$status_ref, "R|$method|$call_id"; # Thread $who is running $method

    $call_id_ref->[STATUS] = 'started';

    print DBG "S|$who|$call_id|$seconds|$micro|$method\n";

    $call_id_ref->[THREAD_LIST]{$who} = 1;

    #print DBG "Ajout de $who pour la THREAD_LIST de $call_id\n\t";
    #print DBG "$call_id_ref ";
    #for ( sort keys %{$call_id_ref->[THREAD_LIST]} ) {
    #        print DBG "$_ ";
    #}
    #print DBG "\n";

    $call_id_ref->[THREAD]{$who} = 1;
    $self->[CALL]{$call_id}      = $call_id_ref;

    $thread_ref->[CALL_ID_REF] = $call_id_ref;
    $thread_ref->[CALL_ID]     = $call_id;

    $self->[THREAD][$who] = $thread_ref;

    #Débuggage du débuggage
    #my @imbriqued_calls = keys %{ $call_id_ref->[THREAD_LIST] };
    #if ( scalar @imbriqued_calls > 2 ) {
    #        for my $thread_id ( sort @imbriqued_calls ) {
    #print DBG "\tS!!! $thread_id|";
    #            for my $status ( @{ $self->[THREAD][$thread_id][STATUS] } ) {
    #print DBG " $status,";
    #            }
    #print DBG "\n";
    #        }
    #}
    # Vérification de la thread liste de l'appelant si synchrone  (debuggage)
    if ( $call_id_ref->[SYNC] ) {
        my ($client) = split( /_/, $call_id );
        my $thread_ref = $self->[THREAD][$client];

        #if ( defined $thread_ref and defined $thread_ref->[CALL_ID] ) {
        #print DBG "THREAD_LIST de l'appelant $thread_ref->[CALL_ID] :\n\t";
        #my $call_client_ref = $thread_ref->[CALL_ID_REF];
        #for ( sort keys %{$call_client_ref->[THREAD_LIST]} ) {
        #    print DBG "$_ ";
        #}
        #print DBG "\n";
        #}
    }
    #print DBG "Fin de trace_start : $call_id, $call_id_ref, $call_id_ref->[THREAD_LIST]\n";
}

sub async_status {
    my ( $self, $call_id ) = @_;

#print "Dans async_status $self|$call_id|", $self->[CALL]{$call_id}[STATUS], "\n";
#print DBG "Dans async_status $self|$call_id|", $self->[CALL]{$call_id}[STATUS], "\n";
    return $self->[CALL]{$call_id}[STATUS];
}

sub async_response {
    my ( $self, $call_id ) = @_;

    my $call_id_ref = $self->[CALL]{$call_id};
    return if ( !defined $call_id_ref );
    if ( $call_id_ref->[STATUS] eq 'ended' ) {
        my $response = $self->[RESPONSE]{$call_id};

        # Ménage : la réponse ne peut être récupérée qu'une seule fois
        %{ $call_id_ref->[THREAD_LIST] }   = ();
        %{ $call_id_ref->[METHOD_LIST] }   = ();
        %{ $call_id_ref->[INSTANCE_LIST] } = ();

        #$call_id_ref->[PREVIOUS] = 0;
        $self->[CALL]{$call_id} = $call_id_ref;
        @{ $self->[CALL]{$call_id} } = ();
        delete $self->[CALL]{$call_id};
        delete $self->[RESPONSE]{$call_id};
        return eval $response;
    }
    return;
}

sub size_self_data {
    my ($self) = @_;

    print "DATA self size ", total_size($self), "\n";
    print "   THREAD   : ", total_size( $self->[THREAD] ), "\n";
    print "   CALL     : ", total_size( $self->[CALL] ),   "\n";
    my @array = %{ $self->[CALL] };
    print "Nombre de clé x 2 : ", scalar(@array), "\n";
    print DBG "Nombre de clé x 2 : ", scalar(@array), "\n";
    my $hash_ref = $self->[CALL];
    for ( sort keys %{ $self->[CALL] } ) {
        print DBG "\t$_|", $hash_ref->{$_}[CONTEXT], "|",
          $hash_ref->{$_}[METHOD], "\n";
    }
    print "   RESPONSE : ", total_size( $self->[RESPONSE] ), "\n";
    print "   DATA THREAD :", total_size( threads->self() ), "\n";
    print "   TOT CALLS   :", $self->[TOTAL][CALLS],     "\n";
    print "   TOT STARTS  :", $self->[TOTAL][STARTS],    "\n";
    print "   TOT RESPONS :", $self->[TOTAL][RESPONSES], "\n";
}

sub print_thread_list {
    my ( $self, $tid ) = @_;

    return if ( !defined $tid );
    my $string = "Thread liste :";

    my $thread_ref = $self->[THREAD][$tid];
    if ( !defined $thread_ref ) {
        $string .= "\n\t|$tid";
    }
    else {
        my $call_id_ref = $thread_ref->[CALL_ID_REF];

        if ( defined $call_id_ref ) {
            $string .= " ($thread_ref->[CALL_ID])\n\t";
            for my $thread_id ( sort keys %{ $call_id_ref->[THREAD_LIST] } ) {
                $string .= "|$thread_id";
            }
        }
        else {
            $string .= "\n\t|$tid";
        }
    }
    print $string, "|\n";
}

sub reference_zone {
    my ( $self, $hash_ref ) = @_;

    my $name = $hash_ref->{'name'};
    return if ( !defined $name );
    $self->[ZONE]{$name} = $hash_ref;
}

sub zone_named {
    my ( $self, $name ) = @_;

    my $hash = $self->[ZONE]{$name};
    #print DBG "Nom de la zone cherchée : $name\n";
    bless $hash, 'Text::Editor::Easy::Zone';
}

sub zone_list {
    my ($self, $complete) = @_;

    if ( ! defined $complete ) {
        return keys %{ $self->[ZONE] };
    }
    return $self->[ZONE];
}

sub save_current {
    my ( $self, $ref ) = @_;
    
    $self->[CURRENT] = $ref;    
}

sub data_last_current {
    my ( $self ) = @_;
    
    return $self->[CURRENT];
}

sub data_get_search_options {
        my ( $self, $ref ) = @_;
        
        return $self->[SEARCH]{$ref};
}

sub data_set_search_options {
        my ( $self, $ref, $options_ref ) = @_;
        
        $self->[SEARCH]{$ref} = $options_ref;
}

my $event_number = 0;

sub trace_user_event {
    my ( $self, $id, $event, $options_ref ) = @_;
    
    # Procédure appelée uniquement par le thread graphique (tid 0)
    my $thread_0_ref = $self->[THREAD][0];
    if ( $thread_0_ref->[STATUS][0] !~ /^idle/ ) {
        return $thread_0_ref->[CALL_ID];
    }
    
    my $call_id = 'U_' . $event_number;
    #trace_call ( $self, $call_id, 0, $event, $id, 'void', 0, 0);
    if ( $self->[FULL_TRACE] ) {
        Text::Editor::Easy::Async->trace_full_call( $call_id, undef, $event );
    }
    my $call_id_ref = $self->[CALL]{$call_id};
    $call_id_ref->[INSTANCE_LIST]{$id} = 1;
    $call_id_ref->[METHOD_LIST]{'user event'} = 1;
    $call_id_ref->[THREAD_LIST]{0} = 1;
    $call_id_ref->[C_INSTANCE] = $id;
    $call_id_ref->[STATUS] = 'started';
    $self->[CALL]{$call_id} = $call_id_ref;
    print DBG "Evènement $event\n\tDéclaration de call_id $call_id, ref $call_id_ref, $call_id_ref->[THREAD_LIST]\n";
    trace_start ( $self, 0, $call_id, $event, 0, 0 );
    return $call_id;
}

sub trace_end_of_user_event {
    my ( $self, $info ) = @_;
    
    # Procédure appelée uniquement par le thread graphique (tid 0)
    
    my $call_id = 'U_' . $event_number;
    my $call_id_ref = $self->[CALL]{$call_id};
    if ( !defined $call_id_ref ) {
        print DBG "L'évènement $call_id ('$info') n'avait pas été déclarée initialement ?...\n";
        return;
    }
    else {
        print DBG "Fin correctement déclarée de l'évènement '$info'\n";
    }
    %{ $call_id_ref->[INSTANCE_LIST] } = ();
    %{ $call_id_ref->[METHOD_LIST] } = ();

        #$call_id_ref->[PREVIOUS] = 0;
    $self->[CALL]{$call_id} = $call_id_ref;
    @{ $self->[CALL]{$call_id} } = ();
    delete $self->[CALL]{$call_id};
    $self->[THREAD][0] = ();
    $self->[THREAD][0][STATUS][0] = "idle|$call_id";

    #trace_response ( $self, 0, $call_id, undef, 0, 0 );
    $event_number += 1;
}

sub trace_eval {
    my ( $self, $eval, $tid, $file, $package,$line ) = @_;
#
    my $call_id = $self->[THREAD][$tid][CALL_ID];
    print DBG "Dans trace_eval : eval = $eval\n";
    print DBG "\t tid $tid|call_id $call_id\n";
    print DBG "\tpackage $package | line $line\n";
    if ( $self->[FULL_TRACE] ) {
        Text::Editor::Easy::Async->trace_full_eval (
            $eval, $tid, $file, $package, $line, $call_id,
        );
    }
    return $call_id;
    #\ttid $tid\n\tprevious $previous_call_id\n\tCALLS @calls\n";
}

my $length_s_n;

sub tell_length_slash_n {
    print DBG "Dans tell length\n";
    if ( defined $length_s_n ) {
        print DBG "length_s_n est déjà défini et vaut $length_s_n\n";
        return $length_s_n;
    }
    #return if ( ! $trace_ref{'trace_print'} );
    my $first = tell ENC;
    print DBG "Dans tell ltength : first = $first\n";
    print ENC "\n";
    print DBG "Dans tell ltength : taille ", tell(ENC) - $first,"\n";    
    $length_s_n = tell(ENC) - $first;
    return $length_s_n;
}


sub configure {
    my ( $self, $conf_ref ) = @_;
    
    $self->[CONF] = $conf_ref;
}

sub get_conf {
    my ( $self ) = @_;
    
    return $self->[CONF];
}

=head1 FUNCTIONS

=head2 async_response

=head2 async_status

=head2 data_file_name

=head2 data_get_editor_from_file_name

=head2 data_get_editor_from_name

=head2 data_get_search_options

Get the previously saved options of the search (regexp, initial positions) : not yet finished.

=head2 data_last_current

Get the Text::Editor::Easy reference that had focus when ctrl-f was pressed.

=head2 data_name

=head2 data_set_search_options

Set the search options (regexp, initial positions) : not yet finished.

=head2 find_in_zone

=head2 free_call_id

=head2 init_data

This sub shouldn't have been created. The link should always be made by the Zone object and a Zone event.

=head2 list_in_zone

=head2 print_thread_list

=head2 reference_editor

=head2 reference_print_redirection

=head2 reference_zone

=head2 save_conf

Return Text::Editor::Easy configurations : first line on the screen, at which height, cursor position...

=head2 save_current

Save the reference of the Text::Editor::Easy instance that has the focus and in which a search begins.

=head2 size_self_data

=head2 trace

=head2 trace_call

=head2 trace_new

=head2 trace_print

=head2 trace_response

=head2 trace_start

=head2 zone_list

=head2 zone_named

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


