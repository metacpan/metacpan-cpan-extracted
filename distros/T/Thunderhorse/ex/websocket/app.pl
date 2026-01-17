use v5.40;

package WebsocketApp;

use Mooish::Base;
use Future::AsyncAwait;

extends 'Thunderhorse::App';

sub build ($self)
{
	$self->load_module('Template');

	my $r = $self->router;

	$r->add(
		'/' => {
			to => 'init_ws',
		}
	);

	$r->add(
		'/ws' => {
			action => 'websocket',
			to => 'handle_ws',
		}
	);
}

sub init_ws ($self, $ctx)
{
	return $self->template(\*DATA);
}

async sub handle_ws ($self, $ctx)
{
	my $ws = $ctx->ws;

	await $ws->accept;
	await $ws->each_text(
		async sub ($text) {
			await $ws->send_text("Echo: $text");
		}
	);
}

WebsocketApp->new->run;

__DATA__
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>WebSocket Ping/Pong</title>
	<style>
		body {
			font-family: monospace;
			max-width: 800px;
			margin: 50px auto;
			padding: 20px;
		}
		#log {
			border: 1px solid #ccc;
			height: 400px;
			overflow-y: auto;
			padding: 10px;
			background: #f5f5f5;
			margin: 20px 0;
		}
		.message {
			margin: 5px 0;
			padding: 5px;
		}
		.sent {
			color: #0066cc;
		}
		.received {
			color: #009900;
		}
		.error {
			color: #cc0000;
		}
		.info {
			color: #666;
		}
		button {
			padding: 10px 20px;
			margin: 5px;
			font-size: 14px;
		}
	</style>
</head>
<body>
	<h1>WebSocket Ping/Pong Test</h1>

	<div>
		<button id="connect">Connect</button>
		<button id="disconnect" disabled>Disconnect</button>
		<button id="ping" disabled>Send Ping</button>
	</div>

	<div id="log"></div>

	<script>
		let ws = null;
		const log = document.getElementById('log');
		const connectBtn = document.getElementById('connect');
		const disconnectBtn = document.getElementById('disconnect');
		const pingBtn = document.getElementById('ping');

		function addLog(message, className) {
			const div = document.createElement('div');
			div.className = 'message ' + className;
			const timestamp = new Date().toLocaleTimeString();
			div.textContent = `[${timestamp}] ${message}`;
			log.appendChild(div);
			log.scrollTop = log.scrollHeight;
		}

		function connect() {
			const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
			const wsUrl = `${protocol}//${window.location.host}/ws`;

			addLog(`Connecting to ${wsUrl}...`, 'info');
			ws = new WebSocket(wsUrl);

			ws.onopen = function() {
				addLog('Connected!', 'info');
				connectBtn.disabled = true;
				disconnectBtn.disabled = false;
				pingBtn.disabled = false;
			};

			ws.onmessage = function(event) {
				addLog(`Received: ${event.data}`, 'received');
			};

			ws.onerror = function(error) {
				addLog('WebSocket error occurred', 'error');
			};

			ws.onclose = function() {
				addLog('Disconnected', 'info');
				connectBtn.disabled = false;
				disconnectBtn.disabled = true;
				pingBtn.disabled = true;
				ws = null;
			};
		}

		function disconnect() {
			if (ws) {
				ws.close();
			}
		}

		function sendPing() {
			if (ws && ws.readyState === WebSocket.OPEN) {
				const message = 'ping';
				ws.send(message);
				addLog(`Sent: ${message}`, 'sent');
			} else {
				addLog('WebSocket is not connected', 'error');
			}
		}

		connectBtn.addEventListener('click', connect);
		disconnectBtn.addEventListener('click', disconnect);
		pingBtn.addEventListener('click', sendPing);
	</script>
</body>
</html>

