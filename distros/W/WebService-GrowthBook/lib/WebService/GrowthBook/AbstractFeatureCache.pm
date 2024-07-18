package WebService::GrowthBook::AbstractFeatureCache;
use strict;
use warnings;
no indirect;
use Object::Pad;

our $VERSION = '0.002';    ## VERSION

class WebService::GrowthBook::AbstractFeatureCache {
    method get($key) {
        die "get not implemented";
    }
    method set($key, $value, $ttl) {
        die "set not implemented";
    }
    method clear() {
        die "clear not implemented";
    }
};

1;
