package WebService::GrowthBook::FeatureRepository;
use strict;
use warnings;
no indirect;
use Scalar::Util qw(blessed);
use Object::Pad;
use HTTP::Tiny;
use Log::Any    qw($log);
use Digest::MD5 qw(md5_base64);
use Syntax::Keyword::Try;
use JSON::MaybeUTF8 qw(decode_json_utf8);
use WebService::GrowthBook::InMemoryFeatureCache;

our $VERSION = '0.002';    ## VERSION

class WebService::GrowthBook::FeatureRepository {
    field $http : param : writer //= HTTP::Tiny->new();
    field $cache : param //= WebService::GrowthBook::InMemoryFeatureCache->singleton();
    method set_cache($new_cache) {
        die "Invalid cache object $new_cache" unless blessed($new_cache) && $new_cache->isa('WebService::GrowthBook::AbstractFeatureCache');
        $cache = $new_cache;
    }

    method clear_cache() {
        $cache->clear();
    }
    method load_features($api_host, $client_key, $ttl = 60) {
        my $key      = get_cache_key($api_host, $client_key);
        my $features = $cache->get($key);
        if ($features) {
            $log->debug("Features loaded from cache");
            return $features;
        }
        $features = $self->_fetch_features($api_host, $client_key);
        if ($features) {
            $cache->set($key, $features, $ttl);
            $log->debug("Features loaded from GrowthBook API, set in cache");
        }

        return $features;
    }

    method _fetch_features($api_host, $client_key) {
        my $decoded = $self->_fetch_and_decode($api_host, $client_key);

        # TODO decrypt here
        if (exists $decoded->{features}) {
            return $decoded->{features};
        } else {
            $log->warn("GrowthBook API response missing features");
            return;
        }
    }

    method _fetch_and_decode($api_host, $client_key) {
        try {
            my $r = $self->_get($self->_get_features_url($api_host, $client_key));
            if ($r->{status} >= 400) {
                $log->warnf("Failed to fetch features, received status code %d", $r->{status});
                return;
            }
            my $decoded = decode_json_utf8($r->{content});
            return $decoded;
        } catch ($e) {
            $log->warnf("Failed to decode feature JSON from GrowthBook API: %s", $e);
        }
        return;
    }
    method _get($url) {
        my $headers = {
            'Content-Type' => 'application/json',
        };

        return $http->get($url, {headers => $headers});
    }

    method _get_features_url($api_host, $client_key) {
        return "$api_host/api/features/$client_key";
    }
}

sub get_cache_key ($api_host, $client_key) {
    return md5_base64($api_host . '::' . $client_key);
}
1;
