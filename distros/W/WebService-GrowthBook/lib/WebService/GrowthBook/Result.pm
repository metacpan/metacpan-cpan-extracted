package WebService::GrowthBook::Result;

use strict;
use warnings;
no indirect;
use Object::Pad;

our $VERSION = '0.003'; ## VERSION

class WebService::GrowthBook::Result{
    field $variation_id :param :reader;
    field $in_experiment :param :reader;
    field $value :param :reader;
    field $hash_used :param :reader;
    field $hash_attribute :param :reader;
    field $hash_value :param :reader;
    field $feature_id :param :reader;
    field $bucket :param :reader //= undef;
    field $sticky_bucket_used :param :reader //= undef;
    field $meta :param //= undef;
    field $key :reader //= undef;

    field $name :reader //= "";
    field $passthrough :reader //= 0;;

    sub BUILDARGS {
        my $class = shift;
        my %args = @_;
        return %args;
    }

    ADJUST {
        $key = defined($variation_id) ? "$variation_id" : undef;
        $name = $meta->{name} if exists $meta->{name};
        $key = $meta->{key} if exists $meta->{key};
        $passthrough = $meta->{passthrough} if exists $meta->{passthrough};
    }

    method to_hash {
        my %obj = (
            featureId         => $feature_id,
            variationId       => $variation_id,
            inExperiment      => $in_experiment,
            value              => $value,
            hashUsed          => $hash_used,
            hashAttribute     => $hash_attribute,
            hashValue         => $hash_value,
            key                => $key,
        );

        $obj{stickyBucketUsed} = $sticky_bucket_used if $sticky_bucket_used;
        $obj{bucket} = $self->bucket if defined $bucket;
        $obj{name} = $name if $name;
        $obj{passthrough} = 1 if $self->passthrough;

        return \%obj;
    }


}

1;
