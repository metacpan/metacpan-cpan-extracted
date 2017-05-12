use strict;
use warnings;

use Test::More 0.96;

use WebService::TeamCity;

{
    my %camel = (
        project => [
            {
                id     => 7,
                name   => 'test 1',
                webUrl => 'http://...',
            },
            {
                id              => 42,
                name            => 'test 2',
                webUrl          => 'http://...',
                parentProjectId => 7,
                subHash         => {
                    moreCamel => 'foo',
                },
            },
        ],
    );

    my %expect = (
        project => [
            {
                id      => 7,
                name    => 'test 1',
                web_url => 'http://...',
            },
            {
                id                => 42,
                name              => 'test 2',
                web_url           => 'http://...',
                parent_project_id => 7,
                sub_hash          => {
                    more_camel => 'foo',
                },
            },
        ],
    );

    ## no critic (Subroutines::ProtectPrivateSubs)
    is_deeply(
        WebService::TeamCity->_decamelize_keys( \%camel ),
        \%expect,
        '_decamelize_keys recursively turns camel case keys to snake case'
    );
}

done_testing();
