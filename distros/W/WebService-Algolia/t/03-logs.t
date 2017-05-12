use Test::Modern;
use t::lib::Harness qw(alg skip_unless_has_keys);

skip_unless_has_keys;

subtest 'Log Management' => sub {
    my $logs = alg->get_logs;
    is @{$logs->{logs}} => 10,
        'Retrieved 10 log entries by default'
        or diag explain $logs;

    my $offset = 4;
    my $length = 2;
    $logs = alg->get_logs({
        offset     => $offset,
        length     => $length,
    });
    is @{$logs->{logs}} => 2,
        "Retrieved $length log entries at offset $offset"
        or diag explain $logs;
};

done_testing;
