package UR::Value::String;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::String',
    is => ['UR::Value::Text'],
);

1;
#$Header$
