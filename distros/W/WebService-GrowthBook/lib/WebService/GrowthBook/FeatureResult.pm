package WebService::GrowthBook::FeatureResult;
use strict;
use warnings;
no indirect;
use Object::Pad;
use Log::Any qw($log);

our $VERSION = '0.001';    ## VERSION

class WebService::GrowthBook::FeatureResult {
    field $id    : param : reader;
    field $value : param : reader;
    field $type  : param : reader;
    method on {
        if ($type eq 'boolean') {
            return $value ? 1 : 0;
        }
        $log->errorf("FeatureResult->on called on non-boolean feature %s", $id);
        return undef;
    }
    method off {
        if ($type eq 'boolean') {
            return $value ? 0 : 1;
        }
        $log->errorf("FeatureResult->off called on non-boolean feature %s", $id);
        return undef;
    }
}
