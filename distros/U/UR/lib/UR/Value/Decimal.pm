package UR::Value::Decimal;
use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::Decimal',
    is => ['UR::Value::Number'],
);

1;
