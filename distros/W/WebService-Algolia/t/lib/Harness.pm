package t::lib::Harness;

use Exporter 'import';
use Memoize;
use Test::More import => [qw(plan)];
use WebService::Algolia;

our @EXPORT_OK = qw(
    alg
    skip_unless_has_keys
);

memoize 'alg';
sub alg {
    return WebService::Algolia->new(
        application_id => application_id(),
        api_key        => api_key(),
    ) if (application_id() and api_key());
}

sub application_id { $ENV{ALGOLIA_APPLICATION_ID} }
sub api_key        { $ENV{ALGOLIA_API_KEY}        }

sub skip_unless_has_keys {
    plan skip_all => 'ALGOLIA_APPLICATION_ID and ALGOLIA_API_KEY are required'
        unless alg();
}

1;
