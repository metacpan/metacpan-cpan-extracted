use strict;
use warnings;
use utf8;
use Test::More;
use Web::ChromeLogger;
use MIME::Base64;
use JSON::XS;

my $logger = Web::ChromeLogger->new;
$logger->info('All');
$logger->warn('your');
$logger->error('base');
$logger->group_collapsed('Group1');
$logger->info('are belongs to us.');
$logger->group_end('Group1');
$logger->wrap_by_group('Group2');

my $src = $logger->finalize;
my $json = MIME::Base64::decode_base64($src);
my $dat = decode_json($json);

is_deeply $dat, {
    'columns' => [
        'log',
        'backtrace',
        'type'
    ],
    'version' => '0.2',
    'rows' => [
        [ [ 'Group2' ], undef, 'group' ],
        [ [ 'All' ], undef, 'info' ],
        [ [ 'your' ], undef, 'warn' ],
        [ [ 'base' ], undef, 'error' ],
        [ [ 'Group1' ], undef, 'groupCollapsed' ],
        [ [ 'are belongs to us.' ], undef, 'info' ],
        [ [ 'Group1' ], undef, 'groupEnd' ],
        [ [ 'Group2' ], undef, 'groupEnd' ]
    ],
};

done_testing;

