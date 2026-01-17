package Thunderhorse::Module::Middleware;
$Thunderhorse::Module::Middleware::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;
use Gears qw(load_component get_component_name);

extends 'Thunderhorse::Module';

sub build ($self)
{
	weaken $self;
	my %wrap = $self->config->%*;

	# NOTE: order must be reversed, because of LIFO
	my @keys = reverse sort { ($wrap{$a}{_order} // 0) <=> ($wrap{$b}{_order} // 0) or $a cmp $b }
		keys %wrap;

	foreach my $key (@keys) {
		delete $wrap{$key}{_order};

		my $class = load_component(get_component_name($key, 'PAGI::Middleware'));
		my $mw = $class->new($wrap{$key}->%*);
		$self->add_middleware($mw);
	}
}

__END__

=head1 NAME

Thunderhorse::Module::Middleware - Middleware module for Thunderhorse

=head1 SYNOPSIS

	# in application build method
	$self->load_module('Middleware' => {
		Static => {
			path => '/static',
			root => 'public',
		},
		Session => {
			store => 'file',
		},
	});

	# with explicit ordering
	$self->load_module('Middleware' => {
		Static => { path => '/static', root => 'public', _order => 1 },
		Session => { store => 'file', _order => 2 },
	});

=head1 DESCRIPTION

The Middleware module allows loading any PAGI middleware into the application.
It wraps the entire PAGI application with specified middlewares.

=head1 CONFIGURATION

Each key in the configuration is a middleware class name (will be prefixed with
C<PAGI::Middleware::> unless it starts with C<^>). The value is a hash
reference of configuration passed to that middleware's constructor.

Middlewares are applied in deterministic order (sorted by key name). To control
the order explicitly, use the C<_order> key in middleware configuration.

Lower C<_order> values are applied first, higher values are applied last.

=head1 ADDED INTERFACE

=head2 Application-level middleware

Application is wrapped in all middleware specified in the config.

=head1 SEE ALSO

L<Thunderhorse::Module>, L<PAGI::Middleware>

