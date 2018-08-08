package UR::Value::Integer;


use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::Integer',
    is => ['UR::Value::Number'],
);

1;
#$Header$
