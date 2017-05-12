use Test::More;
use Config;
BEGIN {
    if ( ! $Config{'useithreads'} ) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
    elsif ( ! -f 'tk_is_ok' ) {
        plan skip_all => "Tk is not working properly on this machine";
    }
    else {
        plan no_plan;
    }
}

use strict;
use lib '../lib';

use Text::Editor::Easy;
#{
#    'trace' => {
#        'all' => 'tmp/',
#        'trace_print' => 'full',
#    }
#};

use Text::Editor::Easy::Comm qw( anything_for_me have_task_done );

my $editor = Text::Editor::Easy->new (
    {
        #'sub'      => 'main',    # Sub for action
        'x_offset' => 60,
        'y_offset' => 170,
        'width'    => 500,
        'height'   => 300,
    }
);


		
		# Full trace thread creation
		print "Full trace thread creation by trace_print call\n";
		my @first_list = threads->list;
		print "Scakar first ", scalar (@first_list), "\n";
        
		my $tid = Text::Editor::Easy->create_new_server(
		   {
				'package' => 'Text::Editor::Easy::Comm',
				'methods' => [],
				'object' => [] 
		    });
		print "Après create_new_server : ", scalar (threads->list), ", tid créé $tid\n";
		
		my @second_list = threads->list;		
		is ( scalar(@second_list), scalar(@first_list) + 1, "One more thread");
		
		print "Avant appel add_thread_method : ", scalar (threads->list), "\n";

		my $call_id = Text::Editor::Easy::Async->ask_thread(
		    'stop_thread', $tid,
		);
        
        print "Dans programme de test, call_id = $call_id\n";
        my $status = '';
        while ( ! defined $status or $status ne 'ended' ) {
            $status = Text::Editor::Easy->async_status( $call_id );
            if ( anything_for_me ) {
                have_task_done;
            }
        }

		print "Après appel stop_thread : ", scalar (threads->list), "\n";
		my @third_list = threads->list;
		
		print "Third second ", scalar (@third_list), "\n";
		is (  scalar(@third_list), scalar(@second_list) - 1, "One thread less");
		# Tests de création de thread nommés (méthodes mises en commun sans augmentation du nombre d'entrée de %get_tid_from_instance_method

		# Vérifier le bon partage du même objet
		# Donner la possibilité d'avoir un objet personnel ?
		# Si oui tester le bon partage par défaut, la différence si souhaitée
        # Ajout avec une autre méthode de classe définie pour l'occassion
		# Vérifier l'appel de classe correct
		# Vérifier l'héritage automatique
		# Vérifier l'appel de classe incorrect (appel Text::Editor::Easy avec méthode uniquement définie dans la classe héritée)
		# Vérifier l'implémentation de "->super"
		# Vérifier le non écrasement de méthode ? (add et non overload ?)

	Text::Editor::Easy->exit(0);
		