use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;

use Future::AsyncAwait;

################################################################################
# This tests whether Thunderhorse SSE works
################################################################################

package SSETestApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		$router->add(
			'/simple' => {
				action => 'sse',
				to => 'simple',
			}
		);

		$router->add(
			'/json' => {
				action => 'sse',
				to => 'json_stream',
			}
		);

		$router->add(
			'/counter' => {
				action => 'sse',
				to => 'counter',
			}
		);

		$router->add(
			'/close' => {
				action => 'sse',
				to => 'close_test',
			}
		);
	}

	async sub simple ($self, $ctx)
	{
		my $sse = $ctx->sse;

		await $sse->send("hello");
		await $sse->send("world");
	}

	async sub json_stream ($self, $ctx)
	{
		my $sse = $ctx->sse;

		await $sse->send_json({message => 'first', count => 1});
		await $sse->send_json({message => 'second', count => 2});
	}

	async sub counter ($self, $ctx)
	{
		my $sse = $ctx->sse;

		for my $i (1 .. 3) {
			await $sse->send_event(
				data => "Message $i",
				event => 'counter',
				id => $i,
			);
		}
	}

	async sub close_test ($self, $ctx)
	{
		my $sse = $ctx->sse;

		my $closed = false;
		$sse->on_close(sub { $closed = true });

		await $sse->send("start");

		# Wait for close from test side
		while (!$closed) {
			await $self->loop->delay_future(after => 0.1);
		}
	}
};

my $app = SSETestApp->new;

subtest 'should handle client disconnect' => sub {
	sse $app, '/close';

	is sse->receive_event->{data}, 'start', 'start message ok';

	sse->close;
	ok sse->is_closed, 'closed ok';
};

subtest 'should send simple text events' => sub {
	sse $app, '/simple';

	is sse->receive_event->{data}, 'hello', 'first message ok';
	is sse->receive_event->{data}, 'world', 'second message ok';
};

subtest 'should send json events' => sub {
	sse $app, '/json';

	is sse->receive_json, {message => 'first', count => 1}, 'first json ok';
	is sse->receive_json, {message => 'second', count => 2}, 'second json ok';
};

subtest 'should send events with metadata' => sub {
	sse $app, '/counter';

	my $event1 = sse->receive_event;
	is $event1->{data}, 'Message 1', 'first message data';
	is $event1->{event}, 'counter', 'first message event type';
	is $event1->{id}, 1, 'first message id';

	my $event2 = sse->receive_event;
	is $event2->{data}, 'Message 2', 'second message data';
	is $event2->{id}, 2, 'second message id';

	my $event3 = sse->receive_event;
	is $event3->{data}, 'Message 3', 'third message data';
	is $event3->{id}, 3, 'third message id';
};

done_testing;

