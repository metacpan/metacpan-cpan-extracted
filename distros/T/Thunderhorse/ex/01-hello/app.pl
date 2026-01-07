use v5.40;

package HelloApp;

use Mooish::Base -standard;
extends 'Thunderhorse::App';

sub build ($self)
{
	$self->router->add(
		'/hello/?msg' => {
			to => sub ($self, $ctx, $msg) {
				return "Hello, $msg";
			},
			defaults => {
				msg => 'world',
			},
		}
	);
}

HelloApp->new->run;

