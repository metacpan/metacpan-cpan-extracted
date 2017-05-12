use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'LWP::Protocol::PSGI';
use File::Temp;
use File::pushd;

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

my $pushd = pushd(File::Temp::tempdir(CLEANUP => 1));

my $client = Ukigumo::Client->new(
    vc => Ukigumo::Client::VC::Callback->new(
        update_cb  => sub {
            open my $fh, '>', '.ukigumo.yml'
                or die;
            print {$fh} "--\n- x\n   - Y\nTHIS IS INVALID YAML";
            close $fh;
        },
        branch     => 'master',
        repository => 'git:...',
    ),
    server_url => 'http://localhost/',
    executor   => Ukigumo::Client::Executor::Callback->new(
        run_cb => sub {
            return STATUS_NA;
        }
    ),
    quiet => 1,
);
eval { $client->run() };
like $@, qr/.ukigumo.yml/;
note $@;

done_testing;
