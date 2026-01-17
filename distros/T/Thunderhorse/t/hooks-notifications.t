use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether hooks notifications are handled correctly
################################################################################

package HooksApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	has field 'events' => (
		clearer => 1,
		lazy => sub { {} },
	);

	sub build ($self)
	{
		weaken $self;

		$self->add_hook(
			error => sub (@args) {
				$self->events->{error} = [@args];
			}
		);

		$self->add_hook(
			startup => sub (@args) {
				$self->events->{startup} = [@args];
			}
		);

		$self->add_hook(
			shutdown => sub (@args) {
				$self->events->{shutdown} = [@args];
			}
		);

		$self->router->add(
			'/error' => {
				to => sub {
					die {error => true};
				}
			}
		);
	}
};

subtest 'should handle lifespan events' => sub {
	my $app = HooksApp->new;
	my $state = pagi_run $app, sub { };

	is $app->events->{startup}, [exact_ref $state], 'startup ok';
	is $app->events->{shutdown}, [exact_ref $state], 'shutdown ok';
};

subtest 'should handle 404 event' => sub {
	my $app = HooksApp->new;
	http $app, GET '/error';

	is $app->events->{error}, [
		check_isa('Thunderhorse::Controller'),
		check_isa('Thunderhorse::Context'),
		{error => true}
		],
		'error ok';
};

done_testing;

