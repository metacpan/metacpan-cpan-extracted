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
print "Scalar first ", scalar (@first_list), "\n";

my $tid = $editor->create_new_server(
   {
		'use' => 'Text::Editor::Easy::Test::Test3', 
		'package' => 'Text::Editor::Easy::Test::Test3',
		'methods' => ['test3', 'test4', 'object_test'], 
		'object' => [23, "rere"] ,
	});

print "Après create_new_server : ", scalar (threads->list), "\n";

my @second_list = threads->list;		
is ( scalar(@second_list), scalar(@first_list) + 1, "One more thread");

my @param = ( 3, 'BOF' );
my ( $first, $second ) = $editor->object_test( @param );
is ( $first, 12 * 23 - 2 * 3, "First return value, first instance call" );
is ( $second, "rereBOFBOF", "Second return value, first instance call" );

@param = ( 7, 'zefvfc' );
( $first, $second ) = $editor->object_test( @param );
is ( $first, 12 * 23 - 2 * 7, "First return value, first instance call" );
is ( $second, "rereBOFzefvfc", "Second return value, first instance call" );

my $editor2 = Text::Editor::Easy->new();

my @first = threads->list;
my $first_thread_number = scalar (@first);
print "Avant appel add_thread_method : $first_thread_number\n";


$editor2->ask_thread(
	'add_thread_object', $tid, 
	{
		'object' => [4, "titi"] ,
	}
);
my @second = threads->list;
my $second_thread_number = scalar (@second);
print "Après appel add_thread_object : $second_thread_number\n";

is (  $first_thread_number, $second_thread_number, "No thread more");

@param = ( 7, 'zefvfc' );
( $first, $second ) = $editor2->object_test( @param );
is ( $first, 12 * 4 - 2 * 7, "First return value, second instance call" );
is ( $second, "titiBOFzefvfc", "Second return value, second instance call" );

@param = ( 5, 'ee' );
( $first, $second ) = $editor->object_test( @param );
is ( $first, 12 * 23 - 2 * 5, "First return value, first instance call" );
is ( $second, "rereBOFee", "Second return value, first instance call" );

( $first, $second ) = $editor2->object_test( @param );
is ( $first, 12 * 4 - 2 * 5, "First return value, second instance call" );
is ( $second, "titiBOFee", "Second return value, second instance call" );

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
