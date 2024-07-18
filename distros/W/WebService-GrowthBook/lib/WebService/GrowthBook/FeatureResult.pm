package WebService::GrowthBook::FeatureResult;
use strict;
use warnings;
no indirect;
use Object::Pad;
use Log::Any qw($log);
use JSON::MaybeXS;

our $VERSION = '0.002';    ## VERSION

class WebService::GrowthBook::FeatureResult {
    field $id    : param : reader;
    field $value : param : reader;
    method on {
        if (JSON::MaybeXS::is_bool($value)) {
            return $value ? 1 : 0;
        }
        $log->errorf("FeatureResult->on/off called on non-boolean feature %s", $id);
        return undef;
    }
    method off {
        my $result = $self->on;
        return $result unless defined($result);
        return $result ? 0 : 1;
    }
}
