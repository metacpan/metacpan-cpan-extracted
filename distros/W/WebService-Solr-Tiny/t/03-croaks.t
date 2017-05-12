use strict;
use warnings;

use Test::Fatal;
use Test::MockObject;
use Test::More tests => 1;
use WebService::Solr::Tiny;

my $agent = Test::MockObject->new;

$agent->set_always(
    get => {
        content => 'Solr had a boo boo',
        success => 0,
    },
);

my $solr = WebService::Solr::Tiny->new( agent => $agent );

is exception { $solr->search },
    'Solr request failed - Solr had a boo boo at ' .
    __FILE__ . ' line ' . ( __LINE__ - 2 ) . ".\n";
