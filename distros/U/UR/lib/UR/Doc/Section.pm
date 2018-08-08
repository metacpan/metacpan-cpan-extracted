package UR::Doc::Section;

use strict;
use warnings;

use UR;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Doc::Section {
    is => 'UR::Object',
    has => [
        title => {
            is => 'Text',
            is_optional => 1,
        },
        content => {
            is => 'Text',
            doc => 'pod content for this section',
        },
        format => {
            is => 'Text',
            default_value => 'pod',
            valid_values => ['html','pod','txt'],
        },
    ],
};
