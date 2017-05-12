package UR::Value::JSON;

use strict;
use warnings;

use JSON;

class UR::Value::JSON {
    is => 'UR::Value',
};

my $_JS_CODEC = new JSON->allow_nonref;

sub __serialize_id__ {
    shift;
    return $_JS_CODEC->canonical->encode(@_);
}

sub __deserialize_id__ {
    shift;
    return $_JS_CODEC->decode(@_);
}

1;
