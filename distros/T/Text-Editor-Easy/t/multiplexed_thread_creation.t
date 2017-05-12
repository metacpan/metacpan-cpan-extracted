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
        'width'    => 200,
        'height'   => 200,
    }
);
		
		print "Full trace thread creation by trace_print indirect call\n";
my @first_list = threads->list;

my $tid = $editor->create_new_server(
   {
		'use' => 'Text::Editor::Easy::Test::Test1', 
		'package' => 'Text::Editor::Easy::Test::Test1',
		'methods' => [ 'test1', 'test2', 'test11', 'test12' ], 
		'new' => ['Text::Editor::Easy::Test::Test1::new', 7, 'ut'] ,
		'put_tid' => 1, # Multi-plexed
	});

my @second_list = threads->list;
is ( scalar(@second_list), scalar(@first_list) + 1, "One more thread");

my @param = ( 3, 'BOF' );
my ( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor->test1( @param );
is ( $tid, $thread_tid, "Thread number, first call" );
is ( $_3xparam0, 3 * $param[0], "First return value, first call" );
is ( $TEST1_param1, "TEST1" . $param[1], "Second return value, first call" );

@param = ( 14, 'dslf ds' );
( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor->test2( @param );
is ( $tid, $thread_tid, "Thread number, second call" );
is ( $_3xparam0, 2 * $param[0], "First return value, second call" );
is ( $TEST1_param1, "TEST2" . $param[1], "Second return value, second call" );

@param = ( 142, 'essai' );
( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor->test11( @param );
is ( $tid, $thread_tid, "Thread number, third call" );
is ( $_3xparam0, 3 * $param[0] + 7 + 2, "First return value, third call" );
is ( $TEST1_param1, "TEST1" . $param[1] . 'utbof', "Second return value, third call" );

@param = ( 1, 'ez' );
( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor->test12( @param );
is ( $tid, $thread_tid, "Thread number, fourth call" );
is ( $_3xparam0, 2 * $param[0] + 2*(7+2), "First return value, fourth call" );
is ( $TEST1_param1, "TEST2" . $param[1] . 'teutbof', "Second return value, fourth call" );

my $editor2 = Text::Editor::Easy->new();

@first_list = threads->list;

$editor2->ask_thread('add_thread_object', $tid, {
		'new' => [ 'Text::Editor::Easy::Test::Test1::new', 12, 're' ]
} );

@second_list = threads->list;
is ( scalar(@second_list), scalar(@first_list), "No more thread");

@param = ( 3, 'BOF' );
( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor2->test1( @param );
is ( $tid, $thread_tid, "Thread number, fifth call" );
is ( $_3xparam0, 3 * $param[0], "First return value, fifth call" );
is ( $TEST1_param1, "TEST1" . $param[1], "Second return value, fifth call" );

@param = ( 14, 'dslf ds' );
( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor2->test2( @param );
is ( $tid, $thread_tid, "Thread number, sixth call" );
is ( $_3xparam0, 2 * $param[0], "First return value, sixth call" );
is ( $TEST1_param1, "TEST2" . $param[1], "Second return value, sixth call" );

@param = ( 142, 'essai' );
( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor2->test11( @param );
is ( $tid, $thread_tid, "Thread number, seventh call" );
is ( $_3xparam0, 3 * $param[0] + 12 + 2, "First return value, seventh call" );
is ( $TEST1_param1, "TEST1" . $param[1] . 'rebof', "Second return value, seventh call" );

@param = ( 1, 'ez' );
( $thread_tid, $_3xparam0, $TEST1_param1 ) = $editor2->test12( @param );
is ( $tid, $thread_tid, "Thread number, eighth call" );
is ( $_3xparam0, 2 * $param[0] + 2*(12+2), "First return value, eighth call" );
is ( $TEST1_param1, "TEST2" . $param[1] . 'terebof', "Second return value, eighth call" );

