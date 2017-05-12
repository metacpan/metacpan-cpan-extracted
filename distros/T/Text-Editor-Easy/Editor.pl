#!/usr/bin/perl
use lib 'lib';

use warnings;
use strict;

=head1 NAME

Editor.pl - An editor written using Text::Editor::Easy objects.

=head1 VERSION

Version 0.49

=cut

use IO::File;
use Data::Dump qw(dump);

if ( ! -d 'tmp' ) {
    print STDERR "Need a tmp directory under your current directory : can't go on\n";
    exit 1;
}

my %demo = (
    'demo7.pl'  => 1,
    'demo9.pl'  => 1,
    'demo10.pl' => 1,
    'demo12.pl' => 1,
);

sub demo8 {
    my $editor = Text::Editor::Easy->whose_name('demo8.pl');
    
    my $sub_ref = eval $editor->slurp;
    return $sub_ref->(@_);

    #print "End of execution\n";
}

sub main;

use Text::Editor::Easy { 
    'trace' => {
        'all' => 'tmp/',
        'trace_print' => 'full',
    },
    'short' => 'Editor', # Not so short, but clear
};

# Start from a distant path
use File::Basename;
my ( $file_name, $file_path ) = fileparse($0);

# Start of launching perl process (F5 key management)
open EXEC, "| perl ${file_path}exec.pl" or die "Fork impossible\n";
autoflush EXEC;

Text::Editor::Easy->set_event(
    'motion',
    {
        'action' => 'nop',
        'thread' => 'Motion',
    },
    { 'values' => 'undefined' }
);

# List of main tab files (loading delayed)
my @files_session;
for my $demo ( 1 .. 12 ) {
    $file_name = "${file_path}demo${demo}.pl";
    push @files_session,
      {
        'zone'      => 'zone1',
        'file'      => $file_name,
        'name'      => "demo${demo}.pl",
        'highlight' => {
            'use'     => 'Text::Editor::Easy::Syntax::Perl_glue',
            'package' => 'Text::Editor::Easy::Syntax::Perl_glue',
            'sub'     => 'syntax',
        },
      };
}

# Main tab
my $main_tab_info_ref = {
            'file_list' => \@files_session,
            'color'     => 'yellow',
            'selected' => 0,
        };
my $session_ref;
if ( -f "editor.session" ) {
    $session_ref = do "editor.session";
    $main_tab_info_ref = $session_ref->{'main_tab'};
    @files_session = @{$main_tab_info_ref->{'file_list'}};
}
my @window_size;
while ( my ($key, $value) = each %{$session_ref->{'window'}}) {
    #print "Valeur $key / $value\n";
    push @window_size, $key, $value;
}

my $size_zone4 = {
            '-x'        => 0,
            '-rely'     => 0,
            '-relwidth' => 1,
            '-height'   => 25,
        };

my $zone_list_ref = $session_ref->{'zone_list'};
if ( defined $zone_list_ref ) {
    my $zone4_ref = $zone_list_ref->{'zone4'};
    #print "Zone 4 ref = $zone4_ref | ", dump ( $zone4_ref ), "\n";
    if ( my $size = $zone4_ref->{'size'} ) {
        #print "Zone 4 size = $size | ", dump ( $size ), "\n";
        $size_zone4 = $size;
    }
}

# Main tab "zone", area of the main window (syntax re-used : 'place' of Tk)
my $zone4 = Text::Editor::Easy::Zone->new(
    {
        'size' => $size_zone4,
        'name'      => 'zone4',
    }
);

Editor->new(
    {
        'zone'        => $zone4,
        'sub'         => 'main', # Program "Editor.pl" will go on with another thread (sub "main" executed)
        'name'        => 'main_tab',
        'events' => {
            'motion' => {
                'use'     => 'Text::Editor::Easy::Program::Tab',
                'package' => 'Text::Editor::Easy::Program::Tab',
                'sub'     => 'motion_over_tab',
                'thread'    => 'Motion',
            }
        },
        'save_info' => $main_tab_info_ref,
        'font_size' => 11,
        @window_size,
    }
);

print "Taille de l'écran : ", join ( ' | ', Editor->window->get) ,"\n";

save_session();

# End of launching perl process (F5 key management)
print EXEC "quit\n";
close EXEC; # This should be enough to stop process "exec.pl"


# End of Editor.pl
#unlink ( "editor.session" );

sub main {
    my ( $onglet, @parm ) = @_;
    
    my $tab_tid = $onglet->ask_named_thread( 'get_tid', 'File_manager');
    $onglet->ask_thread('add_thread_method', $tab_tid,
        {
                'use' => 'Text::Editor::Easy::Program::Tab',
                'package' => 'Text::Editor::Easy::Program::Tab',
                'method' =>  [ 
                        'select_new_on_top',
                        ],
        }
    );
    Editor->ask_thread('add_thread_method', $tab_tid,
    #Text::Editor::Easy->ask_thread('add_thread_method', $tab_tid,
        {
                'use' => 'Text::Editor::Easy::Program::Tab',
                'package' => 'Text::Editor::Easy::Program::Tab',
                'method' =>  [ 
                    'save_conf',
                    'update_conf',
                    'get_conf_for_absolute_file_name',
                    ],
        }
    );
    Editor->ask_thread('add_thread_method', 0,
        {
                'use' => 'Text::Editor::Easy::Program::Tab',
                'package' => 'Text::Editor::Easy::Program::Tab',
                'method' =>  'save_conf_thread_0',
        }
    );
    Editor->ask_thread('add_thread_method', 0,
        {
                'package' => 'main',
                'method' =>  'restart',
        }
    );
    
    my $out_tab_zone_size = {
        '-relx'     => 0.5,
        '-y'        => 25,
        '-relwidth' => 0.5,
        '-height'   => 25,
    };
    if ( defined $zone_list_ref ) {
        my $zone_ref = $zone_list_ref->{'out_tab_zone'};
        if ( $zone_ref and my $size = $zone_ref->{'size'} ) {
             $out_tab_zone_size = $size;
        }
    };

    my $out_tab_zone = Text::Editor::Easy::Zone->new( {
        'size' => $out_tab_zone_size,
        'name'      => 'out_tab_zone',
    } );

    my $out_tab = Editor->new(
        {
            'zone'        => $out_tab_zone,
            'name'        => 'out_tab',
            'events' => {
                'motion' => {
                    'use'     => 'Text::Editor::Easy::Program::Tab',
                    'package' => 'Text::Editor::Easy::Program::Tab',
                    'sub'     => 'motion_over_tab',
                    'thread'    => 'Motion',
               }
            },
            'save_info' => { 'color' => 'green', },
        }
    );
    my $id_onglet = $onglet->id;
    
    my $zone1_size = {
        '-x'                   => 0,
        '-y'                   => 25,
        '-relwidth'            => 0.5,
        '-relheight'           => 0.7,
        '-height'              => -25,
    };
    if ( defined $zone_list_ref ) {
        my $zone_ref = $zone_list_ref->{'zone1'};
        if ( $zone_ref and my $size = $zone_ref->{'size'} ) {
            $zone1_size = $size;
        }
    };

    my $zone1 = Text::Editor::Easy::Zone->new(
        {
            'size' => $zone1_size,
            'name'                 => 'zone1',
            'events' => {
                'editor_destroy' => {
                    'use'     => 'Text::Editor::Easy::Program::Tab',
                    'package' => 'Text::Editor::Easy::Program::Tab',
                    'sub'     => [ 'on_editor_destroy', $id_onglet ],
                },
                'top_editor_change' => {
                    'use'     => 'Text::Editor::Easy::Program::Tab',
                    'package' => 'Text::Editor::Easy::Program::Tab',
                    'sub'     => [ 'on_main_editor_change', $id_onglet ],
                },
            },
        }
    );
    my $new_ref = $files_session[$main_tab_info_ref->{'selected'}];
    $new_ref->{'focus'} = 'yes';
			
    Editor->new( $new_ref );

    Editor->bind_key(
        { 'package' => 'main', 'sub' => 'launch', 'key' => 'F5' } );

    Editor->bind_key(
        { 'package' => 'main', 'sub' => 'toto', 'key' => 'alt_shift_t' } );


    # Zone des display
    my $zone2 = Text::Editor::Easy::Zone->new(
        {
            'size' => {
                '-relx'                => 0.5,
                '-y'                   => 50,
                '-relwidth'            => 0.5,
                '-relheight'           => 0.7,
                '-height'              => -50,
            },
            'name'                 => 'zone2',
            'events' => {
                'top_editor_change' => {
                    'use'     => 'Text::Editor::Easy::Program::Tab',
                    'package' => 'Text::Editor::Easy::Program::Tab',
                    'sub'     => [ 'on_top_editor_change', $out_tab->id ],
                }
            }
        }
    );

    # Zone des appels de display, traces
    my $zone3 = Text::Editor::Easy::Zone->new(
        {
            'size' => {
                '-relx'      => 0.5,
                '-rely'      => 0.7,
                '-relwidth'  => 0.5,
                '-relheight' => 0.3,
            },
            'name'       => 'zone3',
        }
    );
    my $who = Editor->new(
        {
            'zone'        => $zone3,
            'name'        => 'call_stack',
            'events' => {
                'motion' => {
                    'use'     => 'Text::Editor::Easy::Motion',
                    'package' => 'Text::Editor::Easy::Motion',
                    'sub'     => 'cursor_set_on_who_file',
                    'thread'    => 'Motion',
                    'init' => [ 'Text::Editor::Easy::Motion::init_set', $zone1 ]
                }
            },
        }
    );
    use File::Basename;
    my $name  = fileparse($0);
    my $out_1 = Editor->new(
        {
            'zone'         => $zone2,
            'file'         => "tmp/${name}_trace.trc",
            'name'         => 'Editor',
            'growing_file' => 1,
            'events' => {
                'shift_motion'  => {
                    'use'       => 'Text::Editor::Easy::Motion',
                    'package' => 'Text::Editor::Easy::Motion',
                    'sub'        => 'move_over_out_editor',
                    'thread'   => 'Motion',
                    'init'      => [ 'Text::Editor::Easy::Motion::init_move', $who->id, $zone1 ],
                }
            },
        }
    );
    my $out = Editor->new(
        {
            'zone' => $zone2,
            'name' => 'Eval',
            'events' => {
                'shift_motion'  => {
                    'package' => 'Text::Editor::Easy::Motion',
                    'sub'     => 'move_over_eval_editor',
                    'thread'  => 'Motion',
                }
            },
        }
    );

    my $zone5 = Text::Editor::Easy::Zone->new(
        {
            'size' => {
                '-x'         => 0,
                '-rely'      => 0.7,
                '-relwidth'  => 0.5,
                '-relheight' => 0.3,
            },
            'name'       => 'zone5',
        }
    );
    my $macro = Editor->new(
        {
            'zone'        => $zone5,
            'name'        => 'macro',
            'highlight' => {
                'use'     => 'Text::Editor::Easy::Syntax::Perl_glue',
                'package' => 'Text::Editor::Easy::Syntax::Perl_glue',
                'sub'     => 'syntax',
            },
           'events' => {
                'change' => {
                    'use'     => 'Text::Editor::Easy::Program::Search',
                    'package' => 'Text::Editor::Easy::Program::Search',
                    'sub'     => 'modify_pattern',
                    'thread' => 'Macro',
                    'init' => [ 'Text::Editor::Easy::Program::Search::init_eval', $out->id ],
                }
            },
        }
    );
    
    Editor->bind_key( { 'package' => 'main', 'sub' => 'restart', 'key' => 'F10' } );
    Editor->bind_key({ 
            'package' => 'Text::Editor::Easy::Program::Open_editor',
            'use' => 'Text::Editor::Easy::Program::Open_editor',
            'sub' => 'open',
            'key' => 'ctrl_o'
    } );
    Editor->bind_key({ 
            'package' => 'Text::Editor::Easy::Program::Open_editor',
            'use' => 'Text::Editor::Easy::Program::Open_editor',
            'sub' => 'open',
            'key' => 'ctrl_O'
    } );
    
    # Self designing : no annulation management yet, frequent save for the moment
    if ( -d "../../save" ) {
        Editor->create_new_server( {
            'use' => 'Text::Editor::Easy::Program::Save',
            'package' => 'Text::Editor::Easy::Program::Save',
            'methods' =>  [ 
                'save_arbo',
            ],
            'object' => {},
            'init'   => [
                'Text::Editor::Easy::Program::Save::init',
            ],
            'name' => 'Save',
        } );
    }
}



sub launch {
    # Appui sur F5
    my ($self) = @_;

    my $file_name = $self->file_name;

    if (   $file_name eq 'demo8.pl' )
    {
        Editor->whose_name('Eval')->at_top;
        my $macro_instructions;
        if ( $file_name eq 'demo8.pl' ) {
            $macro_instructions = << 'END_PROGRAM';
my $editor = Text::Editor::Easy->whose_name('call_stack');
$editor->add_method('demo8');
print $editor->demo8(4, "bof");
END_PROGRAM
        }

        my $eval_editor = Editor->whose_name( 'macro' );
        $eval_editor->empty;
        $eval_editor->insert($macro_instructions);
        return;
    }
    if ( $demo{$file_name} ) {
        my $hash_ref = do "${file_path}$file_name";
        print $@ if ( $@ );
        $hash_ref->{'F5'}->( $self, $hash_ref );
        return;
    }
    if ( defined $file_name ) {
        #print "fichier $file_name\n";
        my $out_name = $file_name;
        $out_name =~ s/\.pl$//;
        $out_name =~ s/\.t$//;
        return if ( $out_name eq $file_name );
        my $out_editor = Editor->whose_name( $out_name );

        #print "Avant lancement : $file_name|start|perl -I${file_path}lib -MText::Editor::Easy::Program::Flush ${file_path}$file_name\n";
        print EXEC
"$file_name|start|perl -I${file_path}lib -MText::Editor::Easy::Program::Flush ${file_path}$file_name\n";

        if ( ! defined $out_editor ) {
        
          $out_editor = Editor->new( {
            'zone' => 'zone2',
            'name' => $out_name,
            'file'         => "tmp/${file_name}_trace.trc",
            'growing_file' => 1,
            'events' => {
                'shift_motion'  => {
                    'use'     => 'Text::Editor::Easy::Motion',
                    'package' => 'Text::Editor::Easy::Motion',
                    'sub'     => 'move_over_external_editor',
                    'thread'    => 'Motion',
                }
            },
          } );
          Editor->declare_trace_for ( 
              $out_name,
              "tmp/${file_name}_trace.trc",
          );
        }
        else {
           #print "Le fichier correspondant à $out_name existe : $out_name\n";
            $out_editor->empty;
            $out_editor->set_at_end;
        }
    }
}

sub demo8 {
    my $editor = Editor->whose_name('demo8.pl');
    
    my $sub_ref = eval $editor->slurp;
    return $sub_ref->(@_);

    #print "End of execution\n";
}

sub restart {
    print "\nDans restart...\n\n";

    save_session ();
    
    # Lancement d'un nouvel éditeur (qui récupèrera la configuration)
    print EXEC "Editor.pl|start|perl ${file_path}Editor.pl\n";

    # Fin de l'éditeur courant
    Editor->exit;
}

sub save_session {
    # In thread 0, the graphical MainLoop is over
    #print "Début save_session\n";
    $session_ref->{'main_tab'} = Editor->save_conf_thread_0;
    $session_ref->{'window'} = scalar Editor->window->get;
    $session_ref->{'zone_list'} = Text::Editor::Easy::Zone->list('complete');

    open (INFO, ">editor.session" ) or die "Can't write editor.session : $!\n";
    print INFO dump $session_ref;
    close INFO;
    #print "Fin save_session\n";
}

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut









