
package UR::Object::Set::View::Default::Html;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Object::Set::View::Default::Html {
    is => 'UR::Object::View::Default::Html',
    has_constant => [
        default_aspects => {
            value => [
                'rule_display',
                'members'
            ]
        }
    ]
};

1;
