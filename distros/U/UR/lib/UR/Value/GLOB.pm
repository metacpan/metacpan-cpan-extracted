package UR::Value::GLOB;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::GLOB',
    is => ['UR::Value::PerlReference'],
);

1;
#$Header$
