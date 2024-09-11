package WebService::GrowthBook::FeatureResult;
use strict;
use warnings;
no indirect;
use Object::Pad;
use Log::Any qw($log);
use JSON::MaybeXS;

our $VERSION = '0.003'; ## VERSION

class WebService::GrowthBook::FeatureResult{
    field $feature_id :param :reader;
    field $value :param :reader;
    field $source :param :reader //= '';
    field $experiment :param //= undef;
    field $experiment_result :param //= undef;
    field $rule_id :param //= undef;

    method on{
        return $value ? 1 : 0;
    }
    method off{
        my $result = $self->on;
        return $result ? 0 : 1;
    }

    method to_hash {
        my %data = (
            value => $value,
            source => $source,
            on => $self->on,
            off => $self->off,
        );

        $data{ruleId} = $rule_id if defined $rule_id;
        $data{experiment} = $experiment->to_hash() if defined $experiment;
        $data{experimentResult} = $experiment_result->to_hash() if defined $experiment_result;
        return \%data;
    }
}
