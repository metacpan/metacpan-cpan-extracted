package UR::Value::FOF;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::FOF',
    is => ['UR::Value'],
);

1;
#$Header$
