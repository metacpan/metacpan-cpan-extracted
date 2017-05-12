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

my $editor = Text::Editor::Easy->new (
    {
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

my $tid = $editor->create_new_server(
   {
		'use' => 'Text::Editor::Easy::Test::Test1', 
		'package' => 'Text::Editor::Easy::Test::Test1',
		'methods' => ['test1'],
		'object' => [] 
	});

print "Après create_new_server : ", scalar (threads->list), "\n";

my @second_list = threads->list;		
is ( scalar(@second_list), scalar(@first_list) + 1, "One more thread");

print "Avant appel add_thread_method : ", scalar (threads->list), "\n";

$editor->ask_thread(
	'add_thread_method', $tid, 
	{
		'package' => 'Text::Editor::Easy::Test::Test3',
		'use' => 'Text::Editor::Easy::Test::Test3',
		'method' => 'test3'
	}
);
print "Après appel add_thread_method : ", scalar (threads->list), "\n";
my @third_list = threads->list;

print "Third second ", scalar (@third_list), "\n";
is (  scalar(@third_list), scalar(@second_list), "No thread more");

my @param = ( 3, 'BOF' );
my ( $thread_tid, $_4xparam0, $TEST3_param1 ) = $editor->test3( @param );
is ( $thread_tid, $tid, "Thread number, first instance call" );
is ( $_4xparam0, 4 * $param[0], "First return value, first instance call" );
is ( $TEST3_param1, "TEST3" . $param[1], "Second return value, first instance call" );

@param = ( 7, 'zefvfc' );
( $thread_tid, $_4xparam0, $TEST3_param1 ) = $editor->test3( @param );
is ( $thread_tid, $tid, "Thread number, second instance call" );
is ( $_4xparam0, 4 * $param[0], "First return value, second instance call" );
is ( $TEST3_param1, "TEST3" . $param[1], "Second return value, second instance call" );

Text::Editor::Easy->ask_thread(
	'add_thread_method', $tid, 
	{
		'package' => 'Text::Editor::Easy::Test::Test1',
		'method' => 'test2'
	}
);

( $thread_tid, $_4xparam0, $TEST3_param1 ) = Text::Editor::Easy->test2( @param );
is ( $thread_tid, $tid, "Thread number, first class call" );
is ( $_4xparam0, 2 * $param[0], "First return value, first class call" );
is ( $TEST3_param1, "TEST2" . $param[1], "Second return value, first class call" );

@param = ( 34, "dkfkfkf" );
( $thread_tid, $_4xparam0, $TEST3_param1 ) = Text::Editor::Easy->test2( @param );
is ( $tid, $thread_tid, "Thread number, second class call" );
is ( $_4xparam0, 2 * $param[0], "First return value, second class call" );
is ( $TEST3_param1, "TEST2" . $param[1], "Second return value, second class call" );

my $editor2 = Text::Editor::Easy->new();
$editor2->ask_thread(
	'add_thread_method', $tid, 
	{
		'package' => 'Text::Editor::Easy::Test::Test3',
		'method' => 'test4'
	}
);

#( $thread_tid, $_4xparam0, $TEST3_param1 ) = $editor2->test4( @param );
#is ( $thread_tid, $tid, "Thread number, third instance call" );
#is ( $_4xparam0, 5 * $param[0], "First return value, third instance call" );
#is ( $TEST3_param1, "TEST4" . $param[1], "Second return value, third instance call" );

#( $thread_tid, $_4xparam0, $TEST3_param1 ) = Text::Editor::Easy->test4( @param );
#is ( $thread_tid, undef, "Wrong call n°1, value 1" );
#is ( $_4xparam0, undef, "Wrong call n°1, value 2" );
#is ( $TEST3_param1, undef, "Wrong call n°1, value 3" );

( $thread_tid, $_4xparam0, $TEST3_param1 ) = Text::Editor::Easy->test3( @param );
is ( $thread_tid, undef, "Wrong call n°2, value 1" );
is ( $_4xparam0, undef, "Wrong call n°2, value 2" );
is ( $TEST3_param1, undef, "Wrong call n°2, value 3" );

( $thread_tid, $_4xparam0, $TEST3_param1 ) = $editor2->test3( @param );
is ( $thread_tid, undef, "Wrong call n°3, value 1" );
is ( $_4xparam0, undef, "Wrong call n°3, value 2" );
is ( $TEST3_param1, undef, "Wrong call n°3, value 3" );

#( $thread_tid, $_4xparam0, $TEST3_param1 ) = $editor->test4( @param );
#is ( $thread_tid, undef, "Wrong call n°4, value 1" );
#is ( $_4xparam0, undef, "Wrong call n°4, value 2" );
#is ( $TEST3_param1, undef, "Wrong call n°4, value 3" );

( $thread_tid, $_4xparam0, $TEST3_param1 ) = $editor->test2( @param );
is ( $thread_tid, undef, "Wrong call n°5, value 1" );
is ( $_4xparam0, undef, "Wrong call n°5, value 2" );
is ( $TEST3_param1, undef, "Wrong call n°5, value 3" );


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
