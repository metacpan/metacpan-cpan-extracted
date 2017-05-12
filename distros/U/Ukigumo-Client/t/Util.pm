package t::Util;
use strict;
use warnings;
use Ukigumo::Client;
use Ukigumo::Client::VC::Callback;
use Ukigumo::Client::Executor::Callback;

use parent qw/Exporter/;
our @EXPORT_OK = qw/dispense_client/;

sub dispense_client {
    Ukigumo::Client->new(
        vc => Ukigumo::Client::VC::Callback->new(
            update_cb  => sub { },
            branch     => 'master',
            repository => 'git:...',
        ),
        server_url => 'http://localhost/',
        executor   => Ukigumo::Client::Executor::Callback->new(
            run_cb => sub { }
        ),
        workdir => '/tmp',
        quiet => 1,
    );
}

1;

