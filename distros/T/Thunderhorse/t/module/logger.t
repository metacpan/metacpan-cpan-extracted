use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse Logger module works
################################################################################

my $logged = '';

sub save_log ($msg)
{
	$logged .= $msg->{message};
}

package LoggerApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		# Configure Log4perl with TestBuffer appender to capture output
		$self->load_module(
			'Logger' => {
				outputs => [
					forward => {
						forward_to => \&main::save_log,
						maxlevel => 'info',
					},
				]
			}
		);

		$self->router->add(
			'/test-log' => {
				to => 'test_log',
			}
		);

		$self->router->add(
			'/test-error' => {
				to => 'test_error',
			}
		);
	}

	sub test_log ($self, $ctx)
	{
		$self->log(debug => 'unseen');
		$self->log(info => 'seen');
		$self->log(fatal => 'Test message');
		return 'logged';
	}

	sub test_error ($self, $ctx)
	{
		die "Test error\n";
	}
};

my $app = LoggerApp->new;

subtest 'should have access to log method' => sub {
	$logged = '';    # Clear buffer

	http $app, GET '/test-log';
	http_status_is 200;
	http_text_is 'logged';

	like $logged, qr/^\[.+\] \[INFO\] seen$/m, 'log message captured';
	like $logged, qr/^\[.+\] \[FATAL\] Test message$/m, 'log message captured';
	unlike $logged, qr/unseen/, 'unseen message not logged';
	unlike $logged, qr/\v\v/, 'double newlines not logged';
};

subtest 'should catch and log errors' => sub {
	$logged = '';    # Clear buffer

	http [$app, raise_app_exceptions => false], GET '/test-error';
	http_status_is 500;

	like $logged, qr/^\[.+\] \[ERROR\] Test error$/m, 'error message captured';
	unlike $logged, qr/\v\v/, 'double newlines not logged';
};

done_testing;

