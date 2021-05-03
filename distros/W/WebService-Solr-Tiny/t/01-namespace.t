use Test2::V0;
use WebService::Solr::Tiny;

is [ sort keys %WebService::Solr::Tiny:: ] => [ qw/
    BEGIN EXPORT EXPORT_OK VERSION __ANON__
    import new search solr_escape solr_query
/];

done_testing;
