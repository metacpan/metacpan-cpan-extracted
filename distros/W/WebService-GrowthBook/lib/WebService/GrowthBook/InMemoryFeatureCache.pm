package WebService::GrowthBook::InMemoryFeatureCache;
use strict;
use warnings;
no indirect;
use feature qw(state);
use Object::Pad;
use WebService::GrowthBook::CacheEntry;

our $VERSION = '0.001';    ## VERSION

class WebService::GrowthBook::InMemoryFeatureCache : isa(WebService::GrowthBook::AbstractFeatureCache) {
    field %cache;

    method get($key) {
        my $entry = $cache{$key};
        return undef unless $entry;
        return $entry->value if !$entry->expired;
        return undef;
    }

    method set($key, $value, $ttl) {
        if (exists $cache{$key}) {
            $cache{$key}->update($value);
            return;
        }
        $cache{$key} = WebService::GrowthBook::CacheEntry->new(
            value => $value,
            ttl   => $ttl
        );
    }

    method clear() {
        %cache = ();
    }

    sub singleton ($class) {
        state $instance = $class->new();
        return $instance;
    }
}
