use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'LWP::Protocol::PSGI';
use File::Temp;
use Cwd;

use Ukigumo::Client;
use Ukigumo::Client::VC::Callback;
use Ukigumo::Client::Executor::Callback;
use Ukigumo::Constants;
use JSON;

my $REPORT_URL = 'http://...';
my $test_count = 0;
LWP::Protocol::PSGI->register(sub{
    ok 1;
    $test_count++;

    [200, ['Content-Type' => 'text/json'], [
        encode_json(+{
            report => {
                url => 'http://...',
            },
        })
    ]];
});

my $tmpdir    = File::Temp::tempdir(CLEANUP => 1);
my $revisions = [qw/aaa bbb bbb bbb/];

dispense_client($revisions)->run();
is $test_count, 1;

dispense_client($revisions)->run();
is $test_count, 1;

done_testing;

sub dispense_client {
    my $revisions = shift;

    Ukigumo::Client->new(
        vc => Ukigumo::Client::VC::Callback->new(
            update_cb          => sub { },
            branch             => 'master',
            repository         => 'git:...',
            skip_if_unmodified => 1,
            revision_cb => sub { shift @$revisions },
        ),
        server_url => 'http://localhost/',
        executor   => Ukigumo::Client::Executor::Callback->new(
            run_cb => sub {
                return STATUS_NA;
            }
        ),
        workdir => $tmpdir,
        quiet => 1,
    );
}
