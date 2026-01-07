package Thunderhorse::Module::Middleware;
$Thunderhorse::Module::Middleware::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;
use Gears qw(load_component get_component_name);

extends 'Thunderhorse::Module';

sub build ($self)
{
	weaken $self;
	my %wrap = $self->config->%*;

	# NOTE: order must be reversed, because LIFO
	my @keys = reverse sort { ($wrap{$a}{_order} // 0) <=> ($wrap{$b}{_order} // 0) or $a cmp $b }
		keys %wrap;

	$self->wrap(
		sub ($app) {
			foreach my $key (@keys) {
				delete $wrap{$key}{_order};

				my $class = load_component(get_component_name($key, 'PAGI::Middleware'));
				my $mw = $class->new($wrap{$key}->%*);
				$app = $mw->wrap($app);
			}

			return $app;
		}
	);
}

