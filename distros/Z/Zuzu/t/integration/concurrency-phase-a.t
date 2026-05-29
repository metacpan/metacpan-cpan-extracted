use Test2::V0;

use File::Temp qw( tempdir );
use IO::Socket::INET;
use POSIX qw( mkfifo );
use Time::HiRes qw( sleep time );
use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub run_zuzu {
	my ( $source ) = @_;

	my $ast = $parser->parse( $source, '<concurrency-phase-a>' );
	my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules' ] );
	my $out = '';
	my $ok = eval {
		local *STDOUT;
		open STDOUT, '>:encoding(UTF-8)', \$out
			or die "Could not open scalar stdout: $!";
		$runtime->evaluate($ast);
		$runtime->call('__main__') if $runtime->has_function('__main__');
		1;
	};
	my $err = $@ if !$ok;

	return ( $ok, $out, $err, $runtime );
}

sub zuzu_string {
	my ( $value ) = @_;

	$value =~ s/\\/\\\\/g;
	$value =~ s/"/\\"/g;
	$value =~ s/\n/\\n/g;

	return qq{"$value"};
}

sub start_delayed_http_server {
	my ( $body, $delay ) = @_;

	my $listen = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Proto => 'tcp',
		Listen => 1,
		ReuseAddr => 1,
	) or return ( undef, undef, "Could not start local HTTP listener: $!" );
	my $port = $listen->sockport;
	my $pid = fork();
	if ( !defined $pid ) {
		my $err = "fork failed: $!";
		close $listen;
		return ( undef, undef, $err );
	}
	if ( $pid == 0 ) {
		local $SIG{TERM} = sub { exit 0 };
		my $client = $listen->accept();
		if ($client) {
			while ( my $header = <$client> ) {
				last if $header =~ /^\r?\n\z/;
			}
			sleep($delay);
			print {$client} "HTTP/1.1 200 OK\r\n";
			print {$client} "Content-Type: text/plain\r\n";
			print {$client} "Content-Length: " . length($body) . "\r\n";
			print {$client} "Connection: close\r\n\r\n";
			print {$client} $body;
			close $client;
		}
		POSIX::_exit(0);
	}
	close $listen;

	return ( $port, $pid, undef );
}

my ( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import resolved, all, race, Channel, sleep, timeout;

async function answer () {
	let base := await {
		resolved(40);
	};
	return base + 2;
}

class Box {
	async method value () {
		return await {
			resolved(42);
		};
	}
}

async function __main__ () {
	let first := await {
		answer();
	};
	print first;
	print "\n";

	let spawned := spawn {
		let value := await {
			resolved(21);
		};
		value * 2;
	};
	print await {
		spawned;
	};
	print "\n";

	let box := new Box();
	print await {
		box.value();
	};
	print "\n";

	let both := await {
		all( [ answer(), resolved(7) ] );
	};
	print both[0];
	print ":";
	print both[1];
	print "\n";

	print await {
		race( [ resolved("fast"), answer() ] );
	};
	print "\n";

	let ch := new Channel();
	await {
		ch.send("ready");
	};
	print await {
		ch.recv();
	};
	print "\n";

	let later := new Channel();
	let pending := later.recv();
	await {
		later.send("later");
	};
	print await {
		pending;
	};
	print "\n";

	try {
		await {
			timeout( 0.05, later.recv() );
		};
		print "no-timeout";
	}
	catch ( Exception e ) {
		print "timeout";
	}
	print "\n";

	let cancel_me := sleep(5);
	print cancel_me.status();
	print ":";
	cancel_me.cancel();
	print cancel_me.status();
	print ":";
	print cancel_me.is_done();
	print ":";
	print cancel_me.done();
	print "\n";

	try {
		await {
			cancel_me;
		};
		print "no-cancel";
	}
	catch ( CancelledException e ) {
		print "cancelled-type";
	}
	print "\n";

	let closed := new Channel();
	closed.close();
	try {
		await {
			closed.send("x");
		};
		print "no-closed";
	}
	catch ( ChannelClosedException e ) {
		print "closed-type";
	}
	print "\n";

	try {
		await {
			timeout( 0.01, new Channel().recv() );
		};
		print "no-timeout-type";
	}
	catch ( TimeoutException e ) {
		print "timeout-type";
	}
	print "\n";
}
ZZS

ok $ok, 'async __main__ ran successfully' or diag $err;
is $out, "42\n42\n42\n42:7\nfast\nready\nlater\ntimeout\nsleeping:cancelled:1:1\ncancelled-type\nclosed-type\ntimeout-type\n",
	'await/spawn blocks and std/task helpers work';

my $start = time;
( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import all, sleep;

async function __main__ () {
	let left := spawn {
		await {
			sleep(0.35);
		};
		"left";
	};
	let right := spawn {
		await {
			sleep(0.35);
		};
		"right";
	};
	let got := await {
		all( [ left, right ] );
	};
	print got[0];
	print ":";
	print got[1];
	print "\n";
}
ZZS
my $elapsed = time - $start;

ok $ok, 'spawned sleep tasks ran successfully' or diag $err;
is $out, "left:right\n", 'spawned task results preserve all() order';
ok $elapsed < 0.65, 'spawned sleeps overlap instead of running serially';

$start = time;
( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import all, sleep;

async function __main__ () {
	let left := sleep(0.35);
	let right := sleep(0.35);
	let got := await {
		all( [ left, right ] );
	};
	print got.length();
	print "\n";
}
ZZS
$elapsed = time - $start;

ok $ok, 'same-process sleep tasks ran successfully' or diag $err;
is $out, "2\n", 'all() returns both timer results';
ok $elapsed < 0.65, 'std/task sleep timers overlap without spawn';

$start = time;
( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import all, sleep;

async function after ( label, seconds ) {
	await {
		sleep(seconds);
	};
	return label;
}

async function __main__ () {
	let got := await {
		all( [ after( "left", 0.35 ), after( "right", 0.35 ) ] );
	};
	print got[0];
	print ":";
	print got[1];
	print "\n";
}
ZZS
$elapsed = time - $start;

ok $ok, 'same-process async tasks ran successfully' or diag $err;
is $out, "left:right\n", 'same-process async all() preserves order';
ok $elapsed < 0.65, 'same-process async tasks overlap at await points';

$start = time;
( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/proc import Proc;
from std/task import all;

async function __main__ () {
	let got := await {
		all( [
			Proc.run_async(
				"perl",
				[ "-e", "select undef, undef, undef, 0.35;" ],
			),
			Proc.run_async(
				"perl",
				[ "-e", "select undef, undef, undef, 0.35;" ],
			),
		] );
	};
	print got[0]{ok};
	print ":";
	print got[1]{ok};
	print "\n";
}
ZZS
$elapsed = time - $start;

ok $ok, 'async process tasks ran successfully' or diag $err;
is $out, "1:1\n", 'process async all() preserves result order';
ok $elapsed < 0.65, 'process async tasks overlap instead of running serially';

my $io_tmpdir = tempdir( CLEANUP => 1 );
my $fifo_left = "$io_tmpdir/left.fifo";
my $fifo_right = "$io_tmpdir/right.fifo";
mkfifo( $fifo_left, 0600 ) or die "mkfifo $fifo_left failed: $!";
mkfifo( $fifo_right, 0600 ) or die "mkfifo $fifo_right failed: $!";
my @fifo_writers;
for my $pair ( [ $fifo_left, "left" ], [ $fifo_right, "right" ] ) {
	my ( $fifo, $text ) = @$pair;
	my $pid = fork();
	defined $pid or die "fork failed: $!";
	if ( $pid == 0 ) {
		sleep(0.35);
		open my $fh, '>:encoding(UTF-8)', $fifo
			or die "open $fifo failed: $!";
		print {$fh} $text;
		close $fh;
		POSIX::_exit(0);
	}
	push @fifo_writers, $pid;
}

my $fifo_left_lit = zuzu_string($fifo_left);
my $fifo_right_lit = zuzu_string($fifo_right);
$start = time;
( $ok, $out, $err ) = run_zuzu( <<"ZZS" );
from std/io import Path;
from std/task import all;

async function __main__ () {
	let left := new Path($fifo_left_lit).slurp_utf8_async();
	let right := new Path($fifo_right_lit).slurp_utf8_async();
	let got := await {
		all( [ left, right ] );
	};
	print got[0];
	print ":";
	print got[1];
	print "\\n";
}
ZZS
$elapsed = time - $start;
waitpid( $_, 0 ) for @fifo_writers;

ok $ok, 'async file tasks ran successfully' or diag $err;
is $out, "left:right\n", 'file async all() preserves read order';
ok $elapsed < 0.65, 'file async tasks overlap while waiting for host I/O';

my ( $http_left_port, $http_left_pid, $http_left_error ) = start_delayed_http_server(
	"left",
	0.35,
);
my ( $http_right_port, $http_right_pid, $http_right_error ) = start_delayed_http_server(
	"right",
	0.35,
);
if ( defined $http_left_error or defined $http_right_error ) {
	if ( defined $http_left_pid ) {
		kill 'TERM', $http_left_pid;
		waitpid( $http_left_pid, 0 );
	}
	if ( defined $http_right_pid ) {
		kill 'TERM', $http_right_pid;
		waitpid( $http_right_pid, 0 );
	}
	my $skip_reason = "loopback HTTP listener unavailable: "
		. ( $http_left_error // $http_right_error );
	pass "async HTTP tasks skipped ($skip_reason)";
	pass "HTTP async response order skipped ($skip_reason)";
	pass "HTTP async overlap skipped ($skip_reason)";
}
else {
	$start = time;
	( $ok, $out, $err ) = run_zuzu( <<"ZZS" );
from std/net/http import UserAgent;
from std/task import all;

async function __main__ () {
	let ua := new UserAgent(timeout: 2);
	let got := await {
		all( [
			ua.get_async("http://127.0.0.1:$http_left_port/"),
			ua.get_async("http://127.0.0.1:$http_right_port/"),
		] );
	};
	print got[0].content();
	print ":";
	print got[1].content();
	print "\\n";
}
ZZS
	$elapsed = time - $start;
	waitpid( $http_left_pid, 0 );
	waitpid( $http_right_pid, 0 );

	ok $ok, 'async HTTP tasks ran successfully' or diag $err;
	is $out, "left:right\n", 'HTTP async all() preserves response order';
	ok $elapsed < 0.65, 'HTTP async tasks overlap instead of running serially';
}

$start = time;
( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import all, race, sleep, timeout;

async function __main__ () {
	let group := all( [ sleep(0.05), sleep(0.05) ] );
	let won := await {
		race( [ sleep(0.30), group ] );
	};
	print won.length();
	print ":";
	try {
		await {
			timeout( 0.05, all( [ sleep(0.30), sleep(0.30) ] ) );
		};
		print "no-timeout";
	}
	catch ( Exception e ) {
		print "timeout";
	}
	print "\n";
}
ZZS
$elapsed = time - $start;

ok $ok, 'nested combinator tasks ran successfully' or diag $err;
is $out, "2:timeout\n",
	'all() is pollable inside race() and timeout()';
ok $elapsed < 0.25,
	'timeout can cancel nested all() without waiting for child sleeps';

$start = time;
( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import race, sleep;

async function __main__ () {
	let marker := "alive";
	let slow := spawn {
		await {
			sleep(0.40);
		};
		marker := "slow-finished";
		"slow";
	};
	let fast := spawn {
		await {
			sleep(0.10);
		};
		"fast";
	};
	print await {
		race( [ slow, fast ] );
	};
	await {
		sleep(0.20);
	};
	print ":";
	print marker;
	print "\n";
}
ZZS
$elapsed = time - $start;

ok $ok, 'race over spawned sleeps ran successfully' or diag $err;
is $out, "fast:alive\n",
	'race returns first completed task and cancels the loser';
ok $elapsed < 0.38, 'race returns before slower task completes';

( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import all, sleep, resolved;

async function while_control () {
	let i := 0;
	let total := 0;
	while ( i < 5 ) {
		i := i + 1;
		await {
			sleep(0.01);
		};
		if ( i = 2 ) {
			next;
		}
		if ( i = 5 ) {
			last;
		}
		total := total + i;
	}
	return total;
}

async function for_control () {
	let total := 0;
	for ( let n in [ 1, 2, 3, 4 ] ) {
		await {
			sleep(0.01);
		};
		if ( n = 2 ) {
			next;
		}
		total := total + n;
		if ( n = 3 ) {
			last;
		}
	}
	return total;
}

async function catch_control () {
	try {
		await {
			sleep(0.01);
		};
		throw new Exception( message: "caught-ok" );
	}
	catch ( Exception e ) {
		return e.to_String();
	}
}

class AsyncBox {
	async method value () {
		await {
			sleep(0.01);
		};
		return 9;
	}
}

async function nested_spawn () {
	let outer := spawn {
		let inner := spawn {
			await {
				sleep(0.01);
			};
			"inner";
		};
		await {
			inner;
		} _ "-outer";
	};
	return await {
		outer;
	};
}

async function __main__ () {
	let inc := async fn x -> await { resolved(x + 1); };
	let box := new AsyncBox();
	let got := await {
		all( [
			while_control(),
			for_control(),
			catch_control(),
			inc(4),
			box.value(),
			nested_spawn(),
		] );
	};
	print got[0];
	print ":";
	print got[1];
	print ":";
	print got[2];
	print ":";
	print got[3];
	print ":";
	print got[4];
	print ":";
	print got[5];
	print "\n";
}
ZZS

ok $ok, 'control flow across await ran successfully' or diag $err;
is $out, "8:4:Exception: caught-ok:5:9:inner-outer\n",
	'await preserves loops, catch, lambdas, methods, and nested spawn';

( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/defer import Guard;
from std/task import all, failed, race, sleep;

let cleanup_log := "";

async function doubled ( n ) {
	await {
		sleep(0.01);
	};
	return n * 2;
}

async function even ( n ) {
	await {
		sleep(0.01);
	};
	return n mod 2 = 0;
}

async function add_after_wait ( left, right ) {
	await {
		sleep(0.01);
	};
	return left + right;
}

async function switch_wait ( n ) {
	let picked := "";
	switch ( n ) {
		case 1: {
			await {
				sleep(0.01);
			};
			picked := "one";
		}
		default: {
			await {
				sleep(0.01);
			};
			picked := "other";
		}
	}
	return picked;
}

async function cleanup_after_await () {
	{
		let guard := new Guard(
			callback: function () {
				cleanup_log := cleanup_log _ "clean";
			},
		);
		await {
			sleep(0.01);
		};
		cleanup_log := cleanup_log _ "body-";
	}
}

async function __main__ () {
	let mapped := [ 1, 2, 3 ].map(doubled);
	let filtered := [ 1, 2, 3, 4 ].grep(even);
	let total := [ 1, 2, 3 ].reduce(add_after_wait);
	let switched := await {
		switch_wait(1);
	};
	await {
		cleanup_after_await();
	};

	print mapped[0];
	print ":";
	print mapped[1];
	print ":";
	print mapped[2];
	print ":";
	print filtered[0];
	print ":";
	print filtered[1];
	print ":";
	print total;
	print ":";
	print switched;
	print ":";
	print cleanup_log;
	print ":";

	try {
		await {
			all( [
				sleep(0.10),
				race( [ sleep(0.10), failed("nested-boom") ] ),
			] );
		};
		print "no-error";
	}
	catch ( Exception e ) {
		print e.to_String();
	}
	print "\n";
}
ZZS

ok $ok, 'await works in switch, cleanup, and collection callbacks'
	or diag $err;
is $out, "2:4:6:2:4:6:one:body-clean:Exception: nested-boom\n",
	'phase A async control-surface regressions are covered';

( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import sleep;

async function __main__ () {
	let marker := "before";
	spawn {
		throw new Exception( message: "background failure" );
	};
	spawn {
		await {
			sleep(0.02);
		};
		marker := "after";
	};
	print marker;
	await {
		sleep(0.05);
	};
	print ":";
	print marker;
	print "\n";
}
ZZS

ok $ok, 'spawned tasks are detached until observed' or diag $err;
is $out, "before:after\n",
	'spawn follows JavaScript-style independent promise execution';

( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/task import sleep, Channel, CancellationSource;

async function __main__ () {
	let source := new CancellationSource();
	let token := source.token();
	let watched := sleep(1);
	token.watch(watched);
	source.cancel("token reason");
	try {
		token.throw_if_cancelled();
		print "no-token";
	}
	catch ( CancelledException e ) {
		print e.to_String();
	}
	print ":";
	try {
		await {
			watched;
		};
		print "no-watch";
	}
	catch ( CancelledException e ) {
		print e.to_String();
	}
	print ":";

	let task := sleep(1);
	task.cancel("custom reason");
	try {
		await {
			task;
		};
		print "no-cancel";
	}
	catch ( CancelledException e ) {
		print e.to_String();
	}
	print ":";
	let ch := new Channel();
	ch.close();
	let received := await {
		ch.recv();
	};
	if ( received = null ) {
		print "closed-null";
	}
	else {
		print "closed-value";
	}
	print "\n";
}
ZZS

ok $ok, 'cancellation tokens, reasons, and closed receive semantics ran successfully'
	or diag $err;
is $out,
	"CancelledException: token reason:CancelledException: token reason:"
		. "CancelledException: custom reason:closed-null\n",
	'cancellation tokens cancel watched tasks and closed recv resolves null';

( $ok, $out, $err ) = run_zuzu( <<'ZZS' );
from std/defer import Guard;
from std/task import sleep;

let cleanup_log := "";

async function cleanup_worker () {
	{
		let guard := new Guard(
			callback: function () {
				cleanup_log := cleanup_log _ "clean";
			},
		);
		await {
			sleep(1);
		};
		cleanup_log := cleanup_log _ "late";
	}
}

async function __main__ () {
	let task := spawn {
		await {
			cleanup_worker();
		};
	};
	await {
		sleep(0.02);
	};
	task.cancel("stop");
	try {
		await {
			task;
		};
	}
	catch ( CancelledException e ) {
		print e.to_String();
	}
	await {
		sleep(0.02);
	};
	print ":";
	print cleanup_log;
	print "\n";
}
ZZS

ok $ok, 'cancellation cleanup script ran successfully' or diag $err;
is $out, "CancelledException: stop:clean\n",
	'cancellation unwinds task cleanup without running later code';

{
	local $Zuzu::Runtime::DEBUG_LEVEL = 1;
	my ( $trace_ok, $trace_out, $trace_err, $trace_runtime ) =
		run_zuzu( <<'ZZS' );
from std/task import sleep;

async function __main__ () {
	let child := spawn {
		await {
			sleep(0.01);
		};
		"child";
	};
	print await {
		child;
	};
	print "\n";
}
ZZS

	ok $trace_ok, 'debug trace script ran successfully'
		or diag $trace_err;
	is $trace_out, "child\n", 'debug trace does not affect output';
	my $events = $trace_runtime->{_scheduler}->trace_events;
	ok scalar(@$events) > 0, 'debug mode records task lifecycle events';
	ok(
		grep( { $_->{event} eq 'schedule' } @$events ),
		'debug trace includes schedule events',
	);
	ok(
		grep( { $_->{event} eq 'start' } @$events ),
		'debug trace includes start events',
	);
	ok(
		grep( { $_->{event} eq 'fulfill' } @$events ),
		'debug trace includes fulfillment events',
	);
	ok(
		grep( {
			( $_->{event} eq 'schedule' )
				and ( $_->{name} // '' ) eq '<spawn>'
				and defined $_->{task_id}
				and defined $_->{parent_task_id}
				and defined $_->{file}
				and defined $_->{line}
		} @$events ),
		'debug trace records task IDs, parent task IDs, and creation location',
	);
}

{
	local $Zuzu::Runtime::DEBUG_LEVEL = 1;
	my ( $blocked_ok, $blocked_out, $blocked_err, $blocked_runtime ) =
		run_zuzu( <<'ZZS' );
from std/io import Path;
from std/net/http import UserAgent;
from std/proc import Proc;

async function __main__ () {
	let file := Path.tempfile();
	file.spew_utf8("sync write");
	print file.slurp_utf8();
	print "\n";
	Proc.run( "perl", [ "-e", "exit 0" ] );
	let ua := new UserAgent(timeout: 1);
	ua.get( "http://127.0.0.1:1/" );
}
ZZS

	ok $blocked_ok, 'blocked-operation diagnostic script ran successfully'
		or diag $blocked_err;
	is $blocked_out, "sync write\n",
		'blocked-operation diagnostics do not change script output';
	my $events = $blocked_runtime->{_scheduler}->trace_events;
	ok(
		grep( {
			( $_->{event} eq 'blocked_operation' )
				and ( $_->{operation} // '' ) eq 'std/io Path.spew_utf8'
				and defined $_->{file}
				and defined $_->{line}
		} @$events ),
		'debug trace records blocking synchronous file writes in async tasks',
	);
	ok(
		grep( {
			( $_->{event} eq 'blocked_operation' )
				and ( $_->{operation} // '' ) eq 'std/io Path.slurp_utf8'
		} @$events ),
		'debug trace records blocking synchronous file reads in async tasks',
	);
	ok(
		grep( {
			( $_->{event} eq 'blocked_operation' )
				and ( $_->{operation} // '' ) eq 'std/proc Proc.run'
		} @$events ),
		'debug trace records blocking synchronous process calls in async tasks',
	);
	ok(
		grep( {
			( $_->{event} eq 'blocked_operation' )
				and ( $_->{operation} // '' ) eq 'std/net/http UserAgent.send'
		} @$events ),
		'debug trace records blocking synchronous HTTP calls in async tasks',
	);
}

my ( $cleanup_ok, $cleanup_out, $cleanup_err, $cleanup_runtime ) =
	run_zuzu( <<'ZZS' );
from std/task import all, race, sleep;

async function __main__ () {
	let one := spawn {
		await {
			sleep(0.01);
		};
		"one";
	};
	let two := spawn {
		await {
			sleep(0.01);
		};
		"two";
	};
	await {
		all( [ one, two ] );
	};
	await {
		race( [ sleep(0.01), sleep(0.02) ] );
	};
	print "done\n";
}
ZZS

ok $cleanup_ok, 'scheduler cleanup script ran successfully'
	or diag $cleanup_err;
is $cleanup_out, "done\n", 'cleanup script output is stable';
is $cleanup_runtime->{_scheduler}->active_count, 0,
	'scheduler removes completed tasks';
is scalar keys %{ $cleanup_runtime->{_scheduler}->root_group->tasks }, 0,
	'root task group removes completed tasks';

my ( $shutdown_ok, $shutdown_out, $shutdown_err, $shutdown_runtime ) =
	run_zuzu( <<'ZZS' );
from std/task import sleep;

async function __main__ () {
	spawn {
		await {
			sleep(5);
		};
		"late";
	};
	print "returned\n";
}
ZZS

ok $shutdown_ok, 'background task script ran successfully'
	or diag $shutdown_err;
is $shutdown_out, "returned\n", 'background task script output is stable';
ok $shutdown_runtime->{_scheduler}->active_count > 0,
	'scheduler tracks unawaited background task';
$shutdown_runtime->{_scheduler}->shutdown;
is $shutdown_runtime->{_scheduler}->active_count, 0,
	'scheduler shutdown cancels unawaited background tasks';

my $top_level = eval {
	$parser->parse(
		'from std/task import resolved; let x := await { resolved(1); };',
		'<top-await>',
	);
	1;
};
ok $top_level, 'top-level await is accepted';

my $static_async_warning = '';
my $static_async = eval {
	local $SIG{__WARN__} = sub {
		$static_async_warning .= join '', @_;
	};
	$parser->parse(
		'class C { static async method value () { return 1; } }',
		'<static-async>',
	);
	1;
};
ok $static_async, 'Perl parser accepts static async method spelling';
like $static_async_warning, qr/static async method is deprecated; use async static method/,
	'Perl parser warns for static async method spelling';

my $async_static_warning = '';
my $async_static = eval {
	local $SIG{__WARN__} = sub {
		$async_static_warning .= join '', @_;
	};
	$parser->parse(
		'class C { async static method value () { return 1; } }',
		'<async-static>',
	);
	1;
};
ok $async_static, 'Perl parser accepts canonical async static method spelling';
is $async_static_warning, '',
	'Perl parser does not warn for canonical async static method spelling';

my $bad = eval {
	$parser->parse(
		'function bad () { let x := await { 1; }; }',
		'<bad-await>',
	);
	1;
};
ok !$bad, 'await inside non-async function is rejected';
like "$@", qr/await may only be used inside async code/,
	'await rejection explains async context requirement';

done_testing;
