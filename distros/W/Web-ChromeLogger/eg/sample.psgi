use v5.18.0;
use Web::ChromeLogger;

sub {
    my $logger = Web::ChromeLogger->new;
    $logger->info('All');
    $logger->warn('your');
    $logger->error('base');
    $logger->group_collapsed('Group1');
    $logger->info('are belongs to us.');
    $logger->group_end('Group1');
    $logger->wrap_by_group('Group2');

    [
        200,
        [
            'Content-Type' => 'text/plain; charset=utf-8',
            'X-ChromeLogger-Data' => $logger->finalize,
        ],
        ['OK']
    ]
};
