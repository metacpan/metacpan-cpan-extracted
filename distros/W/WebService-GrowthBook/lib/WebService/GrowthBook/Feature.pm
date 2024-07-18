package WebService::GrowthBook::Feature;
use strict;
use warnings;
no indirect;
use Object::Pad;

our $VERSION = '0.002';    ## VERSION

class WebService::GrowthBook::Feature {
    field $id            : param : reader;
    field $default_value : param : reader;
}

1;
