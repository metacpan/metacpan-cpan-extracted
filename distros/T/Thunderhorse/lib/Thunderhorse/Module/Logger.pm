package Thunderhorse::Module::Logger;
$Thunderhorse::Module::Logger::VERSION = '0.102';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;
use Gears::Logger::Handler;

use Future::AsyncAwait;

extends 'Thunderhorse::Module';

has field 'logger' => (
	isa => InstanceOf ['Gears::Logger'],
	lazy => 1,
);

sub _build_logger ($self)
{
	my $config = $self->config;

	return Gears::Logger::Handler->new($config->%*);
}

sub build ($self)
{
	weaken $self;
	my $logger = $self->logger;

	$self->add_method(
		controller => log => sub ($controller, $level, @messages) {
			$logger->message($level, @messages);
			return $controller;
		}
	);

	$self->add_hook(
		error => sub ($controller, $ctx, $error) {
			$logger->message(error => $error);
		}
	);
}

__END__

=head1 NAME

Thunderhorse::Module::Logger - Logger module for Thunderhorse

=head1 SYNOPSIS

	# in application build method
	$self->load_module('Logger' => {
		outputs => [
			screen => {
				'utf-8' => true,
			},
		],
	});

	# in controller method
	sub some_action ($self, $ctx)
	{
		$self->log(info => 'Processing request');
		$self->log(error => 'Something went wrong');

		return "Done";
	}

=head1 DESCRIPTION

The Logger module adds logging capabilities to the application. It wraps the
entire application to catch and log errors, and adds a C<log> method to
controllers.

=head1 CONFIGURATION

Configuration is passed to C<Gears::Logger::Handler>, which handles the actual
logging using L<Log::Handler>. Common configuration keys:

=over

=item * C<outputs> - hash of Log::Handler output destinations (file, screen, etc.)

=item * C<date_format> - strftime date format in logs, mimicing apache format by default

=item * C<log_format> - sprintf log format, mimicing apache format by default

=back

The default C<log_format> is C<[%s] [%s] %s>, where placeholders are: date,
level and message. Log format can be specified on Log::Handler level in
C<outputs> (per output), but it would cause duplication of formatting. In that
case C<log_format> must be set to C<undef> to avoid an exception on startup.

=head1 ADDED INTERFACE

=head2 Controller Methods

=head3 log

	$self->log(info => 'Processing request');
	$self->log(error => 'Something went wrong');

Logs a message at the specified level. Returns the controller instance for
method chaining. Accepts the same arguments as C<Gears::Logger::Handler>'s
C<message> method.

=head2 Hooks

=head3 error

Automatically logs any unhandled exceptions that occur during request
processing at the C<error> level.

=head1 SEE ALSO

L<Thunderhorse::Module>, L<Gears::Logger>

