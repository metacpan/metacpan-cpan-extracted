package UR::Value::Blob;

use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::Blob',
    is => ['UR::Value'],
);

1;
#$Header$
