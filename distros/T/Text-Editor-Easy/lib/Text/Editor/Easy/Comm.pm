use threads;
use threads::shared;
use Thread::Queue;

=head1 NAME

Text::Editor::Easy::Comm - Thread communication mecanism of "Text::Editor::Easy" module.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

=head1 SYNOPSIS

This is an internal module. Several threads are created during the first "Text::Editor::Easy" instance creation. You can create your own threads too.
All these threads can make actions to "Text::Editor::Easy" instances by simply calling methods of the interface, thanks to this module.

=head1 PRINCIPLE

There are 2 (or 3 if we include the L<Text::Editor::Easy::File_manager> module) complex modules in the "Text::Editor::Easy" tree.
This module and the L<Text::Editor::Easy::Abstract> which handles graphics in an encapsulated way.

This module tries to make thread manipulation obvious with "Text::Editor::Easy" objects. Maybe this module could be adpated to be used
with other objects to facilitate thread creation and use.

There are 2 main classes of threads : server and client.

A client thread is, for instance, your program that runs sequentially and, from time to time, ask a server thread for a service.

A server thread is a waiting thread that manages a particular service. From time to time, the server threads is called by a client which 
can be a real client thread or another server thread : the calling server thread can be seen here as a client for our responding server. The server
thread responds to the client and then waits again. Of course, if the server is saturated with calls, it won't wait and will execute all the calls in the
order they have been made. So, the clients (real or other servers) may have to wait for the response of the server... but not always. Here come 
asynchronous calls : in an asynchronous call, the client asks for something to the server (gets, if it wants, an identification of the call, the "call_id"),
and can go on without waiting for the response. But asynchronous calls are not always possible. Often, you have to make things in a certain order
and be sure they have been made before going on. So most calls to server threads (by client) will be synchronous and blocking.

Now that we have seen the 2 classes of threads let's talk more about server threads.

There are mainly 3 types of server threads : owned by an instance (let's call it OWNED thread), shared by all the instances with separate data
for all the instances (let's call it MULTIPLEXED thread), shared with all instances with no separate data (let's call it CLASS thread).
All these types of threads haven't been invented for theorical beauty, but just because I needed them. The OWNED thread is the "File_manager"
thread : each "Text::Editor::Easy" instance have a private one. The MULTIPLEXED thread is the graphic thread (number 0) : Tk is not
multi-threaded, so I had to put private data in only one thread. All other threads that I use are CLASS threads : the thread model, number 1, that
is only used to create new threads, the "Data" thread number 2, that shares common data such as "call_id" and asynchronous responses...

The thread system allows me to create all the types of threads defined previously (OWNED, MULTIPLEXED, and CLASS) but it allows me 
more. First, there is no real limit between the 3 types of threads (I can have a thread with a MULTIPLEXED and CLASS personnality...
or any other combination). Second, I'm able to define dynamic methods and have access to the code of all the methods to enable dynamic
modifications.

The "create_new_server" method can be called either with an instance, or with a class :

  my $tid = $editor->create_new_server ( {...} );
  
or

  my $tid = Text::Editor::Easy->create_new_server ( {...} );

For an OWNED or MULTIPLEXED type, use the instance call. For the CLASS type use the class call. "create_new_server" uses a
hash reference for parameters, and returns the "tid" ("thread identification" in the interpreted thread perl mecanism), which is an integer.
This interface may be changed : just given to see actual capabilities. Of course, the more I use this interface to create all my threads,
and the more I will be reluctant to change the interface.

Here are the parameters of the given hash to the "create_new_server" method :

  $editor->create_new_server ( {
        # optionnal, without this option, no new module is evaluated by the new created thread
        'use' => 'Module_name', 
        
        # optional, without this option, the "main" package is used for the following methods
        'package' => 'Package_name',
        
        # mandatory : methods to be added to the instance or to the class.
        # Calls to these methods will be served by the new created thread.
        # The names of the methods must correspond to the name of the subs to be called.
        # This limitation may be suppressed later (by including a hash ref in the elements
        # of the array)
        'methods' => [ 'method1', 'method2', 'method3', ... ],
        
        # optionnal but either 'object' or 'new' must be provided.
        # 'object' or 'new' specify the first parameter that the methods handled
        # by your thread will receive (the other parameters will be given by
        # the call itself : for instance "$editor->method1('param2', 'param3', ...)"
        'object' => ... (any "dumpable" reference for instance [], or {} ...),
        
        # optionnal but either 'object' or 'new' must be provided.
        # Method that will be called first by the new thread :
        # - must return the object that the thread will use for the methods call (first parameter)
        # - the return value of the method can contain non "dumpable" data (sub reference, file descriptor, ...)
        # The first value of the tab reference is the sub name (including the package),
        # the other values are "dumpable" parameters to be sent to the sub returning the object.
        # The first parameter received by 'package::sub_name' will be 'param1', the second 'param2' and so on
        'new' => [ 'package::sub_name', 'param1', 'param2', ... ],
        
        # optionnal, gives a sub that will initialize the object.
        # The sub does not need to return the object because the reference is given.
        # Be careful, the first parameter received by 'package::sub_name' is the reference
        # of the object that will be used when calling the newly defined methods (this is
        # what should be initialized)
        # AND THE SECOND PARAMETER is the "pseudo-reference" with which the "create_new_server"
        # has been called (either "a unique reference" for an instance call which is an integer that
        # uniquely identifies a "Text::Editor::Easy" object, or the class name)
        init => [ 'package::sub_name', 'param3', 'param4', ...],
        
        # optionnal (allows multiple OWNED threads to share code (one different tid for each instance)
        'name' => 'thread_name',
        
        # optionnal, put the tid of the thread in the shared hash %get_tid_from_instance_method
        # even if a name is given (could be used for MULTIPLEXED thread)
        'put_tid' => 1,
        
        # optionnal, indicates that the code of the methods won't be shared with other instances.
        # May be used for specific OWNED thread.
        # In short, some methods may be have the same name but different associated code according
        # to the instance calling the method
        'specific' => 1,
        
        # optionnal, indicates that no thread will be created, the calling client (true client)
        # will have to manage itself the defined methods (the client thread will have to 
        # use "anything_for_me" and "have_task_done" methods exported by "Text::Editor::Easy::Comm"
        # to respond to potential clients; it could also use "get_task_to_do" and "execute_this_task"
        # instead of "have_task_done" to have a better control over the client calls : see
        # 'Text::Editor::Easy::Abstract::examine_external_request' for that).
        # The tid returned by the "create_new_server" will be the tid of the calling client
        'do_not_create' => 1,
  } );

Once your thread is created, you can change a little it's behaviour with the following calls. Again, you can use instance call or class call.

  Text::Editor::Easy->ask_thread('add_thread_method', 'tid', { ... } );
  
  $editor2->ask_thread('add_thread_object', 'tid', { ... } );
  
  $editor2->ask_thread('any_function_you_want', 'tid', 'param3', 'param4', 'param5' );

The difficult task achieved by "Text::Editor::Easy::Comm" module is to ask the good server thread for the "Text::Editor::Easy" method-call
that you've made (either instance or class call). As long as you provide the "tid" of the thread you want to ask for something when using "ask_thread",
you can specify anything for the method, even if it hasn't been declared as a method : still the fully qualified method should be known by the
thread (in a package contained by 'main' or by any other module that has already been evaluated by the thread : either with "create_new_server"
and  'use' option or by the "add_thread_method" and the 'use' option).

The 'add_thread_method' allows you to define a new method for the thread and not necessarily for the same reference that was initially used
for the thread creation. This "reference change" can modify slightly the "personnality" of your thread. The possible options for the hash are :

  'use' (evaluation of a new module for this method)
  'package'
  'method'
  'sub' (if the sub of the package has a different name of the method)
  'code' (for dynamic designing : the code of the method to be executed is given and not on a file)

The 'add_thread_object' method allows you to add new objects in a MULTIPLEXED thread. The possible options for the hash are :

  'object' (see "create_new_server")
  'new' (see "create_new_server")
  
You don't add a new thread, but you ask an existing thread to handle a new instance with the same default methods that have been defined
by "create_new_server" (and possibly added by "add_thread_method" if the reference was the same as the first initially used with "create_new_server").

You may have a look at the tests included with "Text::Editor::Easy" if you want to understand by practise these explanations (for instance,
"multiplexed_without_thread_creation.t" is a good example for asynchronous calls and a client that acts as a server).

=head1 EXPORT

There are only 2 reasons to include this module in a private module of yours. Either you've created a pseudo-server with
the "do_not_create" option during "create_new_server" call, or (a little more interesting), you want to create a server with
a "lazy behaviour" : that is to say, which implements interruptible tasks.

=head2 anything_for_me

As communication between threads uses the "Thread::Queue" mecanism, you can know if there is something waiting for you in the "Queue".
I encapsulate the "pending call" to the queue object in the "anything_for_me" function which does not accept any parameter.
"anything_for_me" returns true if there is another task for you, false otherwise.
If you look at my code, you'll see, in lots of my lazy graphical methods, the

        return if anything_for_me;
        
This little line is magical. Before beginning a new heavy instruction, you check if something could invalidate your processing. Then, you may
see another reason to create thread : if you can separate the functions that lead to give up other ones, you can put these functions in a
single thread and write them in "lazy mode". No matter the memory used ! It's now cheap. But take into consideration the time of your
user : it's the most precious thing.

=head2 have_task_done

Another useful function exported is "have_task_done". Used with "anything_for_me", this allows you to implement "interruptible long task".
For me, what I have in mind is "counting the lines of a file that may be huge", or "parsing a file for contextual syntax highlighting". I really needed
that to go further in the development of my Editor. "have_task_done" does not accept any parameter. For the moment, it returns "true" only
if the thread should be stopped ("stop_thread" method already called).
So, to create an interruptible long task, you could write, from time to time, during your long process :

  while ( anything_for_me ) {
    return if ( have_task_done );
  }
  
The difference between "return if anything_for_me" is that your thread still is in your long interruptible task after having done a few more
urgent tasks. More over, you don't lose any of the values of your variables before the call. Except the "main shared object" that
some of your methods normally shares (it could have been modified by the urgent calls), nothing should have been changed.

=head2 get_task_to_do and execute_this_task

You can make your interruptible tasks a little more complex using "get_task_to_do" and "execute_this_task" as a replacement of
"have_task_done". If there is anything for you, you can get what is really for you with "get_task_to_do". The first parameter returned is the
method called, the second the "call_id". An example of this is the "examine_external_request" sub of the
"Text::Editor::Easy::Abstract" module. This allows my module to know if we're working responding to a graphical event or responding to
a client call. This is used to test "event conditions" before calling user callback after an Editor event occurs. This mecanism has still to be
improved (more events have to be added and tested...).

=cut

my $data_thread : shared;

package Text::Editor::Easy::Comm::Trace;

use warnings;
use strict;

use Data::Dump qw(dump);
use Time::HiRes qw(gettimeofday);

sub TIEHANDLE {
    my ( $classe, $type ) = @_;

    my $array_ref;
    $array_ref->[0] = $type;
    bless $array_ref, $classe;
}

sub PRINT {
    my $self = shift;
    my $type = $self->[0];

    my $who = threads->tid;

    # Traçage de l'appel dans Data et de façon synchrone ==> Data doit connaître le statut de tous les threads impliqués
    # par ce print pour pouvoir faire des redirections très précises (voir reference_print_redirection et trace_full)
    my @calls;
    my $indice = 0;
    while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
        push @calls, [ $pack, $file, $line ];
    }
    my $array_dump = dump @calls;
    my $hash_dump  = dump(
        'who'   => $who,
        'on'    => $type,
        'calls' => $array_dump,
        'time'  => scalar(gettimeofday)
    );
    Text::Editor::Easy->trace_print( $hash_dump, @_ );
}

package Text::Editor::Easy::Comm::Null;

use warnings;
use strict;

sub TIEHANDLE {
    my ($classe) = @_;

    bless [], $classe;
}

sub PRINT {
    return;
}

sub CLOSE {
    return;
}

package Text::Editor::Easy::Comm;

use warnings;
use strict;

require Exporter;
our @ISA = ("Exporter");

#  qw ( execute_this_task anything_for_me get_task_to_do ask2 verify_model_thread respond simple_context_call verify_graphic have_task_done);
our @EXPORT =
  qw ( execute_this_task anything_for_me anything_for ask2 get_task_to_do have_task_done);

our @EXPORT_OK =
  qw(ask_named_thread anything_for_me have_task_done)
  ;    # symbols to export on request

use Data::Dump qw(dump);
use Time::HiRes qw(gettimeofday);

use threads;
use Thread::Queue;
use threads::shared;
use Scalar::Util qw(refaddr weaken);

use Text::Editor::Easy::Events;

 # Queue de réponse (queue cliente : un serveur la possède aussi)
my %queue_by_tid;   
share(%queue_by_tid);

# Queue server, d'attente de tâche : un client l'a aussi car il est d'abord serveur en attente au départ
# lors de la création de la grappe de thread
my %server_queue_by_tid;
share(%server_queue_by_tid);

my %stop_dequeue_server_queue;
share(%server_queue_by_tid);

# indéfini tant que l'objet n'est pas correctement fini, 1 sinon (entrée, id)
my %synchronize; 
share(%synchronize);

my %stop_server;
share(%stop_server);

# Nouvelle gestion des méthodes et des threads
my %ref_method;
my %use;    # Liste des modules utilisés par un thread

use constant {
    USE     => 0,
    PACKAGE => 1,
    SUB     => 2,
    MEMORY  => 3,
    REF     => 4,
    OTHER   => 5,
    COMPIL  => 6,
    EXEC    => 7,
};
my %thread_knowledge;

my %get_tid_from_class_method;
share(%get_tid_from_class_method);

my %get_tid_from_instance_method;
share(%get_tid_from_instance_method);

my %get_tid_from_thread_name;
share(%get_tid_from_thread_name);

sub add_thread_method {
    my ( $self_server, $reference, $options_ref ) = @_;

    if ( $reference =~ /\D/ ) {
        $reference = 'Text::Editor::Easy';
    }

    my $instance_ref = $thread_knowledge{'instance'};
    #print "Dans add thread method : ", scalar( threads->list ), "\n";

    my $method = $options_ref->{'method'};
    return if ( !defined $method );
    if ( my $ref_method = ref $method ) { # Affectation et pas test
        if ( $ref_method eq 'ARRAY' ) {
            # ARRAY
            # Appel récursif : à optimiser par la suite... (?)
            for my $new_method ( @$method ) {
                $options_ref->{'method'} = $new_method;
                add_thread_method ( $self_server, $reference, $options_ref );
            }
        }
        else {
            # HASH
            # Appel récursif : à optimiser par la suite... (?)
            while ( my ($key, $value) = each %$method) { 
                $options_ref->{'method'} = $key;
                $options_ref->{'sub'} = $value;
                add_thread_method ( $self_server, $reference, $options_ref );
            }
        }
        return;
    }
    my $method_ref;
    if ( my $program = $options_ref->{'code'} ) {

        #Le code doit renvoyer une référence de sub
        $method_ref->[REF] = eval "sub { $program }";
        if ($@) {
            $method_ref->[COMPIL] = $@;
            print STDERR "Wrong code for method $method :\n$@\n";
        }
        $method_ref->[MEMORY] = $program;
    }
    else {
        my $use = $options_ref->{'use'};
        if ( defined $use ) {
            if ( !$use{$use} ) {
                eval "use $use";
                if ($@) {
                    print STDERR "Wrong code for module $use :\n$@\n";
                }
                $use{$use}{'messages'} = $@;
            }
        }

        $method_ref->[USE] = $use;
        my $package = $options_ref->{'package'} || 'main';
        $method_ref->[PACKAGE] = $package;
        my $sub = $options_ref->{'sub'} || $method;
        $method_ref->[SUB] = $sub;
        $method_ref->[REF] = eval "\\&${package}::$sub";
    }
    my $is_initial_reference = 0;
#    print DBG "Add de la méthode $method, reference $reference, \$instance_ref->{$reference} = $instance_ref->{$reference}, \$thread_knowledge{'self_server'} = $thread_knowledge{'self_server'}\n";
    if ( ! defined $instance_ref->{$reference} or $instance_ref->{$reference} != $thread_knowledge{'self_server'} ) {
    #if ( !$instance_ref->{'Text::Editor::Easy'} ) {
        print DBG "Ajout pour la nouvelle classe/méthode $reference de $method\n";
        #$ref_method{$method}[OTHER]{'Text::Editor::Easy'} = $method_ref;
        $ref_method{$method}[OTHER]{$reference} = $method_ref;
    }
    else {
        print DBG "Ajout pour la même classe de la méthode $method (classe $reference)\n";
        $ref_method{$method} = $method_ref;
        $is_initial_reference = 1;
    }

    # Mise à jour des méthodes gérées (hachages shared)
    if ( $reference =~ /^\d+$/ ) {    # spécific instance method
        my %hash;
        share(%hash);
        my $hash_ref = $get_tid_from_instance_method{$method};

        #print "Ajout d'une méthode d'instance pour '$instance $method'\n";
        if ( defined $hash_ref ) {
            %hash = %{$hash_ref};
        }
        my $class = $options_ref->{'class'};
        if ( $is_initial_reference and defined $class ) {
            #$hash{$class} = threads->tid;
            $hash{'Text::Editor::Easy'} = threads->tid;
        }
        else {
            $hash{$reference} = threads->tid;
        }
        $get_tid_from_instance_method{$method} = \%hash;
    }
    else {                            # Class method
        my %hash;
        share(%hash);
        my $hash_ref = $get_tid_from_class_method{$method};
        if ( defined $hash_ref ) {
            %hash = %{$hash_ref};
        }
        #$hash{$reference} = threads->tid;
        $hash{'Text::Editor::Easy'} = threads->tid;
        #print "Ajout de la méthode $method pour la classe $reference\n";
        $get_tid_from_class_method{$method} = \%hash;
    }
    #print "Fin de add thread method : ", scalar( threads->list ), "\n";
}

sub decode_message {
    my ($message) = @_;

    return if ( ! defined $message );
    return eval $message;
}

my %com_unique;

sub simple_call {
    my ( $self, $sub_name, $sub_ref, $call_id, $context, @param ) = @_;

    my ( $who, $id ) = split( /_/, $call_id );

    # Following call not to be shown in trace
    my $response = simple_context_call( $self, $sub_name, $sub_ref, $call_id, $context, @param );

    #print DBG "Longueur de context  call_id $call_id|$context|\n";
    if (length $context == 1) { # Synchronous call
        if ( threads->tid == $who ) {    # Même thread
            my ( $return_call_id, $return_message ) = split( /;/, $response, 2 );
            return decode_message($return_message);
        }
        else { 
            if ( !defined $queue_by_tid{$who} ) {
                print STDERR "Can't answer to client $who as no queue to receive result has been found\n";
                return;
            }
            $queue_by_tid{$who}->enqueue($response);
        }
    }
    else {    # Appel asynchrone
        return if ( $sub_name =~ /^trace/ );
        #print DBG "Appel asynchrone pour $sub_name, call_id $call_id, tid ", threads->tid, "\n";
        
        # Thread Data will memorize the answer (if "call_id" has been fetched by the client when calling the method)
        my ( $return_call_id, $return_message ) = split( /;/, $response, 2 );
        #print DBG "Pour appel call_id = $return_call_id, je renvoie la réponse $return_message\n";
        Text::Editor::Easy->trace_response( threads->tid, $call_id, undef, gettimeofday(), $return_message );
    }
}

sub simple_context_call {
    my ( $self, $sub_name, $sub_ref, $call_id, $context, @param ) = @_;

    my $response;
    #print DBG "SIMPLE_CONTEXT_CALL : $call_id|$sub_name|\n";
    if ( $context eq 'A' or $context eq 'AA' ) {
        # Inter-thread call, not to be shown in trace
        my @return = $sub_ref->( $self, @param );
        $response = dump @return;
    }
    else {
        # Following call not to be shown in trace
        my $return = $sub_ref->( $self, @param );
        $response = dump $return;
    }
    return "$call_id;$response";
}

sub anything_for_me {
    my $who = threads->tid;
    return if ( defined $stop_dequeue_server_queue{$who} );
    return $server_queue_by_tid{$who}->pending;
}

sub anything_for {
    my ( $who ) = @_;
    
    return if ( defined $stop_dequeue_server_queue{$who} );
    return $server_queue_by_tid{$who}->pending;
}


sub get_message_for {
    my ( $who, $from, $method, $call_id, $context, $data ) = @_;

    if ( $method !~ /^trace/ ) {
        Text::Editor::Easy->trace_response( $from, $call_id, $method, gettimeofday(), $data );
    }
    my ( $return_call_id, $return_message ) = split( /;/, $data, 2 );
    if ( $return_call_id ne $call_id and $method ne 'trace_print' ) {
        print DBG
          "Différence de call_id !! appel $call_id|retour $return_call_id\n";
        print DBG
          "\tFROM $from, méthode $method, contexte $context|$return_message\n";
    }
    return decode_message($return_message);
}

sub get_task_to_do {

    # Le thread serveur se bloque dans l'attente d'un nouveau travail à faire
    my $who = threads->tid;
    my $data;
    do {
        $data = $server_queue_by_tid{$who}->dequeue;
    } while ( defined $stop_dequeue_server_queue{$who} );

# Un nouveau travail a été dépilé de la file d'attente
# Réinitialiser ici la variable shared  à 0 : le thread recommence à travailler
# Mieux : repositionner une heure de départ pour savoir quelle durée l'action va couter
# On peut associer la fonction (decode_message qui suit) pour avoir des statistiques sur les durées des méthodes
#return decode_message($data);
    my ( $what, @param ) = decode_message($data);

    if ( $what =~ /^trace/ ) {
        return ( $what, @param );
    }
    else {
        #print DBG
        #  "Avant appel trace_start de $what (call_id $param[0], tid $who)\n";
        Text::Editor::Easy->trace_start( $who, $param[0], $what, gettimeofday() );
    }
    return ( $what, @param );
}

my %method;   # Permet de trouver le serveur qui gère une méthode éditeur donnée
share(%method);


my $call_order = 0;

sub ask2 {
    my ( $self, $method, @data ) = @_;

    my $server_tid;

    my $id;
    if ( ! ref($self) ) {    # Appel d'une méthode de classe
        $id = '';
    }
    else {
       $id = $com_unique{ refaddr $self };

        if ( !defined $id ) {
            print STDERR "No reference found for object $self, can't manage this instance of ", ref($self), "\n";
            return;
        }
    }
    my $client_tid = threads->tid;

    my $tid;
    if ($id) {
        my $hash_ref = $get_tid_from_instance_method{$method};
        $tid = $hash_ref->{$id};

        if ( !defined $tid ) {
            $tid = $hash_ref->{'Text::Editor::Easy'};
            #$tid = $hash_ref->{ ref($self) };
            #if ( ! defined $tid ) { #Tester l'héritage ici ... long
            #    $tid = $hash_ref->{'Text::Editor::Easy'};
            #}
            if ( defined $tid and $tid =~ /\D/ ) {
                print DBG "Trouvé un appel nommé : méthode $method, nom $tid\n";
                my $hash_ref = $get_tid_from_thread_name{$tid};
                $tid = $hash_ref->{$id};
                if ( ! defined $tid ) {
                    print DBG "Problème de récupe tid numérique pour méthode $method : ", dump( $hash_ref ), "\n";
                }
                else {
                    print DBG "TID de l'appel nommé : $tid pour la méthode $method\n";
                }
            }
            elsif ( ! defined $tid ) {
                print DBG "Pas de tid trouvé pour la méthode $method\n";
                print DBG "hACHAge $hash_ref, valeur : ", dump( $hash_ref ), "\n";
#                print DBG "hACHAge $hash_ref, ------ : ", $hash_ref->{'Text::Editor::Easy'}, "\n";
            }
        }
    }
    else {
        my $hash_ref = $get_tid_from_class_method{$method};
        if ( defined $hash_ref ) {
            #$tid = $hash_ref->{$self};
            $tid = $hash_ref->{'Text::Editor::Easy'};

            print DBG "Récupération de get_tid_from_class_method de $method : $hash_ref pour $self\n";
# Tester l'héritage ici
            if ( ! defined $tid ) {
                $tid = $hash_ref->{'Text::Editor::Easy::Async'};

                print DBG "Récupération de tid avec Async pour la méthode $method: ", dump( $hash_ref ), "\n";
            }
        }
    }
    print DBG "Recherche pour méthode $method...\n";

    if ( defined $tid ) {
         print DBG "TID défini pour méthode $method... : $tid\n";
        $server_tid = $tid;
        # Following call not to be shown in trace
        return new_ask( $self, $method, $id, $client_tid, $server_tid, @data );
    }
    # La méthode s'exécute dans le contexte du thread client appelant
    print DBG "La méthode $method n'est pas gérée par un thread serveur\n";

    my $sub = $method{ $id . ' ' . $method };
    if ( !defined $sub ) {

        print DBG "Recherche de la méthode 'shared' $method...\n";
        $sub = $method{$method};

        if ( !defined $sub ) {
             print DBG "Impossible de trouver la sub pour la méthode $method...\n";
             print STDERR "Can't handle method $method for object $self ($id)\n";             
             return;
        }
    }
    else {
        print DBG "La méthode $method est spécifique à la référence $id\n";
    }
    my $sub_ref = eval "\\&$sub";
    # Following call not to be shown in trace
    return $sub_ref->( $self, @data );
}

sub new_ask {
    my ( $self, $method, $id, $client_tid, $server_tid, @data ) = @_;

    if ( $method eq 'bind_key' ) {
        print DBG "self $self, method $method, id $id, client_tid $client_tid, server_tid $server_tid\n";
    }

    my $context = '';

    if ( ref($self) eq 'Text::Editor::Easy::Async'
        or $self eq 'Text::Editor::Easy::Async' )
    {
        print DBG "Appel asynchrone détecté pour la méthode $method\n";
        $context = 'A';
    }
    if (wantarray) {
        $context .= 'A';
    }
    elsif ( defined(wantarray) ) {
        $context .= 'S';
    }
    else {
        $context .= 'V';
    }
    if ( ! defined $server_tid ) {
        print "new_ask pbm : methode $method, id $id, client_tid $client_tid @data\n";
    }

    if ( $client_tid == $server_tid and length($context) ne 2 ) {
        
        #Le call_id ne sert ici à rien (pas d'échange avec le thread Data)
        # mais nécessaire à execute_task
        my $call_id     = $client_tid . '_' . $call_order;
        my $self_server = $thread_knowledge{'self_server'};

#        print DBG "Contexte avant appel execute_task |$context| pour appel méthode $method\n";
#        print DBG "\tSELF SERVER : $self_server\n";
#        print DBG "\tCALL_ID     : $call_id\n";

        # Following call not to be shown in trace
        return execute_task( 'sync', $self_server, $method, $call_id,
            $id || $self,
            $context, @data );
    }

    #print DBG "SERVER _TID = $server_tid pour $method\n";
    my $queue = $server_queue_by_tid{$server_tid};

    $call_order += 1  if ( $method !~ /^trace/ );
    my $call_id = $client_tid . '_' . $call_order;

    if ( $method !~ /^trace/ )
    {    # 2 serveurs pour les traces : ne plus tester le tid :
            # toute méthode qui commencera par "trace" ne sera pas tracée...
            # Traçage de l'appel dans Data

        my @calls;
        my $indice = 0;
        while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
            push @calls, [ $pack, $file, $line ];
        }
        my @call_params = (
            $call_id, $server_tid,    $method, $id,
            $context, gettimeofday(), @calls
        );
        Text::Editor::Easy->trace_call(@call_params);
    }

    my $message = dump ( $method, $call_id, $id || $self, $context, @data );

    my $reference_sent = $id || $self;

    while ( $queue_by_tid{$client_tid}->pending ) {
        print DBG "   PROBLEME appel avec file perso déjà remplie...\n";
        my $data = $queue_by_tid{$client_tid}->dequeue;
    }
    $queue->enqueue($message);

# Pour l'instant on ne traite pas les demandes synchrones ou asynchrones (pas de modification de who)
# Horrible verrue pour rendre "synchrone" le join de thread, par principe asynchrone
    if ( $method eq 'stop_thread' ) {
        print DBG "Dans l'attente stop_thread de new_ask, tid = ", threads->tid, "\n";
# Procédure qui bloque le thread appelant : à revoir (gérer l'erreur qui peut provenir de $message)
#print "Fin demandée pour le serveur $server_tid\n";
        while ( !$stop_server{$server_tid} ) {
        }
        my $abstract_call_id = $stop_server{$server_tid};

        #print "On va attendre la fin de la requête $call_id\n";
        # Récupération du message initial
        #my $message = get_message_for( $client_tid, $server_tid, $method, $call_id, $context );
        my $status = Text::Editor::Easy->async_status($abstract_call_id);
        while ( $status ne 'ended' ) {
            print DBG "Statut reçu : $status\n";
            if ( anything_for_me() ) {
                have_task_done();
            }
            $status = Text::Editor::Easy->async_status($abstract_call_id);
        }

        # Nettoyage
        my $response = Text::Editor::Easy->async_response($abstract_call_id);
        delete $server_queue_by_tid{$server_tid};
        delete $queue_by_tid{$server_tid};
        
        print DBG "Le statut est a ended, on renvoie la main au thread appelant\n";
        if ( $context =~ /^A/ ) {
            return $call_id;
        }
        else {
            return 1;
        }
    }

    if ( length($context) == 2 ) {
        # Appel asynchrone, la réponse sera récupérée par Data
        # Le thread client ne récupère que l'identifiant du call
        return $call_id;
    }
    #print DBG "File d'attente pour WHO = $who\n";
    my $data = $queue_by_tid{$client_tid}->dequeue;
    return get_message_for( $client_tid, $server_tid, $method, $call_id,
        $context, $data );
}

sub ask_thread {
    my ( $self, $method, $server_tid, @data ) = @_;

    # En commun avec ask2 : à simplifier !!!
    my $id;
    if ( ! ref $self ) { #eq 'Text::Editor::Easy' or $self eq 'Text::Editor::Easy::Async' )
        # Appel d'une méthode de classe
        $id = '';
    }
    else {
        $id = $com_unique{ refaddr $self };

        if ( !defined $id ) {
            print STDERR "ask_thread : no reference found for object $self\n";
            return;
        }
    }
    
# Attention, la première donnée de la fonction est $id || $self ==> cad la référence avec laquelle la méthode de thread
# a été appelée
    # Following call not to be shown in trace
    return new_ask( 
        $self, $method, $id, threads->tid, $server_tid, $id || $self, @data
    );
}

sub ask_named_thread {
    my ( $self, $method, $server, @data ) = @_;

    # En commun avec ask2 : à simplifier !!!
    my $id;
    if ( ! ref $self  ) { #eq 'Text::Editor::Easy' or $self eq 'Text::Editor::Easy::Async' )
        # Appel d'une méthode de classe
        $id = '';
    }
    else {
        $id = $com_unique{ refaddr $self };

        if ( !defined $id ) {
            print STDERR "ask_named_thread : no reference found for object $self\n";
            return;
        }
    }
    my $server_tid = $server;
    if ( $server =~ /\D/ ) {
        my $hash_ref = $get_tid_from_thread_name{$server};
        $server_tid = $hash_ref->{$id};
        #print "Ask named thread, trouvé pour server $server tid $server_tid|@data\n";
    }
    
# Attention, la première donnée de la fonction est $id || $self ==> cad la référence avec laquelle la méthode de thread
# a été appelée
    return new_ask( $self, $method, $id, threads->tid, $server_tid, @data );
}

sub create_thread {
    my ( undef, @param ) = @_;

    print DBG "Dans create_thread : tid = ", threads->tid, "\n";

    my $thread = threads->new( \&verify_server_queue_and_wait, @param );

    # On ne peut pas sortir sans être sûr de pouvoir s'adresser au thread créé
    # ===> création de la file d'attente
    my $tid = $thread->tid;

    my $string =
        "Dans create thread, création de $tid ("
      . scalar( threads->list )
      . " threads actifs)\n";
    my $indice = 0;
    while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
        $string .= "P|F|L|$pack|$file|$line|\n";
    }
    print DBG $string;

    if ( !$server_queue_by_tid{$tid} ) {
        $server_queue_by_tid{$tid} = Thread::Queue->new;
    }

    #print "Création du thread $tid finie\n";
    return $tid;
}
my $model_thread : shared;

use IO::File;
use File::Basename;
my $name = fileparse($0);

sub verify_model_thread {
    my ( $trace_ref ) = @_;
    
    if ( defined $data_thread ) {
        return trace_new();
    }

# To suppress "taint error" => "Insecure dependency in open while running with -T switch at ..."
    $name =~ m/^([a-zA-Z0-9\._]+)$/; 

    manage_debug_file( __PACKAGE__, *DBG, { 'trace' => $trace_ref } );
    print DBG
"\nThis is a multi-thread debug File as any thread knows Text::Editor::Easy::Comm\n\n";

    my $queue = $server_queue_by_tid{0};

    # Vérification de la queue serveur
    if ( !$queue ) {
        $queue = Thread::Queue->new;
        $server_queue_by_tid{0} = $queue;
    }

    # Vérification de la queue cliente
    if ( !$queue_by_tid{0} ) {
        $queue_by_tid{0} = Thread::Queue->new;
    }

    # Traçage des demandes de création (appels à la méthode new)
    my ( $package, $filename, $line ) = caller(1);

    # Traçage de l'appel dans Data mais de façon asynchrone
    my @calls;
    my $indice = 1;
    while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
        push @calls, ( $pack, $file, $line );
    }
    my $array_dump = dump @calls;

    # La création de thread est déjà opérationnelle
    return if ( defined $model_thread );    

# Maintenant, on ne peut pas rendre la main tant que la création de thread n'est pas opérationnelle
    # Redirection des print sur STDERR et SDTOUT
    $trace_ref = {} if ( ! defined $trace_ref );    
    if ( $trace_ref->{'trace_print'} ) {
        tie *STDOUT, "Text::Editor::Easy::Comm::Trace", ('STDOUT');
        tie *STDERR, "Text::Editor::Easy::Comm::Trace", ('STDERR');
    }

    my $thread = threads->new( \&thread_generator );
    my $tid    = $thread->tid;

    $queue = $server_queue_by_tid{$tid};
    while ( !$queue ) {
        $queue = $server_queue_by_tid{$tid};
    }

    # Création multi-thread possible : on n'est pas seul...
    $model_thread = $tid if ( !defined $model_thread );
    
    if ( $model_thread != $tid ) {
    # Le model_thread a été créé par un autre éditeur, il faut éliminer le notre
        my $message = dump (undef);
        $queue->enqueue($message);

        $thread->join();
        # Suppression des queue (ou recyclage ?) à faire
    }
    else {
        for my $method ( 'model_method', 'trace_create' ) {
            my %hash;
            share(%hash);
            my $hash_ref = $get_tid_from_class_method{$method};
            if ( defined $hash_ref ) {
                %hash = %{$hash_ref};
            }
            #$hash{$reference} = threads->tid;
            $hash{'Text::Editor::Easy'} = $model_thread;
            #print "Ajout de la méthode $method pour la classe $reference\n";
            $get_tid_from_class_method{$method} = \%hash;
        }
        
        $method{'explain_method'}   = ('explain_method');
        $method{'display_instance'} = ('display_instance');
        $method{'display_class'}    = ('display_class');

        $method{'empty_queue'}          = ('empty_queue');
        $method{'create_new_server'}    = ('create_new_server');
        $method{'create_client_thread'} =
          ('create_client_thread');
        $method{'id'}               = ('id');
        $method{'set_synchronize'}  = ('set_synchronize');
        $method{'get_synchronized'} = ('get_synchronized');

        $method{'create_thread'} = ('shared_thread:Text::Editor::Easy::Comm');
        $method{'add_method'}    = ('add_method');
        $method{'ask_thread'}    = ('ask_thread');
        $method{'ask_named_thread'}    = ('ask_named_thread');
        $method{'get_from_id'}   = ('get_from_id');
        create_data_thread( $trace_ref );
        $method{'set_event'}     = ('Text::Editor::Easy::Events::set_event');
        $method{'set_events'}    = ('Text::Editor::Easy::Events::set_events');
        $method{'set_sequence'}    = ('Text::Editor::Easy::Events::set_sequence');
    }
    
    # Now that everything has been created, we can trace the 'new' call
    return trace_new();
}

sub trace_new {
        my $string = "Dans trace_new...\n";
        my $indice = 0;
        while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
            $string .= "P|F|L|$pack|$file|$line|\n";
        }
        print DBG $string;
}

sub manage_debug_file {
    my ( $package, $file, $options_ref ) = @_;
    
    if ( ! defined $options_ref ) {
        $options_ref = Text::Editor::Easy->get_conf;
    }
    
    my $trace_ref = undef;
    if ( defined $options_ref and ref $options_ref eq 'HASH' ) {
        $trace_ref = $options_ref->{'trace'};
    }

    my $suffix = $package;
    $suffix =~ s/::/_/g;
    my $tid = threads->tid;
    
    if ( exists $trace_ref->{$package} ) {
        my $prefix = $trace_ref->{$package};
        if ( !defined $prefix ) {

            # Redirection
            tie $file, "Text::Editor::Easy::Comm::Null";
            print DBG
"Valeur spécifique pour $package non définie, il ne faut rien afficher\n";
        }
        else {
            # Ouverture
            my $data_trace = "${prefix}${name}__${tid}__${suffix}.trc";
            open( $file, ">$data_trace" )
              or die "Can't open debug file $data_trace : $!\n";
            autoflush $file;
            print DBG "Valeur $prefix spécifique trouvée pour $package\n";
            print DBG "Ouverture du fichier $data_trace pour $package / $tid\n";
        }
    }
    elsif ( my $prefix = $trace_ref->{'all'} ) {

        # Ouverture
        my $data_trace = "${prefix}${name}__${tid}__${suffix}.trc";
        open( $file, ">$data_trace" )
          or die "Can't open debug file $data_trace : $!\n";
        autoflush $file;
        print DBG
"Rien de spécifique pour $package mais un préfixe au niveau global : $prefix\n";
        print DBG "Ouverture du fichier $data_trace pour $package / $tid\n";
    }
    else {

        # Redirection
        tie $file, "Text::Editor::Easy::Comm::Null";
        print DBG
"Rien de spécifique pour $package, rien au niveau global : il faut rediriger\n";
    }
}

sub untie_print {
    untie *STDOUT if ( tied *STDOUT );
    untie *STDERR if ( tied *STDERR );

    #print "Fin de untie_print\n";
}

sub empty_queue {

# Arrêter l'exécution de requêtes asynchrones lorsque l'on sait qu'elles deviennent inutiles (voir eval_print)
    my ( $self, $tid ) = @_;

    #print DBG "Dans empty_queue self, tid = $self, $tid\n";
    $stop_dequeue_server_queue{$tid} = 1;
    while ( $server_queue_by_tid{$tid}->pending ) {
        my $data = $server_queue_by_tid{$tid}->dequeue;
        my ( $method, $call_id ) = decode_message($data);

# Problème subtil si appel en asynchrone (Text::Editor::Easy::Async) : à décortiquer
#   => piste ?, le thread 2 (Data) exécutant "free_call_id" est aussi responsable
#                   de la réception des requêtes asynchrones
#  Peut-on mélanger les appels synchrones et asynchrones vis-à-vis de ce thread ?
        Text::Editor::Easy->free_call_id($call_id)
          ; # call_id est en attente d'exécution, il faut libérer la mémoire occupée par Data
    }
    undef $stop_dequeue_server_queue{$tid};
}

sub create_data_thread {
    my ( $trace_ref ) = @_;


# Maintenant, on ne peut pas rendre la main tant que la création de thread n'est pas opérationnelle

    my $tid = Text::Editor::Easy->create_new_server(
        {
            'use'     => "Text::Editor::Easy::Data",
            'use_parm' => $trace_ref,
            'package' => 'Text::Editor::Easy::Data',
            'methods' => [
                'find_in_zone',
                'list_in_zone',
                'reference_editor',
                'data_file_name',
                'data_name',
                'trace',
                'trace_print',
                'trace_call',
                'trace_start',
                'trace_response',
                'async_status',
                'async_response',
                'reference_print_redirection',
                'size_self_data',
                'free_call_id',
                'print_thread_list',
                'data_get_editor_from_name',
                'data_get_editor_from_file_name',
                'reference_zone',
                'zone_named',
                'zone_list',
                'save_current',
                'data_last_current',
                'data_get_search_options',
                'data_set_search_options',
                'trace_user_event',
                'trace_end_of_user_event',
                'trace_eval',
                'tell_length_slash_n',
                'data_zone',
                'update_full_trace',
                'data_set_event',
                'data_set_events',
                'data_set_sequence',
                'data_events',
                'data_sequences',
                'print_default_events',
                'configure',
                'get_conf',
                'get_event_threads',
                'set_default',
                'event_threads',
            ],
            'object' => [],
            'init'   => ['Text::Editor::Easy::Data::init_data', $trace_ref],
            'name' => 'Data',
        }
    );

    my $queue = $server_queue_by_tid{$tid};
    while ( !$queue ) {
        $queue = $server_queue_by_tid{$tid};
    }

    $data_thread = $tid;
}

sub verify_graphic {
    my ( $hash_ref, $editor ) = @_;
    my $zone_ref = $hash_ref->{'zone'};

    #print "verify graphic : force_resize $force_resize\n";
    my $ref = refaddr $editor;
    set_ref ( $editor, $ref );
    #$com_unique{$ref} = $ref;

    my $queue = $server_queue_by_tid{0};

    my $tid = threads->tid;

    if ( $tid == 0 ) {
        if ( $get_tid_from_instance_method{'insert'} ) {
            #print "Pas de double création, serveur graphique déjà créé\n";
                return ask_thread( $editor,
                    'add_thread_object',
                    0,
                    {
                        'new' =>
                          [ 'Text::Editor::Easy::Comm::new_editor', $ref, $hash_ref ]
                    }
                );
        }
        else {
        print "Réservation du thread avec tid 0 pour le graphique, référence de la première instance : $ref\n";
        $editor->create_new_server(
            {
                'use'     => 'Text::Editor::Easy::Abstract',
                'package' => 'Text::Editor::Easy::Abstract',
                'new'     => [
                    'Text::Editor::Easy::Abstract::new',
                    'Text::Editor::Easy::Abstract',
                    $hash_ref, $editor, $ref
                ],
                'name' => 'Graphic',
                'put_tid' => 1,
                
                'do_not_create' => 1,
                
                'methods'       => [
                    'test',

                    #    'exit',   class method
                    #    'abstract_join', class method
                    'insert',
                    'enter',
                    'erase',
                    'change_title',
                    'bind_key',
                    'wrap',
                    'display',
                    'empty',
                    'deselect',
                    'eval',
                    'save_search',
                    'focus',
                    'at_top',
                    'width',
                    'height',

                    'abstract_size',

                    'new_editor',
                    'editor_visual_search',

                    'screen_first',
                    'screen_last',
                    'screen_number',
                    'screen_font_height',
                    'screen_height',
                    'screen_y_offset',
                    'screen_x_offset',
                    'screen_line_height',
                    'screen_margin',
                    'screen_width',
                    'screen_set_width',
                    'screen_set_height',
                    'screen_set_x_corner',
                    'screen_set_y_corner',
                    'screen_move',
                    'screen_wrap',
                    'screen_set_wrap',
                    'screen_unset_wrap',
                    'screen_check_borders',

                    'display_text',
                    'display_next',
                    'display_previous',
                    'display_next_is_same',
                    'display_previous_is_same',
                    'display_number',
                    'display_ord',
                    'display_height',
                    'display_middle_ord',
                    'display_abs',
                    'display_select',

                    'line_displayed',
                    'line_select',
                    'line_deselect',
                    'line_set',
                    'line_top_ord',
                    'line_bottom_ord',

                    'cursor_position_in_display',
                    'cursor_position_in_text',
                    'cursor_abs',
                    'cursor_virtual_abs',
                    'cursor_line',
                    'cursor_display',
                    'cursor_set',
                    'cursor_set_shape',
                    'cursor_get',
                    'cursor_make_visible',

                    'load_search',
                    'debug_display_lines',
                    'on_focus_lost',
                    'graphic_kill',
                    'repeat_instance_method',
                    'growing_check',
                    'set_at_end',
                    'unset_at_end',
                    #'zone',
                    'make_visible',
                    'set_replace',
                    'set_insert',
                    'insert_mode',
                    'background',
                    'set_background',
                    'set_highlight',
                    'visual_slurp',

                    # Event management
                    'key',
                    'clic',
                    'motion',
                    'resize',
                    'drag',
                    'wheel',
                    'double_clic',
                    'right_clic',
                    'execute_sequence',
                ],
            }
        );
        # Intégrer la possibilité de mettre un hachage dans "create_new_server" (quand 'sub' ne 'method')
        
        ############################################
        #
        # Bug à voir => méthodes non reportées sur les instances suivantes... => renommage des méthodes
        #
        ############################################
        #$editor->ask_thread(
        #    'add_thread_method',
        #    0,
        #    {
        #        'package' => 'Text::Editor::Easy::Abstract',
        #        'method' => {
        #            'insert_mode' => 'editor_insert_mode',
        #            'set_insert' => 'editor_set_insert',
        #            'set_replace' => 'editor_set_replace',
        #            'make_visible' => 'editor_make_visible',
        #        },
        #        'class' => 'Text::Editor::Easy',
        #    }
        #);

        Text::Editor::Easy->ask_thread(
            'add_thread_method',
            0,
            {
                'package' => 'Text::Editor::Easy::Abstract',
                'method'  => [ 
                        'reference_zone_events',
                        'exit', 
                        'abstract_join', 
                        'manage_event', 
                        'clipboard_set', 
                        'clipboard_get', 
                        'on_top_ref_editor', 
                        'on_editor_destroy', 
                        'repeat',
                        'repeat_class_method',
                        'window_set',
                        'window_get',
                        'graphic_zone_update',
                    ]
            }
        );
        Text::Editor::Easy->ask_thread(
            'add_thread_method',
            0,
            {
                'package' => 'Text::Editor::Easy::Abstract',
                'method'  => 'bind_key',
                'sub'      => 'bind_key_global',
            }
        );
        }
        # Permet de renvoyer 0 si pas de création (suite à problème)
        #return Text::Editor::Easy->ask_thread(
        #    'Text::Editor::Easy::Abstract::abstract_number',
        #    0,
        #);
        return 1;
    }
    else {
        #print "Appel de add_thread_object par le thread ", threads->tid, " pour l'instance $ref\n";
        return $editor->ask_thread(
            'add_thread_object',
            0,
            {
                'new' =>
                  [ 'Text::Editor::Easy::Comm::new_editor', $ref, $hash_ref ]
            }
        );
    }
}

my %editor;

sub set_ref {
    my ( $self, $ref ) = @_;

    return if ( !defined $ref );
    $com_unique{ refaddr $self } = $ref;
    
    print DBG "Dans set_ref, on fixe la ref $ref pour l'éditeur $self|", refaddr $self, "\n";
    print DBG "...tid = ", threads->tid, "\n";

    if ( ref $self ne 'Text::Editor::Easy::Async' ) {
        #print "Danger, Async référencé !\n";
        $editor{ threads->tid . '_' . $ref } = $self;        
    }
}

sub id {
    my ($self) = @_;

    return $com_unique{ refaddr $self };
}

sub get_from_id {
    my ( $self, $id ) = @_;
    
    # Méthode de classe mais peut être appelée avec une instance (self non utilisée)
    return if ( ! $id );
    
    my $editor = $editor{ threads->tid . '_' . $id};
    
    if ( $editor ) {
        #print "Editeur $editor défini pour l'id $id, refaddr ", refaddr $editor, "| tid = ", threads->tid, "\n";
        return $editor;
    }
    
    #  Tester la validité de $id (en controlant %com_unique) ? ... analyser les conséquences possibles de la non vérification.
 
    $editor = bless \do { my $anonymous_scalar }, 'Text::Editor::Easy';
    
    print DBG "On fixe a id = $id le nouvel éditeur editor = $editor| refaddr.. = ", refaddr $editor, "\n";
    
    $com_unique{ refaddr $editor } = $id;
    $editor{ threads->tid . '_' . $id} = $editor;
    
    return $editor;
}

sub new_editor {
    my ( $ref, $hash_ref ) = @_;

    print DBG "Dans new_editor $ref|$hash_ref\n";

    #print "\tREF $ref\n\tREF_HASH $hash_ref\n\tRESTE $reste\n";
    my $editor = bless \do { my $anonymous_scalar }, 'Text::Editor::Easy';
    print DBG "Dans new_editor editor = $editor| refaddr.. = ", refaddr $editor, ", id ==> $ref\n";
    set_ref( $editor, $ref );
    #$com_unique{ refaddr $editor } = $ref;

    print DBG "Dans new_editor, avant appel Abstract new\n";
    my $object = Text::Editor::Easy::Abstract->new( $hash_ref, $editor, $ref );
    print DBG "Fin de new_editor\n";

    return $object;
}

sub create_client_thread {

    #print "Dans la méthode de création d'un thread client\n";
    my ( $self, $sub_name, $package ) = @_;

    my $ref        = refaddr $self;
    my $id = $com_unique{$ref};
    if ( !$id ) {
        print STDERR "create_client_thread : no reference found for object $self\n";
        return;
    }

#print "... méthode de création d'un thread client : $id\n";
# Cette méthode de top bas niveau devrait être masquée de l'interface : juste un exemple de thread "shared" entre les éditeurs
    $package = 'main' if ( !defined $package );
    my $tid = create_thread( $self, $id, $package );
    #my $tid = Text::Editor::Easy->trace_create( $self, $id, $package );

    #print "TID = $tid\n";
    my $queue = $server_queue_by_tid{$tid};

    my $message =
      dump ( "${package}::$sub_name", threads->tid, "S", $id,
        $package );
    $queue->enqueue($message);

# Attention, le code retour devra être analysé en cas de problème : attente sur la queue cliente
# Pour l'instant, cela serai bloquant puisque thread_generator ne renvoie rien
# my $response = $queue_by_tid{threads->tid}->dequeue;
# return if ( ! defined $response );

    return $tid;
}

sub thread_generator {
    my $tid = threads->tid;

    if ( !$server_queue_by_tid{$tid} ) {
        $server_queue_by_tid{$tid} = Thread::Queue->new;
    }
    if ( !$queue_by_tid{$tid} ) {
        $queue_by_tid{$tid} = Thread::Queue->new;
    }
    
    init_server_thread('Text::Editor::Easy', {
        'package' => 'Text::Editor::Easy::Comm',
        'methods' => [ 'model_method', 'trace_create' ],
        'object'  => [],
    } );
    
    print DBG "Thread générator démarré...\n";
    
    while ( my ( $what, $call_id, @param ) = get_task_to_do ) {
        last if ( !defined $what );

        # La seule chose que sait faire le thread_generator, c'est générer des threads
        #print DBG "Dans thread générator : $what|$call_id|@param\n";
        execute_this_task( $what, $call_id, @param );
        #if ( $what eq 'create_thread' ) {
        #    simple_call( undef, 'create_thread', \&create_thread, @param );
        #}
        #else {
            #my $tid = shift @param;
        #    print "Dans thread_generator, tid = $tid, param = @param\n";
        #}
    }
    print DBG "Thread générator fini...\n";
}

sub verify_server_queue_and_wait {
    my ( $id, $package ) = @_;

    my $tid = threads->tid;

    print DBG "Création de queue_by_tid pour $tid\n";
    if ( !$queue_by_tid{$tid} ) {
        $queue_by_tid{$tid} = Thread::Queue->new;
    }

    my $queue = $server_queue_by_tid{$tid};

    # Il ne faut pas se mettre en attente sur une file non encore créée
    while ( !$queue ) {
        # La création est faite en parallèle par le thread qui a créé celui-ci
        $queue = $server_queue_by_tid{ $tid }; 
    }
    
    # Initalisation du $call_order, utile si le thread devient un serveur
    $call_order = 0;

    #print "Mise en attente du thread $tid\n";
    my $data = $queue->dequeue;

    my ( $what, @param ) = decode_message($data);
    if ( defined $what ) {

        my $sub_ref = eval "\\&$what";

        #print "Utilisation du thread $tid et appel $what ($sub_ref)\n";

      # Appel seulement lorsque la file d'attente client existe (faire un while)
        if ( defined $id ) {    # Thread dédié à un éditeur
            my $editor;
            if ( $id =~ /\D/ ) {

                # Class call
                $editor = $id;
            }
            else {
                $editor = bless \do { my $anonymous_scalar }, 'Text::Editor::Easy';
                set_ref( $editor, $id );
                print DBG "Dans verif_server_queue editor = $editor| refaddr.. = ", refaddr $editor, "\, id = $id\n";
                #$com_unique{ refaddr $editor } = $id;
            }

            #print "PARAM @param|", scalar(@param), "\n";

  # Attention l'instruction qui suit doit être mise dans un eval
  # En cas d'échec il faut sortir avec undef et renvoyer cela au thead demandeur
            shift @param;
            shift @param;
            # Inter-thread call, not to be shown in trace
            $sub_ref->( $editor, @param );
        }
        else {    # Thread partagé entre tous les éditeurs
            shift @param;
            shift @param;

            $sub_ref->(@param);
        }
    }
    print "Dans Comm, mort du thread $tid\n";
    return 1;
}

sub set_synchronize {
    my ($self) = @_;

    my $id = $com_unique{ refaddr $self };
    $synchronize{$id} = 1;
}

sub get_synchronized {
    my ($self) = @_;

    my $id = $com_unique{ refaddr $self };
    while ( !$synchronize{$id} ) {
    }
}

sub init_server_thread {
    my ( $self_caller, $options_ref ) = @_;

#Bug à voir : comment est-ce que l'on peut déjà avoir une clé renseignée dans $thread_knowledge ?
    $thread_knowledge{'instance'} = {};

    my $indice = 0;
    while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
        print DBG "P|F|L|$pack|$file|$line|\n";
    }
    %ref_method = ();

    my $use = $options_ref->{'use'};
    my $use_parm = $options_ref->{'use_parm'};
    my $package = $options_ref->{'package'} || 'main';
    for my $method ( @{ $options_ref->{'methods'} } ) {
        print DBG "Ajout dans \%ref_method de $method (", threads->tid, ") : package $package\n";
        $ref_method{$method}[USE]     = $use;
        $ref_method{$method}[PACKAGE] = $package;
        $ref_method{$method}[SUB]     = $method;
        $ref_method{$method}[REF]     = eval "\\&${package}::$method";
    }
    if ( defined $use ) {
        my $string = "use $use;";
        if ( defined $use_parm ) {
            $string = "use $use " . dump($use_parm) . ";";
        }
        #print "Dans manage_request2, évaluation de $string\n";
        eval $string;
        
        $use{$use}{'messages'} = $@;
        if ($@) {
            print DBG "Error while evaluating module $use :\n$@\n";
            print STDERR "Error while evaluating module $use :\n$@\n";
        }
        else {
            print DBG "Evaluation de $use correcte\n";
        }
    }

    # Recalcul de $self_server
    my $self_server = $options_ref->{'object'};
    if ( !defined $self_server ) {
        if ( my $new_ref = $options_ref->{'new'} ) {
            my ( $sub_name, @param ) = @$new_ref;
            my $sub_ref = eval "\\&$sub_name";
            print DBG "Avant appel new : |$sub_name|@param|$sub_ref|\n";
            $self_server = $sub_ref->(@param);
        }
    }

    $thread_knowledge{'package'} = $package;
    my $initial_reference;
    if ( ref $self_caller )
    {    # Actuellement, c'est toujours une référence d'objet Text::Editor::Easy
            # car verify_server_queue ... crée un objet Text::Editor::Easy
            # sans se soucier de ce qu'il était éventuellement au départ
            # Owned thread
        print DBG "OWNED THREAD : SELF caller $self_caller|",
          ref $self_caller, "|\n";
        $initial_reference = $com_unique{ refaddr $self_caller };
    }
    elsif ( $self_caller =~ /^\d+$/ ) {
        print DBG "OWNED THREAD ou MULTIPLEXED : SELF caller $self_caller|";
        $initial_reference = $self_caller;
    }
    else {
        # Shared thread
        print DBG "SHARED THREAD : SELF caller $self_caller|";
        #  ref $self_caller, "|$self_server\n";
        $initial_reference = 'Text::Editor::Easy'
#if ( $self_caller eq 'Text::Editor::Easy::Async' );
#    $initial_reference = $self_caller;
#}
    }
    
    # A revoir (paramètres d'appels de model thread)
    $initial_reference = 'Text::Editor::Easy' if ( ! defined $initial_reference );
    
    $thread_knowledge{'instance'}{$initial_reference} = $self_server;
    print DBG "On met $self_server dans thread_knowledge de instance (tid ",
      threads->tid, ") de $initial_reference\n";
    $thread_knowledge{'self_server'} = $self_server;

    return $self_server;
}

sub manage_requests2 {
    my ( $self_caller, $options_ref ) = @_;

    my $self_server = init_server_thread( $self_caller, $options_ref );

    while ( my ( $method, $call_id, $reference, @param ) = get_task_to_do ) {
        #print DBG "Dans manage2, avant appel execute $method|", scalar(@param),
        #  "|reference : $reference\n\t|";
        for my $indice ( 0 .. scalar(@param) - 1 ) {
            my $element = $param[ $indice - 1 ];
            if ( defined $element ) {
                print DBG $element, "|";
            }
            else {
                print DBG 'undef|',;
            }
        }
        print DBG "\n";
        if (
            execute_task(
                'async',  $self_server, $method,
                $call_id, $reference,   @param
            )
          )
        {
            last;
        }
    }
    print DBG "Fin du thread ", threads->tid, "\n";

    # Nettoyage
    my $call_id = Text::Editor::Easy::Async->abstract_join( threads->tid, "useless" );
    $stop_server{ threads->tid } = $call_id;
    print DBG "On quitte avec call_id $call_id\n";
}

my %com_method = (
    'use_module' => 1,
    'add_thread_method' => 1,    
    'get_tid' => 1,
    'add_thread_object' => 1,    
    'stop_thread' => 1,
);

sub execute_task {
    my ( $call, $self_server, $method, $call_id, $reference, @param ) = @_;

    print DBG "Appel request2: ", threads->tid, "|$method|$call_id|$reference|context $param[0]\n";
    my $reference_ref = $thread_knowledge{'instance'};

    my $string =
        "CLES de \$thread_knowledge{'instance'} : "
      . threads->tid
      . " ($method) dans execute_task\n";
    for my $key ( keys %$reference_ref ) {
        $string .= "\t$key|" . $reference_ref->{$key} . "|\n";
    }
    print DBG $string;
    
    $reference = 'Text::Editor::Easy' if ( $reference =~ /\D/ );
    print DBG "Nouvelle référence = $reference\n";
      #if ( $reference eq 'Text::Editor::Easy::Async' );

    # Problème sous Windows, undef obligatoire (bug perl ?)
    # Bug subtil sans le "= undef" ... ==> parfois défini et tout déconne
    my $method_ref = undef;

    #my $object = $reference_ref->{$reference};
    my $object = $reference_ref->{$reference};

    #print DBG "On a récupéré ( tid ", threads->tid,
    #  ", méthode : $method) dans thread_knowledge de instance de $reference |";
    #print DBG "\$object défini => |$object" if ( defined $object );
    #print DBG "|\n";
    if ( defined $object ) {
        print DBG "Avant définition de \$method_ref\n";
        $self_server = $object;
        $method_ref  = $ref_method{$method};
        #my $string = "Appel avec une référence initale |$method|";
        #if ( defined $method_ref ) {
        #    $string .=
        #      "\$method_ref défini => |$method_ref|" . $method_ref->[REF];
        #}
        #$string .= "|\n";
        #print DBG $string;
    }
    else {
        print DBG "Appel avec autre ref : |$reference|$method\n";

# Problème sous Linux ($method_ref devient défini de façon magique ?  bug perl ?)
        $method_ref = undef;

        if ( my $ref = $ref_method{$method} ) {
            print DBG "REF = $ref\n";
            if ( my $other_ref = $ref->[OTHER] ) {
                print DBG "Référence trouvée\n";
                $method_ref = $ref_method{$method}[OTHER]{$reference};
            }
        }
        if ( !defined $method_ref and $reference =~ /\D/ )
        {    # Méthode de classe non définie
                # On force (héritage) Text::Editor::Easy pour la classe
            print DBG
"Dans manage_...2 : on force la méthode de classe Text::Editor::Easy pour $method\n";
            if ( $reference_ref->{'Text::Editor::Easy'} )
            {    # Shared thread
                $method_ref = $ref_method{$method};
                print DBG
"méthode de classe Text::Editor::Easy trouvée en standard...$method_ref\n";
            }
            elsif ( my $ref = $ref_method{$method} ) {    # Owned thread
                print DBG "OWNED THREAD...\n";
                if ( my $other_ref = $ref->[OTHER] ) {
                    print DBG "Trouvé other_ref : $other_ref pout $method\n";
                    $method_ref = $other_ref->{'Text::Editor::Easy'};
                }
            }
        }
    }

    #print "Dans manage_request2 avant tests |$method|$method_ref|\n";
    if ( !defined $method_ref )
    {    # Methode de thread : eval, add_method, overload_method ...
         # Tester l'appartenance à un sous-ensemble de méthodes autorisées => il ne faut pas lancer n'importe quoi
         # en cas d'erreur réelle
        print DBG "Appel d'une fonction non définie par défaut : $method\n";
        
        if ( $method !~ /::/ and ! $com_method{$method} ) {
            # La méthode est donnée sans nom de package
            # => on place le package par défaut du thread, sinon c'est Text::Editor::Easy::Comm qui est pris
            # tout le temps ce qui est beaucoup moins intéressant
            
            
            print DBG "Avant use of un...\n";
            #my $indice = 0;
            #while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
            #    print "\tfile $file| |line $line|pack $pack\n";
            #}

            
            $method = $thread_knowledge{'package'} . '::' . $method;
        }
        
        my $ref_sub = eval "\\&$method";
        if ( $@ ) {
            print STDERR "Wrong evaluation of pseudo-method $method in thread tid ", threads->tid, ":\n$@\n";
        }
        
        # Problème, on ne récupère pas la valeur retour dans l'appelant (par exemple, lorque on fait un
        # ask_thread dans le même thread...)
        my @return;
        my $return;
        
        if ( wantarray ) {
            @return = eval { simple_call( $self_server, $method, $ref_sub, $call_id, @param ); }
            # Modifier ask_thread et le fichier test "...add_method.t"
             # La procédure d'init passe aussi par ici et elle doit récupérer l'objet standard qui sera utilisé
             # pour tous les appels suivants (init = initialisation de cet objet => voir file_manager)
        }
        else {
            $return =  eval { simple_call( $self_server, $method, $ref_sub, $call_id, @param ); }
        }
        if ( $@ ) {
            print STDERR "Wrong execution of pseudo-method $method in thread tid ", threads->tid, "\n$@\n";
            if ( $call eq 'sync' ) {
                return;
            }
        }
        elsif ( $call eq 'sync' ) {
            if ( wantarray ) {
                return @return;
            }
            else {
                return $return;
            }
        }

        #print "Fin de l'appel spécial de $method\n";
    }
    elsif ( my $sub_ref = $method_ref->[REF] ) {
        #print DBG "Appel standard simple_call pour $method\n";
        if ( $call eq 'sync' ) {
            return simple_call( $self_server, $method, $sub_ref,
                $call_id, @param );
        }
        else {
            simple_call( $self_server, $method, $sub_ref, $call_id, @param );
        }
    }
    else
    {    # Ne devrait jamais servir : évaluer toujours lors de l'initialisation
        #print DBG "Appel à vérifier : $method (", threads->tid, ")\n";

        # Si utilisé, alors traiter [MEMORY] avant
        my $package = $method_ref->[PACKAGE];
        my $sub     = $method_ref->[SUB];
        if ( defined $sub and defined $package ) {
            my $sub_ref = eval "\\&${package}::$sub";
            simple_call( $self_server, $sub, $sub_ref, $call_id, @param );
        }
        else {
            #print DBG "SUB et PACKAGE indéfinis...|", $method_ref->[REF], "|\n";
        }
    }
    return $thread_knowledge{'stop_wanted'};
}

sub stop_thread {
    my ( $self_server, $reference, $options_ref ) = @_;

    print DBG "Dans stop_thread, tid = ", threads->tid, "\n";
    $thread_knowledge{'stop_wanted'} = 1;
}

sub add_thread_object {    # Permet de rendre un thread multi-plexed
    my ( $self_server, $reference, $options_ref ) = @_;

    #print "Dans add_thread_object : self_server = $self_server, reference = $reference\n";

    my $initial_instance_ref = $thread_knowledge{'instance'};
    if ( $initial_instance_ref->{$reference} ) {
        print STDERR
"Can't add object to thread for the already existing reference $reference\n";
        print STDERR "ini..ref = ", dump( $initial_instance_ref ), "\n";
        return;
    }
    if ( my $object = $options_ref->{'object'} ) {
        $initial_instance_ref->{$reference} = $object;
        return $object;
    }
    if ( my $new_ref = $options_ref->{'new'} ) {
        my ( $sub_name, @param ) = @$new_ref;
        my $sub_ref = eval "\\&$sub_name";
        my $object = $sub_ref->(@param);
        $initial_instance_ref->{$reference} = $object;
        return $object;
    }
}

sub explain_method {
    my ( $self, $method ) = @_;

    print "Dans explain_method : $self, $method\n";
}

sub add_method {
    my ( $self, $method, $options_ref ) = @_;

    # Add method without thread association
    # ==> the method will be executed by the calling thread itself
    return if ( !defined $method );

    my $key;

    #if ( $options_ref->{'use'}
    my $package = 'main' || $options_ref->{'package'};
    my $name = $options_ref->{'sub'} || $method;

    #my $name = $method;
    #$name = $options_ref->{'sub'} if ( defined $options_ref->{'sub'} );
    if ( ref $self ) {

        # instance method (adding it for only one Text::Editor::Easy object)
        print "Adding method $method to object $self\n";
        $key = id($self) . ' ' . $method;
    }
    else {

        # class method (adding it for all Text::Editor::Easy objects)
        print "Adding method $method to all Text::Editor::Easy objects\n";
        $key = $method;
    }
    $method{$key} = "${package}::$name";
}

sub create_new_server {
    my ( $self, $options_ref ) = @_;

    my $package         = $options_ref->{'package'} || 'main';
    my $tab_methods_ref = $options_ref->{'methods'};
    my $self_server     = $options_ref->{'object'};

    #print DBG "Début create_new_server \$self $self, méthodes : ", @$tab_methods_ref, "\n";

    my $id = undef;
    if ( defined $self and ref($self) ) {
        #print DBG "Dans create_new_server, thread d'instance 1 : ref \$self = ", ref($self), "\n";
        
        my $ref = refaddr $self;
        $id = $com_unique{$ref};

        if ( !defined $id ) {
            print STDERR "create_new_server : no reference found for object $self\n";
            return;
        }
    }
    my $self_caller;
    if ( !$id ) {
        $self_caller = $self;    # Class call => shared thread expected
    }
    else {
        $self_caller = $id;
    }
    my $tid = threads->tid;
    if ( !$options_ref->{'do_not_create'} ) {
        #$tid = create_thread( $self, $self_caller, $package );
        $tid = Text::Editor::Easy->trace_create( $self, $self_caller, $package );
    }
    {
        my $key;
        my $name     = $options_ref->{'name'};
        if ( $id ) {       # Appel d'instance ($self est un objet)
            #my $class    = ref $self;
            my $class = 'Text::Editor::Easy';
            
            my $name_tid = $name || $tid;
            $name_tid = $tid if ( $options_ref->{'put_tid'} );
            if ( $options_ref->{'specific'} ) {
                $key = $id;
            }
            else {
                $key = $class;
            }
            if ( $name and !$options_ref->{'put_tid'} ) {
                my $hash_ref = $get_tid_from_thread_name{$name};
                my %hash;
                share(%hash);
                if ( defined $hash_ref ) {
                    %hash = %{$hash_ref};
                }
                $hash{$id}               = $tid;
                $get_tid_from_thread_name{$name} = \%hash;
            }
            for my $method ( @{$tab_methods_ref} ) {
                print DBG
"Ajout dans \%get_tid_from_instance_method de $method (name_tid $name_tid)\n";
                my $hash_ref = $get_tid_from_instance_method{$method};
                my %hash;
                share(%hash);
                if ($hash_ref) {
                    %hash = %{$hash_ref};
                }
                $hash{$key}                            = $name_tid;
                $get_tid_from_instance_method{$method} = \%hash;
            }
        }
        else
        { # Appel de classe ($self ne compte plus => 'Text::Editor::Easy' est forcé)
            for my $method ( @{$tab_methods_ref} ) {
                print DBG "Ajout dans \%get_tid_from_class_method de $method\n";
                my $hash_ref = $get_tid_from_class_method{$method};
                my %hash;
                share(%hash);
                if ($hash_ref) {
                    %hash = %{$hash_ref};
                }
                $hash{'Text::Editor::Easy'} = $tid;
                $get_tid_from_class_method{$method} = \%hash;
            }
            # On renseigne le nom éventuel...
            if ( $name ) {
                my $hash_ref = $get_tid_from_thread_name{$name};
                my %hash;
                share(%hash);
                if ( defined $hash_ref ) {
                    %hash = %{$hash_ref};
                }
                $hash{''}               = $tid;
                $get_tid_from_thread_name{$name} = \%hash;
            }
        }
    }

    if ( !$options_ref->{'do_not_create'} ) {
        my $queue = $server_queue_by_tid{$tid};

        my $message = dump (
            "Text::Editor::Easy::Comm::manage_requests2",
            threads->tid,
            "S",
            {
                'package'  => $package,
                'methods'  => $tab_methods_ref,
                'use'      => $options_ref->{'use'},
                'use_parm' => $options_ref->{'use_parm'},
                'new'      =>
                  $options_ref->{'new'},    # $self_server vaut peut être undef
                'object' => $options_ref->{'object'},
            }
        );
        $queue->enqueue($message);
    }
    else {
        init_server_thread(
            $self_caller,
            {
                'package' => $package,
                'methods' => $tab_methods_ref,
                'use'     => $options_ref->{'use'},
                # $self_server vaut peut être undef
                'new'     => $options_ref->{'new'},
                'object'  => $options_ref->{'object'},
            }
        );
    }

# Attention, le code retour devra être analysé en cas de problème : attente sur la queue cliente
# Pour l'instant, cela serait bloquant puisque thread_generator ne renvoie rien
# my $response = $queue_by_tid{threads->tid}->dequeue;
# return if ( ! defined $response );

    print DBG "Create_new_server_thread : Je renvoie $tid\n";
    if ( my $init_sub_ref = $options_ref->{'init'} ) {
        # There is an "init sub" associated with the thread creation : we execute it
        my ( $what, @param ) = @$init_sub_ref;
        Text::Editor::Easy::Async->ask_thread( $what, $tid, @param );
    }

    print DBG "Fin de create_new_server $tid\n";
    return $tid;
}

sub comm_eval {
    my ( $self, $program ) = @_;

    no warnings;    # Make visible "global lexical variables" in eval
    %get_tid_from_class_method;
    %get_tid_from_instance_method;
    %get_tid_from_thread_name;
    use warnings;

    my @return;
    my $return;
    if (wantarray) {
        @return = eval $program;
    }
    else {
        $return = eval $program;
    }
    if ($@) {
        print $@, "\n";
        return;
    }
    if (wantarray) {
        return @return;
    }
    else {
        return $return;
    }
}

sub have_task_done {

# Called from an interruptible long task
# the (long) interruptible task has to call explicitly "have_task_done" from time to time
#  ==> there is no pre-emption (use another thread or another process for that)
# Generally, long interruptible task will be called asynchronously (but not mandatory :
# blocking the calling thread with a synchronous call does not prevent other threads
# from making calls to the executing thread)

# If a long interruptible task launch another long interruptible task, the first
# task will recover CPU only when the 2nd launched task is over
    my $self_server = $thread_knowledge{'self_server'};
    my ( $method, $call_id, $reference, @param ) = get_task_to_do;

    if ( $method eq 'clipboard_set' ) {
        print "HAVE_TASK_DONE : Appel clipboard_set, @param\n";
    }
    execute_task( 'async', $self_server, $method, $call_id, $reference,
        @param );
}

sub execute_this_task {
    my ( $method, $call_id, $reference, @param ) = @_;
    my $self_server = $thread_knowledge{'self_server'};
    execute_task( 'async', $self_server, $method, $call_id, $reference,
        @param );
}

sub get_tid {
    return threads->tid;
}

sub get_tid_from_name_and_instance {
    my ( $id, $name ) = @_;
        
    if ( ! ref $id ) {
        # Appel d'une méthode de classe
        $id = '';
    }
    else {
        $id = $com_unique{ refaddr $id };

        if ( !defined $id ) {
            print STDERR "get_tid_from_name_and_instance : no reference found for object $id\n";
            return;
        }
    }

    my $hash_ref = $get_tid_from_thread_name{$name};
    my $server_tid = $hash_ref->{$id};
    if ( defined $server_tid ) {
        #print "Dans get_tid... 1 : renvoie server_tid = $server_tid\n";
        return $server_tid;
    }
    if ( defined $id ) {
        $server_tid = $hash_ref->{''};
    }
    #print "Dans get_tid... 2 : renvoie server_tid = $server_tid\n";
    return $server_tid;
}

sub use_module {
    my ( $self_server, $reference, $module ) = @_;
    
    eval "use $module";
    if ( $@ ) {
        # Lire les lignes et ajouter une origine supplémentaire (les lignes du module responsable du message)
        print STDERR "Wrong code for module $module :\n$@\n";
    }
}

sub model_method {
    my ( $self, @param ) = @_;
    
    print DBG "Dans model_method, tid = ", threads->tid, "\n";
    return @param;
}

sub trace_create {
    my ( $self, @param ) = @_;
    
    create_thread ( $self, @param );
}

=head1 FUNCTIONS

=head2 add_method

=head2 add_thread_method

=head2 add_thread_object

=head2 anything_for

"anything_for_me" can tell one thread if there is something more to do for itself. With "anything_for" and the tid of the thread given, any thread can know about the queue of any other thread.
This is used to propagate lazyness between threads : a running task can be stopped if the change in another thread invalidates it.

=head2 ask2

=head2 ask_common

=head2 ask_thread

=head2 ask_named_thread

ask_thread requires to know the tid of a thread. But an arbitrary number is not what we'd like to use.

=head2 comm_eval

=head2 create_client_thread

=head2 create_data_thread

=head2 create_new_server

=head2 create_thread

=head2 decode_message

=head2 empty_queue

=head2 execute_task

=head2 explain_method

=head2 get_message_for

Return the reference (unique) of a Text::Editor::Easy instance.

=head2 get_synchronized

=head2 init_server_thread

=head2 manage_requests2

=head2 new_ask

=head2 new_editor

This sub is called only in the graphic thread context (with the thread that has tid 0).
It initializes new graphical data for the new "Text::Editor::Easy" object as well as reference this object for
thread communication.

=head2 manage_debug_file

Quick mecanism to display or to hide debug information from a package / thread. Don't need to remove
all the "print DBG" everywhere.

=head2 ref

=head2 respond

=head2 set_ref

=head2 set_synchronize

=head2 simple_call

=head2 simple_context_call

=head2 stop_thread

=head2 thread_generator

=head2 trace_new

Every AUTOLOAD calls are traced. Still some important methods (instance creation, thread creation, ...) are not yet traced. To be done.

=head2 untie_print

=head2 verify_graphic

=head2 verify_model_thread

=head2 verify_server_queue_and_wait

=head1 AUTHOR

Sebastien Grommier, C<< <sgrommier at free.fr> >>

=head1 BUGS

Besides the numerous bugs installed maybe for years in this code, there is one which I think about. It's deadlock.
This, of course, is not a bug of my module, but a bug in the conception of the server thread calls.
For the moment, I just print "DANGER client '$client' asking '$method' to server '$server', already pending : $thread_status" when a thread
is called whereas it's already busy. See "Text::Editor::Easy::Data" for this warning.
Well, in the future, I will handle deadlocks : when circular calls will be noticed, I will give up one of the call made to free other calls. Of course,
the response of the given up call will be "undef" and not correct. But you're supposed to test it and it'll be always better than not to respond
any more to any other requests... Still, this situation should never happened in a good thread organisation (I sometimes had to debug
deadlocks for now, but not really much : I often use asynchronous calls to avoid that).

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;