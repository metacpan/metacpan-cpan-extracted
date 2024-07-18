package WebService::GrowthBook::CacheEntry;
use strict;
use warnings;
no indirect;
use Object::Pad;

our $VERSION = '0.002';    ## VERSION

class WebService::GrowthBook::CacheEntry {
    field $value : param : reader;
    field $ttl : param;
    field $expires;        # = time() + $ttl;
    ADJUST {
        $expires = time() + $ttl;
    }
    method update($new_value) {
        $value   = $new_value;
        $expires = time() + $ttl;
    }
    method expired() {
        return $expires < time();
    }
}
1;
