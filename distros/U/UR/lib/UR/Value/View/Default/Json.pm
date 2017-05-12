package UR::Value::View::Default::Json;
use strict;
use warnings;
use UR;

# These Values inherit from Text which inherits from UR::Object::View::Default::Text
class UR::Value::View::Default::Json {
    is => 'UR::Value::View::Default::Text',
};

1;
