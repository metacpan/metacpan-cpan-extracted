
package UR::Object::Set::View::Default::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Object::Set::View::Default::Text {
    is => 'UR::Object::View::Default::Text',
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
