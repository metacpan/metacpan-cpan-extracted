#use Test::More;
sub plan {
    # sub for compilation OK, replaced in case of trouble (when skipping)
};
use Config;
BEGIN {
    if ( ! $Config{'useithreads'} ) {
        eval "use Test::More;"; # Replacing sub plan but only when perl not compiled with 'useithreads' (eval not done at compile time)
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
    elsif ( ! -f 'tk_is_ok' ) {   
        eval "use Test::More;"; # Replacing sub plan but only when tk is not OK (eval not done at compile time)
        plan skip_all => 'Tk is not working properly on this machine';
    }
}

use strict;
use lib '../lib';
use Text::Editor::Easy;

# This test module simulate the graphic thread (number 0) which is a multiplexed thread (all editor instances
# use it and have data reserved in it). Morevover, as Tk (and surely as most graphic managers) need the thread 0,
# there is a server creation without thread creation (thread graphic is 0 and server but can't be created as long
# as it's the first initial thread) : this explains why we work asynchronously in this test (to avoid deadlock : because
# the client thread is also the server thread)
#
#is ( 'OK', 'OK', 'End');

Text::Editor::Easy->new (
    {
        'sub'      => 'main',    # Sub for action
        'x_offset' => 60,
        'y_offset' => 170,
        'width'    => 200,
        'height'   => 200,
    }
);


sub main {
		my ( $editor_sync ) = @_;
		
        use Test::More qw( no_plan );
        
        print "Full trace thread creation by trace_print indirect call\n";
		my @first_list = threads->list;
		
		my $tid = $editor_sync->create_new_server(
		   {
				'use' => 'Text::Editor::Easy::Test::Test1', 
				'package' => 'Text::Editor::Easy::Test::Test1',
				'methods' => [ 'test1', 'test2', 'test11', 'test12' ], 
				'new' => ['Text::Editor::Easy::Test::Test1::new', 7, 'ut'] ,
				'put_tid' => 1, # Multi-plexed ('put_tid' option useless because no 'name' option)
				'do_not_create' => 1
		    });
		
		my @second_list = threads->list;
		is ( scalar(@second_list), scalar(@first_list), "No thread creation");
		
		use Text::Editor::Easy::Comm;
		
		if ( anything_for_me ) {
				is ( 1, 0, "Something to be done !");
		}
		else {
				is ( 1, 1, "Nothing to be done");
		}
		my $editor = $editor_sync->async; # Appels asynchrones pour ne pas bloquer (le thread client est aussi serveur !)
		
		my @param = ( 3, 'BOF' );
		
		# Contexte de liste souhaité pour la réponse
		my ( $call_id ) = $editor->test1( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "First call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "First call not received !");
		}
		my ( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );
		is ( $thread_tid, $tid, "Thread number, first call" );
		is ( $_3xparam0, 3 * $param[0], "First return value, first call" );
		is ( $TEST1_param1, "TEST1" . $param[1], "Second return value, first call" );
		
		@param = ( 14, 'dslf ds' );
		
		( $call_id ) = $editor->test2( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "Second call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "Second call not received !");
		}

		( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );
		
		is ( $thread_tid, $tid, "Thread number, second call" );
		is ( $_3xparam0, 2 * $param[0], "First return value, second call" );
		is ( $TEST1_param1, "TEST2" . $param[1], "Second return value, second call" );

		@param = ( 142, 'essai' );
		( $call_id ) = $editor->test11( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "Third call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "Third call not received !");
		}
		( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );
		is ( $tid, $thread_tid, "Thread number, third call" );
		is ( $_3xparam0, 3 * $param[0] + 7 + 2, "First return value, third call" );
		is ( $TEST1_param1, "TEST1" . $param[1] . 'utbof', "Second return value, third call" );

		if ( anything_for_me ) {
				is ( 1, 0, "Task to be done !");
		}
		
		@param = ( 1, 'ez' );
		( $call_id ) = $editor->test12( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "Fourth call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "Fourth call not received !");
		}
		( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );
		is ( $tid, $thread_tid, "Thread number, fourth call" );
		is ( $_3xparam0, 2 * $param[0] + 2*(7+2), "First return value, fourth call" );
		is ( $TEST1_param1, "TEST2" . $param[1] . 'teutbof', "Second return value, fourth call" );

		my $editor2_sync = Text::Editor::Easy->new();
		
		@first_list = threads->list;
		
		$editor2_sync->ask_thread('add_thread_object', $tid, {
				'new' => [ 'Text::Editor::Easy::Test::Test1::new', 12, 're' ]
		} );

        @second_list = threads->list;
		is ( scalar(@second_list), scalar(@first_list), "No more thread");

        my $editor2 = $editor2_sync->async;
		if ( anything_for_me ) {
				is ( 1, 0, "Task to be done !");
		}

		@param = ( 3, 'BOF' );
		( $call_id ) = $editor2->test1( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "Fifth call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "Fifth call not received !");
		}
		( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );
		is ( $tid, $thread_tid, "Thread number, fifth call" );
		is ( $_3xparam0, 3 * $param[0], "First return value, fifth call" );
		is ( $TEST1_param1, "TEST1" . $param[1], "Second return value, fifth call" );
		
		@param = ( 14, 'dslf ds' );
		( $call_id ) = $editor2->test2( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "Sixth call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "Sixth call not received !");
		}
		( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );
		is ( $tid, $thread_tid, "Thread number, sixth call" );
		is ( $_3xparam0, 2 * $param[0], "First return value, sixth call" );
		is ( $TEST1_param1, "TEST2" . $param[1], "Second return value, sixth call" );

		@param = ( 142, 'essai' );
		( $call_id ) = $editor2->test11( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "Seventh call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "Seventh call not received !");
		}
		( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );
		is ( $tid, $thread_tid, "Thread number, seventh call" );
		is ( $_3xparam0, 3 * $param[0] + 12 + 2, "First return value, seventh call" );
		is ( $TEST1_param1, "TEST1" . $param[1] . 'rebof', "Second return value, seventh call" );

		@param = ( 1, 'ez' );
		( $call_id ) = $editor2->test12( @param );
		if ( anything_for_me ) {
				is ( 1, 1, "Eighth call received");
				have_task_done;
		}
		else {
				is ( 1, 0, "Eighth call not received !");
		}
		( $thread_tid, $_3xparam0, $TEST1_param1 ) = Text::Editor::Easy->async_response( $call_id );

		is ( $tid, $thread_tid, "Thread number, eighth call" );
		is ( $_3xparam0, 2 * $param[0] + 2*(12+2), "First return value, eighth call" );
		is ( $TEST1_param1, "TEST2" . $param[1] . 'terebof', "Second return value, eighth call" );

		Text::Editor::Easy->exit(0);
}		