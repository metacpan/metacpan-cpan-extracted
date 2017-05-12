package UR::Value::CSV;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::CSV',
    is => ['UR::Value'],
);

1;
#$Header$
