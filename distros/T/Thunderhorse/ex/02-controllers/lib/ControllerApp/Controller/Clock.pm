package ControllerApp::Controller::Clock;

use v5.40;
use Mooish::Base -standard;

extends 'Thunderhorse::Controller';

sub build ($self)
{
	my $r = $self->router;

	$r->add(
		'/clock' => {
			to => 'show_clock',
		}
	);
}

sub show_clock ($self, $ctx)
{
	return $self->render(\*DATA);
}

__DATA__
<!DOCTYPE html>
<html>
<head>
	<title>Digital Clock</title>
	<style>
		body {
			margin: 0;
			padding: 0;
			display: flex;
			justify-content: center;
			align-items: center;
			height: 100vh;
			background-color: #000;
			font-family: 'Courier New', monospace;
		}
		#clock {
			font-size: 80px;
			color: #0f0;
			text-shadow: 0 0 20px #0f0;
		}
	</style>
</head>
<body>
	<div id="clock"></div>
	<script>
		function updateClock() {
			const now = new Date();
			const hours = String(now.getHours()).padStart(2, '0');
			const minutes = String(now.getMinutes()).padStart(2, '0');
			const seconds = String(now.getSeconds()).padStart(2, '0');
			document.getElementById('clock').textContent = hours + ':' + minutes + ':' + seconds;
		}
		updateClock();
		setInterval(updateClock, 1000);
	</script>
</body>
</html>

