use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use WebService::Backlog;
use Encode;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

my $projects = $backlog->getProjects;
is( scalar( @{$projects} ), 1 );
is( $projects->[0]->id,     20 );
is( $projects->[0]->key,    'BLG' );

#is( $projects->[0]->name,   decode_utf8('バグ報告・要望受付') );
is( $projects->[0]->url, 'https://backlog.backlog.jp/projects/BLG' );

