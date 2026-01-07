package Thunderhorse::Module::Template;
$Thunderhorse::Module::Template::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;
use Gears::Template::TT;

extends 'Thunderhorse::Module';

has field 'template' => (
	isa => InstanceOf ['Gears::Template'],
	lazy => 1,
);

sub _build_template ($self)
{
	my $config = $self->config;

	return Gears::Template::TT->new($config->%*);
}

sub build ($self)
{
	weaken $self;
	my $tpl = $self->template;

	$self->register(
		controller => render => sub ($controller, $template, $vars = {}) {
			return $tpl->process($template, $vars);
		}
	);
}

