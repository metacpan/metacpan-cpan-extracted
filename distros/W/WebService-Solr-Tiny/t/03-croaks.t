use Test2::V0;
use WebService::Solr::Tiny;

my $solr = WebService::Solr::Tiny->new(
    agent => mock {} => add => [ get => sub { { content => 500 } } ] );

is dies { $solr->search },
    'Solr request failed - 500 at ' .
    __FILE__ . ' line ' . ( __LINE__ - 2 ) . ".\n";

done_testing;
