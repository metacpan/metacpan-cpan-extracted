use strict;
use warnings;
use DateTime;

{
    schema_class => 'WWW::Hashbang::Pastebin::Schema',
    resultsets => ['Paste'],
    fixture_sets => {
        basic => [
            Paste => [
                [qw( paste_id paste_content paste_deleted paste_date )],
                [1, "test1\nline2", 0, DateTime->now( time_zone => 'UTC' )->subtract( minutes => 5 )],
                [2, 'test2', 1, DateTime->now( time_zone => 'UTC' )->subtract( minutes => 5 )],
                [3, '<omg>', 0, DateTime->now( time_zone => 'UTC' )->subtract( minutes => 4 )],
            ]
        ]
    },
};
