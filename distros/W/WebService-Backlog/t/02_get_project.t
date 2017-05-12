use strict;
use warnings;
use utf8;

use Test::More tests => 10;

use WebService::Backlog;
use Encode;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

{
    my $project = $backlog->getProject(20);
    ok($project);
    is( $project->id,  20 );
    is( $project->key, 'BLG' );

    #    is( $project->name, decode_utf8('バグ報告・要望受付') );
    is( $project->url, 'https://backlog.backlog.jp/projects/BLG' );
}

{
    my $project = $backlog->getProject('BLG');
    ok($project);
    is( $project->id,  20 );
    is( $project->key, 'BLG' );

    #    is( $project->name, decode_utf8('バグ報告・要望受付') );
    is( $project->url, 'https://backlog.backlog.jp/projects/BLG' );
}

# Project not found.
{
    my $project = $backlog->getProject(10);
    ok( !$project );
}
{
    my $project = $backlog->getProject('FOOO');
    ok( !$project );
}
