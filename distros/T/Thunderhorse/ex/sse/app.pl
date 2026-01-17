use v5.40;

package SSEApp;

use Mooish::Base;
use Future::AsyncAwait;

extends 'Thunderhorse::App';

sub build ($self)
{
	$self->load_module('Template');

	my $r = $self->router;

	$r->add(
		'/' => {
			to => 'init_sse',
		}
	);

	$r->add(
		'/stream' => {
			action => 'sse.*',
			to => 'handle_sse',
		}
	);
}

sub init_sse ($self, $ctx)
{
	return $self->template(\*DATA);
}

async sub handle_sse ($self, $ctx)
{
	my $sse = $ctx->sse;

	my $running = true;
	$sse->on_close(sub { $running = false });

	my $counter = 0;
	while ($running) {
		$counter++;
		my $time = localtime;

		await $sse->send_event(
			data => "Message #$counter at $time",
			id => $counter,
		);

		await $self->loop->delay_future(after => 1);
	}
}

SSEApp->new->run;

__DATA__
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Server-Sent Events Demo</title>
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
		.event {
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
		#status {
			padding: 10px;
			margin: 10px 0;
			border-radius: 5px;
		}
		.connected {
			background: #d4edda;
			color: #155724;
		}
		.disconnected {
			background: #f8d7da;
			color: #721c24;
		}
	</style>
</head>
<body>
	<h1>Server-Sent Events: Time Stream</h1>
	<p>Server will push timestamped messages every second.</p>

	<div id="status" class="disconnected">
		Status: <span id="statusText">Disconnected</span>
	</div>

	<div>
		<button id="connect">Connect</button>
		<button id="disconnect" disabled>Disconnect</button>
		<button id="clear">Clear Log</button>
	</div>

	<div id="log"></div>

	<script>
		let eventSource = null;
		const log = document.getElementById('log');
		const connectBtn = document.getElementById('connect');
		const disconnectBtn = document.getElementById('disconnect');
		const clearBtn = document.getElementById('clear');
		const status = document.getElementById('status');
		const statusText = document.getElementById('statusText');

		function addLog(message, className) {
			const div = document.createElement('div');
			div.className = 'message ' + className;
			const timestamp = new Date().toLocaleTimeString();
			div.textContent = `[${timestamp}] ${message}`;
			log.appendChild(div);
			log.scrollTop = log.scrollHeight;
		}

		function setStatus(connected) {
			if (connected) {
				status.className = 'connected';
				statusText.textContent = 'Connected';
			} else {
				status.className = 'disconnected';
				statusText.textContent = 'Disconnected';
			}
		}

		function connect() {
			const url = `${window.location.protocol}//${window.location.host}/stream`;

			addLog(`Connecting to ${url}...`, 'info');
			eventSource = new EventSource(url);

			eventSource.onopen = function() {
				addLog('Connected! Waiting for messages...', 'info');
				setStatus(true);
				connectBtn.disabled = true;
				disconnectBtn.disabled = false;
			};

			eventSource.onmessage = function(event) {
				addLog(`Server says: ${event.data}`, 'event');
				if (event.lastEventId) {
					addLog(`  (Event ID: ${event.lastEventId})`, 'info');
				}
			};

			eventSource.onerror = function(error) {
				addLog('Connection error or closed by server', 'error');
				setStatus(false);
				connectBtn.disabled = false;
				disconnectBtn.disabled = true;
				if (eventSource.readyState === EventSource.CLOSED) {
					eventSource = null;
				}
			};
		}

		function disconnect() {
			if (eventSource) {
				eventSource.close();
				addLog('Disconnected by user', 'info');
				setStatus(false);
				connectBtn.disabled = false;
				disconnectBtn.disabled = true;
				eventSource = null;
			}
		}

		function clearLog() {
			log.innerHTML = '';
		}

		connectBtn.addEventListener('click', connect);
		disconnectBtn.addEventListener('click', disconnect);
		clearBtn.addEventListener('click', clearLog);
	</script>
</body>
</html>

