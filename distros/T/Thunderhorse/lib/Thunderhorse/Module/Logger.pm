package Thunderhorse::Module::Logger;
$Thunderhorse::Module::Logger::VERSION = '0.001';
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

	$self->register(
		controller => log => sub ($controller, $level, @messages) {
			$logger->message($level, @messages);
			return $controller;
		}
	);

	$self->wrap(
		sub ($app) {
			return async sub (@args) {
				try {
					await $app->(@args);
				}
				catch ($ex) {
					$logger->message(error => "$ex");
					die $ex;
				}
			};
		}
	);
}

