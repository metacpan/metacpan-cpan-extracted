use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'LWP::Protocol::PSGI';
use File::Temp;

use Ukigumo::Client;
use Ukigumo::Client::VC::Callback;
use Ukigumo::Client::Executor::Callback;
use Ukigumo::Client::Notify::Callback;
use Ukigumo::Constants;
use JSON;

my $REPORT_URL = 'http://...';
LWP::Protocol::PSGI->register(sub{
	ok 1;

	[200, ['Content-Type' => 'text/json'], [
		encode_json(+{
			report => {
				url => $REPORT_URL,
			},
		})
	]];
});

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $client = Ukigumo::Client->new(
    vc => Ukigumo::Client::VC::Callback->new(
        update_cb  => sub { },
        branch     => 'master',
        repository => 'git:...',
    ),
    server_url => 'http://localhost/',
    executor   => Ukigumo::Client::Executor::Callback->new(
        run_cb => sub {
            return STATUS_NA;
        }
    ),
    workdir => $tempdir,
    quiet => 1,
);

$client->push_notifier(
    Ukigumo::Client::Notify::Callback->new(
        send_cb => sub {
            my ($c, $status, $last_status, $report_url) = @_;
            is $status,     STATUS_NA;
            ok !$last_status;
            is $report_url, $REPORT_URL;
        }
    ),
);

$client->run();

done_testing;
