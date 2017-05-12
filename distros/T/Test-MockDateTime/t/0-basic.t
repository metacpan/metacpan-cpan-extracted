use strict;
use warnings;
use DateTime;
use Test::More;

use ok 'Test::MockDateTime';

can_ok 'main', 'on';

# I hope nobody turns back the time :-)
isnt +DateTime->now->ymd,
    '2013-01-02', 
    'current time is later than 2013-01-02';

on '2013-01-02 12:23:45', sub {
    isa_ok +DateTime->now, 'DateTime';
    
    is +DateTime->now->ymd,
        '2013-01-02',
        'mocked now date is 2013-01-02';

    is +DateTime->now->hms,
        '12:23:45',
        'mocked now time is 12:23:45';
};

isnt +DateTime->now->ymd,
    '2013-01-02', 
    'current time is later than 2013-01-02 again';

done_testing;
