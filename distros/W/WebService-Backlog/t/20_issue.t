use strict;
use Test::More tests => 14;

use Data::Dumper;

use WebService::Backlog::Issue;

{
    my $issue = new WebService::Backlog::Issue->new(
        {
            id         => 123,
            key        => 'BLG-1400',
            components => [
                {
                    id   => 1001,
                    name => 'カテゴリ1001',
                },
                {
                    id   => 1002,
                    name => 'カテゴリ1002',
                },
            ],
        }
    );
    is( ref( $issue->components ),         'ARRAY' );
    is( scalar( @{ $issue->components } ), 2 );
    is( $issue->components->[0]->name,     'カテゴリ1001' );
    is( $issue->components->[1]->name,     'カテゴリ1002' );

    ok( !$issue->milestones );
}
{
    my $issue = new WebService::Backlog::Issue->new(
        {
            id         => 123,
            key        => 'BLG-1400',
            components => [
                {
                    id   => 1001,
                    name => 'カテゴリ1001',
                },
                {
                    id   => 1002,
                    name => 'カテゴリ1002',
                },
            ],
            versions => [
                {
                    id   => 10001,
                    name => 'バージョン10001',
                },
                {
                    id   => 10002,
                    name => 'バージョン10002',
                },
                {
                    id   => 10003,
                    name => 'バージョン10003',
                },
            ],
        }
    );
    is( ref( $issue->components ),         'ARRAY' );
    is( scalar( @{ $issue->components } ), 2 );
    is( $issue->components->[0]->name,     'カテゴリ1001' );
    is( $issue->components->[1]->name,     'カテゴリ1002' );

    is( ref( $issue->versions ),         'ARRAY' );
    is( scalar( @{ $issue->versions } ), 3 );
    is( $issue->versions->[0]->name,     'バージョン10001' );
    is( $issue->versions->[1]->name,     'バージョン10002' );

    ok( !$issue->milestones );
}
