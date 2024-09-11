package WebService::GrowthBook::Experiment;

use strict;
use warnings;
use WebService::GrowthBook::Util qw(adjust_args_camel_to_snake);
use Object::Pad;

our $VERSION = '0.003'; ## VERSION

class WebService::GrowthBook::Experiment {
    field $key :param :reader;
    field $variations :param :reader //= [];
    field $weights :param :reader //= [];
    field $active :param :reader //= 1;
    field $status :param :reader //= "running";
    field $coverage :param :reader //= undef;
    field $condition :param :reader //= undef;
    field $namespace :param :reader //= undef;
    field $url :param :reader //= '';
    field $include :param :reader //= undef;
    field $groups :param :reader //= undef;
    field $force :param :reader //= undef;
    field $hash_attribute :param :reader //= 'id';
    field $fallback_attribute :param :reader //= undef;
    field $hash_version :param :reader //= 1;
    field $ranges :param :reader //= undef;
    field $meta :param :reader //= undef;
    field $filters :param :reader //= undef;
    field $seed :param :reader //= undef;
    field $name :param :reader //= undef;
    field $phase :param :reader //= undef;;
    field $disable_sticky_bucketing :param :reader //= 0;
    field $bucket_version :param :reader //= 0;
    field $min_bucket_version :param :reader //= 0;
    field $parent_conditions :param :reader //= undef;

    sub BUILDARGS {
        my ($class, %args) = @_;
        adjust_args_camel_to_snake(\%args);
        return %args;
    }


    method update($data) {
        $weights = $data->{weights} if exists $data->{weights};
        $status = $data->{status} if exists $data->{status};
        $coverage = $data->{coverage} if exists $data->{coverage};
        $url = $data->{url} if exists $data->{url};
        $groups = $data->{groups} if exists $data->{groups};
        $force = $data->{force} if exists $data->{force};
    }

    method to_hash {
        my %obj = (
            key                     => $key,
            variations              => $variations,
            weights                 => $weights,
            active                  => $active,
            coverage                => $coverage // 1,
            condition               => $condition,
            namespace               => $namespace,
            force                   => $force,
            hash_attribute           => $hash_attribute,
            hash_version             => $hash_version,
            ranges                  => $ranges,
            meta                    => $meta,
            filters                 => $filters,
            seed                    => $seed,
            name                    => $name,
            phase                   => $phase,
        );

        $obj{fallback_attribute} = $fallback_attribute if defined $fallback_attribute;
        $obj{disable_sticky_bucketing} = 1 if $disable_sticky_bucketing;
        $obj{bucket_version} = bucket_version if $bucket_version;
        $obj{min_bucket_version} = min_bucket_version if $min_bucket_version;
        $obj{parent_conditions} = parent_conditions if $parent_conditions;

        return \%obj;
    }
}

1;
