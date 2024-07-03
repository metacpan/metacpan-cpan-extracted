package WebService::GrowthBook::Feature;
use strict;
use warnings;
no indirect;
use Object::Pad;

our $VERSION = '0.001';    ## VERSION

class WebService::GrowthBook::Feature {
    field $id            : param : reader;
    field $default_value : param : reader;
    field $value_type    : param : reader;
}

1;
