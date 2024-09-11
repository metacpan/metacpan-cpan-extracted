package WebService::GrowthBook::FeatureRule;
use strict;
use warnings;
no indirect;
use WebService::GrowthBook::Util qw(adjust_args_camel_to_snake);
use Object::Pad;

our $VERSION = '0.003'; ## VERSION

# TODO check every class's feild if they are camelCase or snake_case
class WebService::GrowthBook::FeatureRule {
    field $id :param :reader //= undef;
    field $key :param :reader //= '';
    field $variations :param :reader //= undef;
    field $weights :param :reader //= undef;
    field $coverage :param :reader //= undef;
    field $condition :param :reader //= undef;
    field $namespace :param :reader //= undef;
    field $force :param :reader //= undef;
    field $hash_attribute :param :reader //= 'id';
    field $fallback_attribute :param :reader //= undef;
    field $hash_version :param :reader //= 1;
    field $range :param :reader //= undef;
    field $ranges :param :reader //= undef;
    field $meta :param :reader //= undef;
    field $filters :param :reader //= undef;
    field $seed :param :reader //= undef;
    field $name :param :reader //= undef;
    field $phase :param :reader //= undef;
    field $disable_sticky_bucketing :param :reader //= undef;
    field $bucket_version :param :reader //= 0;
    field $min_bucket_version :param :reader //= 0;
    field $parent_conditions :param :reader //= undef;

    sub BUILDARGS {
        my ($class, %args) = @_;
        adjust_args_camel_to_snake(\%args);
        return %args;
    }

    ADJUST {
        if($disable_sticky_bucketing){
            $fallback_attribute = undef;
        }

    }

    method to_hash {
        return {
            id => $id,
            key => $key,
            variations => $variations,
            weights => $weights,
            coverage => $coverage,
            condition => $condition,
            namespace => $namespace,
            force => $force,
            hash_attribute => $hash_attribute,
            fallback_attribute => $fallback_attribute,
            hash_version => $hash_version,
            range => $range,
            ranges => $ranges,
            meta => $meta,
            filters => $filters,
            seed => $seed,
            name => $name,
            phase => $phase,
            disable_sticky_bucketing => $disable_sticky_bucketing,
            bucket_version => $bucket_version,
            min_bucket_version => $min_bucket_version,
            parent_conditions => $parent_conditions,
        };
    }
}
