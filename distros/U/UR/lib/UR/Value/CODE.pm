package UR::Value::CODE;

use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::CODE',
    is => ['UR::Value::PerlReference'],
);

1;
#$Header$
