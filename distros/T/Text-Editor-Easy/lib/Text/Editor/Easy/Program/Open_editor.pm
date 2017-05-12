package Text::Editor::Easy::Program::Open_editor;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Program::Open_editor - The "Open" function of the "Editor.pl" program uses a special "Text::Editor::Easy" object.
Here is the code that makes this instance special.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Text::Editor::Easy::Comm  qw(anything_for_me);
use threads;

sub syntax { 
        # Pas encore de gestion d'un affichage avec "filtre"
        # La mise en forme nécessiterait l'envoi de moins de caractères que ceux présents sur le fichier
        # Donc pour l'instant, on verra apparaître soit "D - ", soit "F - " en début de ligne
    my ($text) = @_;

    if ( $text =~ /^D - / ) { # Directory
        return [ $text, 'Package' ];
    }
    elsif ( $text =~ /^F - / ) { # File
        return [ $text, 'Subroutine' ];
    }
    else {
        return [ $text, 'comment' ];
    }
}

my $open_editor;

sub open {
    print "Dans open de Open_editor tid = ", threads->tid, "\n";
    
    my $dir;
    if ( ! defined $open_editor ) {
        use Cwd;
        $dir = getcwd;
    }
    else {
        $dir = $open_editor->load_info('dir');
    }
    if ( ! opendir(DIR,$dir) ) {
        print STDERR "Can't open directory $dir : $!\n";
        use Cwd;
        $dir = getcwd;
        $open_editor->save_info($dir, 'dir');
        if ( ! opendir(DIR,$dir) ) { 
            print STDERR "Can't open directory $dir : $!\n";
            return;
        }
    }
    print "Répertoire actuel $dir\n";
    my @content = readdir(DIR);
    my @dirs = grep { -d "$dir/$_" } @content;
    my @files = grep { -f "$dir/$_" } @content;
    
    # Pas encore d'interface utilisable pour travailler en mémoire avec File_manager : passage par un fichier intermédiaire
    # ==> un peu long
    #open (TMP, ">tmp/open_editor.tmp") or print STDERR "Can't open open_editor.tmp : $!\n";
    my $bloc;
    #print TMP "$dir\n";
    for ( sort @dirs ) {
        next if ( $_ eq '.' );
        #print TMP "D - $_\n";
        $bloc .= "D - $_\n";
    }
    for ( sort @files ) {
        #print TMP "F - $_\n";
        $bloc .= "F - $_\n";
    }
    #close TMP;
    
    if ( ! defined $open_editor ) {
        $open_editor = Text::Editor::Easy->new( {
            'zone'        => 'zone2',
            'focus'      => 'yes',
            'name'        => 'Open',
            'bloc' => $bloc,
            'highlight' => {
                'use'     => 'Text::Editor::Easy::Program::Open_editor',
                'package' => 'Text::Editor::Easy::Program::Open_editor',
                'sub'     => 'syntax',
            },
			'events' => {
                'motion' => {
                    'use'     => 'Text::Editor::Easy::Program::Open_editor',
                    'package' => 'Text::Editor::Easy::Program::Open_editor',
                    'sub'     => 'motion_last',
                    'thread'    => 'Motion',
                },
                'cursor_set' => {
                    'use'     => 'Text::Editor::Easy::Program::Open_editor',
                    'package' => 'Text::Editor::Easy::Program::Open_editor',
                    'sub'     => 'cursor_set_last',
                },
                'after_clic' => {
                    'use'     => 'Text::Editor::Easy::Program::Open_editor',
                    'sub'     => 'after_clic',
                },
		    },
        } );
        $open_editor->save_info($dir, 'dir');
        $open_editor->bind_key({ 'package' => 'Text::Editor::Easy::Program::Open_editor', 'sub' => 'up', 'key' => 'Up' } );
        $open_editor->bind_key({ 'package' => 'Text::Editor::Easy::Program::Open_editor', 'sub' => 'down', 'key' => 'Down' } );
        $open_editor->bind_key({ 'package' => 'Text::Editor::Easy::Program::Open_editor', 'sub' => 'enter', 'key' => 'Return' } );
    }
    else {
        $open_editor->empty;
        my $first_line = $open_editor->first;
        $open_editor->insert( $bloc, {
            'at_line' => $first_line,
            'display' => [
                $first_line,
                {'at' => 'top' },
            ],
            'cursor' => 'at_start',
        } );
        $open_editor->focus;
    }
    #print "Création de open_editor finie : $open_editor\n";
}

sub down {
    my ( $self ) = @_;

    print "Dans down_open...\n";
    # Appel de la touche par défaut... (avec l'objet Abstract auquel on n'a pas accès)
    my ( $ref_line ) = $self->ask_thread( 'Text::Editor::Easy::Abstract::Key::down', 0 );

    $self->deselect;    
    $self->line_select( $ref_line );
}

sub up {
    my ( $self ) = @_;

    print "Dans up_open...\n";
    # Appel de la touche par défaut... (avec l'objet Abstract auquel on n'a pas accès)
    my ( $ref_line ) = $self->ask_thread( 'Text::Editor::Easy::Abstract::Key::up', 0 );
    
    print "LINE_REF avec Up : $ref_line\n";    
    $self->deselect;    
    $self->line_select( $ref_line );
}

sub enter {
    my ( $self ) = @_;

    print "Dans enter_open...\n";

    my ( $line ) = $self->cursor->line;
    
    my $text = $line->text;
    print "LINE_text : $text\n";
    my $dir = $self->load_info('dir');
    if ( $text =~ /^F - (.*)$/ ) {
        my $file_name = $1;
        print "Il faut ouvrir le fichier $dir/$file_name\n";
        
        my $editor = Text::Editor::Easy->whose_name($file_name);
        if ( ! $editor ) {
            my $file_conf_ref = Text::Editor::Easy->get_conf_for_absolute_file_name( "$dir/$file_name" );
            if ( defined $file_conf_ref ) {
                $editor = Text::Editor::Easy->new( $file_conf_ref );
            }
            else {
                my @highlight;
                if ( $file_name =~ /\.pl$/i or $file_name =~ /\.pm$/ or $file_name =~ /\.t$/ ) {
                    @highlight = ( 'highlight' => {
                        'use'     => 'Text::Editor::Easy::Syntax::Perl_glue',
                        'package' => 'Text::Editor::Easy::Syntax::Perl_glue',
                        'sub'     => 'syntax',
                    } );
                }
                $editor = Text::Editor::Easy->new( {
                    'zone'      => 'zone1',
                    'file'      => "$dir/$file_name",
                    'name'      => $file_name,
                    @highlight,
                } );
            }
        }
        $editor->focus;
        return;
    }
    if ( $text =~ /^D - (.*)$/ ) {
        my $sub_dir = $1;
        
        print "Il faut ouvrir le répertoire $sub_dir du répertoire $dir\n";
        if ( $sub_dir ne '..') {
            $dir = "$dir/$sub_dir";
            $self->save_info($dir, 'dir');
            Text::Editor::Easy::Program::Open_editor::open();
        }
        else {
            $dir =~ /^(.*)\/[^\/]+$/;
            my $new_dir = $1;
            print "Il faut ouvrir le répertoire $new_dir ...\n";
            $self->save_info($new_dir, 'dir');
            Text::Editor::Easy::Program::Open_editor::open();
        }
    }
}

sub motion_last {
    my ( $id, $editor, $hash_ref ) = @_;
    
    return if ( anything_for_me );
    $editor->async->make_visible;
    return if ( anything_for_me );
    #print "Dans motion_last de Open_editor : editor = $editor\n";
    my $dir_or_file = $hash_ref->{'display'};
    my $initial_ord = $dir_or_file->ord;
    
    # La valeur de retour devra maintenant utiliser un hachage : beaucoup trop de paramètres !
    my ( undef, undef, $cursor_display ) = $editor->cursor->get;
    
    return if ( anything_for_me );
    my $final_ord;
    if ( $dir_or_file ne $cursor_display ) {
        print "Display du motion : $dir_or_file soit ", $dir_or_file->text, "\n";
        print "Display du curseur : $cursor_display soit ", $cursor_display->text, "\n";
        ( undef, undef, undef, undef, undef, undef, undef, $final_ord ) = $editor->cursor->set( 0, $dir_or_file );
        
        # Défilement automatique vers le bas ou vers le haut en l'absence de focus... : le clic standard a aussi été redirigé
        if ( $initial_ord != $final_ord ) {
            print "Dans motion last de Open_editor : ORD = init : $initial_ord, final : $final_ord\n";
            $editor->motion( 15, $initial_ord - 1);
       }
    }
}

sub cursor_set_last {
    my ( $editor, $hash_ref ) = @_;

    print "Dans cursor_set_last de Open_editor...$editor\n";
    $editor->deselect;
    print "Ligne à sélectionner :", $hash_ref->{'line'}->text, "\n";
    $hash_ref->{'line'}->select;
}

sub after_clic {
    my ( $editor, $hash_ref ) = @_;
    
	print "Dans after clic de Open_editor\n";
    enter ( $editor );
	print "Dans after clic de Open_editor, après enter\n";
    $editor->motion( $hash_ref->{'x'}, $hash_ref->{'y'} );
	print "Dans after clic de Open_editor, après motion\n";
}


=head1 FUNCTIONS

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;




