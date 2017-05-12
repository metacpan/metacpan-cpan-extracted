use 5.14.1;
use warnings;

use Test::More;
use Test::Fatal;

use Twitter::API::Util qw/:all/;

## Timestamp methods

sub ex_timestamp { 'Wed Jun 06 20:07:10 +0000 2012' }
sub ex_time { 1339013230 }

can_ok('Twitter::API::Util', $_) for qw/
    timestamp_to_time
    timestamp_to_gmtime
    timestamp_to_localtime
    is_twitter_api_error
/;

is timestamp_to_time(ex_timestamp), ex_time, 'example timestamp to time';
is(
    scalar timestamp_to_gmtime(ex_timestamp),
    scalar gmtime(ex_time),
    'example timestamp to gmtime (scalar)'
);
is(
    scalar timestamp_to_localtime(ex_timestamp),
    scalar localtime(ex_time),
    'example timestamp to localtime (scalar)'
);
is_deeply(
    [ timestamp_to_gmtime(ex_timestamp) ],
    [ gmtime(ex_time) ],
    'example timestamp to gmtime (list context)'
);
is(
    scalar timestamp_to_localtime(ex_timestamp),
    scalar localtime(ex_time),
    'example timestamp to localtime (list context)'
);

is timestamp_to_time(), undef, 'returns undef on undef input';

like(
    exception { timestamp_to_time('bougus') },
    qr/invalid timestamp/,
    'croaks on invalid format'
);

## Twitter::API::Error

ok is_twitter_api_error(bless {}, 'Twitter::API::Error'), 'is api error';
ok !is_twitter_api_error(bless {}, 'Foo'), 'other object is not api error';
ok !is_twitter_api_error(1234), 'plain scalar is not api error';
ok !is_twitter_api_error(), 'empty is not api error';

done_testing;
