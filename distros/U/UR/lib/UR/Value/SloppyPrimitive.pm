package UR::Value::SloppyPrimitive;
use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::SloppyPrimitive',
    is => ['UR::Value'],
);

# namespaces which have allow_sloppy_primitives() set to true 
# will use this for any unrecognizable data types.

1;

