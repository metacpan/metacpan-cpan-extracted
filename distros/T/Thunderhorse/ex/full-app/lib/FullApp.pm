package FullApp;

use v5.40;
use Mooish::Base;

extends 'Thunderhorse::App';

sub build ($self)
{
	# system has been initialized with config files
	$self->router->add(
		'/' => {
			to => 'welcome_page',
		},
	);
}

sub welcome_page ($self, $ctx)
{
	return $self->template(
		'welcome', {
			config => $self->config->config,
			api_url => $self->url_for('location_list_api'),
		}
	);
}

