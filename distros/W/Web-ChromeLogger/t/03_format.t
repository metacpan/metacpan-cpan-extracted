use strict;
use warnings;
use utf8;
use Test::More;
use Web::ChromeLogger;
use MIME::Base64;
use JSON::XS;

my $logger = Web::ChromeLogger->new;
$logger->infof('%s', 'All');
$logger->warnf('%s', 'your');
$logger->errorf('%s', 'base');
$logger->group_collapsedf('Group%d', 1);
$logger->infof('are %s to %s.', 'belongs', 'us');
$logger->group_endf('Group%d', 1);
$logger->wrap_by_groupf('Group%d', 2);
$logger->groupf('Group%d', 3);
$logger->group_endf('Group%d', 3);

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
        [ [ 'Group2' ], undef, 'groupEnd' ],
        [ [ 'Group3' ], undef, 'group' ],
        [ [ 'Group3' ], undef, 'groupEnd' ],
    ],
};

done_testing;

