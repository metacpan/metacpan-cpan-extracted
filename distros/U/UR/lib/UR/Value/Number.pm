package UR::Value::Number;
use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::Number',
    is => ['UR::Value'],
);

sub __display_name__ {
    shift->id + 0;
}

1;
