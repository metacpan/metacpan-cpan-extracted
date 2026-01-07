use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;

use Future::AsyncAwait;

################################################################################
# This tests whether Thunderhorse websockets work
################################################################################

package WebSocketApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		$router->add(
			'/echo' => {
				action => 'websocket',
				to => 'echo',
			}
		);

		$router->add(
			'/json' => {
				action => 'websocket',
				to => 'json_echo',
			}
		);

		$router->add(
			'/close' => {
				action => 'websocket',
				to => 'close_test',
			}
		);
	}

	async sub echo ($self, $ctx)
	{
		my $ws = $ctx->ws;
		await $ws->accept;

		await $ws->each_text(
			async sub ($text) {
				await $ws->send_text("echo: $text");
			}
		);
	}

	async sub json_echo ($self, $ctx)
	{
		my $ws = $ctx->ws;
		await $ws->accept;

		await $ws->each_json(
			async sub ($data) {
				$data->{echoed} = 1;
				await $ws->send_json($data);
			}
		);
	}

	async sub close_test ($self, $ctx)
	{
		my $ws = $ctx->ws;
		await $ws->accept;

		my $msg = await $ws->receive_text;
		await $ws->close(1000, 'goodbye');
	}
};

my $app = WebSocketApp->new;

subtest 'should echo text messages' => sub {
	websocket $app, '/echo';

	websocket->send_text('hello');
	is websocket->receive_text, 'echo: hello', 'text response ok';

	websocket->send_text('świecie');
	is websocket->receive_text, 'echo: świecie', 'text response unicode ok';

	websocket->close;
	ok websocket->is_closed, 'closed ok';
};

subtest 'should echo json messages' => sub {
	websocket $app, '/json';

	websocket->send_json({action => 'test', value => 42});
	is websocket->receive_json, {action => 'test', value => 42, echoed => 1}, 'json response ok';
};

subtest 'should handle server initiated close' => sub {
	websocket $app, '/close';

	websocket->send_text('trigger close');
	ok websocket->is_closed, 'auto-closed ok';
};

done_testing;

